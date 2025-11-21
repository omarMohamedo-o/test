# Voting App - Quick Start Guide

## 🚀 Quick Start (5 Minutes)

### Step 1: Build and Start

```bash
# Navigate to project directory
cd /home/omar/Projects/tactful-votingapp-cloud-infra

# Build and start all services
docker compose up -d
```

### Step 2: Verify Services

```bash
# Check status (all should show "Up" and healthy)
docker compose ps
```

Expected output:

```
NAME      IMAGE              STATUS                    PORTS
db        postgres:15-alpine Up (healthy)              5432/tcp
redis     redis:7-alpine     Up (healthy)              6379/tcp
vote      vote               Up (healthy)              0.0.0.0:8080->80/tcp
result    result             Up (healthy)              0.0.0.0:8081->4000/tcp
worker    worker             Up
```

### Step 3: Test the Application

```bash
# Run automated tests
./test-e2e.sh
```

### Step 4: Access the Applications

**Vote Application**: <http://localhost:8080>

- Cast your vote (Cats vs Dogs)

**Result Application**: <http://localhost:8081>

- View live results

## 📝 Common Commands

```bash
# View logs
docker compose logs -f

# Stop all services
docker compose down

# Stop and remove all data (fresh start)
docker compose down -v

# Restart a specific service
docker compose restart vote

# View resource usage
docker stats
```

## 🌱 Seed Test Data (Optional)

```bash
# Generate 3000 test votes
docker compose --profile seed up seed-data

# Watch results update
# Open: http://localhost:8081
```

## 🐛 Troubleshooting

**Port already in use?**

```bash
# Check what's using the port
sudo lsof -i :8080
sudo lsof -i :8081

# Kill the process or change ports in docker-compose.yml
```

**Services not healthy?**

```bash
# Check specific service logs
docker compose logs vote
docker compose logs redis
docker compose logs db

# Rebuild a service
docker compose build --no-cache vote
docker compose up -d vote
```

**Need clean restart?**

```bash
# Remove everything and start fresh
docker compose down -v
docker compose build --no-cache
docker compose up -d
```

## 📚 Full Documentation

See [SETUP-GUIDE.md](./SETUP-GUIDE.md) for complete documentation including:

- Architecture details
- Best practices explanations
- Comprehensive testing guide
- Security validation
- Performance optimization

## ✅ Success Checklist

- [ ] `docker compose ps` shows all services as "Up"
- [ ] Redis and DB show "(healthy)" status
- [ ] Can access <http://localhost:8080>
- [ ] Can access <http://localhost:8081>
- [ ] Can submit votes and see results
- [ ] `./test-e2e.sh` passes all tests

**Need help?** Check the full guide: [SETUP-GUIDE.md](./SETUP-GUIDE.md)
