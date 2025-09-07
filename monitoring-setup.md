# Monitoring & Observability Setup for EKS (Prometheus + Grafana)

This document is your single-source reference for installing and configuring **Prometheus**, **Grafana**, and related monitoring components on an **EKS** cluster. Keep this file for future reference and automation.

---

## Prerequisites

* `kubectl` configured to talk to your EKS cluster (`~/.kube/config`).
* `helm` installed on the machine from which you'll deploy.
* AWS EKS cluster with nodegroups running and EBS CSI driver (for dynamic EBS PVC provisioning).
* Ensure you have permission to create LoadBalancers, PVCs and helm charts in the cluster (IAM / kube RBAC).

---

## Quick checklist before you begin

```bash
kubectl version --short
helm version
kubectl config current-context
kubectl get nodes
kubectl get sc
```

* Make sure at least one StorageClass suitable for EBS exists (e.g. `gp3`/`gp2` or `ebs-sc`).
* We will create monitoring resources in the `monitoring` namespace.

---

## Step 1 — Install Helm (if not already installed)

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version
```

---

## Step 2 — Add Prometheus Helm repo and update

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

---

## Step 3 — Create monitoring namespace

```bash
kubectl create namespace monitoring
```

---

## Step 4 — Verify / create StorageClass (EBS)

You need a StorageClass that provisions EBS volumes. Check existing classes:

```bash
kubectl get sc
```

If you already have a default class (e.g. `gp3` or `gp2`) you can use that. If you want a dedicated name `ebs-sc`, create this YAML and apply it.

**ebs-sc.yaml**

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ebs-sc
provisioner: ebs.csi.aws.com
allowVolumeExpansion: true
parameters:
  type: gp3
  fsType: ext4
  encrypted: "true"
reclaimPolicy: Delete
volumeBindingMode: WaitForFirstConsumer
```

```bash
kubectl apply -f ebs-sc.yaml
kubectl get sc ebs-sc
```

**Why `WaitForFirstConsumer`?** EBS volumes are zonal. This option delays PV creation until the pod is scheduled so the PV is created in the correct AZ.

---

## Step 5 — Create Grafana admin secret (do NOT hardcode passwords in git)

Create a Kubernetes Secret in the monitoring namespace and keep strong password policies:

```bash
kubectl -n monitoring create secret generic grafana-admin-secret \
  --from-literal=admin-user=admin \
  --from-literal=admin-password='StrongPassw0rd!'
```

You can later rotate the password with:

```bash
kubectl -n monitoring create secret generic grafana-admin-secret \
  --from-literal=admin-user=admin \
  --from-literal=admin-password='NewStrongPassw0rd!' --dry-run=client -o yaml | kubectl apply -f -
```

To view the current Grafana password (if needed):

```bash
kubectl -n monitoring get secret grafana-admin-secret -o jsonpath='{.data.admin-password}' | base64 --decode
```

---

## Step 6 — Create values file for kube-prometheus-stack (monitoring-values.yaml)

Create `monitoring-values.yaml` with the following contents. This file sets Prometheus and Grafana to use LoadBalancers and instructs Prometheus to use an EBS-backed PVC for persistence.

```yaml
alertmanager:
  enabled: false

prometheus:
  prometheusSpec:
    service:
      type: LoadBalancer
    storageSpec:
      volumeClaimTemplate:
        spec:
          storageClassName: ebs-sc
          accessModes:
            - ReadWriteOnce
          resources:
            requests:
              storage: 5Gi

grafana:
  enabled: true
  service:
    type: LoadBalancer
  admin:
    existingSecret: grafana-admin-secret
    userKey: admin-user
    passwordKey: admin-password

nodeExporter:
  enabled: true
  service:
    type: ClusterIP

kubeStateMetrics:
  enabled: true
  service:
    type: ClusterIP

# additionalScrapeConfigs is optional; the operator usually configures these automatically
additionalScrapeConfigs:
  - job_name: node-exporter
    static_configs:
      - targets: ['node-exporter.monitoring.svc.cluster.local:9100']
  - job_name: kube-state-metrics
    static_configs:
      - targets: ['kube-state-metrics.monitoring.svc.cluster.local:8080']
```

Save the file as `monitoring-values.yaml` in your working directory.

---

## Step 7 — Install kube-prometheus-stack via Helm

```bash
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  -n monitoring -f monitoring-values.yaml
```

If this is the first time installing the chart, Helm will create Prometheus, Alertmanager (disabled by config above), Grafana, node-exporter, kube-state-metrics, and other resources.

---

## Step 8 — Verify resources and services

Check pods and status:

```bash
kubectl get pods -n monitoring
kubectl describe pods -n monitoring --selector=app.kubernetes.io/name=prometheus
```

Check services and external IPs (LoadBalancers may take a few minutes):

```bash
kubectl get svc -n monitoring
kubectl get pvc -n monitoring
```

* **Prometheus** service typically named `prometheus-operated` or similar.
* **Grafana** service typically named `prometheus-grafana` or `monitoring-grafana` depending on chart version.

If PVCs are in `Pending`, verify `storageClassName` exists and `ebs-csi-driver` add-on is installed and healthy in EKS.

---

## Step 9 — Access Grafana & Prometheus

Fetch LoadBalancer IPs from `kubectl get svc -n monitoring` then open in browser:

* Grafana: `http://<grafana-lb-ip>:80`  (or port 3000 based on chart; check `kubectl get svc` output)

  * Username: `admin` (or value from your secret)
  * Password: value from `grafana-admin-secret`

