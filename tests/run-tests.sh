#!/bin/bash
# Test runner script for the entire platform
# Runs all tests across all repositories

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test results
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

echo -e "${BLUE}======================================================================"
echo "Cloud-Native Ansible Lifecycle - Test Suite"
echo -e "======================================================================${NC}"
echo ""

# Change to workspace root
cd "$(dirname "$0")/.."

# Function to run a test
run_test() {
    local test_name="$1"
    local test_command="$2"

    echo -e "${BLUE}Running: ${test_name}${NC}"

    if eval "$test_command"; then
        echo -e "${GREEN}✅ PASSED: ${test_name}${NC}"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}❌ FAILED: ${test_name}${NC}"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Function to skip a test
skip_test() {
    local test_name="$1"
    local reason="$2"

    echo -e "${YELLOW}⊘ SKIPPED: ${test_name} - ${reason}${NC}"
    ((TESTS_SKIPPED++))
}

echo "======================================================================"
echo "1. SMOKE TESTS"
echo "======================================================================"
echo ""

run_test "Platform Smoke Test" \
    "ansible-playbook tests/test-playbooks/smoke-test.yml" || true

echo ""
echo "======================================================================"
echo "2. PRE-COMMIT TESTS"
echo "======================================================================"
echo ""

for repo in cluster-config aap-config-as-code automation-collection-example automation-ee-example automation-release-manifest; do
    if [ -d "$repo" ] && [ -f "$repo/.pre-commit-config.yaml" ]; then
        run_test "Pre-commit: $repo" \
            "cd $repo && pre-commit run --all-files" || true
    else
        skip_test "Pre-commit: $repo" "Configuration not found"
    fi
done

echo ""
echo "======================================================================"
echo "3. YAML VALIDATION TESTS"
echo "======================================================================"
echo ""

run_test "Validate cluster-config" \
    "ansible-playbook tests/test-playbooks/validate-cluster-config.yml" || true

run_test "Validate aap-config-as-code" \
    "ansible-playbook tests/test-playbooks/validate-aap-config.yml" || true

echo ""
echo "======================================================================"
echo "4. ANSIBLE LINT TESTS"
echo "======================================================================"
echo ""

if [ -d "aap-config-as-code" ]; then
    run_test "Ansible Lint: aap-config-as-code" \
        "cd aap-config-as-code && ansible-lint --profile production" || true
else
    skip_test "Ansible Lint: aap-config-as-code" "Directory not found"
fi

if [ -d "automation-collection-example" ]; then
    run_test "Ansible Lint: automation-collection-example" \
        "cd automation-collection-example && ansible-lint --profile production" || true
else
    skip_test "Ansible Lint: automation-collection-example" "Directory not found"
fi

echo ""
echo "======================================================================"
echo "5. PYTHON TESTS"
echo "======================================================================"
echo ""

if [ -d "automation-collection-example/tests" ]; then
    if command -v pytest &> /dev/null; then
        run_test "Python Unit Tests" \
            "cd automation-collection-example && pytest tests/unit/ -v" || true

        run_test "Python Integration Tests" \
            "cd automation-collection-example && pytest tests/integration/ -v" || true
    else
        skip_test "Python Tests" "pytest not installed"
    fi
else
    skip_test "Python Tests" "Test directory not found"
fi

echo ""
echo "======================================================================"
echo "6. MOLECULE TESTS"
echo "======================================================================"
echo ""

if [ -d "automation-collection-example/roles" ]; then
    if command -v molecule &> /dev/null; then
        for role in automation-collection-example/roles/*; do
            if [ -d "$role/molecule" ]; then
                role_name=$(basename "$role")
                run_test "Molecule: $role_name (default)" \
                    "cd $role && molecule test -s default" || true
            fi
        done
    else
        skip_test "Molecule Tests" "molecule not installed"
    fi
else
    skip_test "Molecule Tests" "Roles directory not found"
fi

echo ""
echo "======================================================================"
echo "7. SECURITY TESTS"
echo "======================================================================"
echo ""

if command -v detect-secrets &> /dev/null; then
    run_test "Secret Detection: cluster-config" \
        "cd cluster-config && detect-secrets scan" || true

    run_test "Secret Detection: aap-config-as-code" \
        "cd aap-config-as-code && detect-secrets scan" || true
else
    skip_test "Secret Detection" "detect-secrets not installed"
fi

if command -v bandit &> /dev/null; then
    if [ -d "automation-collection-example/plugins" ]; then
        run_test "Python Security Scan (Bandit)" \
            "cd automation-collection-example && bandit -r plugins/" || true
    else
        skip_test "Python Security Scan" "plugins directory not found"
    fi
else
    skip_test "Python Security Scan" "bandit not installed"
fi

echo ""
echo "======================================================================"
echo "8. BUILD TESTS"
echo "======================================================================"
echo ""

if [ -d "automation-collection-example" ] && command -v ansible-galaxy &> /dev/null; then
    run_test "Build Ansible Collection" \
        "cd automation-collection-example && ansible-galaxy collection build --force" || true
else
    skip_test "Build Collection" "ansible-galaxy not available"
fi

if [ -d "automation-ee-example" ] && command -v ansible-builder &> /dev/null; then
    run_test "Validate EE Definition" \
        "cd automation-ee-example && ansible-builder create --verbosity 1" || true
else
    skip_test "Validate EE" "ansible-builder not available"
fi

echo ""
echo "======================================================================"
echo "TEST SUMMARY"
echo "======================================================================"
echo ""

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))

echo -e "${GREEN}✅ Passed:  $TESTS_PASSED${NC}"
echo -e "${RED}❌ Failed:  $TESTS_FAILED${NC}"
echo -e "${YELLOW}⊘  Skipped: $TESTS_SKIPPED${NC}"
echo "   ─────────────"
echo "   Total:    $TOTAL_TESTS"
echo ""

if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Some tests failed. Please review the output above.${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed! 🎉${NC}"
    exit 0
fi



