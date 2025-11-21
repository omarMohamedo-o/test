# Kubernetes Deployment - Voting Application

This directory contains all Kubernetes resources for deploying the voting application on Minikube or Azure AKS.

## Directory Structure

```
k8s/
├── manifests/              # Raw Kubernetes YAML manifests
│   ├── 00-namespace.yaml
│   ├── 01-secrets.yaml
│   ├── 02-configmap.yaml
│   ├── 03-postgres.yaml
│   ├── 04-redis.yaml
│   ├── 05-vote.yaml
│   ├── 06-result.yaml
│   ├── 07-worker.yaml
│   ├── 08-network-policies.yaml
│   └── 09-ingress.yaml
│
├── helm/                   # Helm chart for production deployment
│   └── voting-app/
│       ├── Chart.yaml
│       ├── values.yaml
│       └── templates/
│
├── environments/           # Environment-specific configurations
│   ├── values-dev.yaml
│   └── values-prod.yaml
│
├── setup-minikube.sh      # Provision Minikube cluster
├── deploy.sh              # Deploy using raw manifests
├── deploy-helm.sh         # Deploy using Helm chart
│
├── DEPLOYMENT.md          # Detailed deployment guide
├── TRADEOFFS.md           # Minikube vs AKS comparison
└── README.md              # This file
```

## Quick Start

### 1. Setup Minikube

```bash
./setup-minikube.sh
```

### 2. Update /etc/hosts

```bash
MINIKUBE_IP=$(minikube ip)
echo "$MINIKUBE_IP vote.local result.local" | sudo tee -a /etc/hosts
```

### 3. Deploy Application

**Option A: Using Helm (Recommended)**

```bash
./deploy-helm.sh dev
```

**Option B: Using Raw Manifests**

```bash
./deploy.sh
```

### 4. Access Application

- Vote: <http://vote.local>
- Result: <http://result.local>

## Key Features

### Production-Grade Practices

✅ **Security**

- Pod Security Standards (PSA) enforced
- Non-root containers (runAsUser: 1000/999)
- Read-only root filesystems where possible
- Security contexts with dropped capabilities
- NetworkPolicies for database isolation

✅ **Reliability**

- Liveness and readiness probes
- Resource limits and requests
- StatefulSets for databases
- Multiple replicas for stateless services
- PersistentVolumes for data persistence

✅ **Observability**

- Structured logging
- Resource metrics
- Health check endpoints
- Kubernetes events

✅ **Networking**

- Ingress controller (nginx)
- Service mesh ready
- NetworkPolicies enforced
- TLS-ready ingress

### Multi-Environment Support

- **Development**: Reduced resources, single replicas
- **Production**: Full resources, multi-replicas, HA setup

## Architecture

```
┌─────────────────────────────────────┐
│         Ingress Controller           │
│    (vote.local / result.local)       │
└─────────────────────────────────────┘
                  │
    ┌─────────────┴────────────┐
    │                          │
┌───▼────┐                ┌───▼──────┐
│  Vote  │                │  Result  │
│Service │                │ Service  │
│(x2)    │                │  (x2)    │
└───┬────┘                └────┬─────┘
    │                          │
    │    ┌────────┐            │
    └───▶│ Worker │◄───────────┘
         │Service │
         │  (x1)  │
         └───┬────┘
             │
    ┌────────┴────────┐
    │                 │
┌───▼────┐      ┌────▼─────┐
│ Redis  │      │Postgres  │
│(Master)│      │(StatefulSet)
└────────┘      └──────────┘
```

### Network Isolation

- **Redis**: Only accessible by vote and worker
- **PostgreSQL**: Only accessible by worker and result
- **Vote/Result**: Exposed via Ingress only

## Documentation

- **[DEPLOYMENT.md](./DEPLOYMENT.md)**: Complete deployment guide with troubleshooting
- **[TRADEOFFS.md](./TRADEOFFS.md)**: Minikube vs AKS comparison and migration path

## Prerequisites

- Minikube v1.30+
- kubectl v1.28+
- Helm v3.12+
- Docker v20.10+

## Common Operations

### Check Status

```bash
kubectl get all -n voting-app
```

### View Logs

```bash
kubectl logs -n voting-app -l app=vote -f
```

### Scale Services

```bash
kubectl scale deployment vote --replicas=3 -n voting-app
```

### Access Database

```bash
kubectl exec -it -n voting-app postgresql-0 -- psql -U postgres
```

### Dashboard

```bash
minikube dashboard
```

## Cleanup

```bash
# Uninstall Helm releases
helm uninstall voting-app postgresql redis -n voting-app

# Or delete all resources
kubectl delete namespace voting-app

# Stop Minikube
minikube stop

# Delete Minikube
minikube delete
```

## Next Steps

- [ ] Set up monitoring (Prometheus/Grafana)
- [ ] Implement CI/CD pipeline
- [ ] Add horizontal pod autoscaling
- [ ] Migrate to Azure AKS
- [ ] Implement GitOps with ArgoCD

## Support

For issues and questions, see the main project README and DEPLOYMENT.md.