* Prometheus: `http://<prometheus-lb-ip>:9090`

Tip: If you don't want LoadBalancer IPs, port-forward locally:

```bash
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090
kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80
```

---

## Step 10 — Import recommended Grafana dashboards

In Grafana UI → Dashboards → Import:

* `3119` → Kubernetes cluster monitoring
* `6417` → Node Exporter full
* `8588` → Kube State Metrics

You can also import official dashboards for MySQL, Jenkins, etc.

---

## Step 11 — Example alerting (basic)

Enable Alertmanager later and configure Slack notifications. Example of a simple alert rule for node CPU:

Create `node-alerts.yaml` (PrometheusRule CRD):

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: node-alerts
  namespace: monitoring
spec:
  groups:
  - name: node.rules
    rules:
    - alert: NodeHighCPU
      expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Node {{ $labels.instance }} high CPU usage"
        description: "CPU usage is >80% for 5 minutes."
```

```bash
kubectl apply -f node-alerts.yaml
```

To enable Alertmanager with Slack, you will configure Alertmanager's `config.yml` and provide webhook URL; typically you set these via Helm values or via a secret (do not hardcode in git).

---

## Step 12 — Monitor MySQL & Jenkins metrics

* **MySQL**: deploy `prometheus-mysql-exporter` (helm chart) and point it at your MySQL service.
* **Jenkins**: install Jenkins Prometheus plugin and expose `/prometheus` endpoint; add a `ServiceMonitor` to scrape it.

Example MySQL exporter install (Helm):

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install mysql-exporter prometheus-community/prometheus-mysql-exporter \
  -n monitoring --set mysql.user=root --set mysql.password='<mysql-root-password>' \
  --set mysql.host='mysql.rahulverse-prod.svc.cluster.local'
```

**Note:** use Secrets for passwords rather than passing plaintext via command line in production.

---

## Step 13 — Persist Grafana dashboards

* Configure Grafana persistence if you want dashboards to survive chart upgrades:

```yaml
grafana:
  persistence:
    enabled: true
    size: 5Gi
    storageClassName: ebs-sc
```

Add this to `monitoring-values.yaml` and re-run `helm upgrade`.

---

## Step 14 — Best practices & security notes

* **Never commit secrets** (passwords, tokens) to Git. Use Kubernetes Secrets, Jenkins Credentials, or AWS Secrets Manager.
* **Use `existingSecret`** pattern for Helm-managed apps (as shown for Grafana).
* **Use IRSA** (IAM Roles for Service Accounts) for any AWS permissions required by exporters/addons.
* **Set resource requests/limits** for Prometheus/Grafana to avoid OOM on small nodes.
* **Backup Prometheus data** by snapshotting EBS volumes or using remote\_write to long-term storage.

---

## Troubleshooting

* **PVC stuck in Pending**: check `kubectl describe pvc -n monitoring` for events; confirm StorageClass and EBS CSI driver.
* **Grafana startup/login issues**: check `kubectl logs` for Grafana pod; check secret is in correct namespace.
* **LoadBalancer IP not assigned**: AWS ELB provisioning may take several minutes; check `kubectl get svc -n monitoring` and AWS console.
* **Prometheus scrape failures**: check `targets` page in Prometheus UI and `kubectl describe servicemonitor`/`service`.

---

## Useful commands summary

```bash
# Namespace & storage
kubectl create namespace monitoring
kubectl get sc
kubectl apply -f ebs-sc.yaml

# Create Grafana secret
kubectl -n monitoring create secret generic grafana-admin-secret --from-literal=admin-user=admin --from-literal=admin-password='StrongPassw0rd!'

# Install Helm chart
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack -n monitoring -f monitoring-values.yaml

# Verify
kubectl get pods -n monitoring
kubectl get svc -n monitoring
kubectl get pvc -n monitoring

# Port-forward locally (if needed)
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090
kubectl port-forward svc/prometheus-grafana -n monitoring 3000:80

# View Grafana password
kubectl -n monitoring get secret grafana-admin-secret -o jsonpath='{.data.admin-password}' | base64 --decode

# Apply example alerts
kubectl apply -f node-alerts.yaml
```

---

## Appendix — Example Alertmanager Slack config (store as secret, do not commit)

Create a file `alertmanager-config.yaml` containing the Slack webhook in a secret-managed way; then map it in the Helm values or create a secret and configure Alertmanager to read it.

Example snippet (Alertmanager config `config.yml`):

```yaml
route:
  receiver: slack-notifications
receivers:
  - name: slack-notifications
    slack_configs:
      - channel: '#rahulverse-notification'
        api_url: 'https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX'
```

Create a secret:

```bash
kubectl -n monitoring create secret generic alertmanager-config --from-file=alertmanager.yaml=./config.yml
```

Then set Helm values to use this existing config (example):

```yaml
alertmanager:
  enabled: true
  configMapOverrideName: alertmanager-config
```

*Exact values depend on the chart version; check chart docs for `alertmanager` config options.*

---

## Final notes

* This document is designed to be copy/paste runnable for a typical EKS cluster. Adjust `storageClassName`, `namespace`, and secrets to match your environment.
* After monitoring is up, we can add Loki/Promtail for logs and set up persistent dashboards and alerts for application-level metrics (Jenkins, Nexus, SonarQube, MySQL).

---

*End of document.*
