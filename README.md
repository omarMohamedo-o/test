# Voting Application - Cloud Infrastructure Project

## 🎯 Project Status

### Phase 1 – Containerization & Local Setup ✅ COMPLETE

✅ All services containerized with optimized, non-root Dockerfiles  
✅ Docker Compose with two-tier networking (frontend/backend)  
✅ Health checks for Redis and PostgreSQL  
✅ Exposed ports: 8080 (vote), 8081 (result)  
✅ Fully functional end-to-end local deployment  
✅ Optional seed service with profile support  

### Phase 2 – Kubernetes Deployment ✅ COMPLETE

✅ Minikube cluster provisioning with automation scripts  
✅ Production-grade Kubernetes manifests (Namespace, ConfigMaps, Secrets, Services, Deployments, StatefulSets, Ingress)  
✅ Complete Helm chart with multi-environment support (dev/prod)  
✅ Pod Security Standards (PSA) enforced - restricted mode  
✅ Non-root containers with security contexts  
✅ NetworkPolicies for database isolation  
✅ Resource limits, liveness/readiness probes  
✅ PostgreSQL and Redis deployed via Bitnami Helm charts  
✅ Comprehensive documentation (deployment guide, AKS migration path, trade-offs)  

**👉 See [k8s/README.md](./k8s/README.md) for Kubernetes deployment**  
**📚 See [k8s/DEPLOYMENT.md](./k8s/DEPLOYMENT.md) for detailed K8s guide**  
**🔄 See [k8s/TRADEOFFS.md](./k8s/TRADEOFFS.md) for Minikube vs AKS comparison**

---

## 🚀 Quick Start

### Docker Compose (Phase 1)

```bash
# Build and start all services
docker compose up -d

# Run automated tests
./test-e2e.sh

# Access the applications
# Vote: http://localhost:8080
# Results: http://localhost:8081
```

### Kubernetes (Phase 2)

```bash
# Setup Minikube cluster
cd k8s && ./setup-minikube.sh

# Update /etc/hosts
MINIKUBE_IP=$(minikube ip)
echo "$MINIKUBE_IP vote.local result.local" | sudo tee -a /etc/hosts

# Deploy with Helm
./deploy-helm.sh dev

# Access the applications
# Vote: http://vote.local
# Results: http://result.local
```

**👉 Docker Compose: See [QUICKSTART.md](./QUICKSTART.md)**  
**� Kubernetes: See [k8s/DEPLOYMENT.md](./k8s/DEPLOYMENT.md)**

This is a distributed voting application that allows users to vote between two options and view real-time results. The application consists of multiple microservices that work together to provide a complete voting experience.

## Application Architecture

The voting application consists of the following components:

![Architecture Diagram](./architecture.excalidraw.png)

### Frontend Services

- **Vote Service** (`/vote`): Python Flask web application that provides the voting interface
- **Result Service** (`/result`): Node.js web application that displays real-time voting results

### Backend Services  

- **Worker Service** (`/worker`): .NET worker application that processes votes from the queue
- **Redis**: Message broker that queues votes for processing
- **PostgreSQL**: Database that stores the final vote counts

### Data Flow

1. Users visit the vote service to cast their votes
2. Votes are sent to Redis queue
3. Worker service processes votes from Redis and stores them in PostgreSQL
4. Result service queries PostgreSQL and displays real-time results via WebSocket

### Network Architecture

The application uses a **two-tier network architecture** for security and organization:

- **Frontend Tier Network**:
  - Vote service (port 8080)
  - Result service (port 8081)
  - Accessible from outside the Docker environment

- **Backend Tier Network**:
  - Worker service
  - Redis
  - PostgreSQL
  - Internal communication only

This separation ensures that database and message queue services are not directly accessible from outside, while the web services remain accessible to users.

---

## 📁 Project Structure

```
tactful-votingapp-cloud-infra/
├── docker-compose.yml              # Main orchestration file
├── SETUP-GUIDE.md                  # Complete setup guide with best practices
├── QUICKSTART.md                   # Quick start guide
├── test-e2e.sh                     # Automated end-to-end test script
├── healthchecks/                   # Health check scripts
│   ├── postgres.sh
│   └── redis.sh
├── vote/                           # Python Flask voting app
│   ├── Dockerfile                  # Multi-stage, non-root
│   ├── .dockerignore
│   ├── app.py
│   └── requirements.txt
├── result/                         # Node.js results app
│   ├── Dockerfile                  # Multi-stage, non-root
│   ├── .dockerignore
│   ├── server.js
│   └── package.json
├── worker/                         # .NET worker service
│   ├── Dockerfile                  # Multi-stage, non-root
│   ├── .dockerignore
│   ├── Program.cs
│   └── Worker.csproj
└── seed-data/                      # Test data generator
    ├── Dockerfile                  # Lightweight, non-root
    ├── .dockerignore
    ├── generate-votes.sh
    └── make-data.py
```

