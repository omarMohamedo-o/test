#!/bin/bash
# Quick Commands Reference for Voting App
# Phase 1 - Containerization & Local Setup

echo "==================================="
echo "Voting App - Quick Commands"
echo "==================================="
echo ""

# Function to display menu
show_menu() {
    echo "Select an action:"
    echo ""
    echo "  BUILD & START"
    echo "  1) Build all services"
    echo "  2) Start application (detached)"
    echo "  3) Start application (with logs)"
    echo ""
    echo "  MONITORING"
    echo "  4) View status"
    echo "  5) View all logs"
    echo "  6) View logs (specific service)"
    echo "  7) Monitor resources"
    echo ""
    echo "  TESTING"
    echo "  8) Run automated tests"
    echo "  9) Test vote submission"
    echo "  10) Generate seed data"
    echo ""
    echo "  MANAGEMENT"
    echo "  11) Restart specific service"
    echo "  12) Stop application"
    echo "  13) Stop and remove volumes"
    echo "  14) Clean rebuild"
    echo ""
    echo "  DEBUGGING"
    echo "  15) Shell into service"
    echo "  16) Check networks"
    echo "  17) Check volumes"
    echo "  18) Verify security (non-root)"
    echo ""
    echo "  INFO"
    echo "  19) View architecture"
    echo "  20) Open documentation"
    echo ""
    echo "  0) Exit"
    echo ""
}

# Functions for each action
build_all() {
    echo "Building all services..."
    docker compose build
}

start_detached() {
    echo "Starting application (detached)..."
    docker compose up -d
    echo ""
    echo "Waiting for services to be healthy..."
    sleep 10
    docker compose ps
}

start_logs() {
    echo "Starting application with logs..."
    docker compose up
}

view_status() {
    docker compose ps
}

view_all_logs() {
    docker compose logs -f
}

view_service_logs() {
    echo "Available services: vote, result, worker, redis, db"
    read -p "Enter service name: " service
    docker compose logs -f $service
}

monitor_resources() {
    echo "Monitoring resource usage (Ctrl+C to stop)..."
    docker stats
}

run_tests() {
    echo "Running automated tests..."
    ./test-e2e.sh
}

test_vote() {
    echo "Submitting test vote for option 'a'..."
    curl -X POST http://localhost:8080 \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -d "vote=a"
    echo ""
    echo "Vote submitted! Check results at http://localhost:8081"
}

generate_seed() {
    echo "Generating seed data (3000 votes)..."
    docker compose --profile seed up seed-data
}

restart_service() {
    echo "Available services: vote, result, worker, redis, db"
    read -p "Enter service name: " service
    docker compose restart $service
    docker compose ps $service
}

stop_app() {
    echo "Stopping application..."
    docker compose down
}

stop_and_clean() {
    echo "Stopping application and removing volumes..."
    read -p "This will delete all data. Continue? (y/N): " confirm
    if [[ $confirm == [yY] ]]; then
        docker compose down -v
        echo "Done!"
    else
        echo "Cancelled."
    fi
}

clean_rebuild() {
    echo "Performing clean rebuild..."
    docker compose down -v
    docker compose build --no-cache
    docker compose up -d
    echo ""
    echo "Waiting for services..."
    sleep 10
    docker compose ps
}

shell_into() {
    echo "Available services: vote, result, worker, redis, db"
    read -p "Enter service name: " service
    docker compose exec $service sh
}

check_networks() {
    echo "Networks:"
    docker network ls | grep voting-app
    echo ""
    echo "Frontend network details:"
    docker network inspect voting-app-frontend --format '{{range .Containers}}{{.Name}} {{end}}'
    echo ""
    echo "Backend network details:"
    docker network inspect voting-app-backend --format '{{range .Containers}}{{.Name}} {{end}}'
}

check_volumes() {
    echo "Volumes:"
    docker volume ls | grep voting-app
    echo ""
    echo "Redis volume:"
    docker volume inspect voting-app-redis-data
    echo ""
    echo "PostgreSQL volume:"
    docker volume inspect voting-app-db-data
}

verify_security() {
    echo "Checking non-root users..."
    echo ""
    echo -n "Vote service: "
    docker compose exec -T vote whoami
    echo -n "Result service: "
    docker compose exec -T result whoami
    echo -n "Worker service: "
    docker compose exec -T worker whoami
    echo ""
    echo "All services should show 'appuser' (not root)"
}

view_architecture() {
    cat << 'EOF'

Architecture:
═════════════

Internet/User
     ↓
┌────────────────┐
│ FRONTEND NET   │
│  vote  result  │
└────┬──────┬────┘
     │      │
┌────┴──────┴────┐
│  BACKEND NET   │
│ redis worker db│
└────────────────┘

Data Flow:
══════════
User → Vote → Redis → Worker → PostgreSQL → Result → User

Ports:
══════
Vote:   http://localhost:8080
Result: http://localhost:8081

Services:
═════════
vote   - Python/Flask (frontend)
result - Node.js (frontend)
worker - .NET (backend)
redis  - Redis 7 (backend)
db     - PostgreSQL 15 (backend)

EOF
}

open_docs() {
    echo "Documentation files:"
    echo "  1) QUICKSTART.md - Quick start guide"
    echo "  2) SETUP-GUIDE.md - Complete setup guide"
    echo "  3) CHECKLIST.md - Implementation checklist"
    echo "  4) IMPLEMENTATION-SUMMARY.md - Summary"
    read -p "Enter choice (1-4): " doc
    case $doc in
        1) cat QUICKSTART.md | less ;;
        2) cat SETUP-GUIDE.md | less ;;
        3) cat CHECKLIST.md | less ;;
        4) cat IMPLEMENTATION-SUMMARY.md | less ;;
        *) echo "Invalid choice" ;;
    esac
}

# Main loop
while true; do
    show_menu
    read -p "Enter your choice: " choice
    echo ""
    
    case $choice in
        1) build_all ;;
        2) start_detached ;;
        3) start_logs ;;
        4) view_status ;;
        5) view_all_logs ;;
        6) view_service_logs ;;
        7) monitor_resources ;;
        8) run_tests ;;
        9) test_vote ;;
        10) generate_seed ;;
        11) restart_service ;;
        12) stop_app ;;
        13) stop_and_clean ;;
        14) clean_rebuild ;;
        15) shell_into ;;
        16) check_networks ;;
        17) check_volumes ;;
        18) verify_security ;;
        19) view_architecture ;;
        20) open_docs ;;
        0) echo "Goodbye!"; exit 0 ;;
        *) echo "Invalid choice. Please try again." ;;
    esac
    
    echo ""
    read -p "Press Enter to continue..."
    clear
done
