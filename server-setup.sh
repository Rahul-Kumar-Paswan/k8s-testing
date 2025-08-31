#!/bin/bash
# ===============================
# Installation Script for Server VM
# Installs: zip/unzip, AWS CLI, Terraform, kubectl, eksctl
# ===============================

set -e  # Exit immediately if a command fails

# -------------------------------
# Update & install base packages
# -------------------------------
echo "Updating packages and installing prerequisites..."
sudo apt update -y
sudo apt install -y zip unzip curl wget gnupg lsb-release tar

# -------------------------------
# Install or update AWS CLI
# -------------------------------
echo "Installing AWS CLI..."
curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip -qo awscliv2.zip
sudo ./aws/install --update
rm -rf aws awscliv2.zip
aws --version

# -------------------------------
# Install Terraform
# -------------------------------
echo "Installing Terraform..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
  sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null
sudo apt update -y
sudo apt install -y terraform
terraform -version | head -n 1

# -------------------------------
# Install kubectl
# -------------------------------
echo "Installing kubectl..."
KUBECTL_VERSION=$(curl -sL https://dl.k8s.io/release/stable.txt)
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
kubectl version --client --short

# -------------------------------
# Install eksctl
# -------------------------------
echo "Installing eksctl..."
curl -sLO "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz"
tar -xzf eksctl_$(uname -s)_amd64.tar.gz
sudo mv eksctl /usr/local/bin/
rm -f eksctl_$(uname -s)_amd64.tar.gz
eksctl version

# -------------------------------
# Verification Summary
# -------------------------------
echo "================================"
echo "✅ Installed Versions:"
zip -v | head -n 1
unzip -v | head -n 1
aws --version
terraform -version | head -n 1
kubectl version --client --short
eksctl version
echo "================================"
echo "All tools installed and verified successfully!"
