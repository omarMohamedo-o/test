#!/bin/bash

# Validation script for Kubernetes manifests
# Checks YAML syntax and Kubernetes resource validity

set -e

echo "🔍 Validating Kubernetes manifests..."
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

MANIFESTS_DIR="manifests"
HELM_CHART_DIR="helm/voting-app"
FAILED=0

# Function to validate YAML syntax
validate_yaml() {
    local file=$1
    if command -v yamllint &> /dev/null; then
        if yamllint -d relaxed "$file" &> /dev/null; then
            echo -e "${GREEN}✓${NC} YAML syntax valid: $file"
            return 0
        else
            echo -e "${RED}✗${NC} YAML syntax error: $file"
            yamllint -d relaxed "$file"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠${NC} yamllint not installed, skipping YAML syntax check for $file"
        return 0
    fi
}

# Function to validate Kubernetes resource
validate_k8s() {
    local file=$1
    if kubectl apply --dry-run=client -f "$file" &> /dev/null; then
        echo -e "${GREEN}✓${NC} Kubernetes resource valid: $file"
        return 0
    else
        echo -e "${RED}✗${NC} Kubernetes resource error: $file"
        kubectl apply --dry-run=client -f "$file"
        return 1
    fi
}

# Validate raw manifests
echo "📄 Validating raw manifests in $MANIFESTS_DIR/"
echo ""
for file in $MANIFESTS_DIR/*.yaml; do
    if [ -f "$file" ]; then
        if ! validate_yaml "$file"; then
            FAILED=$((FAILED + 1))
        elif ! validate_k8s "$file"; then
            FAILED=$((FAILED + 1))
        fi
    fi
done

echo ""
echo "📦 Validating Helm chart in $HELM_CHART_DIR/"
echo ""

# Validate Helm chart syntax
if command -v helm &> /dev/null; then
    if helm lint "$HELM_CHART_DIR" &> /dev/null; then
        echo -e "${GREEN}✓${NC} Helm chart syntax valid: $HELM_CHART_DIR"
    else
        echo -e "${RED}✗${NC} Helm chart syntax error: $HELM_CHART_DIR"
        helm lint "$HELM_CHART_DIR"
        FAILED=$((FAILED + 1))
    fi
    
    # Validate Helm template rendering
    if helm template voting-app "$HELM_CHART_DIR" &> /dev/null; then
        echo -e "${GREEN}✓${NC} Helm template rendering valid: $HELM_CHART_DIR"
    else
        echo -e "${RED}✗${NC} Helm template rendering error: $HELM_CHART_DIR"
        helm template voting-app "$HELM_CHART_DIR"
        FAILED=$((FAILED + 1))
    fi
else
    echo -e "${YELLOW}⚠${NC} helm not installed, skipping Helm chart validation"
fi

echo ""
echo "─────────────────────────────────────────"
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All validations passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ $FAILED validation(s) failed${NC}"
    exit 1
fi
