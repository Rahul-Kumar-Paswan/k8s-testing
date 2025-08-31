<!-- # installation on Server VM -->
sudo apt update
sudo apt install zip unzip -y
<!-- Install or update the AWS CLI -->
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

<!-- install terraform -->
wget -O - https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
terraform -version

<!-- clone repo for creating eks cluster -->
git clone https://github.com/Rahul-Kumar-Paswan/rahulverse.git -b terraform-infra
ls # To see folder rahulverse
cd rahulverse
terraform init
terraform apply --auto-approve

<!-- Install kubectl -->
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

<!-- Install eksctl -->
curl -sLO "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz"
tar -xzf eksctl_$(uname -s)_amd64.tar.gz
sudo mv eksctl /usr/local/bin
eksctl version


<!-- aws configure -->
aws configure

<!-- Configure kubeconfig for EKS -->
aws eks --region ap-south-1 update-kubeconfig --name rahulverse-eks

<!-- Associate IAM OIDC Provider with EKS -->
eksctl utils associate-iam-oidc-provider \
  --region ap-south-1 \
  --cluster rahulverse-eks \
  --approve

<!-- Create IAM Service Account for EBS CSI Driver -->
eksctl create iamserviceaccount \
  --region ap-south-1 \
  --name ebs-csi-controller-sa \
  --namespace kube-system \
  --cluster rahulverse-eks \
  --attach-policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy \
  --approve \
  --override-existing-serviceaccounts
# to verify 
kubectl -n kube-system get sa ebs-csi-controller-sa -o yaml 

<!-- EBS CSI Driver -->
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/ecr/?ref=release-1.11"

<!-- 🌐 NGINX Ingress Controller -->
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/cloud/deploy.yaml

<!-- 🔒 cert-manager -->
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.yaml



<!-- # Jenkins Setup  -->

echo "Installing OpenJDK 21..."
sudo apt install -y openjdk-21-jdk-headless

# ------------------------------
# Install Jenkins
# ------------------------------
echo "Setting up Jenkins repository and installing Jenkins..."
sudo mkdir -p /etc/apt/keyrings
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
  sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update
sudo apt-get install -y jenkins

sudo usermod -aG jenkins ubuntu
sudo newgrp
sudo systemctl enable jenkins
sudo systemctl start jenkins

# ------------------------------
# Install Gitleaks
# ------------------------------
echo "Installing Gitleaks..."
sudo apt install -y gitleaks

# ------------------------------
# Install Trivy
# ------------------------------
echo "Installing Trivy..."
sudo apt-get install -y wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | \
  sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install -y trivy

# ------------------------------
# Install Docker & Docker Compose
# ------------------------------
echo "Installing Docker and Docker Compose..."
sudo apt-get install -y ca-certificates curl gnupg

sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
  sudo tee /etc/apt/keyrings/docker.asc > /dev/null
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Set up Docker Compose plugin
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.38.2/docker-compose-linux-x86_64 \
  -o $DOCKER_CONFIG/cli-plugins/docker-compose
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose

docker compose version

# Add jenkins and ubuntu to docker group
sudo usermod -aG docker jenkins
sudo usermod -aG docker ubuntu

<!-- Install kubectl -->
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -sL https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client

<!-- Install eksctl -->
curl -sLO "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz"
tar -xzf eksctl_$(uname -s)_amd64.tar.gz
sudo mv eksctl /usr/local/bin
eksctl version


<!-- # Setup SonarQube -->
sudo apt update
sudo apt install docker.io -y
sudo usermod -aG docker ubuntu
newgrp docker
docker run -d --name SonarQube -p 9000:9000 sonarqube:lts-community
docker ps


<!-- # Setup Nexus -->
sudo apt update
sudo apt install docker.io -y
sudo usermod -aG docker ubuntu
newgrp docker
docker run -d --name nexus3 -p 8081:8081 sonatype/nexus3
docker ps

<!-- Install Plugins on Jenkins -->
stageview
config file provider
maven integration
maven pipeline integration
sonarqube scanner
docker buildpipeline
docker-compose build setup
kubernetes
kubernetes credentials
kubernetes CLI plugins
generic webhook trigger
slack notification
aws credentials

<!-- docker cmds -->
docker login
docker build rahulverse-app:latest .
docker tag rahulverse-app:latest rahulkumarpaswan/rahulverse-app:latest
docker push rahulkumarpaswan/rahulverse-app:latest

<!-- docker-compose cmds -->
docker-compose build .
docker-compose up -d
docker-compose down

