#!/bin/bash
# Push Script - Phase 2: Kubernetes & Terraform

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                    ║${NC}"
echo -e "${BLUE}║     ☁️  Push Phase 2: Kubernetes & Terraform      ║${NC}"
echo -e "${BLUE}║                                                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""

# Navigate to project root
cd /home/omar/Projects/tactful-votingapp-cloud-infra

# Check git status
echo -e "${YELLOW}🔍 Checking git status...${NC}"
git status
echo ""

# Ask for confirmation
echo -e "${YELLOW}📋 Phase 2 will include:${NC}"
echo "  • Terraform configuration"
echo "  • Kubernetes manifests"
echo "  • Helm charts"
echo "  • Monitoring configurations"
echo "  • Deployment scripts"
echo "  • Phase 2 documentation"
echo ""

read -p "Continue with Phase 2 push? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Push cancelled${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}☁️  Step 1: Adding Terraform configuration...${NC}"
git add terraform/
echo -e "${GREEN}✅ Terraform files added${NC}"

echo ""
echo -e "${YELLOW}☁️  Step 2: Adding Kubernetes manifests...${NC}"
git add k8s/manifests/
echo -e "${GREEN}✅ Kubernetes manifests added${NC}"

echo ""
echo -e "${YELLOW}☁️  Step 3: Adding Helm charts...${NC}"
git add k8s/helm/
echo -e "${GREEN}✅ Helm charts added${NC}"

echo ""
echo -e "${YELLOW}☁️  Step 4: Adding environment configurations...${NC}"
git add k8s/environments/
echo -e "${GREEN}✅ Environment configs added${NC}"

echo ""
echo -e "${YELLOW}☁️  Step 5: Adding monitoring configurations...${NC}"
git add k8s/monitoring/
echo -e "${GREEN}✅ Monitoring configs added${NC}"

echo ""
echo -e "${YELLOW}☁️  Step 6: Adding deployment scripts...${NC}"
git add k8s/setup-minikube.sh
git add k8s/deploy.sh
git add k8s/deploy-helm.sh
git add k8s/deploy-helm-full.sh
git add k8s/validate.sh
chmod +x k8s/*.sh
echo -e "${GREEN}✅ Deployment scripts added${NC}"

echo ""
echo -e "${YELLOW}☁️  Step 7: Adding Phase 2 documentation...${NC}"
git add k8s/README.md
git add k8s/DEPLOYMENT.md
git add k8s/TRADEOFFS.md
git add k8s/PHASE2-SUMMARY.md
git add k8s/README-PHASE2.md
git add k8s/QUICK-TEST.md
echo -e "${GREEN}✅ Documentation added${NC}"

echo ""
echo -e "${YELLOW}📊 Files to be committed:${NC}"
git status --short
echo ""

read -p "Proceed with commit? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Commit cancelled${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}💾 Committing Phase 2...${NC}"
git commit -m "feat: Phase 2 - Kubernetes and Terraform infrastructure

☁️ Infrastructure as Code:
- Terraform configuration for Minikube cluster provisioning
- Multi-environment support (dev/prod)
- Automated cluster setup with addons
- Network and security group configuration

🎯 Kubernetes Deployment:
- Production-grade manifests (Deployments, Services, StatefulSets)
- Helm charts with multi-environment values
- ConfigMaps and Secrets management
- NetworkPolicies for database isolation
- Pod Security Standards (PSA) enforcement
- Ingress controller with custom domains

🔒 Security Features:
- Non-root containers enforced
- Resource limits and requests configured
- Network policies isolating backend services
- PSA restricted mode enforcement
- Security contexts on all pods
- RBAC configurations

📦 Dependencies:
- PostgreSQL via Bitnami Helm chart
- Redis via Bitnami Helm chart
- Persistent volumes for data
- StatefulSets for stateful workloads

🚀 Deployment Tools:
- Automated setup scripts
- Helm deployment automation
- Validation scripts
- Multi-environment configuration

📊 Monitoring:
- Prometheus integration ready
- Grafana dashboard configs
- Service monitors for PostgreSQL and Redis
- Loki for log aggregation

✅ Cluster provisioning automated
✅ App deployable via Helm
✅ Security policies enforced
✅ Ready for production patterns"

echo -e "${GREEN}✅ Commit successful${NC}"

echo ""
echo -e "${YELLOW}🚀 Pushing to GitHub...${NC}"

# Detect branch (main or master)
BRANCH=$(git branch --show-current)
echo -e "${BLUE}   Branch: $BRANCH${NC}"

git push origin "$BRANCH"

echo -e "${GREEN}✅ Push successful!${NC}"

echo ""
echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                    ║${NC}"
echo -e "${BLUE}║     🎉 Phase 2 Successfully Pushed!               ║${NC}"
echo -e "${BLUE}║                                                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}☁️  Phase 2 (Kubernetes & Terraform) is now on GitHub!${NC}"
echo ""
echo -e "${YELLOW}🌐 View your repository:${NC}"
echo -e "   ${BLUE}https://github.com/omarMohamedo-o/tactful-votingapp-cloud-infra${NC}"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "  1. Verify files on GitHub"
echo "  2. Check Terraform files in repo"
echo "  3. Run: ./push-phase3.sh"
echo ""
