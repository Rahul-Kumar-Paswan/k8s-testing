#!/bin/bash
# Install Docker on Ubuntu
apt-get update -y
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

# Enable docker
systemctl start docker
systemctl enable docker

# Allow ubuntu user to run docker without sudo
usermod -aG docker ubuntu
