#!/bin/bash
# End-to-End Test Script for Voting Application
# Usage: ./test-e2e.sh

set -e

echo "🧪 Starting End-to-End Test..."
echo "================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counter
PASSED=0
FAILED=0

# Helper function
test_step() {
    echo -e "\n${YELLOW}▶ $1${NC}"
}

pass() {
    echo -e "${GREEN}✅ $1${NC}"
    PASSED=$((PASSED + 1))
}

fail() {
    echo -e "${RED}❌ $1${NC}"
    FAILED=$((FAILED + 1))
}

# Test 1: Check if services are running
test_step "Test 1: Checking if all services are running..."
if docker compose ps | grep -q "vote.*Up"; then
    pass "Vote service is running"
else
    fail "Vote service is not running"
fi

if docker compose ps | grep -q "result.*Up"; then
    pass "Result service is running"
else
    fail "Result service is not running"
fi

if docker compose ps | grep -q "worker.*Up"; then
    pass "Worker service is running"
else
    fail "Worker service is not running"
fi

# Test 2: Check health status
test_step "Test 2: Checking service health..."
if docker compose ps | grep -q "redis.*healthy"; then
    pass "Redis is healthy"
else
    fail "Redis is not healthy"
fi

if docker compose ps | grep -q "db.*healthy"; then
    pass "PostgreSQL is healthy"
else
    fail "PostgreSQL is not healthy"
fi

# Test 3: Check port accessibility
test_step "Test 3: Checking port accessibility..."
if curl -s -f http://localhost:8080 > /dev/null; then
    pass "Vote app accessible on port 8080"
else
    fail "Vote app not accessible on port 8080"
fi

if curl -s -f http://localhost:8081 > /dev/null; then
    pass "Result app accessible on port 8081"
else
    fail "Result app not accessible on port 8081"
fi

# Test 4: Submit votes
test_step "Test 4: Submitting test votes..."
VOTES_SUBMITTED=0

for i in {1..5}; do
    if curl -s -X POST http://localhost:8080 \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "vote=a" > /dev/null 2>&1; then
        VOTES_SUBMITTED=$((VOTES_SUBMITTED + 1))
    fi
done

for i in {1..3}; do
    if curl -s -X POST http://localhost:8080 \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "vote=b" > /dev/null 2>&1; then
        VOTES_SUBMITTED=$((VOTES_SUBMITTED + 1))
    fi
done

if [ $VOTES_SUBMITTED -eq 8 ]; then
    pass "Successfully submitted 8 test votes"
else
    fail "Only submitted $VOTES_SUBMITTED out of 8 votes"
fi

# Test 5: Wait for processing
test_step "Test 5: Waiting for vote processing..."
echo "⏳ Waiting 5 seconds for worker to process votes..."
sleep 5
pass "Wait completed"

# Test 6: Verify database
test_step "Test 6: Checking database..."
VOTE_COUNT=$(docker compose exec -T db psql -U postgres -d postgres -t -c "SELECT COUNT(*) FROM votes;" 2>/dev/null | xargs)

if [ -n "$VOTE_COUNT" ] && [ "$VOTE_COUNT" -gt 0 ]; then
    pass "Found $VOTE_COUNT votes in database"
else
    fail "No votes found in database"
fi

# Test 7: Check networks
test_step "Test 7: Checking network configuration..."
if docker network ls | grep -q "voting-app-frontend"; then
    pass "Frontend network exists"
else
    fail "Frontend network missing"
fi

if docker network ls | grep -q "voting-app-backend"; then
    pass "Backend network exists"
else
    fail "Backend network missing"
fi

# Test 8: Verify non-root users
test_step "Test 8: Verifying security (non-root users)..."
VOTE_USER=$(docker compose exec -T vote whoami 2>/dev/null | tr -d '\r')
if [ "$VOTE_USER" != "root" ]; then
    pass "Vote service running as non-root ($VOTE_USER)"
else
    fail "Vote service running as root"
fi

RESULT_USER=$(docker compose exec -T result whoami 2>/dev/null | tr -d '\r')
if [ "$RESULT_USER" != "root" ]; then
    pass "Result service running as non-root ($RESULT_USER)"
else
    fail "Result service running as root"
fi

# Test 9: Check resource limits
test_step "Test 9: Checking resource limits..."
VOTE_MEM=$(docker inspect vote --format='{{.HostConfig.Memory}}' 2>/dev/null)
if [ "$VOTE_MEM" -gt 0 ]; then
    VOTE_MEM_MB=$((VOTE_MEM / 1024 / 1024))
    pass "Vote service has memory limit: ${VOTE_MEM_MB}MB"
else
    fail "Vote service has no memory limit"
fi

# Test 10: Data persistence
test_step "Test 10: Checking data volumes..."
if docker volume ls | grep -q "voting-app-db-data"; then
    pass "Database volume exists"
else
    fail "Database volume missing"
fi

if docker volume ls | grep -q "voting-app-redis-data"; then
    pass "Redis volume exists"
else
    fail "Redis volume missing"
fi

# Summary
echo ""
echo "================================"
echo "📊 Test Summary"
echo "================================"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo "================================"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed! Your setup is working correctly.${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed. Please check the output above.${NC}"
    exit 1
fi
