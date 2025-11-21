#!/bin/bash
# Minikube Setup and Deployment Script for Voting Application
# This script provisions a Minikube cluster and deploys the voting application

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Voting App - Minikube Setup${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Check prerequisites
echo -e "${YELLOW}▶ Checking prerequisites...${NC}"
command -v minikube >/dev/null 2>&1 || { echo -e "${RED}❌ minikube is not installed${NC}"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}❌ kubectl is not installed${NC}"; exit 1; }
command -v helm >/dev/null 2>&1 || { echo -e "${RED}❌ helm is not installed${NC}"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${RED}❌ docker is not installed${NC}"; exit 1; }
echo -e "${GREEN}✅ All prerequisites installed${NC}\n"

# Start Minikube
echo -e "${YELLOW}▶ Starting Minikube cluster...${NC}"
minikube start \
  --cpus=4 \
  --memory=4096 \
  --disk-size=20g \
  --driver=docker \
  --kubernetes-version=v1.28.3

echo -e "${GREEN}✅ Minikube cluster started${NC}\n"

# Enable required addons
echo -e "${YELLOW}▶ Enabling Minikube addons...${NC}"
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable storage-provisioner
echo -e "${GREEN}✅ Addons enabled${NC}\n"

# Configure kubectl context
echo -e "${YELLOW}▶ Configuring kubectl context...${NC}"
kubectl config use-context minikube
echo -e "${GREEN}✅ kubectl configured${NC}\n"

# Build Docker images in Minikube's Docker environment
echo -e "${YELLOW}▶ Building Docker images in Minikube...${NC}"
eval $(minikube -p minikube docker-env)

# Go to project root directory
cd ..

echo "Building vote image..."
docker build -t tactful-votingapp-cloud-infra-vote:latest ./vote

echo "Building result image..."
docker build -t tactful-votingapp-cloud-infra-result:latest ./result

echo "Building worker image..."
docker build -t tactful-votingapp-cloud-infra-worker:latest ./worker

# Go back to k8s directory
cd k8s

echo -e "${GREEN}✅ Docker images built${NC}\n"

# Wait for ingress controller to be ready
echo -e "${YELLOW}▶ Waiting for ingress controller...${NC}"
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

echo -e "${GREEN}✅ Ingress controller ready${NC}\n"

# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
echo -e "${GREEN}Minikube IP: ${MINIKUBE_IP}${NC}\n"

# Update /etc/hosts
echo -e "${YELLOW}▶ Updating /etc/hosts...${NC}"
echo -e "${BLUE}Please run these commands manually to update /etc/hosts:${NC}"
echo -e "${YELLOW}sudo sed -i '/vote.local/d' /etc/hosts${NC}"
echo -e "${YELLOW}sudo sed -i '/result.local/d' /etc/hosts${NC}"
echo -e "${YELLOW}echo '${MINIKUBE_IP} vote.local result.local' | sudo tee -a /etc/hosts${NC}\n"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Minikube Setup Complete!${NC}"
echo -e "${GREEN}========================================${NC}\n"

echo -e "${BLUE}Next steps:${NC}"
echo -e "  1. Update /etc/hosts with the commands above"
echo -e "  2. Run: ${YELLOW}./deploy.sh${NC} to deploy the application"
echo -e "  3. Or deploy with Helm: ${YELLOW}./deploy-helm.sh${NC}\n"

echo -e "${BLUE}Useful commands:${NC}"
echo -e "  - Check cluster: ${YELLOW}minikube status${NC}"
echo -e "  - Dashboard: ${YELLOW}minikube dashboard${NC}"
echo -e "  - Stop cluster: ${YELLOW}minikube stop${NC}"
echo -e "  - Delete cluster: ${YELLOW}minikube delete${NC}\n"
