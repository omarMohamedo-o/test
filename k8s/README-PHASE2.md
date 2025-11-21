# Phase 2: Infrastructure & Kubernetes Deployment

## Overview

This phase implements production-grade Kubernetes deployment with Infrastructure as Code (Terraform) and Helm charts for the voting application.

## Architecture

### Infrastructure Components

1. **Kubernetes Cluster**: Minikube (for local development; designed for AKS)
2. **Infrastructure as Code**: Terraform
3. **Package Management**: Helm v3
4. **Ingress Controller**: Nginx
5. **Security**: Pod Security Admission (PSA), NetworkPolicies

### Multi-Environment Support

- **Development (dev)**: Lower resources, simplified configuration
- **Production (prod)**: High availability, increased resources, enhanced security

## Directory Structure

```
terraform/
├── main.tf              # Terraform configuration
├── variables.tf         # Variable definitions
├── cluster.tf           # Cluster provisioning
├── outputs.tf           # Output values
├── terraform.tfvars     # Dev environment variables
└── prod.tfvars          # Prod environment variables

k8s/
├── manifests/           # Raw Kubernetes manifests (for reference)
├── helm/
│   ├── voting-app/      # Application Helm chart
│   │   ├── Chart.yaml
│   │   ├── values.yaml
│   │   ├── values-dev.yaml
│   │   └── values-prod.yaml
│   ├── postgresql-values-dev.yaml
│   ├── postgresql-values-prod.yaml
│   ├── redis-values-dev.yaml
│   └── redis-values-prod.yaml
├── deploy-helm-full.sh  # Automated Helm deployment
└── README-PHASE2.md     # This file
```

## Requirements Met

### ✅ Infrastructure Provisioning

- [x] Terraform configuration for cluster provisioning
- [x] Multi-environment support (dev/prod) via variables
- [x] Networking configuration
- [x] Ingress controller setup
- [x] Security groups (NetworkPolicies)

### ✅ Kubernetes Deployment

- [x] ConfigMaps for application configuration
- [x] Secrets for sensitive data (base64 encoded)
- [x] Resource limits and requests
- [x] Liveness and readiness probes
- [x] Pod Security Admission (PSA) - baseline mode
- [x] NetworkPolicies for database isolation

### ✅ Helm Charts

- [x] Production-grade Helm chart for application
- [x] PostgreSQL deployed via Bitnami Helm chart
- [x] Redis deployed via Bitnami Helm chart
- [x] Persistence enabled with PVCs
- [x] Security contexts enforced
- [x] Environment-specific configurations

## Quick Start

### Option 1: Deploy to Existing Minikube (Current State)

The application is currently running on Minikube with raw manifests. To convert to Helm:

```bash
cd k8s

# Deploy with Helm (dev environment)
./deploy-helm-full.sh dev

# Or for production configuration
./deploy-helm-full.sh prod
```

### Option 2: Fresh Deployment with Terraform

```bash
# Navigate to terraform directory
cd terraform

# Initialize Terraform
terraform init

# Deploy development environment
terraform apply -var-file="terraform.tfvars"

# Or deploy production environment
terraform apply -var-file="prod.tfvars"

# Deploy application via Helm
cd ../k8s
./deploy-helm-full.sh dev  # or prod
```

## Manual Deployment Steps

### 1. Provision Infrastructure (Terraform)

```bash
cd terraform

# Initialize
terraform init

# Plan (review changes)
terraform plan -var-file="terraform.tfvars"

# Apply
terraform apply -var-file="terraform.tfvars" -auto-approve

# View outputs
terraform output
```

### 2. Deploy Databases via Helm

```bash
cd k8s

# Add Bitnami repository
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Deploy PostgreSQL
helm install postgresql bitnami/postgresql \
  -n voting-app \
  -f helm/postgresql-values-dev.yaml \
  --create-namespace

# Deploy Redis
helm install redis bitnami/redis \
  -n voting-app \
  -f helm/redis-values-dev.yaml
```

### 3. Deploy Application via Helm

```bash
# Deploy voting app
helm install voting-app helm/voting-app \
  -n voting-app \
  -f helm/voting-app/values-dev.yaml
```

### 4. Verify Deployment

```bash
# Check Helm releases
helm list -n voting-app

# Check pods
kubectl get pods -n voting-app

# Check services
kubectl get svc -n voting-app

# Check ingress
kubectl get ingress -n voting-app
```

## Environment Differences

| Feature | Development | Production |
|---------|------------|------------|
| Replicas | 1 per service | 2 per service |
| CPU Limit | 100m-250m | 250m-1000m |
| Memory Limit | 128Mi-256Mi | 256Mi-1Gi |
| PG Storage | 5Gi | 20Gi |
| Redis Storage | 2Gi | 8Gi |
| Metrics | Disabled | Enabled |
| Backup | Disabled | Enabled* |

*Backup enabled in configuration but requires external storage in real production

## Security Features

### Pod Security Admission (PSA)

- Namespace labeled with `pod-security.kubernetes.io/enforce=baseline`
- All pods run as non-root users
- Privilege escalation disabled
- Capabilities dropped
- Seccomp profile enforced

### NetworkPolicies

