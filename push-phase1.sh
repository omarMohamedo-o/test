#!/bin/bash
# Push Script - Phase 1: Docker Compose

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                    ║${NC}"
echo -e "${BLUE}║     📦 Push Phase 1: Docker Compose               ║${NC}"
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
echo -e "${YELLOW}📋 Phase 1 will include:${NC}"
echo "  • docker-compose.yml"
echo "  • All Dockerfiles (vote, result, worker, seed-data)"
echo "  • Health check scripts"
echo "  • Service source code"
echo "  • Test scripts"
echo ""

read -p "Continue with Phase 1 push? (y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}❌ Push cancelled${NC}"
    exit 1
fi

echo ""
echo -e "${YELLOW}📦 Step 1: Adding Docker Compose configuration...${NC}"
git add docker-compose.yml
echo -e "${GREEN}✅ docker-compose.yml added${NC}"

echo ""
echo -e "${YELLOW}📦 Step 2: Adding Dockerfiles...${NC}"
git add vote/Dockerfile vote/.dockerignore
git add result/Dockerfile result/.dockerignore
git add worker/Dockerfile worker/.dockerignore
git add seed-data/Dockerfile seed-data/.dockerignore
echo -e "${GREEN}✅ All Dockerfiles added${NC}"

echo ""
echo -e "${YELLOW}📦 Step 3: Adding health check scripts...${NC}"
git add healthchecks/
echo -e "${GREEN}✅ Health check scripts added${NC}"

echo ""
echo -e "${YELLOW}📦 Step 4: Adding service source files...${NC}"
git add vote/app.py vote/requirements.txt vote/static/ vote/templates/
git add result/server.js result/package.json result/views/ result/tests/
git add worker/Program.cs worker/Worker.csproj
git add seed-data/generate-votes.sh seed-data/make-data.py
echo -e "${GREEN}✅ Service source files added${NC}"

echo ""
echo -e "${YELLOW}📦 Step 5: Adding test scripts...${NC}"
git add test-e2e.sh
git add test-phase1.sh 2>/dev/null || true
chmod +x test-e2e.sh test-phase1.sh 2>/dev/null || true
echo -e "${GREEN}✅ Test scripts added${NC}"

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
echo -e "${YELLOW}💾 Committing Phase 1...${NC}"
git commit -m "feat: Phase 1 - Docker Compose implementation

✨ Features:
- Multi-stage Dockerfiles for all services (vote, result, worker, seed-data)
- Docker Compose with two-tier networking (frontend/backend)
- Health checks for Redis and PostgreSQL
- Non-root containers for security
- Resource limits and restart policies
- Automated end-to-end testing script

🐳 Services:
- Vote: Python/Flask on port 8080
- Result: Node.js/Express on port 8081
- Worker: .NET Core background processor
- Redis: Message queue with health checks
- PostgreSQL: Database with persistence
- Seed-data: Load testing utility (optional profile)

✅ All services containerized and tested
✅ End-to-end workflow functional
✅ Ready for local development"

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
echo -e "${BLUE}║     🎉 Phase 1 Successfully Pushed!               ║${NC}"
echo -e "${BLUE}║                                                    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${GREEN}📦 Phase 1 (Docker Compose) is now on GitHub!${NC}"
echo ""
echo -e "${YELLOW}🌐 View your repository:${NC}"
echo -e "   ${BLUE}https://github.com/omarMohamedo-o/tactful-votingapp-cloud-infra${NC}"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "  1. Verify files on GitHub"
echo "  2. Run: ./push-phase2.sh"
echo ""