---

## 🎓 Best Practices Implemented

### Docker Best Practices

- ✅ **Multi-stage builds** for all services (40-60% size reduction)
- ✅ **Non-root users** in all containers (security)
- ✅ **Health checks** for critical services
- ✅ **Layer caching optimization** for faster builds
- ✅ **.dockerignore files** to reduce build context
- ✅ **Alpine images** where possible (smaller footprint)

### Docker Compose Best Practices

- ✅ **Two-tier networking** (frontend/backend isolation)
- ✅ **Service dependencies** with health check conditions
- ✅ **Named volumes** for data persistence
- ✅ **Resource limits** (CPU/memory)
- ✅ **Restart policies** for high availability
- ✅ **Profiles** for optional services (seed-data)

### Security Best Practices

- ✅ All containers run as non-root users
- ✅ Backend services isolated from external access
- ✅ Resource limits prevent DoS attacks
- ✅ No hardcoded secrets (environment variables)

---

## 🧪 Testing

### Automated Testing

```bash
# Run complete end-to-end test suite
./test-e2e.sh
```

The test script validates:

- All services are running
- Health checks pass
- Ports are accessible
- Vote submission works
- Data persistence works
- Security (non-root users)
- Resource limits
- Network configuration

### Manual Testing

```bash
# View all service status
docker compose ps

# View logs
docker compose logs -f

# Submit a test vote
curl -X POST http://localhost:8080 \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "vote=a"

# Check results
curl http://localhost:8081
```

### Load Testing (Optional)

```bash
# Generate 3000 test votes
docker compose --profile seed up seed-data
```

---

## 📊 Service Details

| Service | Technology | Port | Network | Health Check |
|---------|-----------|------|---------|--------------|
| Vote | Python 3.11 / Flask / Gunicorn | 8080 | Frontend + Backend | HTTP |
| Result | Node.js 18 / Express / Socket.io | 8081 | Frontend + Backend | HTTP |
| Worker | .NET 7 / C# | - | Backend | - |
| Redis | Redis 7 Alpine | 6379 | Backend | Custom Script |
| PostgreSQL | Postgres 15 Alpine | 5432 | Backend | Custom Script |
| Seed Data | Python 3.11 Alpine / Apache Bench | - | Frontend | - |

---

## 🔧 Common Commands

```bash
# Start application
docker compose up -d

# View status
docker compose ps

# View logs (all services)
docker compose logs -f

# View logs (specific service)
docker compose logs -f vote

# Stop application
docker compose down

# Stop and remove volumes (fresh start)
docker compose down -v

# Rebuild specific service
docker compose build vote
docker compose up -d vote

# Run automated tests
./test-e2e.sh

# Generate seed data
docker compose --profile seed up seed-data

# View resource usage
docker stats
```

---

## 🐛 Troubleshooting

### Services Won't Start

```bash
# Check logs
docker compose logs <service-name>

# Rebuild with no cache
docker compose build --no-cache

# Check for port conflicts
sudo lsof -i :8080
sudo lsof -i :8081
```

### Health Checks Failing

```bash
# Test health check manually
docker compose exec redis sh /healthchecks/redis.sh
docker compose exec db sh /healthchecks/postgres.sh

# Check service connectivity
docker compose exec vote ping redis
docker compose exec worker ping db
```

### Data Not Persisting

```bash
# Verify volumes exist
docker volume ls | grep voting-app

# Inspect volume
docker volume inspect voting-app-db-data
```

