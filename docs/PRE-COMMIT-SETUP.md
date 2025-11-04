# Pre-commit Hooks Installation and Usage Guide

This guide covers the installation and usage of pre-commit hooks across all repositories in the Cloud-Native Ansible Lifecycle platform.

## Table of Contents

- [Overview](#overview)
- [Installation](#installation)
- [Per-Repository Setup](#per-repository-setup)
- [Usage](#usage)
- [Troubleshooting](#troubleshooting)
- [Constitutional Compliance](#constitutional-compliance)
- [Custom Hooks Reference](#custom-hooks-reference)

## Overview

Pre-commit hooks enforce code quality, security, and constitutional compliance **before** code is committed to Git. This ensures:

- ✅ **No secrets in Git** (Article V)
- ✅ **Code quality** (Article IV)
- ✅ **Consistent formatting** (Article IV)
- ✅ **Security scanning** (Article V)
- ✅ **Syntax validation** (Article IV)

### What Gets Checked?

Each repository has custom pre-commit hooks tailored to its purpose:

| Repository | Key Checks |
|------------|------------|
| **cluster-config** | Kubernetes YAML, ArgoCD apps, Tekton pipelines, no secrets, RBAC checks |
| **aap-config-as-code** | Ansible syntax, idempotency, no plain secrets, naming conventions |
| **automation-collection-example** | Python linting, Ansible lint, module docs, Molecule tests |
| **automation-ee-example** | EE structure, version pinning, no latest tags, bindep validation |
| **automation-release-manifest** | Manifest structure, commit SHAs, image digests, semver |

## Installation

### 1. Install Pre-commit Framework

```bash
# Using pip (recommended)
pip install pre-commit

# Or using homebrew (macOS)
brew install pre-commit

# Verify installation
pre-commit --version
```

### 2. Install Additional Dependencies

Some hooks require additional tools:

```bash
# YAML and Ansible tools
pip install yamllint ansible-lint

# Python code quality tools (for collection development)
pip install black isort flake8 pylint bandit

# Security scanning tools
pip install detect-secrets

# Install gitleaks (secrets scanner)
# macOS
brew install gitleaks

# Linux
# See: https://github.com/gitleaks/gitleaks#installing
```

### 3. Optional Tools

```bash
# Kubernetes validation (for cluster-config)
brew install kubeval  # macOS
# or download from: https://github.com/instrumenta/kubeval

# Tekton CLI (for cluster-config)
brew install tektoncd-cli  # macOS
# or see: https://tekton.dev/docs/cli/

# Ansible builder (for automation-ee-example)
pip install ansible-builder

# Shell script linting
brew install shellcheck  # macOS
```

## Per-Repository Setup

### Setup for All Repositories

Run this in **each repository directory**:

```bash
# Navigate to repository
cd cluster-config/  # or aap-config-as-code/, etc.

# Install pre-commit hooks
pre-commit install

# Optional: Install hooks for other Git hooks
pre-commit install --hook-type commit-msg
pre-commit install --hook-type pre-push
```

### Quick Setup Script

Run this from the **workspace root** to set up all repositories:

```bash
#!/bin/bash
# setup-precommit-all.sh

repos=(
  "cluster-config"
  "aap-config-as-code"
  "automation-collection-example"
  "automation-ee-example"
  "automation-release-manifest"
)

for repo in "${repos[@]}"; do
  if [ -d "$repo" ]; then
    echo "Setting up pre-commit in $repo..."
    cd "$repo"
    pre-commit install
    cd ..
    echo "✅ $repo configured"
  else
    echo "⚠️  $repo not found, skipping"
  fi
done

echo ""
echo "✅ Pre-commit hooks installed in all repositories"
echo "Run 'pre-commit run --all-files' in each repo to test"
```

Save this as `setup-precommit-all.sh` and run:

```bash
chmod +x setup-precommit-all.sh
./setup-precommit-all.sh
```

## Usage

### Automatic Checks (On Commit)

Pre-commit hooks run **automatically** when you commit:

```bash
git add .
git commit -m "Add new feature"

# Pre-commit hooks run here automatically
# If any check fails, commit is blocked
```

### Manual Checks

Run checks manually without committing:

```bash
# Run all hooks on all files
pre-commit run --all-files

# Run all hooks on staged files only
pre-commit run

# Run specific hook
pre-commit run ansible-lint --all-files

# Run on specific files
pre-commit run --files path/to/file.yml
```

### First-Time Run

On first setup, run checks on all files to establish baseline:

```bash
cd cluster-config/
pre-commit run --all-files
```

This may find issues in existing code. Fix them or update the configuration.

### Skipping Hooks (Emergency Only)

**Warning**: Only skip hooks when absolutely necessary!

```bash
# Skip pre-commit hooks (NOT RECOMMENDED)
git commit -m "Emergency fix" --no-verify

# Skip specific hook
SKIP=ansible-lint git commit -m "Fix"
```

⚠️ **Constitutional Violation**: Skipping security hooks (detect-secrets, gitleaks) violates Article V!

## Troubleshooting

### Common Issues

#### 1. Hook Not Found

**Problem**: `[INFO] Installing environment for <hook>... failed`

**Solution**:
```bash
# Update pre-commit
pip install --upgrade pre-commit

# Clean cache and reinstall
pre-commit clean
pre-commit install --install-hooks
```

#### 2. Detect-Secrets Baseline Missing

**Problem**: `FileNotFoundError: .secrets.baseline`

**Solution**:
```bash
# Create initial baseline
detect-secrets scan > .secrets.baseline

# Or run first scan
pre-commit run detect-secrets --all-files
```

#### 3. YAML Lint Failures

**Problem**: Many YAML lint errors

**Solution**:
```bash
# Auto-fix some issues
yamllint --config-file=.yamllint . --format auto

# Or adjust .yamllint configuration
vi .yamllint
```

#### 4. Ansible Lint Failures

**Problem**: Ansible lint errors in existing code

**Solution**:
```bash
# Generate lint ignore file
ansible-lint --generate-ignore

# Or fix issues automatically
ansible-lint --fix
```

#### 5. Gitleaks Not Found

**Problem**: `Executable 'gitleaks' not found`

**Solution**:
```bash
# Install gitleaks
brew install gitleaks  # macOS

# Or skip for now (not recommended)
SKIP=gitleaks git commit -m "message"
```

### Updating Hooks

Keep hooks up-to-date:

```bash
# Update to latest hook versions
pre-commit autoupdate

# This updates versions in .pre-commit-config.yaml
```

### Debugging

Enable verbose output:

```bash
# Verbose mode
pre-commit run --all-files --verbose

# Show output from failing hooks
pre-commit run --all-files --show-diff-on-failure
```

## Constitutional Compliance

Pre-commit hooks enforce the five articles of the Constitution:

### Article I: GitOps First

- ✅ Validates all configuration is declarative YAML
- ✅ Prevents manual Dockerfiles (use ansible-builder)

### Article II: Separation of Duties

- ✅ Validates ArgoCD apps don't call AAP APIs
- ✅ Ensures proper tool usage (ArgoCD vs Tekton)

### Article III: Atomic Promotion

- ✅ Prevents `latest` tags in production manifests
- ✅ Validates commit SHAs are full 40 characters
- ✅ Ensures image digests in release manifests

### Article IV: Production-Grade Quality

- ✅ Enforces ansible-lint (production profile)
- ✅ Checks for idempotency in tasks
- ✅ Validates FQCN usage
- ✅ Requires documentation for modules

### Article V: Zero-Trust Security

- ✅ **Detects secrets in code** (detect-secrets + gitleaks)
- ✅ Prevents plain passwords in group_vars
- ✅ Validates security best practices
- ✅ Runs Bandit security scanner on Python code

## Custom Hooks Reference

### cluster-config Hooks

| Hook ID | Purpose | Severity |
|---------|---------|----------|
| `constitution-compliance` | No secrets in YAML | ❌ Blocking |
| `no-latest-tags` | No latest tags in prod | ❌ Blocking |
| `rbac-check` | Least privilege RBAC | ⚠️ Warning |
| `argocd-validation` | Valid ArgoCD apps | ❌ Blocking |

### aap-config-as-code Hooks

| Hook ID | Purpose | Severity |
|---------|---------|----------|
| `no-secrets-in-vars` | No plain secrets | ❌ Blocking |
| `idempotency-check` | Check task idempotency | ⚠️ Warning |
| `playbook-syntax` | Ansible syntax check | ❌ Blocking |
| `inventory-check` | Validate inventory | ❌ Blocking |

### automation-collection-example Hooks

| Hook ID | Purpose | Severity |
|---------|---------|----------|
| `module-documentation` | Module has DOCUMENTATION | ⚠️ Warning |
| `molecule-tests` | Roles have tests | ⚠️ Warning |
| `fqcn-check` | Use FQCN | ⚠️ Warning |
| `bandit` | Python security scan | ❌ Blocking |

### automation-ee-example Hooks

| Hook ID | Purpose | Severity |
|---------|---------|----------|
| `ee-yaml-validation` | Valid EE definition | ❌ Blocking |
| `version-pinning-collections` | Pin collection versions | ⚠️ Warning |
| `no-manual-dockerfile` | No manual Dockerfiles | ❌ Blocking |
| `ee-build-test` | Test EE definition | ❌ Blocking |

### automation-release-manifest Hooks

| Hook ID | Purpose | Severity |
|---------|---------|----------|
| `manifest-validation` | Valid manifest structure | ❌ Blocking |
| `commit-sha-format` | 40-char commit SHAs | ⚠️ Warning |
| `no-latest-tags` | No latest in releases | ❌ Blocking |
| `duplicate-version` | Unique versions | ❌ Blocking |

## Workflow Examples

### Example 1: Making Changes to cluster-config

```bash
cd cluster-config/

# Make changes
vi aap-instances/automation-controller-dev.yaml

# Stage changes
git add aap-instances/automation-controller-dev.yaml

# Commit (hooks run automatically)
git commit -m "Update AAP dev instance configuration"

# If hooks pass:
✅ check-yaml.............................Passed
✅ yamllint...............................Passed
✅ detect-secrets.........................Passed
✅ constitution-compliance................Passed
[main abc1234] Update AAP dev instance configuration

# If hooks fail:
❌ constitution-compliance................Failed
- hook id: constitution-compliance
- exit code: 1

❌ VIOLATION: Possible secret in aap-instances/automation-controller-dev.yaml
Constitution Article V: No secrets in Git

# Fix the issue and try again
```

### Example 2: Developing Ansible Collection

```bash
cd automation-collection-example/

# Create new role
ansible-galaxy role init roles/webserver

# Develop role
vi roles/webserver/tasks/main.yml

# Run pre-commit checks manually
pre-commit run --all-files

# Commit changes
git add roles/webserver
git commit -m "Add webserver role"

# Hooks check:
# - ansible-lint (production profile)
# - yamllint
# - Python code style (if modules)
# - Module documentation
# - Secrets detection
```

### Example 3: Creating Release Manifest

```bash
cd automation-release-manifest/

# Create new manifest
vi releases/release-v1.2.0.yaml

# Run validation
pre-commit run --files releases/release-v1.2.0.yaml

# Checks:
# ✅ Valid YAML syntax
# ✅ Required fields present
# ✅ Commit SHAs are 40 characters
# ✅ Image digests in sha256: format
# ✅ Semantic versioning
# ✅ No latest/main/master references

# Commit
git add releases/release-v1.2.0.yaml
git commit -m "Release v1.2.0"
```

## Best Practices

### 1. Run Hooks Regularly

```bash
# Before starting work
pre-commit run --all-files

# Before creating PR
pre-commit run --all-files
```

### 2. Keep Hooks Updated

```bash
# Monthly or after major changes
pre-commit autoupdate
```

### 3. Add New Hooks

When adding new hooks to `.pre-commit-config.yaml`:

```bash
# Test new hook
pre-commit run <hook-id> --all-files

# Install for all developers
git add .pre-commit-config.yaml
git commit -m "Add new pre-commit hook"
```

### 4. CI Integration

Pre-commit hooks should also run in CI:

```yaml
# .github/workflows/pre-commit.yml
name: Pre-commit

on: [push, pull_request]

jobs:
  pre-commit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
      - uses: pre-commit/action@v3.0.0
```

### 5. Team Onboarding

Add to developer onboarding:

```bash
# 1. Install pre-commit
pip install pre-commit

# 2. Setup all repos
./setup-precommit-all.sh

# 3. Run initial check
cd cluster-config && pre-commit run --all-files
```

## Additional Resources

- **Pre-commit Docs**: https://pre-commit.com/
- **Ansible Lint**: https://ansible-lint.readthedocs.io/
- **YAML Lint**: https://yamllint.readthedocs.io/
- **Detect Secrets**: https://github.com/Yelp/detect-secrets
- **Gitleaks**: https://github.com/gitleaks/gitleaks

## Support

For issues with pre-commit hooks:

1. Check this guide's [Troubleshooting](#troubleshooting) section
2. Review the Constitution for compliance requirements
3. Ask in team chat or file an issue

---

**Last Updated**: 2025-10-30  
**Maintained By**: Platform Team  
**Version**: 1.0



