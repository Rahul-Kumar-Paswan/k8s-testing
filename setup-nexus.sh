#!/bin/bash
# ===============================
# Nexus Repository Setup using Docker
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
# Run Nexus container with persistence
# -------------------------------
echo "Running Nexus container..."
docker run -d --name nexus3 -p 8081:8081 sonatype/nexus3

# -------------------------------
# Check container status
# -------------------------------
echo "Listing running Docker containers..."
docker ps

echo "Waiting for Nexus to start (this may take ~1-2 minutes)..."
sleep 30
docker logs nexus3 --tail 20

# -------------------------------
# Info
# -------------------------------
echo "========================================"
echo "✅ Nexus setup completed!"
echo "Access it at: http://<EC2_IP>:8081"
echo "Default admin password file: /opt/nexus-data/admin.password"
echo "========================================"
