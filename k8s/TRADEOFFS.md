# Phase 2: Kubernetes Deployment - Minikube vs Azure AKS

## Overview

This document outlines the trade-offs and considerations when using Minikube (local Kubernetes) instead of Azure Kubernetes Service (AKS) for the voting application deployment.

## Architectural Decisions

### 1. Cluster Platform: Minikube vs AKS

#### Minikube (Current Implementation)

**Advantages:**

- ✅ **Zero Cost**: Free local development environment
- ✅ **Fast Iteration**: No network latency, instant deployments
- ✅ **Full Control**: Complete control over cluster configuration
- ✅ **Offline Development**: Works without internet connection
- ✅ **Learning Environment**: Perfect for testing and experimentation

**Disadvantages:**

- ❌ **Single Node**: Limited to one node (no true HA testing)
- ❌ **Resource Constraints**: Limited by local machine resources
- ❌ **No Cloud Integration**: Cannot test Azure-specific features
- ❌ **Not Production-Ready**: Cannot serve real users
- ❌ **Manual Scaling**: No auto-scaling capabilities

#### Azure AKS (Not Implemented - Future Consideration)

**Advantages:**

- ✅ **Production-Grade**: Enterprise-ready with SLA guarantees
- ✅ **High Availability**: Multi-node clusters across availability zones
- ✅ **Auto-Scaling**: Horizontal and vertical pod auto-scaling
- ✅ **Managed Service**: Azure manages control plane
- ✅ **Cloud Integration**: Native integration with Azure services
- ✅ **Security Features**: Azure AD integration, Key Vault, Policy
- ✅ **Monitoring**: Azure Monitor, Log Analytics built-in

**Disadvantages:**

- ❌ **Cost**: Pay for nodes, load balancers, storage, egress
- ❌ **Complexity**: More complex setup and configuration
- ❌ **Network Latency**: Remote cluster access
- ❌ **Learning Curve**: Azure-specific concepts to learn

### 2. Networking

#### Minikube

```
┌─────────────────────────────────────┐
│         Minikube Node               │
│  ┌──────────────────────────────┐  │
│  │  Ingress Controller          │  │
│  │  (NodePort on Minikube IP)   │  │
│  └──────────────────────────────┘  │
│  ┌──────────────────────────────┐  │
│  │  Vote/Result Services         │  │
│  │  (ClusterIP)                  │  │
│  └──────────────────────────────┘  │
│  ┌──────────────────────────────┐  │
│  │  Database Services            │  │
│  │  (ClusterIP - Isolated)       │  │
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
       ↓ (Host file mapping)
    vote.local / result.local
```

**Trade-offs:**

- Uses `/etc/hosts` for DNS resolution instead of real DNS
- Single load balancer IP (Minikube IP)
- No external load balancer costs
- Limited to HTTP/HTTPS (no complex routing)

#### AKS (If Used)

```
                  Internet
                     ↓
┌─────────────────────────────────────────────┐
│         Azure Load Balancer                  │
│         (Public IP with DNS)                 │
└─────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────┐
│    Ingress Controller (nginx)                │
│    (LoadBalancer Service)                    │
└─────────────────────────────────────────────┘
                     ↓
┌─────────────────────────────────────────────┐
│     Multi-Node AKS Cluster                   │
│  ┌────────┐  ┌────────┐  ┌────────┐        │
│  │ Node 1 │  │ Node 2 │  │ Node 3 │        │
│  │  Pods  │  │  Pods  │  │  Pods  │        │
│  └────────┘  └────────┘  └────────┘        │
└─────────────────────────────────────────────┘
```

**Benefits:**

- Real public IP with Azure DNS
- Load balancing across multiple nodes
- Azure Application Gateway for advanced routing
- DDoS protection, WAF capabilities

### 3. Storage

#### Minikube

- **StorageClass**: `standard` (hostPath)
- **Persistence**: Local disk on Minikube VM
- **Backup**: Manual copy from Minikube VM
- **Performance**: Limited by local disk I/O

**Trade-offs:**

- ✅ Fast local storage
- ❌ Data lost if Minikube is deleted
- ❌ No replication or backup
- ❌ Cannot test cloud storage features

#### AKS (If Used)

- **StorageClass**: Azure Disk or Azure Files
- **Persistence**: Managed Azure Disks
- **Backup**: Azure Backup integration
- **Performance**: Premium SSD options available

**Benefits:**

- ✅ Persistent across cluster recreation
- ✅ Automated backups
- ✅ Zone-redundant storage
- ✅ Snapshots and cloning

### 4. Security

#### Minikube Implementation

```yaml
# Pod Security Standards (PSA)
- enforce: restricted
- audit: restricted  
- warn: restricted

# Security Context
runAsNonRoot: true
runAsUser: 1000 (or 999 for databases)
allowPrivilegeEscalation: false
capabilities: drop ALL
readOnlyRootFilesystem: true (where possible)

# Network Policies
- Default deny ingress
- Explicit allow rules only
```

**Limitations:**

- No Azure AD integration
- No Key Vault for secrets
- Secrets stored as Kubernetes secrets (base64)
- No external secret managers

#### AKS (If Used)