```yaml
# PostgreSQL: Only accessible from worker and result
# Redis: Only accessible from vote and worker
# Vote: Publicly accessible via ingress
# Result: Publicly accessible via ingress
```

### Secrets Management

- PostgreSQL credentials stored in Secrets
- Redis password stored in Secrets
- Base64 encoded values
- In production: Use external secrets management (Azure Key Vault, HashiCorp Vault)

## Accessing the Application

```bash
# Get Minikube IP
minikube ip

# Application URLs (configured in /etc/hosts)
http://vote.local       # Voting interface
http://result.local     # Results dashboard
```

## Monitoring & Debugging

```bash
# View application logs
kubectl logs -n voting-app -l app=vote --tail=50
kubectl logs -n voting-app -l app=result --tail=50
kubectl logs -n voting-app -l app=worker --tail=50

# View database logs
kubectl logs -n voting-app -l app.kubernetes.io/name=postgresql
kubectl logs -n voting-app -l app.kubernetes.io/name=redis

# Exec into pods
kubectl exec -it -n voting-app <pod-name> -- /bin/sh

# Port forward for debugging
kubectl port-forward -n voting-app svc/vote 8080:80
kubectl port-forward -n voting-app svc/result 8081:4000
```

## Helm Operations

### Upgrade Application

```bash
# Modify values in helm/voting-app/values-dev.yaml
# Then upgrade
helm upgrade voting-app helm/voting-app \
  -n voting-app \
  -f helm/voting-app/values-dev.yaml
```

### Rollback

```bash
# View history
helm history voting-app -n voting-app

# Rollback to previous version
helm rollback voting-app -n voting-app
```

### Uninstall

```bash
# Remove application
helm uninstall voting-app -n voting-app

# Remove databases
helm uninstall postgresql -n voting-app
helm uninstall redis -n voting-app

# Delete namespace
kubectl delete namespace voting-app
```

## Trade-offs: Minikube vs Azure AKS

### Current Setup (Minikube)

**Pros:**

- Free and local
- Fast iteration
- No cloud costs
- Complete control

**Cons:**

- Single node (no true HA)
- Limited resources
- No cloud integrations
- Manual ingress setup

### Azure AKS (Production)

**What Would Change:**

1. **Terraform Configuration:**

```hcl
# terraform/main.tf would use:
resource "azurerm_kubernetes_cluster" "aks" {
  name                = "voting-app-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "voting-app"

  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    load_balancer_sku = "standard"
  }
}

# Add Azure Virtual Network
resource "azurerm_virtual_network" "vnet" {
  # ...
}

# Add Network Security Groups
resource "azurerm_network_security_group" "nsg" {
  # ...
}
```

2. **Ingress:**

- Would use Azure Application Gateway or nginx-ingress with LoadBalancer
- SSL/TLS termination with Azure Key Vault certificates
- Azure DNS for domain management

3. **Storage:**

- Azure Managed Disks for persistence
- Storage Classes: Premium_LRS, StandardSSD_LRS
- Azure Backup for database backups

4. **Secrets:**

- Azure Key Vault integration via CSI driver
- Managed identities for authentication

5. **Monitoring:**

- Azure Monitor integration
- Container Insights
- Log Analytics workspace

6. **Networking:**

- Azure CNI for pod networking
- Azure Firewall for egress control
- Private endpoints for databases

## Cost Estimation (Azure AKS)

**Development Environment:**

- AKS Cluster (2 nodes, Standard_D2_v2): ~$150/month
- Load Balancer: ~$20/month
- Storage (20GB): ~$2/month
- **Total: ~$172/month**

**Production Environment:**

- AKS Cluster (4 nodes, Standard_D4_v2): ~$600/month
- Load Balancer: ~$20/month
- Storage (50GB): ~$5/month
- Azure Monitor: ~$50/month
- **Total: ~$675/month**

## Testing

```bash
# Run end-to-end tests
cd k8s
./validate.sh

# Test voting functionality
curl -X POST -d "vote=a" http://vote.local

# Check results
curl http://result.local
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name> -n voting-app

# Check events
kubectl get events -n voting-app --sort-by='.lastTimestamp'
```

### Ingress Not Working

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress resource
kubectl describe ingress -n voting-app
```

### Database Connection Issues

```bash
# Test PostgreSQL connection
kubectl exec -it -n voting-app postgresql-0 -- psql -U postgres -d postgres

# Test Redis connection
kubectl exec -it -n voting-app redis-master-0 -- redis-cli ping
```

## Next Steps

1. **CI/CD Integration**: Add GitHub Actions/Azure DevOps pipelines
2. **Monitoring**: Integrate Prometheus/Grafana
3. **Logging**: Add EFK stack (Elasticsearch, Fluentd, Kibana)
4. **Backup**: Implement Velero for disaster recovery
5. **Security Scanning**: Add Trivy/Snyk for image scanning
6. **Service Mesh**: Consider Istio/Linkerd for advanced networking

## References

- [Terraform Documentation](https://www.terraform.io/docs)
- [Helm Documentation](https://helm.sh/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs)
- [Bitnami Helm Charts](https://github.com/bitnami/charts)
- [Azure AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
