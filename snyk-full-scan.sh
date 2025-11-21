#!/bin/bash

# Snyk Full Security Scan Script
# Tests code, dependencies, containers, and infrastructure

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                   ║${NC}"
echo -e "${BLUE}║              🔒 SNYK SECURITY SCAN - ALL COMPONENTS               ║${NC}"
echo -e "${BLUE}║                                                                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check Snyk is installed
if ! command -v snyk &> /dev/null; then
    echo -e "${RED}❌ Snyk is not installed!${NC}"
    echo "Install with: npm install -g snyk"
    echo "Or visit: https://docs.snyk.io/snyk-cli/install-the-snyk-cli"
    exit 1
fi

# Check authentication
if ! snyk auth status &> /dev/null; then
    echo -e "${YELLOW}⚠ Not authenticated with Snyk${NC}"
    echo "Run: snyk auth"
    exit 1
fi

echo -e "${GREEN}✓ Snyk CLI ready${NC}"
echo ""

# Create reports directory
mkdir -p security-reports
REPORT_FILE="security-reports/snyk-scan-$(date +%Y%m%d-%H%M%S).txt"

# Start report
echo "=== SNYK SECURITY SCAN REPORT ===" > "$REPORT_FILE"
echo "Date: $(date)" >> "$REPORT_FILE"
echo "Project: Tactful Voting App - Cloud Infrastructure" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

# Counter for issues
TOTAL_ISSUES=0
CRITICAL_ISSUES=0
HIGH_ISSUES=0

