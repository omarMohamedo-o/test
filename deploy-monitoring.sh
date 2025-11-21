#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                   ║${NC}"
echo -e "${BLUE}║           📊 Deploy Monitoring Stack (Prometheus + Grafana)      ║${NC}"
echo -e "${BLUE}║                                                                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if kubectl is working
if ! kubectl get nodes &>/dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster!${NC}"
    echo "Make sure Minikube is running: minikube status"
    exit 1
fi

echo -e "${GREEN}✓ Connected to Kubernetes cluster${NC}"
echo ""

# Add Helm repositories
echo -e "${YELLOW}📦 Adding Helm repositories...${NC}"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
echo -e "${GREEN}✓ Helm repos updated${NC}"
echo ""

# Deploy Prometheus + Grafana stack
echo -e "${YELLOW}🚀 Deploying Prometheus + Grafana stack...${NC}"
echo "This may take 5-10 minutes..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values k8s/monitoring/prometheus-values-dev.yaml \
  --wait \
  --timeout 15m

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Prometheus + Grafana deployed successfully${NC}"
else
    echo -e "${RED}❌ Failed to deploy Prometheus + Grafana${NC}"
    exit 1
fi
echo ""

# Deploy Loki for logging
echo -e "${YELLOW}📝 Deploying Loki logging stack...${NC}"
helm upgrade --install loki grafana/loki-stack \
  --namespace monitoring \
  --values k8s/monitoring/loki-values-dev.yaml \
  --wait \
  --timeout 10m

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Loki deployed successfully${NC}"
else
    echo -e "${YELLOW}⚠ Loki deployment may have issues (non-critical)${NC}"
fi
echo ""

# Deploy ServiceMonitors
echo -e "${YELLOW}📊 Deploying ServiceMonitors...${NC}"
kubectl apply -f k8s/monitoring/servicemonitors/

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ ServiceMonitors applied${NC}"
else
    echo -e "${YELLOW}⚠ ServiceMonitors may not be fully applied${NC}"
fi
echo ""

# Wait for pods to be ready
echo -e "${YELLOW}⏳ Waiting for monitoring pods to be ready...${NC}"
kubectl -n monitoring wait --for=condition=ready pod -l app.kubernetes.io/name=grafana --timeout=5m 2>/dev/null
kubectl -n monitoring wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus --timeout=5m 2>/dev/null
echo ""

# Get Grafana password
GRAFANA_PASSWORD=$(kubectl -n monitoring get secret prometheus-grafana -o jsonpath="{.data.admin-password}" 2>/dev/null | base64 --decode)

# Display summary
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                   ║${NC}"
echo -e "${BLUE}║                  ✅ MONITORING STACK DEPLOYED                     ║${NC}"
echo -e "${BLUE}║                                                                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${GREEN}Deployed Components:${NC}"
echo "  ✓ Prometheus (metrics)"
echo "  ✓ Grafana (dashboards)"
echo "  ✓ AlertManager (alerts)"
echo "  ✓ Loki (logging)"
echo "  ✓ Promtail (log collection)"
echo "  ✓ Node Exporter (node metrics)"
echo "  ✓ Kube State Metrics"
echo ""

echo -e "${YELLOW}📊 Check deployment status:${NC}"
echo "  kubectl -n monitoring get pods"
echo ""

echo -e "${YELLOW}🔍 Access Services:${NC}"
echo ""
echo -e "${GREEN}1. GRAFANA (Dashboards):${NC}"
echo "   kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80"
echo "   → http://localhost:3000"
echo "   → Username: admin"
if [ -n "$GRAFANA_PASSWORD" ]; then
    echo "   → Password: $GRAFANA_PASSWORD"
else
    echo "   → Password: admin (default)"
fi
echo ""

echo -e "${GREEN}2. PROMETHEUS (Metrics):${NC}"
echo "   kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090"
echo "   → http://localhost:9090"
echo ""

echo -e "${GREEN}3. ALERTMANAGER (Alerts):${NC}"
echo "   kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093"
echo "   → http://localhost:9093"
echo ""

echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}🎉 Monitoring stack is ready to use!${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════════${NC}"
