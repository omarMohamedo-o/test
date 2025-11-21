# Phase 3: CI/CD, Security & Observability

Complete automation, security scanning, and monitoring solution for the Voting App.

## 📋 Table of Contents

- [Overview](#overview)
- [CI/CD Pipeline](#cicd-pipeline)
- [Security Scanning](#security-scanning)
- [Monitoring & Observability](#monitoring--observability)
- [Workflows](#workflows)
- [Setup Instructions](#setup-instructions)
- [Usage](#usage)
- [Best Practices](#best-practices)

## 🎯 Overview

Phase 3 implements enterprise-grade automation covering:

- **CI/CD Pipeline**: Automated build, test, scan, and deploy
- **Security**: Multi-layer vulnerability scanning (Trivy, tfsec, CodeQL, TruffleHog)
- **Monitoring**: Prometheus, Grafana, Loki stack
- **Dependency Management**: Automated Dependabot updates
- **Infrastructure Automation**: Terraform workflow automation

## 🚀 CI/CD Pipeline

### Architecture

```
┌─────────────┐     ┌──────────────┐     ┌────────────┐     ┌──────────────┐
│   Commit    │────▶│  Build &     │────▶│  Security  │────▶│   Deploy     │
│   to Repo   │     │  Test Images │     │  Scanning  │     │  to K8s      │
└─────────────┘     └──────────────┘     └────────────┘     └──────────────┘
                                                                     │
                                                                     ▼
                                                              ┌──────────────┐
                                                              │ Smoke Tests  │
                                                              └──────────────┘
```

### Build Process

1. **Image Building** (Parallel for vote, result, worker)
   - Docker BuildKit with layer caching
   - Multi-stage builds for optimization
   - GitHub Actions cache (type=gha)

2. **Security Scanning**
   - Trivy for container vulnerabilities (CRITICAL, HIGH)
   - SARIF upload to GitHub Security tab
   - Fail on critical vulnerabilities

3. **Testing**
   - Container health checks
   - Unit tests per service
   - Integration tests

4. **Registry Push**
   - GitHub Container Registry (ghcr.io)
   - Image tagging strategy:
     - `sha-<commit>` - Specific commit
     - `<branch>` - Latest for branch
     - `latest` - Main branch only

### Deployment Flow

```yaml
PostgreSQL Helm Chart
  ↓
Redis Helm Chart
  ↓
Voting App Helm Chart
  ↓
Smoke Tests
  - Vote submission (POST /vote)
  - Result retrieval (GET /result)
  - Database connectivity
  - Redis connectivity
```

## 🔒 Security Scanning

### Multi-Layer Security

| Layer | Tool | Frequency | Severity |
|-------|------|-----------|----------|
| Dependencies | Trivy (fs scan) | Daily + PR | CRITICAL, HIGH, MEDIUM |
| Container Images | Trivy (image scan) | Every build | CRITICAL, HIGH |
| Source Code | CodeQL | Daily + PR | All |
| Secrets | TruffleHog | Every commit | All |
| IaC | tfsec | Terraform changes | All |

### Security Workflow Features

- **Automated Scans**: Daily scheduled scans at 2 AM UTC
- **PR Integration**: Block merges on critical vulnerabilities
- **SARIF Upload**: Results visible in GitHub Security tab
- **Vulnerability Database**: Auto-updated Trivy database
- **Secret Detection**: Pre-commit hook and CI scanning

### Security Reports

Access reports in:

- **GitHub Security Tab**: `/security/code-scanning`
- **Workflow Artifacts**: 30-day retention
- **Step Summary**: Inline in workflow runs

## 📊 Monitoring & Observability

### Stack Components

```
┌─────────────────────────────────────────────────────┐
│                  Grafana Dashboards                 │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐      │
│  │ App Metrics│  │  Logs     │  │  Alerts   │      │
│  └───────────┘  └───────────┘  └───────────┘      │
└──────────┬──────────────┬──────────────┬───────────┘
           │              │              │
     ┌─────▼─────┐  ┌────▼────┐  ┌──────▼──────┐
     │Prometheus │  │  Loki   │  │AlertManager │
     └─────┬─────┘  └────┬────┘  └─────────────┘
           │              │
     ┌─────▼─────────────▼─────┐
     │   Service Monitors      │
     │ - PostgreSQL Exporter   │
     │ - Redis Exporter        │
     │ - Node Exporter         │
     │ - Promtail (DaemonSet)  │
     └─────────────────────────┘
```

### Metrics Collected

**Application Metrics:**

- Request rate, latency, errors
- Vote submission rate
- Result query performance
- Worker processing time

**Infrastructure Metrics:**

- CPU, Memory, Disk usage
- Network I/O
- Pod restarts
- Resource limits

**Database Metrics:**

- PostgreSQL connections, queries, replication lag
- Redis memory, hit rate, evictions

**Logs:**

- Application logs (stdout/stderr)
- Structured logging with JSON
- Log aggregation via Promtail → Loki

### Grafana Dashboards

Pre-configured dashboards:

1. **Voting App Overview**: Key metrics, vote trends
2. **Infrastructure Health**: Node/pod status, resources
3. **Database Performance**: PostgreSQL/Redis metrics
4. **Application Logs**: Centralized log viewer

## 📝 Workflows

### 1. CI/CD Pipeline (`.github/workflows/ci-cd.yml`)

**Triggers:**

- Push to `main` or `develop` (vote/result/worker paths)
- Pull requests to `main`
- Manual dispatch with environment selection

**Jobs:**

1. `build-vote`: Build vote service image
2. `build-result`: Build result service image
3. `build-worker`: Build worker service image
4. `deploy`: Deploy to Kubernetes with Helm
5. `smoke-tests`: Verify deployment health
6. `notify`: Send success/failure notifications

**Duration:** ~8-12 minutes

### 2. Terraform Automation (`.github/workflows/terraform.yml`)

**Triggers:**

- Push/PR to `main` (terraform/** paths)
- Manual dispatch (plan/apply/destroy actions)

**Jobs:**

1. `terraform-check`: Format, validate, tflint
2. `terraform-security-scan`: tfsec scanning
3. `terraform-plan`: Generate plan with artifact
4. `terraform-apply`: Auto-apply on main push
5. `terraform-destroy`: Manual destroy with protection

**Duration:** ~3-5 minutes

### 3. Security Scanning (`.github/workflows/security-scanning.yml`)

**Triggers:**

- Daily at 2 AM UTC
- Push to `main` or `develop`
- Manual dispatch

**Jobs:**

1. `dependency-scan`: Trivy filesystem scan (3 services)
2. `secret-scan`: TruffleHog for leaked secrets
3. `container-scan`: Trivy image scan (3 services)
4. `codeql-analysis`: Code analysis (Python, JS, C#)
5. `security-summary`: Aggregate results

**Duration:** ~15-20 minutes

### 4. Docker Compose Tests (`.github/workflows/docker-compose-test.yml`)

**Triggers:**

- Push to `main` or `develop` (docker-compose.yml changes)
- Pull requests to `main`

**Tests:**

- Services start successfully
- Health checks pass
- Vote submission works
- Database persistence verified

**Duration:** ~5-7 minutes

### 5. Monitoring Deployment (`.github/workflows/deploy-monitoring.yml`)

**Triggers:**

- Manual dispatch with environment selection
- Push to `main` (k8s/monitoring/** paths)

**Jobs:**

1. `deploy-prometheus`: kube-prometheus-stack
2. `deploy-grafana`: Configure dashboards
3. `deploy-loki`: Log aggregation
4. `setup-servicemonitors`: Metrics exporters

**Duration:** ~10-15 minutes

## ⚙️ Setup Instructions

### Prerequisites

1. **GitHub Repository Secrets**

   ```bash
   # Required secrets (set in GitHub repo settings)
   KUBECONFIG          # Base64 encoded kubeconfig file
   GRAFANA_PASSWORD    # Grafana admin password (prod)
   ```

2. **GitHub Container Registry**

   ```bash
   # Authenticate to ghcr.io
   echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
   ```

3. **Local Development**

   ```bash
   # Install Act for local workflow testing
   brew install act  # macOS
   # OR
   curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
   ```

### Initial Setup

1. **Enable GitHub Actions**

   ```bash
   # In your repository settings:
   # Settings → Actions → General → Allow all actions
   ```

2. **Configure Dependabot**

   ```bash
   # Already configured in .github/dependabot.yml
   # Automatic PR creation for:
   # - npm (result)
   # - pip (vote)
   # - nuget (worker)
   # - Docker base images
   # - GitHub Actions
   ```

3. **Deploy Monitoring Stack**

   ```bash
   # Via GitHub Actions workflow_dispatch
   # Or manually:
   cd k8s/monitoring
   helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
   helm repo add grafana https://grafana.github.io/helm-charts
   helm repo update
   
   # Deploy Prometheus + Grafana
   helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
     --namespace monitoring --create-namespace \
     --values prometheus-values-dev.yaml --wait
   
   # Deploy Loki
   helm upgrade --install loki grafana/loki-stack \
     --namespace monitoring \
     --values loki-values-dev.yaml --wait
   
   # Apply ServiceMonitors
   kubectl apply -f servicemonitors/
   ```

4. **Verify Setup**

   ```bash
   # Check all pods are running
   kubectl get pods -n monitoring
   
   # Access Grafana
   kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
   # Open http://localhost:3000
   # Username: admin
   # Password: (get from secret)
   kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 -d
   ```

## 🎮 Usage

### Triggering CI/CD Pipeline

**Automatic (Push):**

```bash
git add vote/app.py
git commit -m "feat: add new voting feature"
git push origin main
# Pipeline automatically triggered
```

**Manual Dispatch:**

```bash
# Via GitHub UI:
# Actions → CI/CD Pipeline → Run workflow
# Select environment: dev or prod
```

**Via GitHub CLI:**

```bash
gh workflow run ci-cd.yml -f environment=dev
```

### Running Security Scans

**Scheduled:** Runs automatically daily at 2 AM UTC

**Manual:**

```bash
gh workflow run security-scanning.yml
```

**Local Trivy Scan:**

```bash
# Scan filesystem
trivy fs --severity CRITICAL,HIGH vote/

# Scan image
docker build -t vote:test vote/
trivy image --severity CRITICAL,HIGH vote:test
```

### Deploying Infrastructure Changes

**Terraform Plan:**

```bash
gh workflow run terraform.yml -f action=plan -f environment=dev
```

**Terraform Apply:**

```bash
# Auto-applies on push to main (terraform/** paths)
# Or manually:
gh workflow run terraform.yml -f action=apply -f environment=prod
```

**Terraform Destroy:**

```bash
gh workflow run terraform.yml -f action=destroy -f environment=dev
```

### Accessing Monitoring

**Prometheus:**

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Open http://localhost:9090
```

**Grafana:**

```bash
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Open http://localhost:3000
# Credentials in monitoring namespace secret
```

**Loki (Logs):**

```bash
# Access via Grafana → Explore → Loki datasource
# Or direct:
kubectl port-forward -n monitoring svc/loki 3100:3100
# Query: http://localhost:3100/loki/api/v1/query?query={namespace="voting-app"}
```

**AlertManager:**

```bash
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-alertmanager 9093:9093
# Open http://localhost:9093
```

### Viewing Logs

**Application Logs (Loki):**

```bash
# In Grafana → Explore:
{namespace="voting-app"}
{namespace="voting-app", app="vote"}
{namespace="voting-app"} |= "error"
```

**Pod Logs (kubectl):**

```bash
kubectl logs -n voting-app -l app=vote --tail=100 -f
```

**Worker Logs:**

```bash
kubectl logs -n voting-app -l app=worker --tail=100 -f
```

## 🏆 Best Practices

### CI/CD

1. **Branch Protection**
   - Require PR reviews before merge
   - Require status checks (CI/CD pipeline must pass)
   - Require signed commits

2. **Image Tagging**
   - Use SHA tags for immutable deployments
   - Use branch tags for development
   - Use `latest` only for main branch

3. **Deployment Strategy**
   - Dev: Deploy on every commit
   - Prod: Deploy after manual approval
   - Use rolling updates with health checks

### Security

1. **Vulnerability Management**
   - Review security alerts weekly
   - Update dependencies monthly
   - Patch critical vulnerabilities within 24h

2. **Secret Management**
   - Never commit secrets to repo
   - Use GitHub Secrets for sensitive data
   - Rotate secrets quarterly

3. **Scan Coverage**
   - Pre-commit: TruffleHog
   - PR: Trivy, CodeQL
   - Daily: Full security scan
   - Release: Complete audit

### Monitoring

1. **Alerts**
   - Set up Slack/email notifications in AlertManager
   - Alert on: High error rate, pod crashes, resource exhaustion
   - Define SLOs: 99.9% uptime, <500ms p95 latency

2. **Dashboards**
   - Create team-specific views
   - Include links to runbooks
   - Display SLI/SLO metrics

3. **Log Retention**
   - Dev: 7 days
   - Prod: 30 days
   - Archive critical logs to object storage

### Performance

1. **Resource Limits**
   - Set appropriate requests and limits
   - Monitor actual usage vs limits
   - Adjust based on metrics

2. **Caching**
   - Use GitHub Actions cache for Docker layers
   - Cache Helm charts locally
   - Cache dependency downloads

3. **Parallel Jobs**
   - Build services in parallel
   - Run independent tests concurrently
   - Deploy to multiple environments simultaneously

## 📊 Metrics & KPIs

### Deployment Metrics

- **Deployment Frequency**: How often code is deployed
  - Target: 10+ per day (dev), 5+ per week (prod)
  
- **Lead Time**: Time from commit to production
  - Target: <30 minutes
  
- **Change Failure Rate**: % of deployments causing failure
  - Target: <5%
  
- **MTTR (Mean Time To Recovery)**: Time to restore service
  - Target: <1 hour

### Security Metrics

- **Vulnerability Resolution Time**
  - Critical: <24 hours
  - High: <7 days
  - Medium: <30 days

- **Security Scan Coverage**: % of code scanned
  - Target: 100%

- **False Positive Rate**
  - Target: <10%

## 🔧 Troubleshooting

### Pipeline Failures

**Issue: Image build fails**

```bash
# Check Docker build logs
# Verify Dockerfile syntax
docker build -t vote:test vote/

# Check GitHub Actions runner disk space
# May need to prune cache
```

**Issue: Trivy scan fails**

```bash
# Update Trivy database
trivy image --download-db-only

# Check specific vulnerability
trivy image --severity CRITICAL vote:test
```

**Issue: Deployment fails**

```bash
# Check Helm release status
helm list -n voting-app

# Get deployment logs
kubectl describe deployment vote -n voting-app

# Check pod events
kubectl get events -n voting-app --sort-by='.lastTimestamp'
```

### Monitoring Issues

**Issue: Metrics not appearing**

```bash
# Check ServiceMonitor is applied
kubectl get servicemonitor -n voting-app

# Verify Prometheus targets
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Open http://localhost:9090/targets

# Check exporter pods
kubectl get pods -n voting-app -l app.kubernetes.io/component=metrics
```

**Issue: Logs not showing in Grafana**

```bash
# Check Loki is running
kubectl get pods -n monitoring -l app=loki

# Verify Promtail is collecting
kubectl logs -n monitoring -l app=promtail

# Test Loki query
curl http://localhost:3100/loki/api/v1/query?query={namespace=\"voting-app\"}
```

## 📚 References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Trivy Security Scanner](https://aquasecurity.github.io/trivy/)
- [Prometheus Operator](https://prometheus-operator.dev/)
- [Grafana Loki](https://grafana.com/oss/loki/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)

## 🎉 Phase 3 Complete Checklist

- [x] CI/CD pipeline with build, test, scan, deploy
- [x] Trivy security scanning for containers
- [x] tfsec security scanning for Terraform
- [x] CodeQL for source code analysis
- [x] TruffleHog for secret detection
- [x] Dependabot for dependency updates
- [x] Terraform automation workflow
- [x] Docker Compose testing workflow
- [x] Monitoring stack (Prometheus, Grafana, Loki)
- [x] ServiceMonitors for metrics collection
- [x] Comprehensive documentation
- [x] Security SARIF upload to GitHub
- [x] Smoke tests for deployments
- [x] Multi-environment support (dev/prod)
- [x] GitHub Container Registry integration
