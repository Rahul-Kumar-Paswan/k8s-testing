#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

echo "📦 Updating system and installing prerequisites..."
sudo apt update -y
sudo apt install -y zip unzip curl wget gnupg lsb-release ca-certificates apt-transport-https tar software-properties-common

# -------------------------------
# OpenJDK 21
# -------------------------------
echo "☕ Installing OpenJDK 21..."
sudo apt install -y openjdk-21-jdk-headless
java -version

# -------------------------------
# Jenkins
# -------------------------------
echo "🔧 Installing Jenkins..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /etc/apt/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update -y
sudo apt install -y jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins
echo "✅ Jenkins installed."
systemctl status jenkins --no-pager | head -n 5

# -------------------------------
# Gitleaks
# -------------------------------
echo "🔍 Installing Gitleaks..."
sudo apt install -y gitleaks
gitleaks version

# -------------------------------
# Trivy
# -------------------------------
echo "🛡️ Installing Trivy..."
curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/trivy.list > /dev/null
sudo apt update -y
sudo apt install -y trivy
trivy --version

# -------------------------------
# Docker & Docker Compose
# -------------------------------
echo "🐳 Installing Docker..."
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

# Docker Compose
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -fSL https://github.com/docker/compose/releases/download/v2.38.2/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose

sudo usermod -aG docker ubuntu
sudo usermod -aG docker jenkins
echo "✅ Docker installed and users added to Docker group."

docker --version
docker compose version

# -------------------------------
# kubectl
# -------------------------------
echo "📦 Installing kubectl..."
KUBECTL_VERSION=$(curl -sL https://dl.k8s.io/release/stable.txt)
curl -fLO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client --short

# -------------------------------
# AWS CLI
# -------------------------------
echo "☁️ Installing AWS CLI..."
curl -fSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -qo awscliv2.zip
sudo ./aws/install --update
rm -rf awscliv2.zip aws
aws --version

# -------------------------------
# Terraform
# -------------------------------
echo "🛠️ Installing Terraform..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update -y
sudo apt install -y terraform
terraform -version | head -n1

# -------------------------------
# eksctl
# -------------------------------
echo "🚀 Installing eksctl..."
curl -fSL "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" -o eksctl.tar.gz
tar -xzf eksctl.tar.gz
sudo mv eksctl /usr/local/bin/
rm -f eksctl.tar.gz
eksctl version

# -------------------------------
# Final Verification
# -------------------------------
echo "================================"
echo "✅ Installed Versions:"
zip -v | head -n 1
unzip -v | head -n 1
java -version
aws --version
terraform -version
kubectl version --client=true
eksctl version
gitleaks version
trivy --version
docker --version
docker compose version
systemctl status jenkins --no-pager | head -n3
echo "================================"
echo "🎉 All tools installed and verified successfully!"
