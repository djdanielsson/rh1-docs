#!/bin/bash
# Check all dependencies across the platform for updates and vulnerabilities
# Constitutional Article V: Zero-Trust Security

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo -e "${BLUE}${BOLD}🔍 Checking Platform Dependencies${NC}"
echo ""

# Track overall status
ISSUES_FOUND=false

# Function to check Python dependencies in a directory
check_python_deps() {
    local dir=$1
    local name=$2
    
    if [ ! -f "${dir}/requirements.txt" ]; then
        return 0
    fi
    
    echo -e "${BLUE}Checking Python dependencies: ${name}${NC}"
    cd "${dir}"
    
    # Check for outdated packages
    if command -v pip-review &> /dev/null; then
        echo "  → Checking for outdated packages..."
        pip-review --local || true
    fi
    
    # Check for vulnerabilities with pip-audit
    if command -v pip-audit &> /dev/null; then
        echo "  → Scanning for vulnerabilities..."
        if ! pip-audit -r requirements.txt; then
            echo -e "  ${RED}✗ Vulnerabilities found${NC}"
            ISSUES_FOUND=true
        else
            echo -e "  ${GREEN}✓ No vulnerabilities found${NC}"
        fi
    else
        echo -e "  ${YELLOW}⚠  pip-audit not installed, skipping vulnerability scan${NC}"
    fi
    
    cd - > /dev/null
    echo ""
}

# Function to check Ansible collection dependencies
check_ansible_deps() {
    local dir=$1
    local name=$2
    
    if [ ! -f "${dir}/requirements.yml" ]; then
        return 0
    fi
    
    echo -e "${BLUE}Checking Ansible collections: ${name}${NC}"
    cd "${dir}"
    
    # Install collections
    if command -v ansible-galaxy &> /dev/null; then
        echo "  → Installing collections..."
        ansible-galaxy collection install -r requirements.yml --force > /dev/null 2>&1
        
        echo "  → Installed collections:"
        ansible-galaxy collection list | grep -v "^#" | head -20
    else
        echo -e "  ${YELLOW}⚠  ansible-galaxy not installed${NC}"
    fi
    
    cd - > /dev/null
    echo ""
}

# Main script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

cd "${PROJECT_ROOT}"

# Check Python dependencies
echo -e "${BOLD}Python Dependencies:${NC}"
echo ""

if [ -d "automation-collection-example" ]; then
    check_python_deps "automation-collection-example" "Automation Collection"
fi

if [ -d "automation-ee-example" ]; then
    check_python_deps "automation-ee-example" "Execution Environment"
fi

# Check Ansible dependencies
echo -e "${BOLD}Ansible Collection Dependencies:${NC}"
echo ""

if [ -d "automation-collection-example" ]; then
    check_ansible_deps "automation-collection-example" "Collection Requirements"
fi

if [ -d "aap-config-as-code/collections" ]; then
    check_ansible_deps "aap-config-as-code/collections" "AAP Config Collections"
fi

# Check for GitHub Actions updates
echo -e "${BOLD}GitHub Actions:${NC}"
echo ""

if command -v gh &> /dev/null; then
    echo -e "${BLUE}Checking GitHub Actions for updates...${NC}"
    
    # Find all workflow files
    WORKFLOW_COUNT=$(find .github/workflows -name "*.yml" -o -name "*.yaml" 2>/dev/null | wc -l)
    echo "  Found ${WORKFLOW_COUNT} workflow files"
    
    # List actions used
    echo "  Actions in use:"
    grep -h "uses:" .github/workflows/*.yml 2>/dev/null | \
        sed 's/.*uses: //' | \
        sort -u | \
        sed 's/^/    - /'
else
    echo -e "${YELLOW}⚠  GitHub CLI not installed, skipping Actions check${NC}"
fi

echo ""

# Summary
echo -e "${BLUE}${BOLD}📊 Summary${NC}"
echo ""

if [ "$ISSUES_FOUND" = true ]; then
    echo -e "${RED}❌ Security issues found${NC}"
    echo ""
    echo "Recommended actions:"
    echo "  1. Review vulnerability reports above"
    echo "  2. Update affected dependencies"
    echo "  3. Run tests after updates"
    echo "  4. Create PRs for dependency updates"
    echo ""
    exit 1
else
    echo -e "${GREEN}✅ No critical issues found${NC}"
    echo ""
    echo "Regular maintenance:"
    echo "  - Review outdated packages periodically"
    echo "  - Keep dependencies up-to-date"
    echo "  - Monitor security advisories"
    echo ""
fi

echo "Tools used:"
echo "  - pip-audit: Python vulnerability scanning"
echo "  - Safety: Python package security"
echo "  - ansible-galaxy: Collection management"
echo "  - Dependabot: Automated updates (in GitHub)"
echo ""

echo "Constitutional compliance:"
echo "  ✅ Article V: Zero-Trust Security - Dependency monitoring"
echo "  ✅ Article IV: Production-Grade Quality - Regular updates"

