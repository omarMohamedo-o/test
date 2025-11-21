#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default environment
ENVIRONMENT=${1:-dev}

echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}  Deploying Voting App via Helm${NC}"
echo -e "${GREEN}  Environment: ${ENVIRONMENT}${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""

# Validate environment
if [[ ! "$ENVIRONMENT" =~ ^(dev|prod)$ ]]; then
    echo -e "${RED}Error: Environment must be 'dev' or 'prod'${NC}"
    exit 1
fi

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    echo -e "${RED}Error: Helm is not installed${NC}"
    exit 1
fi

# Check if kubectl is configured
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}Error: kubectl is not configured or cluster is not accessible${NC}"
    exit 1
fi

NAMESPACE="voting-app"

echo -e "${YELLOW}Step 1: Creating namespace...${NC}"
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

echo -e "${YELLOW}Step 2: Setting Pod Security Admission...${NC}"
kubectl label namespace $NAMESPACE \
    pod-security.kubernetes.io/enforce=baseline \
    pod-security.kubernetes.io/audit=baseline \
    pod-security.kubernetes.io/warn=baseline \
    --overwrite

echo -e "${YELLOW}Step 3: Adding Bitnami Helm repository...${NC}"
helm repo add bitnami https://charts.bitnami.com/bitnami 2>/dev/null || true
helm repo update

echo -e "${YELLOW}Step 4: Deploying PostgreSQL via Helm...${NC}"
helm upgrade --install postgresql bitnami/postgresql \
    --namespace $NAMESPACE \
    --values helm/postgresql-values-${ENVIRONMENT}.yaml \
    --wait \
    --timeout 5m

echo -e "${YELLOW}Step 5: Deploying Redis via Helm...${NC}"
helm upgrade --install redis bitnami/redis \
    --namespace $NAMESPACE \
    --values helm/redis-values-${ENVIRONMENT}.yaml \
    --wait \
    --timeout 5m

echo -e "${YELLOW}Step 6: Waiting for databases to be ready...${NC}"
kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=postgresql \
    -n $NAMESPACE \
    --timeout=300s

kubectl wait --for=condition=ready pod \
    -l app.kubernetes.io/name=redis \
    -n $NAMESPACE \
    --timeout=300s

echo -e "${YELLOW}Step 7: Deploying Voting App via Helm...${NC}"
helm upgrade --install voting-app helm/voting-app \
    --namespace $NAMESPACE \
    --values helm/voting-app/values-${ENVIRONMENT}.yaml \
    --wait \
    --timeout 5m

echo -e "${YELLOW}Step 8: Waiting for application pods...${NC}"
kubectl wait --for=condition=ready pod \
    -l app=vote \
    -n $NAMESPACE \
    --timeout=300s

kubectl wait --for=condition=ready pod \
    -l app=result \
    -n $NAMESPACE \
    --timeout=300s

kubectl wait --for=condition=ready pod \
    -l app=worker \
    -n $NAMESPACE \
    --timeout=300s

echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}  Deployment Complete!${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo -e "${YELLOW}Application URLs:${NC}"
echo -e "  Vote:   http://vote.local"
echo -e "  Result: http://result.local"
echo ""
echo -e "${YELLOW}Verify deployment:${NC}"
echo -e "  kubectl get pods -n $NAMESPACE"
echo -e "  kubectl get svc -n $NAMESPACE"
echo -e "  kubectl get ingress -n $NAMESPACE"
echo ""
echo -e "${YELLOW}View Helm releases:${NC}"
echo -e "  helm list -n $NAMESPACE"
echo ""
