#!/bin/bash
# ===============================
# SonarQube Setup using Docker
# ===============================

set -e

# -------------------------------
# Install Docker
# -------------------------------
echo "Updating packages and installing Docker..."
sudo apt update -y
sudo apt install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker

# Add ubuntu user to Docker group (requires logout/login to take effect)
sudo usermod -aG docker ubuntu
echo "✅ Added 'ubuntu' to docker group. Please re-login for changes to take effect."

# -------------------------------
# Run SonarQube container with persistence
# -------------------------------
echo "Running SonarQube container..."
docker run -d --name sonarqube -p 9000:9000 sonarqube:lts-community

# -------------------------------
# Check container status
# -------------------------------
echo "Listing running Docker containers..."
docker ps

echo "Waiting for SonarQube to start (can take 2–3 mins)..."
sleep 30
docker logs sonarqube --tail 20

# -------------------------------
# Info
# -------------------------------
echo "========================================"
echo "✅ SonarQube setup completed!"
echo "Access it at: http://<EC2_IP>:9000"
echo "Default login: admin / admin"
echo "========================================"