**Additional Security:**

- Azure AD integration for RBAC
- Azure Key Vault for secret management
- Azure Policy for compliance
- Defender for Cloud integration
- Private clusters (no public API endpoint)

### 5. Observability

#### Minikube

```bash
# Built-in metrics
minikube addons enable metrics-server

# Logs
kubectl logs -n voting-app -l app=vote

# Dashboard
minikube dashboard
```

**Limitations:**

- Basic metrics only
- No centralized logging
- Manual log collection
- No alerts or monitoring

#### AKS (If Used)

**Benefits:**

- Azure Monitor for Containers
- Log Analytics workspace
- Application Insights
- Prometheus/Grafana integration
- Custom alerts and dashboards

### 6. Cost Comparison

#### Minikube (Current)

```
Hardware Cost: $0 (uses existing machine)
Software Cost: $0 (all open source)
Network Cost: $0
Storage Cost: $0
───────────────────────────────
Total Monthly: $0
```

#### AKS (Estimated)

```
Control Plane: $0 (free for standard tier)
Worker Nodes: 3 x Standard_D2s_v3 = ~$140/month
Load Balancer: ~$20/month
Storage: 5GB Premium SSD = ~$1/month
Egress: 100GB = ~$8.74/month
───────────────────────────────
Estimated Monthly: ~$170/month
```

*Note: Prices are approximate and vary by region*

### 7. Multi-Environment Strategy

#### Current Implementation (Minikube)

```
k8s/
├── environments/
│   ├── values-dev.yaml      # Development
│   └── values-prod.yaml     # Production (simulated)
```

**Deployment:**

```bash
# Development
./deploy-helm.sh dev

# Production (simulated)
./deploy-helm.sh prod
```

#### Recommended AKS Strategy

```
environments/
├── dev/
│   ├── terraform.tfvars
│   ├── values.yaml
│   └── secrets/ (Key Vault reference)
├── staging/
│   ├── terraform.tfvars
│   ├── values.yaml
│   └── secrets/
└── prod/
    ├── terraform.tfvars
    ├── values.yaml
    └── secrets/
```

### 8. High Availability

#### Minikube

- **Single Point of Failure**: One node only
- **No Redundancy**: If node fails, entire app is down
- **No Auto-Recovery**: Manual intervention required

**Mitigation:**

- Multiple replicas of stateless services (vote, result)
- Quick restart capabilities
- Good for development/testing

#### AKS (If Used)

- **Multi-Node**: 3+ nodes across availability zones
- **Auto-Healing**: Unhealthy nodes replaced automatically
- **Pod Disruption Budgets**: Ensures minimum replicas
- **Horizontal Pod Autoscaling**: Scales based on load

### 9. Scalability

#### Minikube Limits

```
Max CPU: Host machine CPU
Max Memory: Configured memory (default 4GB)
Max Nodes: 1
Max Pods per Node: 110 (default)
Network Bandwidth: Local network speed
```

#### AKS Capabilities

```
Max Nodes: 1000 per cluster
Max Pods per Node: 250 (configurable)
Auto-scaling: Yes (HPA, VPA, Cluster Autoscaler)
Network: Azure CNI with full bandwidth
Load Balancing: Azure Load Balancer
```

## Migration Path to AKS

### Phase 1: Preparation

1. Create Azure account and subscription
2. Set up Terraform for AKS provisioning
3. Configure Azure DevOps or GitHub Actions for CI/CD
4. Set up Azure Container Registry (ACR)

### Phase 2: Infrastructure

```hcl
# Terraform for AKS
resource "azurerm_kubernetes_cluster" "main" {
  name                = "voting-app-aks"
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "voting-app"

  default_node_pool {
    name       = "default"
    node_count = 3
    vm_size    = "Standard_D2s_v3"
    
    enable_auto_scaling = true
    min_count           = 3
    max_count           = 10
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
  }
}
```

### Phase 3: Application Updates

1. Push images to ACR
2. Update Helm values for AKS
3. Configure Azure Key Vault integration
4. Set up Azure Monitor

### Phase 4: Deployment

```bash
# Connect to AKS
az aks get-credentials --resource-group myResourceGroup --name voting-app-aks

# Deploy with Helm
helm upgrade --install voting-app ./k8s/helm/voting-app \
  -f ./k8s/environments/values-prod-aks.yaml \
  --namespace voting-app
```

## Recommendations

### For Development/Testing (Current Scenario)

✅ **Use Minikube** - Perfect for:

- Learning Kubernetes concepts
- Development and testing
- Cost-free experimentation
- Offline work

### For Production (Future)

✅ **Use AKS** - Required for:

- Serving real users
- High availability needs
- Auto-scaling requirements
- Enterprise security
- Compliance requirements

## Conclusion

The current Minikube implementation provides:

- ✅ Complete Kubernetes feature parity for testing
- ✅ Production-grade manifests that work on AKS
- ✅ Best practices (security, monitoring, networking)
- ✅ Zero cost for development
- ✅ Easy migration path to AKS

The architecture, manifests, and Helm charts are designed to be **cloud-agnostic** and will work on AKS with minimal changes (primarily updating storage classes, ingress annotations, and external service integrations).