<!-- GitHub Webhook Trigger Setup -->
1) GitHub → Jenkins Webhook (Generic Webhook Trigger)
Prerequisites
Jenkins up and reachable from GitHub (public URL or GitHub → Jenkins network path open).
Jenkins plugin: Generic Webhook Trigger (Manage Jenkins → Plugins → Available → install).
A Pipeline (or Freestyle) job in Jenkins.
A. Configure the Jenkins Job
Open your Jenkins job → Configure.
Build Triggers → check Generic Webhook Trigger.
Token → set a token (example: rahulverse). Keep this value secret in docs/repo.
Post content parameters → click Add:
Name: ref
Expression: $.ref
JSONPath (select from the drop-down)
This maps the GitHub payload field ref (e.g., refs/heads/main) into an env var ref in the build.
Optional filter (to only build specific branch):
Expression: $.ref
Text: refs/heads/<BRANCH_NAME> (e.g., refs/heads/main)
Save the job.
Webhook URL format:
http://<JENKINS_URL>/generic-webhook-trigger/invoke?token=<YOUR_TOKEN>
Example:
http://43.204.110.51:8080/generic-webhook-trigger/invoke?token=rahulverse
Note: Avoid committing real tokens/URLs to source control. Use Jenkins Credentials and parameterize where possible.
B. Add Webhook in GitHub
Go to GitHub repo → Settings → Webhooks → Add webhook.
Payload URL: your Jenkins webhook URL from above.
Content type: application/json.
Which events?: Usually Just the push event (add PR events if needed).
Add webhook → then check Recent deliveries to confirm HTTP 200 from Jenkins.


<!-- # slack notification -->
2) Slack Notifications from Jenkins
Option A — Jenkins Slack Plugin (Bot Token)
Best for rich features and easy use of slackSend.
A. Create a Slack App
Go to https://api.slack.com/apps → Create New App → From scratch.
Pick a name (e.g., jenkins) and select your workspace.
OAuth & Permissions → add bot scopes:
chat:write
chat:write.public (optional, to post where the bot isn’t invited)
channels:read, groups:read, users:read (optional for channel/user lookups)
Install to Workspace → authorize → copy Bot User OAuth Token (starts with xoxb-...).
B. Configure Jenkins Slack Plugin
Manage Jenkins → Plugins: install Slack Notification.
Manage Jenkins → System → Slack:
Workspace / Team Subdomain: your Slack subdomain (e.g., myteam).
Credentials: Add Secret Text with the Bot User OAuth Token (ID like slack-bot-token).
Default Channel: e.g., #ci-cd.
Check Use Bot User / Enable Custom Slack App if present.
Test Connection.
C. Send Messages in Jenkinsfile
post {
  success {
    slackSend channel: '#ci-cd', message: "✅ ${env.JOB_NAME} #${env.BUILD_NUMBER} succeeded", notifyCommitters: false
  }
  failure {
    slackSend channel: '#ci-cd', message: "❌ ${env.JOB_NAME} #${env.BUILD_NUMBER} failed: ${env.BUILD_URL}", notifyCommitters: false
  }
}
Option B — Incoming Webhook URL
Simpler, no plugin usage in steps.
In your Slack app → Incoming Webhooks → enable → Add New Webhook to Workspace → choose channel → copy the Webhook URL.
In Jenkins → Manage Credentials → add Secret Text credential with the webhook URL (ID: slack-webhook).
Keep your OAuth token and Webhook URL in Jenkins Credentials (Secret Text). Do not hardcode.


<!-- Mysql User Creation -->
-- Create DB (if not exists)
CREATE DATABASE IF NOT EXISTS rahulverseDB;

-- Create user
CREATE USER 'Rahul'@'%' IDENTIFIED BY 'Rahul@123';
GRANT ALL PRIVILEGES ON rahulverseDB.* TO 'Rahul'@'%';
FLUSH PRIVILEGES;


<!-- Git -->


<!-- terraform cmds -->
terraform init
terraform plan -var-file=./envs/dev.tfvars
terraform apply -var-file=./envs/dev.tfvars --auto-approve
terraform destroy -var-file=./envs/dev.tfvars --auto-approve

<!-- manuall -->
Create a ec2 instance of ubuntu type with t3.large 2cpu 8gb ram  and 25gb storage with sg allowing ports for mysql,22.
install all necessary softwares/tools 
setup jenkins and run pipeline that creates resources like eks, vpc, ec2
configure aws on server and setup eks cluster oidc, service account for jenkins ebs, namespace, roles and role binding, token to connect jenkins
after creation of resources setup nexus and sonarqube 
run mysql user docker container create user and necessary permissions
setup jenkins for app deployment install plugins configure credentials, tools, system, webhook triggers, slack.
run the app deploy pipeline



monitoring is left  and use of argocd