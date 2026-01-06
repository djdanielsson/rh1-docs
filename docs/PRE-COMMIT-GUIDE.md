# Pre-commit Hooks Guide

**Complete guide to pre-commit hooks across all repositories**

---

## 🚀 Quick Start

### Quick Commands

```bash
# Install in current repo
pre-commit install

# Run all hooks on all files
pre-commit run --all-files

# Run specific hook
pre-commit run <hook-id> --all-files

# Update hook versions
pre-commit autoupdate

# Skip hooks (emergency only!)
git commit --no-verify
```

### Useful Aliases

Add to your `.bashrc` or `.zshrc`:

```bash
# Pre-commit aliases
alias pc='pre-commit run --all-files'
alias pci='pre-commit install'
alias pcu='pre-commit autoupdate'
alias pcr='pre-commit run'

# Git with pre-commit
alias gpc='git add -A && pre-commit run'
```

---

## Overview

Pre-commit hooks enforce code quality, security, and constitutional compliance **before** code is committed to Git.

### Benefits

- ✅ **No secrets in Git** (Article V)
- ✅ **Code quality** (Article IV)
- ✅ **Consistent formatting** (Article IV)
- ✅ **Security scanning** (Article V)
- ✅ **Syntax validation** (Article IV)

### Repository-Specific Checks

| Repository | Key Checks |
|------------|------------|
| **cluster-config** | Kubernetes YAML, ArgoCD apps, Tekton pipelines, no secrets, RBAC checks |
| **aap-config-as-code** | Ansible syntax, idempotency, no plain secrets, naming conventions |
| **automation-collection-example** | Python linting, Ansible lint, module docs, Molecule tests |
| **automation-ee-example** | EE structure, version pinning, no latest tags, bindep validation |
| **automation-release-manifest** | Manifest structure, commit SHAs, image digests, semver |

---

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

```bash
# YAML and Ansible tools
pip install yamllint ansible-lint

# Python code quality tools (for collection development)
pip install black isort flake8 pylint bandit

# Security scanning tools
pip install detect-secrets

# Install gitleaks (secrets scanner)
brew install gitleaks  # macOS
# Linux: https://github.com/gitleaks/gitleaks#installing
```

### 3. Optional Tools

```bash
# Kubernetes validation (for cluster-config)
brew install kubeval

# Tekton CLI (for cluster-config)
brew install tektoncd-cli

# Ansible builder (for automation-ee)
pip install ansible-builder

# Shell script linting
brew install shellcheck
```

---

## Repository Setup

### Setup for Each Repository

Run this in **each repository directory**:

```bash
# Navigate to repository
cd cluster-config/  # or other repo

# Install pre-commit hooks
pre-commit install

# Install commit-msg hook (for conventional commits)
pre-commit install --hook-type commit-msg

# Optional: Run once to verify
pre-commit run --all-files
```

## Repository-Specific Hooks

### cluster-config (Platform GitOps)

**Focus**: Kubernetes resources, ArgoCD, Tekton

| Hook | What It Checks | Fix |
|------|---------------|-----|
| `check-yaml` | YAML syntax | Fix YAML syntax errors |
| `yamllint` | YAML formatting | Follow `.yamllint` rules |
| `kubeval` | Kubernetes resource validity | Fix invalid K8s resources |
| `detect-secrets` | Secrets in code | Remove secrets, use K8s Secrets |
| `gitleaks` | Leaked credentials | Remove credentials |
| `no-latest-tags` | No :latest in prod | Pin specific versions |
| `rbac-check` | Least privilege RBAC | Reduce permissions |

**Common Fixes**:
```bash
# Fix YAML formatting
yamllint --config-file=.yamllint . --format auto

# Check ArgoCD apps manually
for f in argocd/applications/*.yaml; do
  kubectl apply --dry-run=client -f $f
done
```

---

### aap-config-as-code (AAP Configuration)

**Focus**: Ansible playbooks, group_vars

| Hook | What It Checks | Fix |
|------|---------------|-----|
| `ansible-lint` | Ansible best practices | Follow ansible-lint rules |
| `yamllint` | YAML formatting | Fix YAML issues |
| `no-secrets-in-vars` | Plain secrets in vars | Use {{ lookup() }} |
| `playbook-syntax` | Playbook syntax | Fix Ansible syntax |
| `idempotency-check` | Task idempotency | Add creates/removes/changed_when |

**Common Fixes**:
```bash
# Fix ansible-lint issues
ansible-lint --fix

# Check playbook syntax
ansible-playbook --syntax-check playbook.yml

# Validate inventory
ansible-inventory -i inventory.yml --list
```

---

### automation-collection (Ansible Collection)

**Focus**: Roles, modules, plugins, Python code

| Hook | What It Checks | Fix |
|------|---------------|-----|
| `ansible-lint` | Ansible best practices | Follow lint rules |
| `black` | Python formatting | Run `black .` |
| `isort` | Python import sorting | Run `isort .` |
| `flake8` | Python code style | Fix PEP8 violations |
| `pylint` | Python code quality | Fix pylint issues |
| `bandit` | Python security | Fix security issues |
| `module-documentation` | Module has docs | Add DOCUMENTATION, EXAMPLES, RETURN |
| `molecule-tests` | Roles have tests | Add molecule tests |

