# Kubernetes Deployment Guide - Voting Application

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Quick Start](#quick-start)
3. [Detailed Setup](#detailed-setup)
4. [Deployment Options](#deployment-options)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)
7. [Operations](#operations)

## Prerequisites

### Required Software

1. **Minikube** (v1.30+)

   ```bash
   curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
   sudo install minikube-linux-amd64 /usr/local/bin/minikube
   ```

2. **kubectl** (v1.28+)

   ```bash
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
   ```

3. **Helm** (v3.12+)

   ```bash
   curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
   ```

4. **Docker** (v20.10+)

   ```bash
   # Already installed from Phase 1
   docker --version
   ```

### System Requirements

- **CPU**: 4 cores minimum (for Minikube)
- **RAM**: 8GB minimum (4GB allocated to Minikube)
- **Disk**: 20GB free space
- **OS**: Linux (Ubuntu 20.04+ recommended)

## Quick Start

### One-Command Deployment

```bash
# 1. Setup Minikube cluster
cd k8s
./setup-minikube.sh

# 2. Update /etc/hosts (copy commands from script output)
MINIKUBE_IP=$(minikube ip)
echo "$MINIKUBE_IP vote.local result.local" | sudo tee -a /etc/hosts

# 3. Deploy with Helm (recommended)
./deploy-helm.sh dev

# 4. Access the application
open http://vote.local
open http://result.local
```

That's it! The application should now be running.

## Detailed Setup

### Step 1: Provision Minikube Cluster

```bash
cd /home/omar/Projects/tactful-votingapp-cloud-infra

# Start Minikube with recommended resources
minikube start \
  --cpus=4 \
  --memory=4096 \
  --disk-size=20g \
  --driver=docker \
  --kubernetes-version=v1.28.3
```

**Verify cluster:**

```bash
kubectl cluster-info
kubectl get nodes
```

Expected output:

```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   1m    v1.28.3
```

### Step 2: Enable Required Addons

```bash
# Ingress controller (nginx)
minikube addons enable ingress

# Metrics server (for resource monitoring)
minikube addons enable metrics-server

# Storage provisioner (already enabled by default)
minikube addons enable storage-provisioner
```

**Verify addons:**

```bash
minikube addons list | grep enabled
```

### Step 3: Build Docker Images

```bash
# Configure Docker to use Minikube's Docker daemon
eval $(minikube -p minikube docker-env)

# Build all images
docker-compose build

# Verify images
docker images | grep tactful-votingapp
```

Expected output:

```
tactful-votingapp-cloud-infra-vote     latest
tactful-votingapp-cloud-infra-result   latest
tactful-votingapp-cloud-infra-worker   latest
```

### Step 4: Configure DNS

```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
echo "Minikube IP: $MINIKUBE_IP"

# Add to /etc/hosts
echo "$MINIKUBE_IP vote.local result.local" | sudo tee -a /etc/hosts

# Verify
ping -c 1 vote.local
```

## Deployment Options

### Option 1: Raw Kubernetes Manifests

**Best for:** Understanding Kubernetes objects, debugging

```bash
cd k8s

# Deploy all manifests
./deploy.sh

# Or manually apply in order
kubectl apply -f manifests/00-namespace.yaml
kubectl apply -f manifests/01-secrets.yaml
kubectl apply -f manifests/02-configmap.yaml
kubectl apply -f manifests/03-postgres.yaml
kubectl apply -f manifests/04-redis.yaml
kubectl apply -f manifests/05-vote.yaml
kubectl apply -f manifests/06-result.yaml
kubectl apply -f manifests/07-worker.yaml
kubectl apply -f manifests/08-network-policies.yaml
kubectl apply -f manifests/09-ingress.yaml
```

**Check status:**

```bash
kubectl get all -n voting-app
```

### Option 2: Helm Chart (Recommended)

**Best for:** Production-like deployment, multi-environment

#### Development Environment

```bash
cd k8s
./deploy-helm.sh dev
```

This deploys with:

- 1 replica per service
- Reduced resource limits
- Dev-specific hostnames (vote.dev.local)

#### Production Environment (Simulated)

```bash
./deploy-helm.sh prod
```

This deploys with:

- 3 replicas for vote/result
- 2 replicas for worker
- Production resource limits
- Prod hostnames (vote.example.com)

#### Manual Helm Deployment

```bash
# Add Bitnami repo
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Deploy PostgreSQL
helm upgrade --install postgresql bitnami/postgresql \
  --namespace voting-app \
  --create-namespace \
  -f k8s/environments/postgres-values.yaml

# Deploy Redis
helm upgrade --install redis bitnami/redis \
  --namespace voting-app \
  -f k8s/environments/redis-values.yaml

# Deploy application
helm upgrade --install voting-app k8s/helm/voting-app \
  --namespace voting-app \
  -f k8s/environments/values-dev.yaml
```

## Verification

### 1. Check Pod Status

```bash
kubectl get pods -n voting-app

# Expected output (all Running):
NAME                      READY   STATUS    RESTARTS   AGE
db-postgresql-0           1/1     Running   0          2m
redis-master-0            1/1     Running   0          2m
vote-xxx-yyy              1/1     Running   0          1m
vote-xxx-zzz              1/1     Running   0          1m
result-xxx-yyy            1/1     Running   0          1m
result-xxx-zzz            1/1     Running   0          1m
worker-xxx-yyy            1/1     Running   0          1m
```

### 2. Check Services

```bash
kubectl get svc -n voting-app

# Should see ClusterIP services for all components
```

### 3. Check Ingress

```bash
kubectl get ingress -n voting-app

# Should show hosts: vote.local, result.local
```

### 4. Test Application

```bash
# Vote service
curl -I http://vote.local

# Result service
curl -I http://result.local

# Both should return 200 OK
```

### 5. Check Logs

```bash
# Vote service logs
kubectl logs -n voting-app -l app=vote --tail=50

# Result service logs
kubectl logs -n voting-app -l app=result --tail=50

# Worker service logs
kubectl logs -n voting-app -l app=worker --tail=50 -f
```

### 6. Test Database Connectivity

```bash
# Connect to PostgreSQL
kubectl exec -it -n voting-app postgresql-0 -- psql -U postgres -d postgres

# Check tables
\dt

# Check votes
SELECT * FROM votes LIMIT 10;

# Exit
\q
```

### 7. Test Network Policies

```bash
# This should fail (network policy blocks direct access)
kubectl run test-pod --rm -it --image=busybox -n voting-app -- \
  wget -O- http://db:5432

# This should work (vote can access redis)
kubectl exec -it -n voting-app deploy/vote -- \
  redis-cli -h redis ping
```

## Troubleshooting

### Pods Not Starting

```bash
# Describe pod to see events
kubectl describe pod <pod-name> -n voting-app

# Common issues:
# 1. Image pull error - rebuild images in Minikube
# 2. Resource limits - reduce in values.yaml
# 3. Security context - check user IDs
```

### Ingress Not Working

```bash
# Check ingress controller
kubectl get pods -n ingress-nginx

# Check ingress
kubectl describe ingress voting-app-ingress -n voting-app

# Verify /etc/hosts
cat /etc/hosts | grep vote.local

# Check Minikube tunnel (if using LoadBalancer)
minikube tunnel
```

### Database Connection Issues

```bash
# Check if postgres pod is ready
kubectl get pods -n voting-app | grep postgresql

# Check logs
kubectl logs -n voting-app postgresql-0

# Test connection from worker
kubectl exec -it -n voting-app deploy/worker -- \
  echo "Testing DB connection"
```

### Network Policy Issues

```bash
# Temporarily disable network policies for debugging
kubectl delete networkpolicies --all -n voting-app

# Re-apply after fixing
kubectl apply -f k8s/manifests/08-network-policies.yaml
```

## Operations

### Scaling Services

```bash
# Scale vote service
kubectl scale deployment vote --replicas=3 -n voting-app

# Scale result service
kubectl scale deployment result --replicas=3 -n voting-app

# Scale worker service
kubectl scale deployment worker --replicas=2 -n voting-app
```

### Updating Application

```bash
# Rebuild image
eval $(minikube docker-env)
docker-compose build vote

# Restart deployment
kubectl rollout restart deployment/vote -n voting-app

# Watch rollout status
kubectl rollout status deployment/vote -n voting-app
```

### Viewing Metrics

```bash
# Pod metrics
kubectl top pods -n voting-app

# Node metrics
kubectl top nodes

# Dashboard
minikube dashboard
```

### Backup Database

```bash
# Backup PostgreSQL
kubectl exec -n voting-app postgresql-0 -- \
  pg_dump -U postgres postgres > backup.sql

# Restore
kubectl exec -i -n voting-app postgresql-0 -- \
  psql -U postgres postgres < backup.sql
```

### Cleanup

```bash
# Delete application
helm uninstall voting-app -n voting-app
helm uninstall postgresql -n voting-app
helm uninstall redis -n voting-app

# Or with manifests
kubectl delete -f k8s/manifests/

# Delete namespace
kubectl delete namespace voting-app

# Stop Minikube
minikube stop

# Delete Minikube cluster
minikube delete
```

## Next Steps

1. **Monitoring**: Set up Prometheus and Grafana
2. **Logging**: Implement ELK stack or Loki
3. **CI/CD**: Set up GitHub Actions for automated deployment
4. **Security**: Implement Pod Security Policies
5. **Backup**: Automate database backups
6. **Terraform**: Infrastructure as Code for cluster provisioning
7. **Migration to AKS**: Follow TRADEOFFS.md guide

## Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)
- [Minikube Documentation](https://minikube.sigs.k8s.io/docs/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