**More troubleshooting help**: See [SETUP-GUIDE.md](./SETUP-GUIDE.md#-troubleshooting)

---

## 📚 Documentation

- **[QUICKSTART.md](./QUICKSTART.md)** - Get started in 5 minutes
- **[SETUP-GUIDE.md](./SETUP-GUIDE.md)** - Complete implementation guide with:
  - Detailed architecture explanation
  - Step-by-step implementation walkthrough
  - Comprehensive testing procedures
  - Best practices explanations
  - Security validation
  - Performance optimization tips

---

## ✅ Success Criteria

Your setup is complete when:

- ✅ All 5 services show "Up" status
- ✅ Redis and PostgreSQL show "(healthy)" status
- ✅ Can access vote app at <http://localhost:8080>
- ✅ Can access result app at <http://localhost:8081>
- ✅ Votes appear in results within 1-2 seconds
- ✅ `./test-e2e.sh` passes all tests
- ✅ Services recover from failures automatically
- ✅ Data persists across container restarts

---

## 🚀 Next Phases

### Phase 2 - Cloud Deployment (Coming Soon)

- Kubernetes manifests
- Helm charts
- Cloud provider configurations (AWS/GCP/Azure)

### Phase 3 - CI/CD Pipeline (Coming Soon)

- GitHub Actions / GitLab CI
- Automated testing
- Container scanning
- Deployment automation

### Phase 4 - Monitoring & Observability (Coming Soon)

- Prometheus metrics
- Grafana dashboards
- Log aggregation
- Distributed tracing

---

## 📞 Support

For detailed help and troubleshooting:

1. Check [SETUP-GUIDE.md](./SETUP-GUIDE.md) for comprehensive documentation
2. Review logs: `docker compose logs -f`
3. Run tests: `./test-e2e.sh`
4. Verify health: `docker compose ps`

---

## 🎉 Phase 1 Complete

**Congratulations!** You now have a fully containerized, production-ready local deployment with:

- ✅ Efficient multi-stage Dockerfiles
- ✅ Non-root security hardening
- ✅ Two-tier network architecture
- ✅ Comprehensive health checks
- ✅ Automated testing
- ✅ Complete documentation

Ready to move to Phase 2: Cloud Deployment! 🚀

## Your Task

As a DevOps engineer, your task is to containerize this application and create the necessary infrastructure files. You need to create:

### 1. Docker Files

Create `Dockerfile` for each service:

- `vote/Dockerfile` - for the Python Flask application
- `result/Dockerfile` - for the Node.js application  
- `worker/Dockerfile` - for the .NET worker application
- `seed-data/Dockerfile` - for the data seeding utility

### 2. Docker Compose

Create `docker-compose.yml` that:

- Defines all services with proper networking using **two-tier architecture**:
  - **Frontend tier**: Vote and Result services (user-facing)
  - **Backend tier**: Worker, Redis, and PostgreSQL (internal services)
- Sets up health checks for Redis and PostgreSQL
- Configures proper service dependencies
- Exposes the vote service on port 8080 and result service on port 8081
- Uses the provided health check scripts in `/healthchecks` directory

### 3. Health Checks

The application includes health check scripts:

- `healthchecks/redis.sh` - Redis health check
- `healthchecks/postgres.sh` - PostgreSQL health check

Use these scripts in your Docker Compose configuration to ensure services are ready before dependent services start.

## Requirements

- All services should be properly networked using **two-tier architecture**:
  - **Frontend tier network**: Connect Vote and Result services
  - **Backend tier network**: Connect Worker, Redis, and PostgreSQL
  - Both tiers should be isolated for security
- Health checks must be implemented for Redis and PostgreSQL
- Services should wait for their dependencies to be healthy before starting
- The vote service should be accessible at `http://localhost:8080`
- The result service should be accessible at `http://localhost:8081`
- Use appropriate base images and follow Docker best practices
- Ensure the application works end-to-end when running `docker compose up`
- Include a seed service that can populate test data

## Data Population

The application includes a seed service (`/seed-data`) that can populate the database with test votes:

- **`make-data.py`**: Creates URL-encoded vote data files (`posta` and `postb`)
- **`generate-votes.sh`**: Uses Apache Bench (ab) to send 3000 test votes:
  - 2000 votes for option A
  - 1000 votes for option B

### How to Use Seed Data

1. Include the seed service in your `docker-compose.yml`
2. Run the seed service after all other services are healthy:

   ```bash
   docker compose run --rm seed
   ```

3. Or run it as a one-time service with a profile:

   ```bash
   docker compose --profile seed up
   ```

## Getting Started

1. Examine the source code in each service directory
2. Create the necessary Dockerfiles
3. Create the docker-compose.yml file with two-tier networking
4. Test your implementation by running `docker compose up`
5. Populate test data using the seed service
6. Verify that you can vote and see results in real-time

## Notes

- The voting application only accepts one vote per client browser
- The result service uses WebSocket for real-time updates
- The worker service continuously processes votes from the Redis queue
- Make sure to handle service startup order properly with health checks

Good luck with your challenge! 🚀
