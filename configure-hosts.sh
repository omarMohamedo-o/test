#!/bin/bash
# Usage: sudo ./configure-hosts.sh
# Adds vote.local and result.local to /etc/hosts for Minikube

PROFILE="voting-app-dev"
MINIKUBE_IP=$(minikube ip -p "$PROFILE")
if [ -z "$MINIKUBE_IP" ]; then
  echo "Error: Could not get Minikube IP. Is Minikube running with profile $PROFILE?"
  exit 1
fi

HOSTS_LINE="$MINIKUBE_IP vote.local result.local"

if grep -q "vote.local" /etc/hosts || grep -q "result.local" /etc/hosts; then
  echo "Removing old vote.local/result.local entries from /etc/hosts..."
  sudo sed -i '/vote\.local/d' /etc/hosts
  sudo sed -i '/result\.local/d' /etc/hosts
fi

echo "Adding: $HOSTS_LINE"
echo "$HOSTS_LINE" | sudo tee -a /etc/hosts

echo "Done! You can now access:"
echo "  http://vote.local"
echo "  http://result.local"
