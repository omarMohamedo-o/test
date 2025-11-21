# Complete Testing Guide - All Phases (Command-Based)

**Date:** November 2025  
**Project:** Tactful Voting App - Cloud Infrastructure  
**Testing Method:** Step-by-step commands (no scripts)

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Security Scanning with Snyk](#security-scanning-with-snyk)
3. [Phase 1: Docker Compose Testing](#phase-1-docker-compose-testing)
4. [Phase 2: Kubernetes Testing](#phase-2-kubernetes-testing)
5. [Phase 3: CI/CD Pipeline Testing](#phase-3-cicd-pipeline-testing)
6. [Helm Charts Testing](#helm-charts-testing)
7. [Monitoring Stack Testing](#monitoring-stack-testing)
8. [Complete System Validation](#complete-system-validation)

---

## Prerequisites

### System Requirements Check

```bash
# Check Docker
docker --version
docker compose version

# Check Kubernetes tools
kubectl version --client
minikube version
helm version

# Check system resources
free -h
df -h

# Check if ports are available
sudo netstat -tulpn | grep -E ':(8080|8081|80|443|3000|9090)'
```

### Environment Setup

```bash
# Navigate to project directory
cd ~/Projects/tactful-votingapp-cloud-infra

# Check git status
git status
git branch

# Verify all files present
ls -la

# Check Docker daemon
sudo systemctl status docker
```

---

## Security Scanning with Snyk

### Step 1: Authenticate with Snyk

```bash
# Authenticate with Snyk (opens browser)
snyk auth

# Verify authentication
snyk config get api

# Check Snyk version
snyk --version
```

### Step 2: Scan Source Code (SAST)

```bash
# Scan vote service (Python)
snyk code test vote/

# Scan result service (Node.js)
snyk code test result/

# Scan worker service (.NET)
snyk code test worker/

# Scan entire project
snyk code test .

# Scan with severity threshold (only high and critical)
snyk code test . --severity-threshold=high

# Include ignored vulnerabilities
snyk code test . --include-ignores

# Output as JSON for analysis
snyk code test . --json > snyk-code-scan.json

# Generate SARIF format for GitHub
snyk code test . --sarif-file-output=snyk-code.sarif
```

### Step 3: Scan Dependencies (SCA)

```bash
# Scan Python dependencies (vote service)
cd vote/
snyk test --file=requirements.txt

# Scan with detailed output
snyk test --file=requirements.txt --print-deps

# Show only high/critical vulnerabilities
snyk test --file=requirements.txt --severity-threshold=high
cd ..

# Scan Node.js dependencies (result service)
cd result/
snyk test --file=package.json

# Show vulnerable paths
snyk test --file=package.json --show-vulnerable-paths=all
cd ..

# Scan .NET dependencies (worker service)
cd worker/
snyk test --file=Worker.csproj
cd ..

# Scan all projects
snyk test --all-projects

# Generate report
snyk test --all-projects --json > snyk-dependencies.json
```

### Step 4: Scan Docker Images

```bash
# Build images first if not already built
docker build -t tactful-votingapp-cloud-infra-vote:latest vote/
docker build -t tactful-votingapp-cloud-infra-result:latest result/
docker build -t tactful-votingapp-cloud-infra-worker:latest worker/

# Scan vote image
snyk container test tactful-votingapp-cloud-infra-vote:latest

# Scan with Dockerfile for better recommendations
snyk container test tactful-votingapp-cloud-infra-vote:latest \
  --file=vote/Dockerfile

# Scan result image
snyk container test tactful-votingapp-cloud-infra-result:latest \
  --file=result/Dockerfile

# Scan worker image
snyk container test tactful-votingapp-cloud-infra-worker:latest \
  --file=worker/Dockerfile

# Exclude base image vulnerabilities
snyk container test tactful-votingapp-cloud-infra-vote:latest \
  --file=vote/Dockerfile \
  --exclude-base-image-vulns

# Scan PostgreSQL image
snyk container test postgres:15-alpine

# Scan Redis image
snyk container test redis:7-alpine

# Generate container scan report
snyk container test tactful-votingapp-cloud-infra-vote:latest --json > snyk-container-vote.json
snyk container test tactful-votingapp-cloud-infra-result:latest --json > snyk-container-result.json
snyk container test tactful-votingapp-cloud-infra-worker:latest --json > snyk-container-worker.json
```

### Step 5: Scan Infrastructure as Code (IaC)

```bash
# Scan Kubernetes manifests
snyk iac test k8s/manifests/

# Scan specific manifest files
snyk iac test k8s/manifests/01-namespace.yaml
snyk iac test k8s/manifests/02-secrets.yaml
snyk iac test k8s/manifests/05-vote.yaml
snyk iac test k8s/manifests/06-result.yaml
snyk iac test k8s/manifests/07-worker.yaml

# Scan with severity threshold
snyk iac test k8s/manifests/ --severity-threshold=high

# Scan Helm charts
snyk iac test k8s/helm/voting-app/

# Scan Helm values
snyk iac test k8s/helm/voting-app/values.yaml
snyk iac test k8s/helm/postgresql-values-dev.yaml
snyk iac test k8s/helm/redis-values-dev.yaml

# Scan monitoring configurations
snyk iac test k8s/monitoring/

# Scan docker-compose.yml
snyk iac test docker-compose.yml

# Generate IaC scan report
snyk iac test k8s/ --json > snyk-iac-scan.json

# Generate SARIF for IaC
snyk iac test k8s/ --sarif-file-output=snyk-iac.sarif
```

### Step 6: Scan Terraform (if used)

```bash
# Scan Terraform files (if you have any)
snyk iac test terraform/ 2>/dev/null || echo "No Terraform files found"

# Scan with custom rules
# snyk iac test terraform/ --rules=custom-rules.tar.gz
```

### Step 7: Monitor Projects in Snyk

```bash
# Monitor vote service
cd vote/
snyk monitor --file=requirements.txt --project-name=voting-app-vote
cd ..

# Monitor result service
cd result/
snyk monitor --file=package.json --project-name=voting-app-result
cd ..

# Monitor worker service
cd worker/
snyk monitor --project-name=voting-app-worker
cd ..

# Monitor all projects
snyk monitor --all-projects

# Check monitored projects
echo "Visit: https://app.snyk.io/org/YOUR_ORG/projects"
```

### Step 8: Generate Comprehensive Security Report

```bash
# Create reports directory
mkdir -p security-reports

# Run all scans and save reports
echo "=== SNYK SECURITY SCAN REPORT ===" > security-reports/snyk-full-report.txt
echo "Date: $(date)" >> security-reports/snyk-full-report.txt
echo "" >> security-reports/snyk-full-report.txt

# Code scan
echo "1. CODE SCAN (SAST)" >> security-reports/snyk-full-report.txt
snyk code test . --severity-threshold=medium >> security-reports/snyk-full-report.txt 2>&1
echo "" >> security-reports/snyk-full-report.txt

# Dependency scan
echo "2. DEPENDENCY SCAN (SCA)" >> security-reports/snyk-full-report.txt
snyk test --all-projects --severity-threshold=medium >> security-reports/snyk-full-report.txt 2>&1
echo "" >> security-reports/snyk-full-report.txt

# Container scan
echo "3. CONTAINER SCAN" >> security-reports/snyk-full-report.txt
echo "Vote Image:" >> security-reports/snyk-full-report.txt
snyk container test tactful-votingapp-cloud-infra-vote:latest --severity-threshold=medium >> security-reports/snyk-full-report.txt 2>&1
echo "Result Image:" >> security-reports/snyk-full-report.txt
snyk container test tactful-votingapp-cloud-infra-result:latest --severity-threshold=medium >> security-reports/snyk-full-report.txt 2>&1
echo "Worker Image:" >> security-reports/snyk-full-report.txt
snyk container test tactful-votingapp-cloud-infra-worker:latest --severity-threshold=medium >> security-reports/snyk-full-report.txt 2>&1
echo "" >> security-reports/snyk-full-report.txt

# IaC scan
echo "4. INFRASTRUCTURE AS CODE SCAN" >> security-reports/snyk-full-report.txt
snyk iac test k8s/ --severity-threshold=medium >> security-reports/snyk-full-report.txt 2>&1
snyk iac test docker-compose.yml >> security-reports/snyk-full-report.txt 2>&1
echo "" >> security-reports/snyk-full-report.txt

echo "Report saved to: security-reports/snyk-full-report.txt"
cat security-reports/snyk-full-report.txt
```

### Step 9: Fix Vulnerabilities

```bash
# Get fix recommendations for dependencies
cd vote/
snyk test --file=requirements.txt --json | jq '.vulnerabilities[] | {package: .packageName, severity: .severity, fixedIn: .fixedIn}'
cd ..

# Auto-fix dependencies (if available)
cd result/
snyk fix
cd ..

# Open vulnerability in Snyk Learn
# snyk open-learn <CVE-ID>

# Trust project folder for scanning
snyk trust /home/omar/Projects/tactful-votingapp-cloud-infra
```

### Step 10: Validate Security Best Practices

```bash
# Check for security misconfigurations
echo "=== SECURITY CHECKLIST ==="

# 1. Check for hardcoded secrets
echo "1. Scanning for hardcoded secrets..."
grep -r "password\|secret\|token\|api_key" --include="*.py" --include="*.js" --include="*.cs" --include="*.yaml" . | grep -v "\.git" | grep -v "node_modules" || echo "  ✓ No obvious hardcoded secrets"

# 2. Check Dockerfile security
echo "2. Checking Dockerfiles for security best practices..."
for dockerfile in vote/Dockerfile result/Dockerfile worker/Dockerfile; do
    echo "  Checking $dockerfile:"
    grep -q "USER" $dockerfile && echo "    ✓ Non-root user defined" || echo "    ✗ No USER directive found"
    grep -q "HEALTHCHECK" $dockerfile && echo "    ✓ Health check defined" || echo "    ✗ No HEALTHCHECK found"
done

# 3. Check Kubernetes security
echo "3. Checking Kubernetes security..."
grep -r "runAsNonRoot: true" k8s/manifests/ > /dev/null && echo "  ✓ Non-root containers configured" || echo "  ✗ Non-root not configured"
grep -r "readOnlyRootFilesystem: true" k8s/manifests/ > /dev/null && echo "  ✓ Read-only root filesystem configured" || echo "  ✗ Read-only filesystem not configured"
grep -r "allowPrivilegeEscalation: false" k8s/manifests/ > /dev/null && echo "  ✓ Privilege escalation disabled" || echo "  ✗ Privilege escalation not disabled"

# 4. Check NetworkPolicies
echo "4. Checking network isolation..."
kubectl get networkpolicy -n voting-app 2>/dev/null > /dev/null && echo "  ✓ NetworkPolicies configured" || echo "  ⚠ NetworkPolicies not found (cluster may not be running)"

# 5. Check Pod Security Standards
echo "5. Checking Pod Security Admission..."
kubectl get namespace voting-app -o yaml 2>/dev/null | grep -q "pod-security.kubernetes.io" && echo "  ✓ PSA labels configured" || echo "  ⚠ PSA not configured (cluster may not be running)"

echo ""
echo "=== SECURITY SCAN COMPLETE ==="
```

### Step 11: Send Feedback to Snyk (Optional)

```bash
# Report prevented issues (after fixing vulnerabilities)
snyk send-feedback \
  --prevented-issues=5 \
  --fixed-issues=3 \
  --path=/home/omar/Projects/tactful-votingapp-cloud-infra

# This helps Snyk track your security improvements
```

---

## Phase 1: Docker Compose Testing

### Step 1: Clean Previous State

```bash
# Stop any running containers
docker compose down -v

# Remove dangling volumes
docker volume prune -f

# Check no containers running
docker ps -a

# Check no volumes
docker volume ls
```

### Step 2: Build Docker Images

```bash
# Build vote service
cd vote/
docker build -t tactful-votingapp-cloud-infra-vote:latest .
cd ..

# Build result service
cd result/
docker build -t tactful-votingapp-cloud-infra-result:latest .
cd ..

# Build worker service
cd worker/
docker build -t tactful-votingapp-cloud-infra-worker:latest .
cd ..

# Verify images built
docker images | grep tactful-votingapp
```

### Step 3: Start Services

```bash
# Start all services
docker compose up -d

# Check all containers running
docker compose ps

# Check container health
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"

# Wait for services to be ready (30 seconds)
sleep 30
```

### Step 4: Test Vote Service

```bash
# Check vote service is up
curl -s http://localhost:8080 | head -10

# Get full HTML
curl -s http://localhost:8080 > /tmp/vote.html

# Check title
grep -i "cats.*dogs" /tmp/vote.html

# Test vote submission (Cats)
curl -X POST http://localhost:8080 \
  -d "vote=a" \
  -H "Content-Type: application/x-www-form-urlencoded"

# Test vote submission (Dogs)
curl -X POST http://localhost:8080 \
  -d "vote=b" \
  -H "Content-Type: application/x-www-form-urlencoded"

# Check vote service logs
docker compose logs vote | tail -20
```

### Step 5: Test Result Service

```bash
# Check result service is up
curl -s http://localhost:8081 | head -10

# Get full HTML
curl -s http://localhost:8081 > /tmp/result.html

# Check for voting results
grep -i "result" /tmp/result.html

# Check result service logs
docker compose logs result | tail -20
```

### Step 6: Test Worker Service

```bash
# Check worker logs
docker compose logs worker | tail -30

# Look for processing messages
docker compose logs worker | grep -i "processing\|connected\|vote"

# Check worker is running
docker compose ps worker
```

### Step 7: Test Redis

```bash
# Connect to Redis
docker compose exec redis redis-cli ping

# Check Redis stats
docker compose exec redis redis-cli INFO stats

# Check if votes are in queue
docker compose exec redis redis-cli LLEN votes

# Monitor Redis in real-time (Ctrl+C to stop)
docker compose exec redis redis-cli MONITOR
```

### Step 8: Test PostgreSQL

```bash
# Connect to PostgreSQL
docker compose exec db psql -U postgres -d postgres

# Or run single query
docker compose exec db psql -U postgres -d postgres -c "\dt"

# Check votes table exists
docker compose exec db psql -U postgres -d postgres -c "SELECT * FROM votes LIMIT 5;"

# Count total votes
docker compose exec db psql -U postgres -d postgres -c "SELECT COUNT(*) FROM votes;"

# Count votes by option
docker compose exec db psql -U postgres -d postgres -c "SELECT vote, COUNT(*) as count FROM votes GROUP BY vote;"

# Check database size
docker compose exec db psql -U postgres -d postgres -c "SELECT pg_size_pretty(pg_database_size('postgres'));"
```

### Step 9: Test Seed Data

```bash
# Run seed data job
docker compose --profile seed up seed-data --force-recreate

# Check seed logs
docker compose logs seed-data

# Verify votes increased
docker compose exec db psql -U postgres -d postgres -c "SELECT vote, COUNT(*) as count FROM votes GROUP BY vote;"
```

### Step 10: Test Networking

```bash
# Check networks
docker network ls | grep tactful

# Inspect frontend network
docker network inspect tactful-votingapp-cloud-infra_frontend

# Inspect backend network
docker network inspect tactful-votingapp-cloud-infra_backend

# Check which containers on each network
docker network inspect tactful-votingapp-cloud-infra_frontend --format '{{range .Containers}}{{.Name}} {{end}}'
docker network inspect tactful-votingapp-cloud-infra_backend --format '{{range .Containers}}{{.Name}} {{end}}'
```

### Step 11: Test Security (Non-root)

```bash
# Check vote container user
docker compose exec vote id

# Check result container user
docker compose exec result id

# Check worker container user
docker compose exec worker id

# Check db container user
docker compose exec db id

# Check redis container user
docker compose exec redis id
```

### Step 12: Test Resource Limits

```bash
# Check resource limits
docker compose exec vote cat /sys/fs/cgroup/memory/memory.limit_in_bytes

# Check CPU limits
docker stats --no-stream

# Detailed stats for each service
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"
```

### Step 13: Test Health Checks

```bash
# Check health status
docker compose ps

# Test PostgreSQL health check
docker compose exec db pg_isready -U postgres

# Test Redis health check
docker compose exec redis redis-cli ping

# View health check logs
docker inspect tactful-votingapp-cloud-infra-db-1 | jq '.[0].State.Health'
```

### Step 14: Test Data Persistence

```bash
# Count current votes
BEFORE=$(docker compose exec db psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM votes;")
echo "Votes before restart: $BEFORE"

# Restart services
docker compose restart

# Wait for services
sleep 20

# Count votes after restart
AFTER=$(docker compose exec db psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM votes;")
echo "Votes after restart: $AFTER"

# Verify data persisted
if [ "$BEFORE" == "$AFTER" ]; then
    echo "✓ Data persistence working!"
else
    echo "✗ Data persistence failed!"
fi
```

### Step 15: Phase 1 Cleanup

```bash
# View logs before cleanup
docker compose logs > /tmp/docker-compose-logs.txt
echo "Logs saved to /tmp/docker-compose-logs.txt"

# Stop all services
docker compose down

# Keep volumes for Phase 2
# Or remove everything: docker compose down -v
```

---

## Phase 2: Kubernetes Testing

### Step 1: Check Cluster Status

```bash
# Check Minikube status
minikube status

# If not running, start it
# minikube start --driver=docker --cpus=4 --memory=8192

# Check kubectl connection
kubectl cluster-info

# Check nodes
kubectl get nodes -o wide

# Check node resources
kubectl top nodes
```

### Step 2: Check Namespaces

```bash
# List all namespaces
kubectl get namespaces

# Check voting-app namespace
kubectl get namespace voting-app

# Describe namespace
kubectl describe namespace voting-app

# Check namespace labels (PSA)
kubectl get namespace voting-app -o yaml | grep -A 5 labels
```

### Step 3: Check All Pods

```bash
# List all pods in voting-app namespace
kubectl get pods -n voting-app

# Wide output with node info
kubectl get pods -n voting-app -o wide

# Check pod status details
kubectl get pods -n voting-app --show-labels

# Watch pods in real-time (Ctrl+C to stop)
kubectl get pods -n voting-app --watch
```

### Step 4: Test Vote Service

```bash
# Check vote deployment
kubectl get deployment vote -n voting-app

# Check vote pods
kubectl get pods -n voting-app -l app=vote

# Check vote service
kubectl get service vote -n voting-app

# Describe vote service
kubectl describe service vote -n voting-app

# Check vote endpoints
kubectl get endpoints vote -n voting-app

# Port-forward to test locally
kubectl port-forward -n voting-app service/vote 8080:80 &
PF_PID=$!
sleep 3

# Test vote service
curl -s http://localhost:8080 | head -10

# Kill port-forward
kill $PF_PID
```

### Step 5: Test Result Service

```bash
# Check result deployment
kubectl get deployment result -n voting-app

# Check result pods
kubectl get pods -n voting-app -l app=result

# Check result service
kubectl get service result -n voting-app

# Port-forward to test
kubectl port-forward -n voting-app service/result 8081:4000 &
PF_PID=$!
sleep 3

# Test result service
curl -s http://localhost:8081 | head -10

# Kill port-forward
kill $PF_PID
```

### Step 6: Test Worker Service

```bash
# Check worker deployment
kubectl get deployment worker -n voting-app

# Check worker pods
kubectl get pods -n voting-app -l app=worker

# Check worker logs
kubectl logs -n voting-app -l app=worker --tail=50

# Follow worker logs (Ctrl+C to stop)
kubectl logs -n voting-app -l app=worker --follow
```

### Step 7: Test PostgreSQL (StatefulSet)

```bash
# Check PostgreSQL StatefulSet
kubectl get statefulset postgres -n voting-app

# Check PostgreSQL pod
kubectl get pod postgres-0 -n voting-app

# Check PostgreSQL service
kubectl get service postgres -n voting-app

# Check PVC
kubectl get pvc -n voting-app | grep postgres

# Connect to PostgreSQL
kubectl exec -n voting-app postgres-0 -- psql -U postgres -d postgres -c "\dt"

# Check votes table
kubectl exec -n voting-app postgres-0 -- psql -U postgres -d postgres -c "SELECT COUNT(*) FROM votes;"

# Check votes by option
kubectl exec -n voting-app postgres-0 -- psql -U postgres -d postgres -c "SELECT vote, COUNT(*) as count FROM votes GROUP BY vote;"

# Check database connections
kubectl exec -n voting-app postgres-0 -- psql -U postgres -d postgres -c "SELECT count(*) FROM pg_stat_activity;"
```

### Step 8: Test Redis (StatefulSet)

```bash
# Check Redis StatefulSet
kubectl get statefulset redis -n voting-app

# Check Redis pod
kubectl get pod redis-0 -n voting-app

# Check Redis service
kubectl get service redis -n voting-app

# Check PVC
kubectl get pvc -n voting-app | grep redis

# Connect to Redis
kubectl exec -n voting-app redis-0 -- redis-cli ping

# Check Redis info
kubectl exec -n voting-app redis-0 -- redis-cli INFO server

# Check Redis memory
kubectl exec -n voting-app redis-0 -- redis-cli INFO memory | grep used_memory_human

# Check votes queue
kubectl exec -n voting-app redis-0 -- redis-cli LLEN votes
```

### Step 9: Test Ingress

```bash
# Check Ingress
kubectl get ingress -n voting-app

# Describe Ingress
kubectl describe ingress voting-app-ingress -n voting-app

# Check Ingress controller
kubectl get pods -n ingress-nginx

# Check Ingress controller service
kubectl get service -n ingress-nginx

# Test vote.local
curl -s http://vote.local | head -10

# Test result.local
curl -s http://result.local | head -10

# Check /etc/hosts has entries
grep -E "vote\.local|result\.local" /etc/hosts
```

### Step 10: Test ConfigMaps and Secrets

```bash
# List ConfigMaps
kubectl get configmap -n voting-app

# View app-config ConfigMap
kubectl get configmap app-config -n voting-app -o yaml

# List Secrets
kubectl get secrets -n voting-app

# Describe secret (without showing values)
kubectl describe secret postgres-secret -n voting-app
kubectl describe secret redis-secret -n voting-app

# Check secret is mounted in pods
kubectl describe pod -n voting-app -l app=worker | grep -A 5 "Environment"
```

### Step 11: Test Network Policies

```bash
# List NetworkPolicies
kubectl get networkpolicy -n voting-app

# Describe database NetworkPolicy
kubectl describe networkpolicy database-network-policy -n voting-app

# Test: Try to access postgres from vote pod (should work via worker)
kubectl exec -n voting-app -it $(kubectl get pod -n voting-app -l app=vote -o jsonpath='{.items[0].metadata.name}') -- nc -zv postgres 5432 || echo "Access restricted (expected)"

# Check if worker can access postgres (should work)
kubectl exec -n voting-app -it $(kubectl get pod -n voting-app -l app=worker -o jsonpath='{.items[0].metadata.name}') -- nc -zv postgres 5432
```

### Step 12: Test Pod Security

```bash
# Check Pod Security Admission labels
kubectl get namespace voting-app -o yaml | grep pod-security

# Check pod security context
kubectl get pod -n voting-app $(kubectl get pod -n voting-app -l app=vote -o jsonpath='{.items[0].metadata.name}') -o yaml | grep -A 10 securityContext

# Verify pods run as non-root
for pod in $(kubectl get pods -n voting-app -o jsonpath='{.items[*].metadata.name}'); do
    echo "Checking $pod:"
    kubectl exec -n voting-app $pod -- id 2>/dev/null || echo "  Cannot check (may be completed job)"
done
```

### Step 13: Test Resource Limits

```bash
# Check pod resource requests and limits
kubectl describe pods -n voting-app | grep -A 5 "Limits:\|Requests:"

# Check actual resource usage
kubectl top pods -n voting-app

# Check node resource allocation
kubectl describe nodes | grep -A 5 "Allocated resources"
```

### Step 14: Test Seed Job

```bash
# Check if seed job exists
kubectl get job seed -n voting-app

# Check seed job status
kubectl describe job seed -n voting-app

# Check seed pod
kubectl get pods -n voting-app -l job-name=seed

# Check seed logs
kubectl logs -n voting-app -l job-name=seed

# Count votes before re-running seed
BEFORE=$(kubectl exec -n voting-app postgres-0 -- psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM votes;")
echo "Votes before seed: $BEFORE"

# Delete and re-apply seed job
kubectl delete job seed -n voting-app
kubectl apply -f k8s/manifests/10-seed.yaml

# Wait for completion
kubectl wait --for=condition=complete job/seed -n voting-app --timeout=5m

# Count votes after seed
AFTER=$(kubectl exec -n voting-app postgres-0 -- psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM votes;")
echo "Votes after seed: $AFTER"
```

### Step 15: Test High Availability

```bash
# Check replica counts
kubectl get deployments -n voting-app

# Check vote pods distribution
kubectl get pods -n voting-app -l app=vote -o wide

# Check result pods distribution
kubectl get pods -n voting-app -l app=result -o wide

# Test failover: Delete one vote pod
VOTE_POD=$(kubectl get pod -n voting-app -l app=vote -o jsonpath='{.items[0].metadata.name}')
echo "Deleting pod: $VOTE_POD"
kubectl delete pod -n voting-app $VOTE_POD

# Watch new pod creation
kubectl get pods -n voting-app -l app=vote --watch

# Verify vote service still works
curl -s http://vote.local | head -10
```

### Step 16: Test Persistence

```bash
# Check PVCs
kubectl get pvc -n voting-app

# Check PVC status and size
kubectl describe pvc -n voting-app

# Get current vote count
VOTES=$(kubectl exec -n voting-app postgres-0 -- psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM votes;")
echo "Current votes: $VOTES"

# Delete postgres pod (data should persist)
kubectl delete pod postgres-0 -n voting-app

# Wait for pod to recreate
kubectl wait --for=condition=ready pod/postgres-0 -n voting-app --timeout=5m

# Verify votes still there
NEW_VOTES=$(kubectl exec -n voting-app postgres-0 -- psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM votes;")
echo "Votes after pod recreation: $NEW_VOTES"

if [ "$VOTES" == "$NEW_VOTES" ]; then
    echo "✓ Persistence working!"
else
    echo "✗ Persistence failed!"
fi
```

### Step 17: End-to-End Test

```bash
# Get current vote counts
echo "=== Before Test ==="
kubectl exec -n voting-app postgres-0 -- psql -U postgres -d postgres -c "SELECT vote, COUNT(*) as count FROM votes GROUP BY vote;"

# Submit 10 votes via vote.local
for i in {1..10}; do
    curl -X POST http://vote.local -d "vote=a" -H "Content-Type: application/x-www-form-urlencoded"
    echo "Vote $i submitted"
    sleep 1
done

# Wait for worker to process
sleep 10

# Check updated counts
echo "=== After Test ==="
kubectl exec -n voting-app postgres-0 -- psql -U postgres -d postgres -c "SELECT vote, COUNT(*) as count FROM votes GROUP BY vote;"

# Check result page
curl -s http://result.local | grep -o '[0-9]*%' | head -2
```

---

## Phase 3: CI/CD Pipeline Testing

### Step 1: Check GitHub Repository

```bash
# Check remote repository
git remote -v

# Check current branch
git branch

# Check last commit
git log --oneline -5

# Check if changes are pushed
git status
```

### Step 2: Check Workflow Files

```bash
# List workflow files
ls -lh .github/workflows/

# Check main CI/CD workflow
cat .github/workflows/ci-cd.yml | head -50

# Check workflow syntax (requires act or GitHub CLI)
# gh workflow view ci-cd.yml
```

### Step 3: Check Docker Images in GHCR

```bash
# Using GitHub CLI (if authenticated)
gh api /user/packages?package_type=container | jq '.[] | {name: .name, visibility: .visibility}'

# Or check manually on GitHub
echo "Visit: https://github.com/omarMohamedo-o?tab=packages"
```

### Step 4: Check Workflow Runs

```bash
# List recent workflow runs (requires gh auth)
gh run list --limit 10

# View specific run
# gh run view <run-id>

# Check run logs
# gh run view <run-id> --log
```

### Step 5: Test Local Workflow Syntax

```bash
# Validate workflow YAML syntax
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci-cd.yml'))" && echo "✓ Valid YAML" || echo "✗ Invalid YAML"

# Check for common issues
grep -n "uses:" .github/workflows/ci-cd.yml
grep -n "runs-on:" .github/workflows/ci-cd.yml
```

### Step 6: Check Dependabot

```bash
# Check Dependabot config
cat .github/dependabot.yml

# Check for Dependabot PRs (requires gh auth)
gh pr list --label dependencies

# Check security advisories
gh api /repos/omarMohamedo-o/tactful-votingapp-cloud-infra/vulnerability-alerts
```

### Step 7: Test Security Scanning Locally

```bash
# Install Trivy if not already installed
# sudo apt-get install trivy

# Scan vote image
trivy image tactful-votingapp-cloud-infra-vote:latest

# Scan result image
trivy image tactful-votingapp-cloud-infra-result:latest

# Scan worker image
trivy image tactful-votingapp-cloud-infra-worker:latest

# Scan with severity filter
trivy image --severity HIGH,CRITICAL tactful-votingapp-cloud-infra-vote:latest
```

### Step 8: Test Docker Build in CI Mode

```bash
# Build with buildx (like CI)
docker buildx create --use
docker buildx build --platform linux/amd64 -t test-vote:latest vote/
docker buildx build --platform linux/amd64 -t test-result:latest result/
docker buildx build --platform linux/amd64 -t test-worker:latest worker/
```

### Step 9: Trigger Manual Workflow

```bash
# Trigger CI/CD workflow manually (requires gh auth)
gh workflow run ci-cd.yml

# Trigger monitoring deployment
gh workflow run deploy-monitoring.yml -f environment=dev

# Check workflow status
gh run list --workflow=ci-cd.yml --limit 5
```

---

## Helm Charts Testing

### Step 1: Validate Helm Chart Syntax

```bash
# Lint custom voting-app chart
helm lint k8s/helm/voting-app/

# Check for errors
helm lint k8s/helm/voting-app/ --strict
```

### Step 2: Validate Helm Values

```bash
# Check values syntax
python3 -c "import yaml; yaml.safe_load(open('k8s/helm/voting-app/values.yaml'))" && echo "✓ values.yaml valid"
python3 -c "import yaml; yaml.safe_load(open('k8s/helm/voting-app/values-dev.yaml'))" && echo "✓ values-dev.yaml valid"
python3 -c "import yaml; yaml.safe_load(open('k8s/helm/voting-app/values-prod.yaml'))" && echo "✓ values-prod.yaml valid"

# Same for PostgreSQL and Redis
python3 -c "import yaml; yaml.safe_load(open('k8s/helm/postgresql-values-dev.yaml'))" && echo "✓ postgresql-values-dev.yaml valid"
python3 -c "import yaml; yaml.safe_load(open('k8s/helm/redis-values-dev.yaml'))" && echo "✓ redis-values-dev.yaml valid"
```

### Step 3: Dry-Run Helm Chart

```bash
# Dry-run voting-app chart
helm install voting-app k8s/helm/voting-app/ \
  --values k8s/helm/voting-app/values-dev.yaml \
  --namespace voting-app \
  --dry-run --debug > /tmp/helm-dryrun.yaml

# Check rendered output
cat /tmp/helm-dryrun.yaml | head -50

# Count resources that would be created
grep "^kind:" /tmp/helm-dryrun.yaml | sort | uniq -c
```

### Step 4: Template Helm Chart

```bash
# Render templates without installation
helm template voting-app k8s/helm/voting-app/ \
  --values k8s/helm/voting-app/values-dev.yaml \
  --namespace voting-app > /tmp/helm-template.yaml

# View rendered templates
less /tmp/helm-template.yaml

# Validate rendered YAML
kubectl apply --dry-run=client -f /tmp/helm-template.yaml
```

### Step 5: Test Helm Chart Values

```bash
# Test with dev values
helm template voting-app k8s/helm/voting-app/ \
  --values k8s/helm/voting-app/values-dev.yaml \
  --namespace voting-app | grep -A 3 "replicas:"

# Test with prod values
helm template voting-app k8s/helm/voting-app/ \
  --values k8s/helm/voting-app/values-prod.yaml \
  --namespace voting-app | grep -A 3 "replicas:"

# Compare differences
diff \
  <(helm template voting-app k8s/helm/voting-app/ --values k8s/helm/voting-app/values-dev.yaml) \
  <(helm template voting-app k8s/helm/voting-app/ --values k8s/helm/voting-app/values-prod.yaml) \
  | head -50
```

### Step 6: Check Helm Dependencies

```bash
# Check if chart has dependencies
helm dependency list k8s/helm/voting-app/

# Show chart info
helm show chart k8s/helm/voting-app/

# Show all values
helm show values k8s/helm/voting-app/
```

### Step 7: Test PostgreSQL Helm Values

```bash
# Validate PostgreSQL values
cat k8s/helm/postgresql-values-dev.yaml

# Check key configurations
grep -A 3 "auth:" k8s/helm/postgresql-values-dev.yaml
grep -A 3 "persistence:" k8s/helm/postgresql-values-dev.yaml
grep -A 3 "resources:" k8s/helm/postgresql-values-dev.yaml
```

### Step 8: Test Redis Helm Values

```bash
# Validate Redis values
cat k8s/helm/redis-values-dev.yaml

# Check key configurations
grep -A 3 "architecture:" k8s/helm/redis-values-dev.yaml
grep -A 3 "persistence:" k8s/helm/redis-values-dev.yaml
grep -A 3 "resources:" k8s/helm/redis-values-dev.yaml
```

### Step 9: Search Bitnami Charts

```bash
# Add Bitnami repo if not already added
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Search for PostgreSQL charts
helm search repo bitnami/postgresql

# Search for Redis charts
helm search repo bitnami/redis

# Show PostgreSQL chart info
helm show chart bitnami/postgresql

# Show Redis chart info
helm show chart bitnami/redis
```

---

## Monitoring Stack Testing

### Step 1: Add Helm Repositories

```bash
# Add Prometheus community repo
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts

# Add Grafana repo
helm repo add grafana https://grafana.github.io/helm-charts

# Update repos
helm repo update

# List repos
helm repo list

# Search for monitoring charts
helm search repo prometheus-community/kube-prometheus-stack
helm search repo grafana/loki-stack
```

### Step 2: Validate Monitoring Values

```bash
# Validate Prometheus values
python3 -c "import yaml; yaml.safe_load(open('k8s/monitoring/prometheus-values-dev.yaml'))" && echo "✓ prometheus-values-dev.yaml valid"

# Validate Loki values
python3 -c "import yaml; yaml.safe_load(open('k8s/monitoring/loki-values-dev.yaml'))" && echo "✓ loki-values-dev.yaml valid"

# Check key configurations
cat k8s/monitoring/prometheus-values-dev.yaml | grep -A 5 "retention:"
cat k8s/monitoring/prometheus-values-dev.yaml | grep -A 5 "grafana:"
```

### Step 3: Dry-Run Prometheus Deployment

```bash
# Dry-run Prometheus stack
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values k8s/monitoring/prometheus-values-dev.yaml \
  --dry-run --debug > /tmp/prometheus-dryrun.yaml

# Check what would be created
grep "^kind:" /tmp/prometheus-dryrun.yaml | sort | uniq -c

# Check size of deployment
wc -l /tmp/prometheus-dryrun.yaml
```

### Step 4: Deploy Prometheus + Grafana

```bash
# Deploy Prometheus stack (takes 5-10 minutes)
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --values k8s/monitoring/prometheus-values-dev.yaml \
  --wait \
  --timeout 15m

# Check deployment status
helm list -n monitoring

# Check pods
kubectl get pods -n monitoring

# Watch pods come up
kubectl get pods -n monitoring --watch
```

### Step 5: Wait for Monitoring Pods

```bash
# Wait for Grafana
kubectl -n monitoring wait --for=condition=ready pod -l app.kubernetes.io/name=grafana --timeout=5m

# Wait for Prometheus
kubectl -n monitoring wait --for=condition=ready pod -l app.kubernetes.io/name=prometheus --timeout=5m

# Wait for AlertManager
kubectl -n monitoring wait --for=condition=ready pod -l app.kubernetes.io/name=alertmanager --timeout=5m

# Check all pods ready
kubectl get pods -n monitoring
```

### Step 6: Deploy Loki Logging

```bash
# Deploy Loki stack
helm upgrade --install loki grafana/loki-stack \
  --namespace monitoring \
  --values k8s/monitoring/loki-values-dev.yaml \
  --wait \
  --timeout 10m

# Check Loki deployment
kubectl get pods -n monitoring -l app=loki

# Check Promtail DaemonSet
kubectl get daemonset -n monitoring

# Check Promtail logs
kubectl logs -n monitoring -l app=promtail --tail=20
```

### Step 7: Deploy ServiceMonitors

```bash
# Apply PostgreSQL ServiceMonitor
kubectl apply -f k8s/monitoring/servicemonitors/postgresql-servicemonitor.yaml

# Apply Redis ServiceMonitor
kubectl apply -f k8s/monitoring/servicemonitors/redis-servicemonitor.yaml

# Check ServiceMonitors
kubectl get servicemonitor -n voting-app

# Describe ServiceMonitors
kubectl describe servicemonitor postgresql -n voting-app
kubectl describe servicemonitor redis -n voting-app
```

### Step 8: Get Grafana Credentials

```bash
# Get Grafana admin password
GRAFANA_PASSWORD=$(kubectl -n monitoring get secret prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
echo "Grafana admin password: $GRAFANA_PASSWORD"

# Save to file
echo "admin" > /tmp/grafana-user.txt
echo "$GRAFANA_PASSWORD" > /tmp/grafana-password.txt
echo "Credentials saved to /tmp/grafana-*.txt"
```

### Step 9: Access Prometheus

```bash
# Port-forward Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &
PF_PROM=$!

# Wait for port-forward
sleep 5

# Test Prometheus API
curl -s http://localhost:9090/api/v1/status/config | jq '.status'

# Query metrics
curl -s 'http://localhost:9090/api/v1/query?query=up' | jq '.data.result[] | {job: .metric.job, instance: .metric.instance, value: .value[1]}'

# Check targets
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | {job: .labels.job, health: .health}'

# Stop port-forward
kill $PF_PROM

echo "Access Prometheus at: http://localhost:9090"
```

### Step 10: Access Grafana

```bash
# Port-forward Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &
PF_GRAF=$!

# Wait for port-forward
sleep 5

# Test Grafana API (requires password)
GRAFANA_PASSWORD=$(kubectl -n monitoring get secret prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
curl -s -u admin:$GRAFANA_PASSWORD http://localhost:3000/api/health | jq '.'

# List datasources
curl -s -u admin:$GRAFANA_PASSWORD http://localhost:3000/api/datasources | jq '.'

# List dashboards
curl -s -u admin:$GRAFANA_PASSWORD http://localhost:3000/api/search | jq '.[] | {title: .title, type: .type}'

# Stop port-forward
kill $PF_GRAF

echo "Access Grafana at: http://localhost:3000"
echo "Username: admin"
echo "Password: $GRAFANA_PASSWORD"
```

### Step 11: Access AlertManager

```bash
# Port-forward AlertManager
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093 &
PF_ALERT=$!

# Wait for port-forward
sleep 5

# Test AlertManager API
curl -s http://localhost:9093/api/v2/status | jq '.'

# Check alerts
curl -s http://localhost:9093/api/v2/alerts | jq '.[] | {labels: .labels, status: .status}'

# Stop port-forward
kill $PF_ALERT

echo "Access AlertManager at: http://localhost:9093"
```

### Step 12: Test Prometheus Queries

```bash
# Port-forward Prometheus again
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &
PF_PROM=$!
sleep 5

# Query CPU usage
curl -s 'http://localhost:9090/api/v1/query?query=rate(container_cpu_usage_seconds_total{namespace="voting-app"}[5m])' | jq '.data.result[] | {pod: .metric.pod, value: .value[1]}'

# Query memory usage
curl -s 'http://localhost:9090/api/v1/query?query=container_memory_usage_bytes{namespace="voting-app"}' | jq '.data.result[] | {pod: .metric.pod, value: .value[1]}'

# Query pod count
curl -s 'http://localhost:9090/api/v1/query?query=count(kube_pod_info{namespace="voting-app"})' | jq '.data.result[0].value[1]'

# Query PostgreSQL metrics (if exporter is running)
curl -s 'http://localhost:9090/api/v1/query?query=pg_up' | jq '.'

# Query Redis metrics (if exporter is running)
curl -s 'http://localhost:9090/api/v1/query?query=redis_up' | jq '.'

# Kill port-forward
kill $PF_PROM
```

### Step 13: Check Loki Logs

```bash
# Get Loki endpoint
kubectl get service -n monitoring loki

# Port-forward Loki
kubectl port-forward -n monitoring svc/loki 3100:3100 &
PF_LOKI=$!
sleep 5

# Query logs from voting-app namespace
curl -s 'http://localhost:3100/loki/api/v1/query?query={namespace="voting-app"}' | jq '.data.result[] | .stream'

# Query specific pod logs
curl -s 'http://localhost:3100/loki/api/v1/query?query={namespace="voting-app",pod=~"vote-.*"}' | jq '.data.result[0].stream'

# Kill port-forward
kill $PF_LOKI
```

### Step 14: Verify ServiceMonitor Scraping

```bash
# Check if ServiceMonitors are being scraped
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &
PF_PROM=$!
sleep 5

# Check PostgreSQL target
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.job=="postgresql") | {job: .labels.job, health: .health, lastScrape: .lastScrape}'

# Check Redis target
curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets[] | select(.labels.job=="redis") | {job: .labels.job, health: .health, lastScrape: .lastScrape}'

# Kill port-forward
kill $PF_PROM
```

### Step 15: Test Monitoring Persistence

```bash
# Check PVCs for monitoring
kubectl get pvc -n monitoring

# Check Prometheus PVC
kubectl describe pvc -n monitoring prometheus-prometheus-kube-prometheus-prometheus-db-prometheus-kube-prometheus-prometheus-0

# Check Grafana PVC
kubectl describe pvc -n monitoring prometheus-grafana

# Restart Grafana to test persistence
kubectl delete pod -n monitoring -l app.kubernetes.io/name=grafana

# Wait for pod to recreate
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=grafana -n monitoring --timeout=5m

# Verify dashboards still exist
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &
PF_GRAF=$!
sleep 5

GRAFANA_PASSWORD=$(kubectl -n monitoring get secret prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
curl -s -u admin:$GRAFANA_PASSWORD http://localhost:3000/api/search | jq 'length'

kill $PF_GRAF
```

---

## Complete System Validation

### Step 1: Full System Status Check

```bash
echo "=== SYSTEM STATUS CHECK ==="
echo ""

# Docker Compose (if running)
echo "1. Docker Compose Status:"
docker compose ps 2>/dev/null || echo "Not running"
echo ""

# Kubernetes Cluster
echo "2. Kubernetes Cluster:"
kubectl cluster-info
echo ""

# All Namespaces
echo "3. Namespaces:"
kubectl get namespaces
echo ""

# Voting App Pods
echo "4. Voting App Pods:"
kubectl get pods -n voting-app
echo ""

# Monitoring Pods
echo "5. Monitoring Pods:"
kubectl get pods -n monitoring 2>/dev/null || echo "Monitoring not deployed"
echo ""

# Services
echo "6. Services:"
kubectl get services -n voting-app
echo ""

# Ingress
echo "7. Ingress:"
kubectl get ingress -n voting-app
echo ""

# PVCs
echo "8. Persistent Volumes:"
kubectl get pvc --all-namespaces
echo ""
```

### Step 2: Resource Usage Summary

```bash
echo "=== RESOURCE USAGE ==="
echo ""

# Node resources
echo "1. Node Resources:"
kubectl top nodes
echo ""

# Voting app resources
echo "2. Voting App Pods:"
kubectl top pods -n voting-app
echo ""

# Monitoring resources
echo "3. Monitoring Pods:"
kubectl top pods -n monitoring 2>/dev/null || echo "Monitoring not deployed"
echo ""

# Total pod count
echo "4. Total Pods:"
kubectl get pods --all-namespaces --no-headers | wc -l
echo ""
```

### Step 3: Complete End-to-End Test

```bash
echo "=== END-TO-END TEST ==="
echo ""

# Get initial vote count
echo "1. Initial vote count:"
INITIAL_VOTES=$(kubectl exec -n voting-app postgres-0 -- psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM votes;")
echo "Initial votes: $INITIAL_VOTES"
echo ""

# Submit votes
echo "2. Submitting 5 votes for Cats..."
for i in {1..5}; do
    curl -s -X POST http://vote.local -d "vote=a" -H "Content-Type: application/x-www-form-urlencoded" > /dev/null
    echo "  Vote $i submitted"
done
echo ""

echo "3. Submitting 3 votes for Dogs..."
for i in {1..3}; do
    curl -s -X POST http://vote.local -d "vote=b" -H "Content-Type: application/x-www-form-urlencoded" > /dev/null
    echo "  Vote $i submitted"
done
echo ""

# Wait for processing
echo "4. Waiting for worker to process votes..."
sleep 15
echo ""

# Check final count
echo "5. Final vote count:"
FINAL_VOTES=$(kubectl exec -n voting-app postgres-0 -- psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM votes;")
echo "Final votes: $FINAL_VOTES"
echo ""

# Show breakdown
echo "6. Vote breakdown:"
kubectl exec -n voting-app postgres-0 -- psql -U postgres -d postgres -c "SELECT vote, COUNT(*) as count FROM votes GROUP BY vote;"
echo ""

# Calculate new votes
NEW_VOTES=$((FINAL_VOTES - INITIAL_VOTES))
echo "7. New votes added: $NEW_VOTES"
if [ $NEW_VOTES -ge 8 ]; then
    echo "✓ End-to-end test PASSED!"
else
    echo "✗ End-to-end test FAILED! (Expected 8, got $NEW_VOTES)"
fi
```

### Step 4: Security Validation

```bash
echo "=== SECURITY VALIDATION ==="
echo ""

# Check PSA
echo "1. Pod Security Admission:"
kubectl get namespace voting-app -o yaml | grep -A 3 "pod-security"
echo ""

# Check NetworkPolicies
echo "2. Network Policies:"
kubectl get networkpolicy -n voting-app
echo ""

# Check pod security contexts
echo "3. Pod Security Contexts (Non-root check):"
for pod in $(kubectl get pods -n voting-app -o jsonpath='{.items[*].metadata.name}'); do
    echo "  Checking $pod:"
    kubectl exec -n voting-app $pod -- id 2>/dev/null | head -1 || echo "    (Completed job)"
done
echo ""

# Check RBAC
echo "4. Service Accounts:"
kubectl get serviceaccount -n voting-app
echo ""
```

### Step 5: High Availability Test

```bash
echo "=== HIGH AVAILABILITY TEST ==="
echo ""

# Check current replicas
echo "1. Current deployments:"
kubectl get deployments -n voting-app -o custom-columns=NAME:.metadata.name,REPLICAS:.spec.replicas,READY:.status.readyReplicas
echo ""

# Delete a vote pod
echo "2. Deleting one vote pod to test failover..."
VOTE_POD=$(kubectl get pod -n voting-app -l app=vote -o jsonpath='{.items[0].metadata.name}')
echo "  Deleting: $VOTE_POD"
kubectl delete pod -n voting-app $VOTE_POD
echo ""

# Wait for new pod
echo "3. Waiting for replacement pod..."
sleep 10
echo ""

# Check pods recovered
echo "4. Current vote pods:"
kubectl get pods -n voting-app -l app=vote
echo ""

# Test service still works
echo "5. Testing vote service availability:"
curl -s http://vote.local | grep -o "Cats vs Dogs" && echo "  ✓ Vote service is UP" || echo "  ✗ Vote service is DOWN"
echo ""
```

### Step 6: Data Persistence Test

```bash
echo "=== DATA PERSISTENCE TEST ==="
echo ""

# Get current data
echo "1. Recording current state..."
VOTES_BEFORE=$(kubectl exec -n voting-app postgres-0 -- psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM votes;")
echo "  Votes before: $VOTES_BEFORE"
echo ""

# Restart database pod
echo "2. Restarting database pod..."
kubectl delete pod postgres-0 -n voting-app
echo ""

# Wait for pod to recreate
echo "3. Waiting for pod to recreate..."
kubectl wait --for=condition=ready pod/postgres-0 -n voting-app --timeout=5m
echo ""

# Check data persisted
echo "4. Checking data after restart..."
VOTES_AFTER=$(kubectl exec -n voting-app postgres-0 -- psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM votes;")
echo "  Votes after: $VOTES_AFTER"
echo ""

# Compare
if [ "$VOTES_BEFORE" == "$VOTES_AFTER" ]; then
    echo "✓ Data persistence test PASSED!"
else
    echo "✗ Data persistence test FAILED!"
fi
echo ""
```

### Step 7: Performance Test

```bash
echo "=== PERFORMANCE TEST ==="
echo ""

# Test vote service response time
echo "1. Vote service response times (10 requests):"
for i in {1..10}; do
    TIME=$(curl -s -o /dev/null -w "%{time_total}" http://vote.local)
    echo "  Request $i: ${TIME}s"
done
echo ""

# Test result service response time
echo "2. Result service response times (10 requests):"
for i in {1..10}; do
    TIME=$(curl -s -o /dev/null -w "%{time_total}" http://result.local)
    echo "  Request $i: ${TIME}s"
done
echo ""

# Test concurrent votes
echo "3. Testing concurrent vote submissions..."
START_TIME=$(date +%s)
for i in {1..50}; do
    curl -s -X POST http://vote.local -d "vote=a" -H "Content-Type: application/x-www-form-urlencoded" > /dev/null &
done
wait
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
echo "  Submitted 50 votes in ${DURATION}s"
echo ""
```

### Step 8: Monitoring Validation

```bash
echo "=== MONITORING VALIDATION ==="
echo ""

# Check Prometheus scraping
echo "1. Checking Prometheus targets:"
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090 &
PF_PROM=$!
sleep 5

TARGETS=$(curl -s http://localhost:9090/api/v1/targets | jq '.data.activeTargets | length')
UP_TARGETS=$(curl -s http://localhost:9090/api/v1/targets | jq '[.data.activeTargets[] | select(.health=="up")] | length')
echo "  Total targets: $TARGETS"
echo "  Healthy targets: $UP_TARGETS"

kill $PF_PROM
echo ""

# Check Grafana dashboards
echo "2. Checking Grafana dashboards:"
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80 &
PF_GRAF=$!
sleep 5

GRAFANA_PASSWORD=$(kubectl -n monitoring get secret prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode)
DASHBOARD_COUNT=$(curl -s -u admin:$GRAFANA_PASSWORD http://localhost:3000/api/search | jq 'length')
echo "  Total dashboards: $DASHBOARD_COUNT"

kill $PF_GRAF
echo ""

# Check Loki logs
echo "3. Checking Loki log aggregation:"
kubectl port-forward -n monitoring svc/loki 3100:3100 &
PF_LOKI=$!
sleep 5

LOG_STREAMS=$(curl -s 'http://localhost:3100/loki/api/v1/query?query={namespace="voting-app"}' | jq '.data.result | length')
echo "  Log streams: $LOG_STREAMS"

kill $PF_LOKI
echo ""
```

### Step 9: Generate Final Report

```bash
echo "=== FINAL TEST REPORT ==="
echo ""
echo "Date: $(date)"
echo ""

# Summary
echo "PHASE 1 - Docker Compose:"
if docker compose ps > /dev/null 2>&1; then
    echo "  Status: Running"
    docker compose ps --format "table {{.Name}}\t{{.Status}}" | tail -n +2
else
    echo "  Status: Not running (Phase 2 active)"
fi
echo ""

echo "PHASE 2 - Kubernetes:"
echo "  Cluster: $(kubectl cluster-info | head -1 | awk '{print $NF}')"
echo "  Nodes: $(kubectl get nodes --no-headers | wc -l)"
echo "  Voting App Pods: $(kubectl get pods -n voting-app --no-headers 2>/dev/null | wc -l)"
echo "  Services:"
kubectl get svc -n voting-app --no-headers | awk '{print "    - " $1 " (" $2 ")"}'
echo ""

echo "PHASE 3 - CI/CD:"
echo "  Workflows configured: $(ls -1 .github/workflows/*.yml | wc -l)"
echo "  Last commit: $(git log --oneline -1)"
echo ""

echo "HELM CHARTS:"
echo "  Custom charts: 1 (voting-app)"
echo "  External charts configured: 2 (PostgreSQL, Redis)"
echo ""

echo "MONITORING:"
if kubectl get namespace monitoring > /dev/null 2>&1; then
    echo "  Status: Deployed"
    echo "  Pods: $(kubectl get pods -n monitoring --no-headers 2>/dev/null | wc -l)"
    echo "  Components: Prometheus, Grafana, AlertManager, Loki, Promtail"
else
    echo "  Status: Not deployed"
fi
echo ""

echo "DATABASE STATISTICS:"
TOTAL_VOTES=$(kubectl exec -n voting-app postgres-0 -- psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM votes;" 2>/dev/null || echo "0")
echo "  Total votes: $TOTAL_VOTES"
kubectl exec -n voting-app postgres-0 -- psql -U postgres -d postgres -c "SELECT vote, COUNT(*) as count FROM votes GROUP BY vote;" 2>/dev/null | tail -n +3 | head -n -2
echo ""

echo "================================"
echo "✅ ALL TESTS COMPLETED"
echo "================================"
```

---

## Troubleshooting Commands

### Docker Compose Issues

```bash
# Check Docker daemon
sudo systemctl status docker

# Check Docker logs
sudo journalctl -u docker --no-pager | tail -50

# Remove all containers and volumes
docker compose down -v
docker system prune -af --volumes

# Check port conflicts
sudo netstat -tulpn | grep -E ':(8080|8081|5432|6379)'

# Rebuild without cache
docker compose build --no-cache
docker compose up -d
```

### Kubernetes Issues

```bash
# Check cluster events
kubectl get events -n voting-app --sort-by='.lastTimestamp'

# Describe failing pod
kubectl describe pod <pod-name> -n voting-app

# Check pod logs
kubectl logs <pod-name> -n voting-app
kubectl logs <pod-name> -n voting-app --previous

# Check node resources
kubectl describe nodes

# Force delete stuck pod
kubectl delete pod <pod-name> -n voting-app --force --grace-period=0

# Restart deployment
kubectl rollout restart deployment/<deployment-name> -n voting-app
```

### Monitoring Issues

```bash
# Check monitoring namespace
kubectl get all -n monitoring

# Check Prometheus operator logs
kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus-operator

# Check Grafana logs
kubectl logs -n monitoring -l app.kubernetes.io/name=grafana

# Delete and redeploy monitoring
helm uninstall prometheus -n monitoring
helm uninstall loki -n monitoring
kubectl delete namespace monitoring
# Then redeploy following monitoring steps
```

### Network Issues

```bash
# Check /etc/hosts
cat /etc/hosts | grep -E "vote\.local|result\.local"

# If missing, add entries
echo "$(minikube ip) vote.local result.local" | sudo tee -a /etc/hosts

# Test DNS resolution
nslookup vote.local
nslookup result.local

# Check Ingress
kubectl get ingress -n voting-app
kubectl describe ingress voting-app-ingress -n voting-app

# Check Ingress controller
kubectl get pods -n ingress-nginx
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

---

## Quick Reference

### Essential Commands Summary

```bash
# Phase 1 - Docker Compose
docker compose up -d                    # Start all services
docker compose ps                       # Check status
docker compose logs -f                  # View logs
docker compose down -v                  # Stop and remove

# Phase 2 - Kubernetes
kubectl get pods -n voting-app          # Check pods
kubectl get svc -n voting-app           # Check services
kubectl logs -f <pod> -n voting-app     # View logs
kubectl exec -it <pod> -n voting-app -- bash  # Shell into pod

# Phase 3 - CI/CD
git status                              # Check changes
git add .                               # Stage changes
git commit -m "message"                 # Commit
git push origin master                  # Push to GitHub

# Helm
helm list -A                            # List releases
helm status <release> -n <namespace>    # Check status
helm uninstall <release> -n <namespace> # Remove release

# Monitoring
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
```

---

**End of Complete Testing Guide**

**Next Steps:**

1. Start with Phase 1 testing
2. Move to Phase 2 after Phase 1 passes
3. Test Phase 3 CI/CD
4. Deploy and test Helm charts
5. Deploy and test monitoring
6. Run complete system validation

**Good luck with your testing!** 🚀
