#!/bin/bash
# Deploy voting application using raw Kubernetes manifests

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Deploying Voting App (Manifests)${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Check if kubectl is configured
kubectl cluster-info >/dev/null 2>&1 || { echo -e "${RED}❌ kubectl is not configured${NC}"; exit 1; }

echo -e "${YELLOW}▶ Applying Kubernetes manifests...${NC}"

# Apply manifests in order
kubectl apply -f k8s/manifests/00-namespace.yaml
echo -e "${GREEN}✅ Namespace created${NC}"

kubectl apply -f k8s/manifests/01-secrets.yaml
echo -e "${GREEN}✅ Secrets created${NC}"

kubectl apply -f k8s/manifests/02-configmap.yaml
echo -e "${GREEN}✅ ConfigMap created${NC}"

kubectl apply -f k8s/manifests/03-postgres.yaml
echo -e "${GREEN}✅ PostgreSQL deployed${NC}"

kubectl apply -f k8s/manifests/04-redis.yaml
echo -e "${GREEN}✅ Redis deployed${NC}"

# Wait for databases to be ready
echo -e "${YELLOW}▶ Waiting for databases to be ready...${NC}"
kubectl wait --namespace voting-app \
  --for=condition=ready pod \
  --selector=app=postgres \
  --timeout=180s

kubectl wait --namespace voting-app \
  --for=condition=ready pod \
  --selector=app=redis \
  --timeout=180s

echo -e "${GREEN}✅ Databases are ready${NC}"

kubectl apply -f k8s/manifests/05-vote.yaml
echo -e "${GREEN}✅ Vote service deployed${NC}"

kubectl apply -f k8s/manifests/06-result.yaml
echo -e "${GREEN}✅ Result service deployed${NC}"

kubectl apply -f k8s/manifests/07-worker.yaml
echo -e "${GREEN}✅ Worker service deployed${NC}"

kubectl apply -f k8s/manifests/08-network-policies.yaml
echo -e "${GREEN}✅ Network policies applied${NC}"

kubectl apply -f k8s/manifests/09-ingress.yaml
echo -e "${GREEN}✅ Ingress configured${NC}"

echo -e "\n${YELLOW}▶ Waiting for application pods to be ready...${NC}"
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

echo -e "${BLUE}Access the application:${NC}"
echo -e "  Vote:   ${YELLOW}http://vote.local${NC}"
echo -e "  Result: ${YELLOW}http://result.local${NC}\n"

echo -e "${BLUE}Check deployment status:${NC}"
echo -e "  ${YELLOW}kubectl get pods -n voting-app${NC}\n"

echo -e "${BLUE}View logs:${NC}"
echo -e "  ${YELLOW}kubectl logs -n voting-app -l app=vote${NC}"
echo -e "  ${YELLOW}kubectl logs -n voting-app -l app=result${NC}"
echo -e "  ${YELLOW}kubectl logs -n voting-app -l app=worker${NC}\n"
