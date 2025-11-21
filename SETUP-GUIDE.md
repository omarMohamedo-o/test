# Phase 1 – Containerization & Local Setup

## Complete Step-by-Step Guide with Testing

---

## 📋 Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Architecture](#architecture)
4. [Step-by-Step Implementation](#step-by-step-implementation)
5. [Testing Guide](#testing-guide)
6. [Troubleshooting](#troubleshooting)
7. [Best Practices Applied](#best-practices-applied)

---

## 🎯 Overview

This guide walks you through containerizing a microservices-based voting application with:

- **Vote Service** (Python/Flask) - Frontend for casting votes
- **Result Service** (Node.js/Express) - Frontend for viewing results
- **Worker Service** (.NET) - Backend processor
- **Redis** - In-memory data store
- **PostgreSQL** - Persistent database
- **Seed Data Service** (Optional) - Test data generator

---

## ✅ Prerequisites

### Required Software

```bash
# Check Docker version (20.10+)
docker --version

# Check Docker Compose version (2.0+)
docker compose version

# Verify Docker is running
docker ps
```

### System Resources

- **CPU**: 2+ cores
- **RAM**: 4GB+ available
- **Disk**: 5GB+ free space

---

## 🏗️ Architecture

### Network Topology (Two-Tier)

```
┌─────────────────────────────────────────────────────────┐
│                    FRONTEND NETWORK                      │
│  ┌──────────┐                           ┌──────────┐   │
│  │   Vote   │                           │  Result  │   │
│  │  :8080   │                           │  :8081   │   │
│  └────┬─────┘                           └─────┬────┘   │
│       │                                       │         │
└───────┼───────────────────────────────────────┼─────────┘
        │                                       │
┌───────┼───────────────────────────────────────┼─────────┐
│       │          BACKEND NETWORK              │         │
│  ┌────┴─────┐    ┌──────────┐    ┌───────────┴────┐   │
│  │  Redis   ├────┤  Worker  ├────┤   PostgreSQL   │   │
│  │  :6379   │    │          │    │     :5432      │   │
│  └──────────┘    └──────────┘    └────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### Service Communication

- **Vote** → Redis (stores votes)
- **Worker** → Redis + PostgreSQL (processes votes)
- **Result** → PostgreSQL (displays results)

---

## 🚀 Step-by-Step Implementation

### Step 1: Understand the Project Structure

```bash
tactful-votingapp-cloud-infra/
├── docker-compose.yml          # Orchestration configuration
├── vote/                       # Python voting app
│   ├── Dockerfile
│   ├── app.py
│   ├── requirements.txt
│   └── .dockerignore
├── result/                     # Node.js results app
│   ├── Dockerfile
│   ├── server.js
│   ├── package.json
│   └── .dockerignore
├── worker/                     # .NET worker service
│   ├── Dockerfile
│   ├── Program.cs
│   ├── Worker.csproj
│   └── .dockerignore
├── seed-data/                  # Optional seed service
│   ├── Dockerfile
│   ├── generate-votes.sh
│   └── .dockerignore
└── healthchecks/               # Health check scripts
    ├── redis.sh
    └── postgres.sh
```

### Step 2: Review Dockerfiles (Best Practices)

#### 🐍 Vote Service Dockerfile (Python)

**Location**: `vote/Dockerfile`

**Best Practices Applied:**

- ✅ Multi-stage build (reduces image size by ~40%)
- ✅ Non-root user (`appuser`)
- ✅ Virtual environment for dependency isolation
- ✅ Health check for container monitoring
- ✅ Production-ready with Gunicorn (4 workers)
- ✅ Layer caching optimization

**Key Features:**

```dockerfile
# Stage 1: Build dependencies
FROM python:3.11-slim AS builder
# Install dependencies in virtual environment

# Stage 2: Runtime
FROM python:3.11-slim
# Copy only what's needed, run as non-root
```

#### 📦 Result Service Dockerfile (Node.js)

**Location**: `result/Dockerfile`

**Best Practices Applied:**

- ✅ Multi-stage build
- ✅ Non-root user
- ✅ `npm ci` for reproducible builds
- ✅ Tini for proper signal handling
- ✅ Health check
- ✅ Alpine base for smaller size

#### ⚙️ Worker Service Dockerfile (.NET)

**Location**: `worker/Dockerfile`

**Best Practices Applied:**

- ✅ Multi-stage build (SDK for build, runtime for execution)
- ✅ Non-root user
- ✅ Optimized layer caching (restore → build → publish)
- ✅ Alpine runtime (smaller footprint)

#### 🌱 Seed Data Service Dockerfile

**Location**: `seed-data/Dockerfile`

**Best Practices Applied:**

- ✅ Lightweight Alpine base
- ✅ Non-root user
- ✅ Single-purpose container

### Step 3: Review Docker Compose Configuration

**Location**: `docker-compose.yml`

**Key Configurations:**

#### Networks (Two-Tier)

```yaml
networks:
  frontend:     # Public-facing services
    - vote
    - result
    - seed-data (optional)
  
  backend:      # Internal services
    - worker
    - redis
    - db
    - vote (bridge to backend)
    - result (bridge to backend)
```

#### Health Checks

```yaml
redis:
  healthcheck:
    test: ["CMD", "sh", "/healthchecks/redis.sh"]
    interval: 10s
    timeout: 5s
    retries: 5
    start_period: 10s

db:
  healthcheck:
    test: ["CMD", "sh", "/healthchecks/postgres.sh"]
    interval: 10s
    timeout: 5s
    retries: 5
    start_period: 10s
```

#### Service Dependencies

```yaml
vote:
  depends_on:
    redis:
      condition: service_healthy

worker:
  depends_on:
    redis:
      condition: service_healthy
    db:
      condition: service_healthy
```

#### Resource Limits

```yaml
deploy:
  resources:
    limits:
      cpus: '0.5'
      memory: 256M
```

### Step 4: Build All Services

```bash
# Navigate to project root
cd /home/omar/Projects/tactful-votingapp-cloud-infra

# Build all services (without starting)
docker compose build

# Build with no cache (clean build)
docker compose build --no-cache

# Build specific service
docker compose build vote
```

**Expected Output:**

```
[+] Building 45.2s (47/47) FINISHED
 => [vote internal] load build definition
 => [result internal] load build definition
 => [worker internal] load build definition
 ...
```

### Step 5: Start the Application

```bash
# Start all services (detached mode)
docker compose up -d

# Start with logs visible
docker compose up

# Start specific services
docker compose up -d vote redis db
```

**Expected Output:**

```
[+] Running 5/5
 ✔ Container redis    Started
 ✔ Container db       Started
 ✔ Container vote     Started
 ✔ Container worker   Started
 ✔ Container result   Started
```

### Step 6: Verify Service Health

```bash
# Check container status
docker compose ps

# Expected output:
# NAME      IMAGE              STATUS                    PORTS
# db        postgres:15-alpine Up (healthy)              5432/tcp
# redis     redis:7-alpine     Up (healthy)              6379/tcp
# vote      vote               Up (healthy)              0.0.0.0:8080->80/tcp
# result    result             Up (healthy)              0.0.0.0:8081->4000/tcp
# worker    worker             Up                        

# Check logs for all services
docker compose logs

# Check logs for specific service
docker compose logs vote
docker compose logs -f worker  # Follow mode
```

---

## 🧪 Testing Guide

### Test 1: Verify Network Connectivity

```bash
# List networks
docker network ls | grep voting-app

# Expected output:
# voting-app-frontend
# voting-app-backend

# Inspect frontend network
docker network inspect voting-app-frontend

# Inspect backend network
docker network inspect voting-app-backend
```

### Test 2: Access Vote Application

```bash
# Test from command line
curl http://localhost:8080

# Expected: HTML response with voting form

# Open in browser
xdg-open http://localhost:8080
# Or manually open: http://localhost:8080
```

**Visual Test:**

- ✅ Should see voting interface with two options (Cats vs Dogs)
- ✅ Click on either option and submit
- ✅ Should receive confirmation

### Test 3: Access Result Application

```bash
# Test from command line
curl http://localhost:8081

# Open in browser
xdg-open http://localhost:8081
# Or manually open: http://localhost:8081
```

**Visual Test:**

- ✅ Should see real-time results dashboard
- ✅ Results update automatically (WebSocket connection)
- ✅ Vote count should reflect your submissions

### Test 4: Verify Data Flow

```bash
# 1. Submit a vote via API
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "vote=a"

# 2. Check Redis queue
docker compose exec redis redis-cli LLEN votes
# Expected: Number of pending votes

docker compose exec redis redis-cli LRANGE votes 0 -1
# Expected: JSON vote data

# 3. Check Worker logs (processing votes)
docker compose logs worker | tail -20
# Expected: "Processing vote for 'a' by '...'"

# 4. Check PostgreSQL data
docker compose exec db psql -U postgres -d postgres -c "SELECT * FROM votes;"
# Expected: Vote records in database

# 5. Verify Result updates
curl http://localhost:8081
# Expected: Updated vote counts
```

### Test 5: Health Checks

```bash
# Check Redis health
docker compose exec redis sh /healthchecks/redis.sh
echo $?  # Should return 0 (success)

# Check PostgreSQL health
docker compose exec db sh /healthchecks/postgres.sh
echo $?  # Should return 0 (success)

# Check Vote service health
curl -f http://localhost:8080/ && echo "✅ Vote is healthy"

# Check Result service health
curl -f http://localhost:8081/ && echo "✅ Result is healthy"
```

### Test 6: Resource Usage

```bash
# Monitor resource usage
docker stats

# Expected output:
# CONTAINER  CPU %  MEM USAGE / LIMIT    MEM %   NET I/O
# vote       2%     45MiB / 256MiB       17%     ...
# result     1%     50MiB / 256MiB       19%     ...
# worker     5%     35MiB / 256MiB       13%     ...
# redis      0.5%   10MiB / 128MiB       7%      ...
# db         1%     25MiB / 256MiB       9%      ...
```

### Test 7: Service Restart & Resilience

```bash
# Test Vote service restart
docker compose restart vote
docker compose ps vote  # Should be Up (healthy)

# Test Redis failure recovery
docker compose stop redis
docker compose logs worker  # Should show "Waiting for redis"
docker compose start redis
docker compose logs worker  # Should show "Connected to redis"

# Test database persistence
docker compose stop db
docker compose start db
# Data should persist (check via result app)
```

### Test 8: Seed Data (Optional)

```bash
# Run seed data profile
docker compose --profile seed up seed-data

# This generates 3000 votes:
# - 2000 for option 'a'
# - 1000 for option 'b'

# Check results
curl http://localhost:8081
# Should show ~2:1 ratio

# View seed logs
docker compose logs seed-data
```

### Test 9: End-to-End Integration Test

```bash
# Complete workflow test script
#!/bin/bash

echo "🧪 Starting E2E Test..."

# 1. Submit multiple votes
for i in {1..10}; do
  curl -s -X POST http://localhost:8080 \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "vote=a" > /dev/null
  echo "Vote $i submitted (option a)"
done

for i in {1..5}; do
  curl -s -X POST http://localhost:8080 \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "vote=b" > /dev/null
  echo "Vote $i submitted (option b)"
done

# 2. Wait for processing
echo "⏳ Waiting 5 seconds for processing..."
sleep 5

# 3. Verify results
echo "📊 Checking results..."
curl -s http://localhost:8081 | grep -q "Cats" && echo "✅ Results page accessible"

# 4. Check database
VOTE_COUNT=$(docker compose exec -T db psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM votes;" | xargs)
echo "📈 Total votes in database: $VOTE_COUNT"

if [ "$VOTE_COUNT" -ge 15 ]; then
  echo "✅ E2E Test PASSED"
else
  echo "❌ E2E Test FAILED"
fi
```

Save as `test-e2e.sh` and run:

```bash
chmod +x test-e2e.sh
./test-e2e.sh
```

### Test 10: Security Validation

```bash
# 1. Verify non-root user in containers
docker compose exec vote whoami
# Expected: appuser (not root)

docker compose exec result whoami
# Expected: appuser (not root)

docker compose exec worker whoami
# Expected: appuser (not root)

# 2. Check no privileged containers
docker compose ps --format json | jq '.[].Config.Privileged'
# Expected: false for all

# 3. Verify resource limits are applied
docker inspect vote | jq '.[].HostConfig.Memory'
# Expected: 268435456 (256MB in bytes)
```

---

## 🐛 Troubleshooting

### Issue 1: Service Won't Start

**Symptoms:**

```bash
docker compose ps
# Shows service with status: Exit 1 or Restarting
```

**Solution:**

```bash
# Check logs
docker compose logs <service-name>

# Common causes:
# - Port already in use
sudo lsof -i :8080
sudo lsof -i :8081

# - Missing dependencies
docker compose build --no-cache <service-name>

# - Health check failing
docker compose exec <service-name> sh
# Debug inside container
```

### Issue 2: Vote Not Appearing in Results

**Check the data pipeline:**

```bash
# 1. Verify vote reached Redis
docker compose exec redis redis-cli LLEN votes
# Should show pending votes

# 2. Check Worker is processing
docker compose logs worker --tail 50
# Should show "Processing vote..." messages

# 3. Verify database connection
docker compose exec db psql -U postgres -d postgres -c "\dt"
# Should show 'votes' table exists

# 4. Check Result service connection
docker compose logs result --tail 50
# Should show "Connected to db"
```

### Issue 3: Health Check Failing

```bash
# Debug health check scripts
docker compose exec redis sh -x /healthchecks/redis.sh
docker compose exec db sh -x /healthchecks/postgres.sh

# Check if service is actually ready
docker compose exec redis redis-cli ping
docker compose exec db pg_isready -U postgres
```

### Issue 4: Network Connectivity Issues

```bash
# Verify networks exist
docker network ls | grep voting-app

# Check service network membership
docker inspect vote | jq '.[].NetworkSettings.Networks'

# Test connectivity between services
docker compose exec vote ping redis
docker compose exec worker ping db
```

### Issue 5: High Resource Usage

```bash
# Check current usage
docker stats --no-stream

# If limits are being hit:
# 1. Adjust limits in docker-compose.yml
# 2. Scale down workers if needed
# 3. Check for memory leaks in logs

docker compose logs worker | grep -i "memory\|leak\|oom"
```

---

## 📚 Best Practices Applied

### 🐳 Dockerfile Best Practices

1. **Multi-Stage Builds**
   - Separates build and runtime environments
   - Reduces final image size by 40-60%
   - Example: Vote service ~150MB vs ~400MB

2. **Non-Root Users**
   - All services run as `appuser` (not root)
   - Improves security posture
   - Prevents privilege escalation

3. **Layer Caching**
   - Dependencies copied before source code
   - Speeds up rebuilds significantly
   - Example: Only source changes = 5s rebuild

4. **Health Checks**
   - Enables automatic container recovery
   - Provides service readiness status
   - Used by `depends_on` conditions

5. **.dockerignore Files**
   - Excludes unnecessary files from build context
   - Speeds up builds and reduces image size
   - Prevents secrets from being embedded

### 🎼 Docker Compose Best Practices

1. **Two-Tier Networking**
   - Frontend: Public-facing services
   - Backend: Internal services only
   - Minimizes attack surface

2. **Service Dependencies**
   - Uses health check conditions
   - Ensures proper startup order
   - Prevents connection failures

3. **Health Checks**
   - Redis & PostgreSQL have custom scripts
   - Vote & Result have HTTP checks
   - Start period allows initialization time

4. **Resource Limits**
   - CPU and memory constraints
   - Prevents resource exhaustion
   - Enables better resource planning

5. **Named Volumes**
   - Persistent data for Redis & PostgreSQL
   - Survives container restarts
   - Easy to backup/restore

6. **Restart Policies**
   - `unless-stopped` for services
   - `no` for seed-data (one-time job)
   - Ensures high availability

7. **Profiles**
   - Seed data is optional (`--profile seed`)
   - Keeps default startup clean
   - Enables different environments

### 🔒 Security Best Practices

1. **Non-Root Containers**
   - All services run as non-privileged users
   - Reduces container escape risks

2. **Network Isolation**
   - Backend services not exposed to host
   - Only necessary services bridge networks

3. **Resource Limits**
   - Prevents DoS via resource exhaustion
   - Ensures fair resource allocation

4. **Health Monitoring**
   - Early detection of service failures
   - Automatic recovery mechanisms

5. **No Hardcoded Secrets**
   - Database credentials via environment variables
   - Can be replaced with secrets management

### ⚡ Performance Best Practices

1. **Alpine Images**
   - Smaller image sizes (5-10x smaller)
   - Faster pulls and startup times
   - Reduced attack surface

2. **Production Servers**
   - Gunicorn for Python (4 workers)
   - Tini for Node.js (signal handling)
   - Optimized for concurrency

3. **Connection Pooling**
   - PostgreSQL connection pooling in Result
   - Redis connection reuse in Worker
   - Reduces connection overhead

4. **Caching Strategy**
   - Docker layer caching
   - npm/pip dependency caching
   - Speeds up iterations

---

## 🎯 Success Criteria

Your setup is complete when:

- ✅ All 5 services start successfully
- ✅ Health checks pass for Redis and PostgreSQL
- ✅ Vote app accessible at <http://localhost:8080>
- ✅ Result app accessible at <http://localhost:8081>
- ✅ Votes submitted via Vote appear in Result within 1-2 seconds
- ✅ Services recover automatically from failures
- ✅ Resource usage stays within defined limits
- ✅ All containers run as non-root users
- ✅ Networks properly isolate frontend/backend
- ✅ Data persists across container restarts

---

## 📝 Quick Reference Commands

### Essential Commands

```bash
# Start application
docker compose up -d

# View status
docker compose ps

# View logs
docker compose logs -f

# Stop application
docker compose down

# Stop and remove volumes (fresh start)
docker compose down -v

# Rebuild specific service
docker compose build vote
docker compose up -d vote

# Scale services (if needed later)
docker compose up -d --scale worker=3

# Execute command in container
docker compose exec vote sh

# View resource usage
docker stats
```

### Maintenance Commands

```bash
# Update images
docker compose pull

# Remove unused resources
docker system prune -a

# Backup database
docker compose exec db pg_dump -U postgres postgres > backup.sql

# Restore database
docker compose exec -T db psql -U postgres postgres < backup.sql

# Export logs
docker compose logs > app-logs.txt
```

---

## 🎓 Next Steps

After completing Phase 1, you should:

1. **Document Your Environment**
   - Note any custom configurations
   - Document port changes
   - Record resource limits

2. **Set Up Monitoring** (Phase 2 prep)
   - Consider adding Prometheus
   - Set up log aggregation
   - Monitor health check patterns

3. **Prepare for Cloud** (Future phases)
   - Document service dependencies
   - Plan for multi-region deployment
   - Consider secrets management

4. **Performance Testing**
   - Run load tests with seed-data
   - Monitor resource usage under load
   - Identify bottlenecks

---

## 📞 Support & Resources

- **Docker Documentation**: <https://docs.docker.com>
- **Docker Compose Reference**: <https://docs.docker.com/compose/compose-file/>
- **Health Check Reference**: <https://docs.docker.com/engine/reference/builder/#healthcheck>

---

## ✅ Completion Checklist

- [ ] All Dockerfiles created with multi-stage builds
- [ ] All services run as non-root users
- [ ] Docker Compose file with two-tier networking
- [ ] Health checks configured for Redis and PostgreSQL
- [ ] Ports exposed: 8080 (vote), 8081 (result)
- [ ] `docker compose up` brings up full stack
- [ ] All services show "healthy" status
- [ ] Can submit votes and see results
- [ ] Services recover from failures
- [ ] Resource limits enforced
- [ ] Seed data profile works (optional)
- [ ] All tests pass

**Congratulations! Phase 1 Complete! 🎉**