# 1. SAST - Code Scanning
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}1. CODE SCAN (SAST) - Static Analysis${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "1. CODE SCAN (SAST)" >> "$REPORT_FILE"
echo "===================" >> "$REPORT_FILE"

for dir in vote result worker; do
    echo -e "${YELLOW}Scanning $dir service...${NC}"
    if snyk code test "$dir/" --severity-threshold=medium >> "$REPORT_FILE" 2>&1; then
        echo -e "${GREEN}  ✓ No issues found in $dir${NC}"
    else
        echo -e "${RED}  ⚠ Issues found in $dir (check report)${NC}"
    fi
done
echo "" >> "$REPORT_FILE"
echo ""

# 2. SCA - Dependency Scanning
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}2. DEPENDENCY SCAN (SCA) - Open Source Vulnerabilities${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "2. DEPENDENCY SCAN (SCA)" >> "$REPORT_FILE"
echo "========================" >> "$REPORT_FILE"

# Python dependencies (vote)
echo -e "${YELLOW}Scanning Python dependencies (vote)...${NC}"
cd vote/
if snyk test --file=requirements.txt --severity-threshold=medium >> "../$REPORT_FILE" 2>&1; then
    echo -e "${GREEN}  ✓ No dependency issues in vote${NC}"
else
    echo -e "${RED}  ⚠ Dependency issues found in vote${NC}"
fi
cd ..

# Node.js dependencies (result)
echo -e "${YELLOW}Scanning Node.js dependencies (result)...${NC}"
cd result/
if snyk test --file=package.json --severity-threshold=medium >> "../$REPORT_FILE" 2>&1; then
    echo -e "${GREEN}  ✓ No dependency issues in result${NC}"
else
    echo -e "${RED}  ⚠ Dependency issues found in result${NC}"
fi
cd ..

# .NET dependencies (worker)
echo -e "${YELLOW}Scanning .NET dependencies (worker)...${NC}"
cd worker/
if snyk test --file=Worker.csproj --severity-threshold=medium >> "../$REPORT_FILE" 2>&1; then
    echo -e "${GREEN}  ✓ No dependency issues in worker${NC}"
else
    echo -e "${RED}  ⚠ Dependency issues found in worker${NC}"
fi
cd ..

echo "" >> "$REPORT_FILE"
echo ""

# 3. Container Scanning
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}3. CONTAINER SCAN - Docker Images${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "3. CONTAINER SCAN" >> "$REPORT_FILE"
echo "=================" >> "$REPORT_FILE"

# Check if images exist
if ! docker images | grep -q "tactful-votingapp-cloud-infra-vote"; then
    echo -e "${YELLOW}⚠ Images not built. Building now...${NC}"
    docker build -t tactful-votingapp-cloud-infra-vote:latest vote/ > /dev/null 2>&1
    docker build -t tactful-votingapp-cloud-infra-result:latest result/ > /dev/null 2>&1
    docker build -t tactful-votingapp-cloud-infra-worker:latest worker/ > /dev/null 2>&1
fi

# Scan vote image
echo -e "${YELLOW}Scanning vote image...${NC}"
echo "Vote Image:" >> "$REPORT_FILE"
if snyk container test tactful-votingapp-cloud-infra-vote:latest \
    --file=vote/Dockerfile \
    --severity-threshold=medium \
    --exclude-base-image-vulns >> "$REPORT_FILE" 2>&1; then
    echo -e "${GREEN}  ✓ No issues in vote image${NC}"
else
    echo -e "${RED}  ⚠ Issues found in vote image${NC}"
fi

# Scan result image
echo -e "${YELLOW}Scanning result image...${NC}"
echo "Result Image:" >> "$REPORT_FILE"
if snyk container test tactful-votingapp-cloud-infra-result:latest \
    --file=result/Dockerfile \
    --severity-threshold=medium \
    --exclude-base-image-vulns >> "$REPORT_FILE" 2>&1; then
    echo -e "${GREEN}  ✓ No issues in result image${NC}"
else
    echo -e "${RED}  ⚠ Issues found in result image${NC}"
fi

# Scan worker image
echo -e "${YELLOW}Scanning worker image...${NC}"
echo "Worker Image:" >> "$REPORT_FILE"
if snyk container test tactful-votingapp-cloud-infra-worker:latest \
    --file=worker/Dockerfile \
    --severity-threshold=medium \
    --exclude-base-image-vulns >> "$REPORT_FILE" 2>&1; then
    echo -e "${GREEN}  ✓ No issues in worker image${NC}"
else
    echo -e "${RED}  ⚠ Issues found in worker image${NC}"
fi

echo "" >> "$REPORT_FILE"
echo ""

# 4. IaC Scanning
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}4. INFRASTRUCTURE AS CODE SCAN - Kubernetes & Docker Compose${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "4. INFRASTRUCTURE AS CODE SCAN" >> "$REPORT_FILE"
echo "===============================" >> "$REPORT_FILE"

# Scan Kubernetes manifests
echo -e "${YELLOW}Scanning Kubernetes manifests...${NC}"
if snyk iac test k8s/manifests/ --severity-threshold=medium >> "$REPORT_FILE" 2>&1; then
    echo -e "${GREEN}  ✓ No issues in Kubernetes manifests${NC}"
else
    echo -e "${RED}  ⚠ Issues found in Kubernetes manifests${NC}"
fi

# Scan Helm charts
echo -e "${YELLOW}Scanning Helm charts...${NC}"
if snyk iac test k8s/helm/ --severity-threshold=medium >> "$REPORT_FILE" 2>&1; then
    echo -e "${GREEN}  ✓ No issues in Helm charts${NC}"
else
    echo -e "${RED}  ⚠ Issues found in Helm charts${NC}"
fi

# Scan docker-compose
echo -e "${YELLOW}Scanning docker-compose.yml...${NC}"
if snyk iac test docker-compose.yml --severity-threshold=medium >> "$REPORT_FILE" 2>&1; then
    echo -e "${GREEN}  ✓ No issues in docker-compose${NC}"
else
    echo -e "${RED}  ⚠ Issues found in docker-compose${NC}"
fi

# Scan monitoring configs
echo -e "${YELLOW}Scanning monitoring configurations...${NC}"
if snyk iac test k8s/monitoring/ --severity-threshold=medium >> "$REPORT_FILE" 2>&1; then
    echo -e "${GREEN}  ✓ No issues in monitoring configs${NC}"
else
    echo -e "${RED}  ⚠ Issues found in monitoring configs${NC}"
fi

echo "" >> "$REPORT_FILE"
echo ""

# 5. Security Best Practices Check
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}5. SECURITY BEST PRACTICES VALIDATION${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "5. SECURITY BEST PRACTICES" >> "$REPORT_FILE"
echo "==========================" >> "$REPORT_FILE"

# Check for hardcoded secrets
echo -e "${YELLOW}Checking for hardcoded secrets...${NC}"
if grep -r "password\|secret\|token\|api_key" --include="*.py" --include="*.js" --include="*.cs" . 2>/dev/null | grep -v "\.git" | grep -v "node_modules" | grep -v "REPORT" > /dev/null; then
    echo -e "${RED}  ⚠ Potential hardcoded secrets found${NC}"
    echo "  ⚠ Potential hardcoded secrets found" >> "$REPORT_FILE"
else
    echo -e "${GREEN}  ✓ No obvious hardcoded secrets${NC}"
    echo "  ✓ No hardcoded secrets detected" >> "$REPORT_FILE"
fi

# Check Dockerfile security
echo -e "${YELLOW}Checking Dockerfile security...${NC}"
echo "Dockerfile Security:" >> "$REPORT_FILE"
for dockerfile in vote/Dockerfile result/Dockerfile worker/Dockerfile; do
    echo "  $dockerfile:" >> "$REPORT_FILE"
    if grep -q "USER" "$dockerfile"; then
        echo -e "${GREEN}    ✓ $dockerfile: Non-root user defined${NC}"
        echo "    ✓ Non-root user defined" >> "$REPORT_FILE"
    else
        echo -e "${RED}    ✗ $dockerfile: No USER directive${NC}"
        echo "    ✗ No USER directive" >> "$REPORT_FILE"
    fi
done

echo "" >> "$REPORT_FILE"
echo ""

# Summary
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}SCAN SUMMARY${NC}"
echo -e "${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo "SUMMARY" >> "$REPORT_FILE"
echo "=======" >> "$REPORT_FILE"
echo "Scan completed at: $(date)" >> "$REPORT_FILE"
echo "Full report saved to: $REPORT_FILE" >> "$REPORT_FILE"
echo "" >> "$REPORT_FILE"

echo -e "${GREEN}✓ Scan completed!${NC}"
echo ""
echo -e "${BLUE}Report saved to: ${YELLOW}$REPORT_FILE${NC}"
echo ""
echo "View report:"
echo "  cat $REPORT_FILE"
echo ""
echo "Open in Snyk dashboard:"
echo "  https://app.snyk.io/"
echo ""

# Optional: Send feedback
echo -e "${YELLOW}💡 Tip: After fixing issues, report your improvements:${NC}"
echo "  snyk send-feedback --prevented-issues=X --fixed-issues=Y --path=\$(pwd)"
echo ""

echo -e "${BLUE}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                                                                   ║${NC}"
echo -e "${BLUE}║                    ✅ SECURITY SCAN COMPLETE                      ║${NC}"
echo -e "${BLUE}║                                                                   ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════════════╝${NC}"
