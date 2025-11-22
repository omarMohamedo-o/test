#!/bin/bash
MINIKUBE_IP=$(minikube ip -p voting-app-dev)

echo "Configuring /etc/hosts..."
sudo sed -i '/vote.local/d' /etc/hosts 2>/dev/null || true
sudo sed -i '/result.local/d' /etc/hosts 2>/dev/null || true
echo "$MINIKUBE_IP vote.local" | sudo tee -a /etc/hosts
echo "$MINIKUBE_IP result.local" | sudo tee -a /etc/hosts
echo "✅ /etc/hosts configured successfully!"
