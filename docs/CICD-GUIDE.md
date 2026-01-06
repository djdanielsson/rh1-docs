# CI/CD & Pre-commit Guide

Complete guide to quality automation: pre-commit hooks, GitHub Actions, and Tekton pipelines.

---

## Quick Start

### Pre-commit Setup

```bash
pip install pre-commit yamllint ansible-lint
pre-commit install
pre-commit run --all-files
```

### Useful Aliases

```bash
alias pc='pre-commit run --all-files'
alias pci='pre-commit install'
alias pcu='pre-commit autoupdate'
```

---

## Overview

| Layer | Tool | Purpose |
|-------|------|---------|
| **Local** | Pre-commit | Immediate feedback before commit |
| **PR** | GitHub Actions | Testing, linting, validation |
| **Build/Release** | Tekton | Build EE, apply CaC, promote |

### What Runs Where

**GitHub Actions** (Testing Only):
- Pre-commit validation
- Linting (ansible-lint, yamllint, Python)
- Testing (sanity, units, integration, Molecule)
- Security scanning (secrets, vulnerabilities)

**Tekton Pipelines** (Building & Releasing):
- Build collections and execution environments
- Create release manifests
- Publish to registries
- Promote between environments

---

## Pre-commit Hooks

### Installation

```bash
pip install pre-commit yamllint ansible-lint
pip install black isort flake8 pylint bandit  # For Python
pip install detect-secrets                      # Security

# Optional
brew install gitleaks shellcheck kubeval
```

### Setup

```bash
cd <repository>
pre-commit install
pre-commit install --hook-type commit-msg
pre-commit run --all-files  # Verify setup
```

### Repository-Specific Hooks

| Repository | Key Checks |
|------------|------------|
| **cluster-config** | K8s YAML, ArgoCD, Tekton, no secrets, RBAC |
| **aap-config-as-code** | Ansible syntax, idempotency, no secrets |
| **automation-collection** | Python linting, Ansible lint, Molecule |
| **automation-ee** | EE structure, version pinning, no :latest |
| **automation-release-manifest** | Manifest structure, commit SHAs, digests |

### Common Fixes

```bash
# YAML formatting
yamllint --config-file=.yamllint . --format auto

# Ansible lint (auto-fix)
ansible-lint --fix

# Python formatting
black --line-length=100 .
isort --profile black --line-length=100 .

# Check playbook syntax
ansible-playbook --syntax-check playbook.yml
```

### Skip Hooks (Emergency Only)

```bash
git commit --no-verify -m "Emergency fix"     # Skip all
SKIP=ansible-lint git commit -m "Fix"         # Skip specific
SKIP=ansible-lint,yamllint git commit -m "X"  # Skip multiple
```

---

## GitHub Actions Workflows

### Workflow Matrix by Repository

| Repository | Workflows | Key Actions |
|------------|-----------|-------------|
| **cluster-config** | 5 | K8s validation, ArgoCD checks, Tekton validation |
| **aap-config-as-code** | 5 | Ansible-lint, syntax, idempotency |
| **automation-collection** | 5 | Sanity, unit, integration, Molecule |
| **automation-ee** | 4 | EE validation, security scanning |
| **automation-release-manifest** | 3 | Manifest validation, semver checks |

### Common Workflow Triggers

| Trigger | Purpose |
|---------|---------|
| `push` | Validate all commits |
| `pull_request` | PR validation |
| `workflow_dispatch` | Manual execution |
| `schedule` | Periodic (dependency updates) |
| `release` (tags) | Build and publish |

### Quick Commands

```bash
gh workflow run <workflow-name>
gh run list --workflow=<workflow-name>
gh run view <run-id> --log
```

### Key Workflows

#### cluster-config
- `pre-commit.yml` - Hooks validation
- `validate-kubernetes.yml` - K8s resource validation
- `pr-validation.yml` - PR checks
- `auto-label.yml` - Automatic labeling

