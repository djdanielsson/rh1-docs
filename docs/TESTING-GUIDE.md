# Testing Guide - Cloud-Native Ansible Lifecycle Platform

Comprehensive guide to testing infrastructure and strategies for the platform.

## Table of Contents

- [Overview](#overview)
- [Testing Philosophy](#testing-philosophy)
- [Test Types](#test-types)
- [Running Tests](#running-tests)
- [Test Infrastructure](#test-infrastructure)
- [Writing Tests](#writing-tests)
- [Troubleshooting](#troubleshooting)

## Overview

The platform includes comprehensive testing at multiple levels:

- **Syntax Validation**: YAML, Ansible, Python
- **Linting**: Code quality and best practices
- **Unit Tests**: Individual components
- **Integration Tests**: Component interactions
- **Molecule Tests**: Role testing in containers
- **Security Tests**: Secret detection, vulnerability scanning
- **Workflow Tests**: End-to-end validation

## Testing Philosophy

### Shift-Left Testing

Test as early as possible in the development cycle:

```
Local Dev → Pre-commit → CI → Integration → Production
   ↓          ↓           ↓        ↓            ↓
 <1 sec    <30 sec    <5 min   <15 min      Validated
```

### Test Pyramid

```
                    /\
                   /  \  E2E Tests
                  /────\  (Few, Slow, High Value)
                 /      \
                /  Inte- \
               /  gration \  Integration Tests
              /────────────\  (Some, Medium Speed)
             /              \
            /     Unit        \
           /     Tests         \  Unit Tests
          /──────────────────────\  (Many, Fast, Focused)
         /                        \
        /     Syntax & Linting     \
       /──────────────────────────\  (Fastest, Always Run)
```

### Constitutional Compliance

All tests enforce the five articles:
- **Article I**: GitOps First - Config in Git
- **Article III**: Atomic Promotion - Version locking
- **Article IV**: Production Quality - Comprehensive testing
- **Article V**: Zero Trust - No secrets, security scanning

## Test Types

### 1. Syntax Validation

**Purpose**: Ensure files are syntactically correct

**Tools**:
- YAML: `yamllint`
- Ansible: `ansible-playbook --syntax-check`
- Python: `python3 -m py_compile`

**When**: Every commit (pre-commit hook)

**Example**:
```bash
# YAML validation
yamllint -c .yamllint .

# Ansible syntax
ansible-playbook --syntax-check playbook.yml

# Python syntax
python3 -m py_compile plugins/modules/*.py
```

### 2. Linting Tests

**Purpose**: Enforce code quality and best practices

**Tools**:
- Ansible: `ansible-lint` (production profile)
- Python: `flake8`, `pylint`, `black`, `isort`
- Shell: `shellcheck`

**When**: Every commit (pre-commit hook + CI)

**Example**:
```bash
# Ansible linting
ansible-lint --profile production

# Python linting
black --check --line-length=100 plugins/
flake8 --max-line-length=100 plugins/
pylint plugins/
```

### 3. Unit Tests

**Purpose**: Test individual functions/modules in isolation

**Location**: `automation-collection-example/tests/unit/`

**Tools**: `pytest`

**When**: Every commit

**Example**:
```bash
# Run unit tests with coverage
cd automation-collection-example/
pytest tests/unit/ -v --cov=plugins --cov-report=term
```

### 4. Integration Tests

**Purpose**: Test component interactions

**Location**: 
- `automation-collection-example/tests/integration/`
- `tests/integration/`

**Tools**: `pytest`, Ansible playbooks

**When**: PR creation, before merge

**Example**:
```bash
# Python integration tests
pytest tests/integration/ -v

# Ansible integration tests
ansible-playbook tests/integration/test-full-workflow.yml
```

### 5. Molecule Tests

**Purpose**: Test Ansible roles in container environments

**Location**: `automation-collection-example/roles/*/molecule/`

**Scenarios**:
- `default`: Basic functionality (Rocky Linux 9)
- `centos`: RHEL-like systems
- `ubuntu`: Debian-like systems

**When**: PR creation, manual testing

**Example**:
```bash
# Run all scenarios for a role
cd automation-collection-example/roles/run/
molecule test

# Run specific scenario
molecule test -s centos

# Test sequence
molecule test  # Full: create, converge, idempotence, verify, destroy
```

**Molecule Test Sequence**:
```
1. dependency    - Install dependencies
2. cleanup       - Clean up from previous run
3. destroy       - Destroy existing instances
4. syntax        - Check playbook syntax
5. create        - Create test instances
6. prepare       - Prepare instances
7. converge      - Run the role
8. idempotence   - Run again (should not change)
9. side_effect   - Test side effects
10. verify       - Run verification tests
11. cleanup      - Clean up
12. destroy      - Destroy instances
```

### 6. Security Tests

**Purpose**: Detect secrets and vulnerabilities

**Tools**:
- Secrets: `detect-secrets`, `gitleaks`
- Python: `bandit`
- Images: `trivy`

**When**: Every commit (pre-commit hook + CI)

**Example**:
```bash
# Detect secrets
detect-secrets scan

# Python security
bandit -r plugins/

# Image scanning
trivy image quay.io/myorg/custom-ee:latest
```

### 7. Validation Tests

**Purpose**: Validate configuration structure and compliance

**Location**: `tests/test-playbooks/`

**Playbooks**:
- `smoke-test.yml`: Quick platform health check
- `validate-cluster-config.yml`: K8s resources validation
- `validate-aap-config.yml`: AAP config validation
- `test-full-workflow.yml`: End-to-end workflow

**Example**:
```bash
# Smoke test
ansible-playbook tests/test-playbooks/smoke-test.yml

# Validate cluster config
ansible-playbook tests/test-playbooks/validate-cluster-config.yml

# Full workflow test
ansible-playbook tests/integration/test-full-workflow.yml
```

## Running Tests

### Quick Start

```bash
# Run all tests
./tests/run-tests.sh

# Run specific test type
ansible-playbook tests/test-playbooks/smoke-test.yml
```

### Local Development

#### Pre-commit Tests

```bash
# Install pre-commit
pip install pre-commit

# Install hooks
pre-commit install

# Run manually
pre-commit run --all-files
```

#### Unit Tests

```bash
cd automation-collection-example/

# Run all unit tests
pytest tests/unit/ -v

# Run with coverage
pytest tests/unit/ --cov=plugins --cov-report=html

# Run specific test
pytest tests/unit/test_basic.py::test_something -v
```

#### Molecule Tests

```bash
cd automation-collection-example/roles/run/

# Test default scenario
molecule test

# Test all scenarios
for scenario in molecule/*/; do
    molecule test -s $(basename $scenario)
done

# Quick test (skip idempotence)
molecule converge
molecule verify
```

#### Integration Tests

```bash
# Python integration tests
cd automation-collection-example/
pytest tests/integration/ -v

# Ansible integration tests
ansible-playbook tests/integration/test-full-workflow.yml
```

### CI/CD Tests

Tests run automatically in GitHub Actions:

```yaml
# Triggered on:
- push: All branches
- pull_request: main/master
- workflow_dispatch: Manual
```

**View Results**:
```bash
# Using GitHub CLI
gh run list
gh run view <run-id>
gh run view <run-id> --log
```

### Complete Test Suite

```bash
#!/bin/bash
# Run complete test suite locally

# 1. Smoke test
echo "Running smoke test..."
ansible-playbook tests/test-playbooks/smoke-test.yml

# 2. Pre-commit all repos
echo "Running pre-commit checks..."
for repo in cluster-config aap-config-as-code automation-collection-example automation-ee-example automation-release-manifest; do
    if [ -d "$repo" ]; then
        cd "$repo"
        pre-commit run --all-files || true
        cd ..
    fi
done

# 3. Validation tests
echo "Running validation tests..."
ansible-playbook tests/test-playbooks/validate-cluster-config.yml
ansible-playbook tests/test-playbooks/validate-aap-config.yml

# 4. Ansible lint
echo "Running ansible-lint..."
cd aap-config-as-code && ansible-lint --profile production
cd ../automation-collection-example && ansible-lint --profile production
cd ..

# 5. Python tests
echo "Running Python tests..."
cd automation-collection-example
pytest tests/unit/ -v
pytest tests/integration/ -v
cd ..

# 6. Molecule tests
echo "Running Molecule tests..."
cd automation-collection-example/roles/run
molecule test
cd ../../..

# 7. Security tests
echo "Running security tests..."
detect-secrets scan
bandit -r automation-collection-example/plugins/

# 8. Build tests
echo "Running build tests..."
cd automation-collection-example && ansible-galaxy collection build --force
cd ../automation-ee-example && ansible-builder create --verbosity 1
cd ..

# 9. Integration workflow
echo "Running full workflow test..."
ansible-playbook tests/integration/test-full-workflow.yml

echo "✅ All tests complete!"
```

## Test Infrastructure

### Directory Structure

```
rh1_ansible_code_lifecycle/
├── tests/
│   ├── run-tests.sh                    # Main test runner
│   ├── fixtures/                       # Mock data
│   │   ├── mock-aap-inventory.yml
│   │   ├── mock-aap-config.yml
│   │   └── mock-release-manifest.yaml
│   ├── test-playbooks/                 # Validation playbooks
│   │   ├── smoke-test.yml
│   │   ├── validate-cluster-config.yml
│   │   └── validate-aap-config.yml
│   └── integration/                    # Integration tests
│       └── test-full-workflow.yml
│
├── automation-collection-example/
│   ├── roles/run/molecule/             # Molecule scenarios
│   │   ├── default/
│   │   ├── centos/
│   │   └── ubuntu/
│   └── tests/
│       ├── unit/                       # Unit tests
│       │   └── test_basic.py
│       └── integration/                # Integration tests
│           ├── test_integration.py
│           └── targets/
│               └── sample_module/
│                   └── tasks/main.yml
```

### Mock Data

Mock data for testing without real infrastructure:

#### Mock AAP Inventory

```yaml
# tests/fixtures/mock-aap-inventory.yml
all:
  children:
    aap_dev:
      hosts:
        aap-dev-mock:
          ansible_host: localhost
          controller_host: "http://localhost:8080"
```

**Usage**:
```bash
ansible-playbook playbook.yml -i tests/fixtures/mock-aap-inventory.yml --check
```

#### Mock AAP Configuration

```yaml
# tests/fixtures/mock-aap-config.yml
controller_organizations:
  - name: "Test Organization"
    description: "Test org"
```

**Usage**:
```bash
# Test configuration structure
ansible-playbook playbook.yml \
    -e @tests/fixtures/mock-aap-config.yml \
    --check
```

#### Mock Release Manifest

```yaml
# tests/fixtures/mock-release-manifest.yaml
version: "0.1.0-test"
components:
  aap_configuration:
    commit: "0123456789abcdef..." # 40-char SHA
```

**Usage**:
```bash
# Test manifest validation
python3 -c "
import yaml
m = yaml.safe_load(open('tests/fixtures/mock-release-manifest.yaml'))
assert 'version' in m
assert len(m['components']['aap_configuration']['commit']) == 40
"
```

## Writing Tests

### Unit Test Example

```python
# tests/unit/test_sample_filter.py
import pytest
from ansible_collections.myorg.custom_collection.plugins.filter.sample_filter import FilterModule

class TestSampleFilter:
    def test_sample_filter_basic(self):
        """Test basic filter functionality."""
        fm = FilterModule()
        filters = fm.filters()
        
        result = filters['sample_filter']("test")
        assert result == "TEST"
    
    def test_sample_filter_empty(self):
        """Test filter with empty input."""
        fm = FilterModule()
        filters = fm.filters()
        
        with pytest.raises(ValueError):
            filters['sample_filter']("")
```

### Integration Test Example

```yaml
# tests/integration/targets/sample_module/tasks/main.yml
---
- name: Test module with valid input
  myorg.custom_collection.sample_module:
    name: "test"
  register: result

- name: Verify module succeeded
  ansible.builtin.assert:
    that:
      - result is success
      - result is changed

- name: Test idempotency
  myorg.custom_collection.sample_module:
    name: "test"
  register: result_idempotent

- name: Verify idempotency
  ansible.builtin.assert:
    that:
      - result_idempotent is not changed
```

### Molecule Scenario Example

```yaml
# roles/run/molecule/custom/molecule.yml
---
dependency:
  name: galaxy

driver:
  name: docker

platforms:
  - name: test-instance
    image: docker.io/geerlingguy/docker-rockylinux9-ansible:latest
    pre_build_image: true
    privileged: true

provisioner:
  name: ansible
  playbooks:
    converge: converge.yml
    verify: verify.yml

verifier:
  name: ansible
```

## Troubleshooting

### Common Issues

#### 1. Molecule Test Fails

**Problem**: `ERROR: Cannot connect to Docker daemon`

**Solution**:
```bash
# Check Docker/Podman is running
docker ps
# or
podman ps

# Set driver if using podman
export MOLECULE_DRIVER=podman
```

#### 2. Pre-commit Hook Slow

**Problem**: Pre-commit hooks take too long

**Solution**:
```bash
# Run only fast hooks during development
SKIP=ansible-lint,molecule git commit -m "message"

# Or disable temporarily
git commit --no-verify -m "message"
```

#### 3. pytest Not Finding Tests

**Problem**: `ERROR: not found: tests/unit/`

**Solution**:
```bash
# Ensure pytest.ini or pyproject.toml exists
cat > pytest.ini <<EOF
[pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
EOF
```

#### 4. Ansible-lint Errors

**Problem**: Too many lint errors to fix

**Solution**:
```bash
# Generate ignore file
ansible-lint --generate-ignore

# Auto-fix some issues
ansible-lint --fix

# Adjust .ansible-lint for your needs
```

### Debug Tips

#### Enable Verbose Output

```bash
# Pytest
pytest -vv --tb=long

# Ansible
ansible-playbook -vvv

# Molecule
molecule --debug test
```

#### Run Specific Tests

```bash
# Pytest
pytest tests/unit/test_basic.py::TestClass::test_method -v

# Ansible
ansible-playbook test.yml --tags=specific-test

# Molecule
molecule test -s default -- --tags=converge
```

## Best Practices

### 1. Test Naming

```python
# Good
def test_module_returns_correct_value():
    pass

def test_filter_handles_empty_input():
    pass

# Bad
def test1():
    pass

def test_stuff():
    pass
```

### 2. Arrange-Act-Assert

```python
def test_sample_function():
    # Arrange
    input_data = "test"
    expected = "TEST"
    
    # Act
    result = sample_function(input_data)
    
    # Assert
    assert result == expected
```

### 3. Test Independence

```python
# Each test should be independent
class TestModule:
    def test_first(self):
        # Don't rely on test_second
        pass
    
    def test_second(self):
        # Don't rely on test_first
        pass
```

### 4. Use Fixtures

```python
@pytest.fixture
def sample_config():
    return {"key": "value"}

def test_with_fixture(sample_config):
    assert sample_config["key"] == "value"
```

## Links

- [pytest Documentation](https://docs.pytest.org/)
- [Molecule Documentation](https://molecule.readthedocs.io/)
- [Ansible Test Guide](https://docs.ansible.com/ansible/latest/dev_guide/testing.html)
- [Pre-commit Hooks](./PRE-COMMIT-SETUP.md)
- [CI/CD Guide](./CICD-GUIDE.md)

---

**Version**: 1.0  
**Last Updated**: 2025-10-30  
**Maintained By**: Platform Team