**Common Fixes**:
```bash
# Auto-fix Python formatting
black --line-length=100 .
isort --profile black --line-length=100 .

# Run ansible-lint with auto-fix
ansible-lint --fix

# Check module documentation
grep -A5 "DOCUMENTATION = " plugins/modules/mymodule.py
```

---

### automation-ee (Execution Environment)

**Focus**: ansible-builder configuration

| Hook | What It Checks | Fix |
|------|---------------|-----|
| `ee-yaml-validation` | Valid EE definition | Fix execution-environment.yml |
| `requirements-validation` | Valid requirements.yml | Add collections key |
| `version-pinning` | Pinned versions | Add version: "x.y.z" |
| `no-latest-tags` | No :latest in base image | Use specific tag |
| `no-manual-dockerfile` | No manual Dockerfiles | Use ansible-builder |
| `ee-build-test` | EE builds successfully | Fix build errors |

**Common Fixes**:
```bash
# Test EE definition
ansible-builder create --verbosity 3

# Build EE locally
ansible-builder build -t test-ee:latest

# Validate requirements.yml
python3 -c "import yaml; print(yaml.safe_load(open('requirements.yml')))"
```

---

### automation-release-manifest (Release Manifests)

**Focus**: Release versioning, atomic promotion

| Hook | What It Checks | Fix |
|------|---------------|-----|
| `manifest-validation` | Valid manifest structure | Add required fields |
| `commit-sha-format` | 40-char commit SHAs | Use full git commit SHA |
| `image-digest-check` | sha256: digest format | Use image digest not tag |
| `semantic-version` | Semver format (x.y.z) | Use proper version |
| `no-latest-tags` | No latest/main in releases | Use commit SHAs |
| `duplicate-version` | Unique versions | Change version number |

**Common Fixes**:
```bash
# Get full commit SHA
git rev-parse HEAD

# Get image digest
podman inspect quay.io/org/image:tag --format='{{.Digest}}'

# Validate manifest structure
python3 -c "
import yaml
m = yaml.safe_load(open('releases/release-25.01.05.0.yaml'))
assert 'version' in m
assert 'components' in m
"
```

---

## Constitutional Compliance

Each hook enforces constitution articles:

### Article I: GitOps First
- All config in Git (YAML validation)
- No manual changes (prevent Dockerfiles)

### Article II: Separation of Duties
- ArgoCD for platform (K8s resources)
- Tekton for apps (AAP config)

### Article III: Atomic Promotion
- No :latest tags in prod
- Full commit SHAs (40 chars)
- Image digests required

### Article IV: Production-Grade Quality
- ansible-lint production profile
- Idempotency checks
- Documentation required
- Testing required (Molecule)

### Article V: Zero-Trust Security
- No secrets in Git (detect-secrets + gitleaks)
- No plain passwords in vars
- Security scanning (Bandit)
- Least privilege RBAC

---

## Troubleshooting

### Hook Installation Failed

```bash
pre-commit clean
pre-commit install --install-hooks
```

### Cache Issues

```bash
rm -rf ~/.cache/pre-commit/
pre-commit install --install-hooks
```

### Python Version Mismatch

```bash
# Use specific Python version
pre-commit run --hook-stage manual --all-files
```

### Hook Takes Too Long

```bash
# Check which hook is slow
time pre-commit run --all-files --verbose

# Disable slow hook temporarily
SKIP=slow-hook git commit -m "message"
```

### Fix All Auto-fixable Issues

```bash
# Run multiple times until no changes
pre-commit run --all-files
pre-commit run --all-files
```

---

## Emergency Procedures

### Skip All Hooks (Last Resort)

```bash
# Only in emergencies!
git commit --no-verify -m "Emergency fix"
```

⚠️ **Warning**: This bypasses all security checks!

### Skip Specific Hook

```bash
# Skip one hook
SKIP=ansible-lint git commit -m "Fix"

# Skip multiple hooks
SKIP=ansible-lint,yamllint git commit -m "Fix"
```

---

## Performance Tips

```bash
# Run only on changed files (faster)
pre-commit run

# Skip slow hooks during development
SKIP=ee-build-test,molecule-tests git commit -m "WIP"

# Cache results (automatic)
# Cache location: ~/.cache/pre-commit/
```

---

## CI/CD Integration

Pre-commit hooks also run in CI:

```yaml
# .github/workflows/pre-commit.yml
name: Pre-commit Checks
on: [push, pull_request]
jobs:
  pre-commit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v4
      - run: pip install pre-commit
      - run: pre-commit run --all-files --show-diff-on-failure
```

---

## Severity Levels

| Symbol | Severity | Action |
|--------|----------|--------|
| ❌ | Blocking | Must fix before commit |
| ⚠️ | Warning | Should fix, but can commit |
| ℹ️ | Info | FYI only |

---

## Links

- **Constitution**: [../.specify/memory/constitution.md](../.specify/memory/constitution.md)
- **Ansible Best Practices**: [./ANSIBLE-BEST-PRACTICES.md](./ANSIBLE-BEST-PRACTICES.md)
- **Code Style Guide**: [./CODE-STYLE-GUIDE.md](./CODE-STYLE-GUIDE.md)
- **Pre-commit Docs**: https://pre-commit.com/