#### automation-collection
- `ansible-test.yml` - Lint, sanity, unit tests
- `molecule-test.yml` - Role testing
- `release.yml` - Build and publish collection

#### automation-ee
- `validate-ee.yml` - EE definition validation
- `build-ee.yml` - Build image with security scan
- `release-ee.yml` - Release to registry

---

## Tekton Pipelines

### Pipeline Types

| Pipeline | Trigger | Purpose |
|----------|---------|---------|
| **CaC Pipeline** | Webhook | Apply AAP configuration |
| **PR Validation** | PR webhook | Test changes |
| **Inner Loop** | Dev push | Quick feedback |
| **Promotion** | Tag/manual | Move to QA/Prod |

### Quick Commands

```bash
# Create release
tkn pipeline start create-release -p VERSION=25.01.05.0

# Promote
tkn pipeline start promote -p VERSION=25.01.05.0 \
  -p FROM_ENVIRONMENT=dev -p TO_ENVIRONMENT=qa

# Rollback
tkn pipeline start rollback -p TARGET_VERSION=25.01.04.0 \
  -p ENVIRONMENT=prod

# View logs
tkn pipelinerun logs <run-name> -n dev-tools -f

# Cancel
tkn pipelinerun cancel <run-name> -n dev-tools
```

---

## Secrets Management

### Required Secrets by Repository

| Repository | Secrets | Purpose |
|------------|---------|---------|
| cluster-config | None | Validation only |
| aap-config-as-code | `AAP_*` | Manual deployment (optional) |
| automation-collection | `GALAXY_API_KEY` | Galaxy publish |
| automation-ee | `QUAY_*` | Registry push |
| automation-release-manifest | None | Uses GITHUB_TOKEN |

### Setting Secrets

```bash
gh secret set QUAY_USERNAME --body "your-username" --repo owner/repo
gh secret set QUAY_PASSWORD --body "your-token" --repo owner/repo
```

---

## Troubleshooting

### Pre-commit Issues

| Issue | Solution |
|-------|----------|
| Hook installation failed | `pre-commit clean && pre-commit install --install-hooks` |
| Cache issues | `rm -rf ~/.cache/pre-commit/` |
| Hook takes too long | `time pre-commit run --all-files --verbose` |

### GitHub Actions Issues

| Issue | Solution |
|-------|----------|
| Secrets not found | `gh secret list --repo owner/repo` |
| Permission denied | Add `permissions:` block to workflow |
| Not triggering | Check `paths` filter, branch name, repo settings |

### Debugging

```bash
# Enable debug logging (set as repo secrets)
ACTIONS_RUNNER_DEBUG: true
ACTIONS_STEP_DEBUG: true

# Re-run with debug
gh run rerun <run-id> --debug
```

---

## Best Practices

### PR Workflow

1. Create feature branch
2. Run `pre-commit run --all-files` locally
3. Push and create PR
4. CI runs all checks
5. Review → Approve → Squash merge

### Release Workflow

1. Ensure all tests pass on main
2. Update version in metadata files
3. Update CHANGELOG
4. Create release tag (`YY.MM.DD.PATCH`)
5. CI builds and publishes
6. Promote: dev → qa → prod

### Constitutional Compliance

All workflows enforce:
- ✅ **Article I**: GitOps First - All config in Git
- ✅ **Article III**: Atomic Promotion - Version locking
- ✅ **Article IV**: Production Quality - Comprehensive testing
- ✅ **Article V**: Zero Trust - No secrets, security scanning

---

## Badge Configuration

```markdown
![Pre-commit](https://github.com/OWNER/REPO/actions/workflows/pre-commit.yml/badge.svg)
![Tests](https://github.com/OWNER/REPO/actions/workflows/ansible-test.yml/badge.svg)
```

---

## References

- [GitHub Actions Docs](https://docs.github.com/en/actions)
- [Pre-commit Docs](https://pre-commit.com/)
- [Tekton Docs](https://tekton.dev/docs/)
