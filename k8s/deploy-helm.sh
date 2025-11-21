#!/bin/bash
# Deploy voting application using Helm chart

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Default environment
ENVIRONMENT=${1:-dev}

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Deploying Voting App (Helm)${NC}"
echo -e "${BLUE}  Environment: ${ENVIRONMENT}${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Check if kubectl is configured
kubectl cluster-info >/dev/null 2>&1 || { echo -e "${RED}❌ kubectl is not configured${NC}"; exit 1; }

# Add Bitnami repo for PostgreSQL and Redis Helm charts
echo -e "${YELLOW}▶ Adding Helm repositories...${NC}"
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
echo -e "${GREEN}✅ Helm repositories updated${NC}\n"

# Deploy PostgreSQL using Bitnami Helm chart
echo -e "${YELLOW}▶ Deploying PostgreSQL with Helm...${NC}"
helm upgrade --install postgresql bitnami/postgresql \
  --namespace voting-app \
  --create-namespace \
  --set auth.username=postgres \
  --set auth.password=changeme-prod-password \
  --set auth.database=postgres \
  --set primary.persistence.size=1Gi \
  --set primary.resources.requests.memory=256Mi \
  --set primary.resources.requests.cpu=250m \
  --set primary.resources.limits.memory=512Mi \
  --set primary.resources.limits.cpu=500m \
  --set primary.podSecurityContext.enabled=true \
  --set primary.podSecurityContext.fsGroup=999 \
  --set primary.containerSecurityContext.enabled=true \
  --set primary.containerSecurityContext.runAsUser=999 \
  --set primary.containerSecurityContext.allowPrivilegeEscalation=false \
  --set primary.containerSecurityContext.runAsNonRoot=true \
  --set fullnameOverride=db \
  --wait

echo -e "${GREEN}✅ PostgreSQL deployed${NC}\n"

# Deploy Redis using Bitnami Helm chart
echo -e "${YELLOW}▶ Deploying Redis with Helm...${NC}"
helm upgrade --install redis bitnami/redis \
  --namespace voting-app \
  --set auth.enabled=false \
  --set master.persistence.size=500Mi \
  --set master.resources.requests.memory=128Mi \
  --set master.resources.requests.cpu=100m \
  --set master.resources.limits.memory=256Mi \
  --set master.resources.limits.cpu=250m \
  --set master.podSecurityContext.enabled=true \
  --set master.podSecurityContext.fsGroup=999 \
  --set master.containerSecurityContext.enabled=true \
  --set master.containerSecurityContext.runAsUser=999 \
  --set master.containerSecurityContext.allowPrivilegeEscalation=false \
  --set master.containerSecurityContext.runAsNonRoot=true \
  --set fullnameOverride=redis \
  --wait

echo -e "${GREEN}✅ Redis deployed${NC}\n"

# Deploy the voting application using our custom Helm chart
echo -e "${YELLOW}▶ Deploying voting application...${NC}"

# Select values file based on environment
if [ "$ENVIRONMENT" = "prod" ]; then
  VALUES_FILE="k8s/environments/values-prod.yaml"
else
  VALUES_FILE="k8s/environments/values-dev.yaml"
fi

# Deploy with Helm
helm upgrade --install voting-app k8s/helm/voting-app \
  --namespace voting-app \
  --create-namespace \
  -f "$VALUES_FILE" \
  --set postgresql.enabled=false \
  --set redis.enabled=false \
  --wait

echo -e "${GREEN}✅ Voting application deployed${NC}\n"

# Wait for pods to be ready
echo -e "${YELLOW}▶ Waiting for all pods to be ready...${NC}"
kubectl wait --namespace voting-app \
  --for=condition=ready pod \
  --selector=app=vote \
  --timeout=180s

kubectl wait --namespace voting-app \
  --for=condition=ready pod \
  --selector=app=result \
  --timeout=180s

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}  Deployment Complete!${NC}"
echo -e "${GREEN}========================================${NC}\n"

# Get the Minikube IP
if command -v minikube &> /dev/null; then
    MINIKUBE_IP=$(minikube ip 2>/dev/null || echo "127.0.0.1")
else
    MINIKUBE_IP="127.0.0.1"
fi

if [ "$ENVIRONMENT" = "prod" ]; then
  VOTE_HOST="vote.example.com"
  RESULT_HOST="result.example.com"
else
  VOTE_HOST="vote.dev.local"
  RESULT_HOST="result.dev.local"
fi

echo -e "${BLUE}Access the application:${NC}"
echo -e "  Vote:   ${YELLOW}http://${VOTE_HOST}${NC}"
echo -e "  Result: ${YELLOW}http://${RESULT_HOST}${NC}\n"

echo -e "${BLUE}Add to /etc/hosts:${NC}"
echo -e "  ${YELLOW}${MINIKUBE_IP} ${VOTE_HOST} ${RESULT_HOST}${NC}\n"

echo -e "${BLUE}Check deployment status:${NC}"
echo -e "  ${YELLOW}helm list -n voting-app${NC}"
echo -e "  ${YELLOW}kubectl get pods -n voting-app${NC}\n"

echo -e "${BLUE}View logs:${NC}"
echo -e "  ${YELLOW}kubectl logs -n voting-app -l app=vote -f${NC}"
echo -e "  ${YELLOW}kubectl logs -n voting-app -l app=result -f${NC}"
echo -e "  ${YELLOW}kubectl logs -n voting-app -l app=worker -f${NC}\n"
