#!/bin/bash
# ===============================
# Jenkins + Tools Setup Script
# Installs: OpenJDK 21, Jenkins, Gitleaks, Trivy, Docker, Docker Compose, kubectl
# ===============================

set -e

# ------------------------------
# Install dependencies
# ------------------------------
echo "Updating system and installing base packages..."
sudo apt update -y
sudo apt install -y wget curl gnupg lsb-release ca-certificates apt-transport-https

# ------------------------------
# Install OpenJDK 21
# ------------------------------
echo "Installing OpenJDK 21..."
sudo apt install -y openjdk-21-jdk-headless

# ------------------------------
# Install Jenkins
# ------------------------------
echo "Setting up Jenkins repository and installing Jenkins..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /etc/apt/keyrings/jenkins-keyring.asc > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
  sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update -y
sudo apt install -y jenkins
sudo usermod -aG docker jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins
echo "Jenkins installed and started successfully."

# ------------------------------
# Install Gitleaks
# ------------------------------
echo "Installing Gitleaks..."
sudo apt install -y gitleaks

# ------------------------------
# Install Trivy
# ------------------------------
echo "Installing Trivy..."
curl -fsSL https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo gpg --dearmor -o /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | \
  sudo tee /etc/apt/sources.list.d/trivy.list > /dev/null
sudo apt update -y
sudo apt install -y trivy

# ------------------------------
# Install Docker & Docker Compose
# ------------------------------
echo "Installing Docker and Docker Compose..."
sudo apt install -y docker.io

# Docker Compose plugin setup
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.38.2/docker-compose-linux-x86_64 \
  -o $DOCKER_CONFIG/cli-plugins/docker-compose
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose

# Add users to Docker group
sudo usermod -aG docker ubuntu
sudo usermod -aG docker jenkins

# -------------------------------
# Install kubectl
# -------------------------------
echo "Installing kubectl..."
KUBECTL_VERSION=$(curl -sL https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# ------------------------------
# Verification
# ------------------------------
echo "Verifying installations..."
java -version
systemctl status jenkins --no-pager | head -n 5
gitleaks version
trivy --version
docker --version
docker compose version
kubectl version --client

echo "✅ Jenkins + Tools setup completed successfully!"
