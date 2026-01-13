

# CI/CD Guide

**Comprehensive guide to CI/CD workflows across all repositories**

---

## 🚀 Quick Start

### Overview

- **15 workflows** across 6 repositories
- **GitHub Actions** for testing & linting (quality gates)
- **Tekton Pipelines** for building & releasing (handled on cluster)
- **Average PR validation**: <5 minutes

### What Runs Where

**GitHub Actions** (Testing Only):
- ✅ Pre-commit validation
- ✅ Linting (ansible-lint, yamllint, Python)
- ✅ Testing (sanity, units, integration, Molecule)
- ✅ Security scanning (secrets, vulnerabilities)
- ✅ PR validation and auto-labeling

**Tekton Pipelines** (Building & Releasing):
- 🏗️ Build collections
- 🐳 Build execution environments
- 📦 Create release manifests
- 🚀 Publish to registries (Galaxy, Quay.io)
- ⬆️ Promote between environments

### Key Workflows Per Repository

| Repository | Workflows | Key Actions |
|------------|-----------|-------------|
| **cluster-config** | 5 | Kubernetes validation, ArgoCD checks, Tekton validation |
| **aap-config-as-code** | 5 | Ansible-lint, playbook syntax, idempotency |
| **automation-collection** | 5 | Sanity tests, unit tests, integration tests, Molecule |
| **automation-ee** | 4 | EE validation, SBOM generation, security scanning |
| **automation-release-manifest** | 3 | Manifest validation, semver checks |

### Quick Commands

```bash
# Manually trigger workflow
gh workflow run <workflow-name>

# Check workflow status
gh run list --workflow=<workflow-name>

# View workflow logs
gh run view <run-id> --log
```

---

## Overview

Each repository in the Cloud-Native Ansible Lifecycle platform has tailored GitHub Actions workflows that enforce quality, security, and constitutional compliance.

### Philosophy

- **Shift-Left Testing**: Catch issues early in development
- **Fast Feedback**: <5 minutes for PR validation
- **Constitutional Enforcement**: Automated compliance checks
- **Security First**: Multiple layers of security scanning
- **Comprehensive Testing**: Unit, integration, Molecule tests

### Workflow Triggers

| Trigger | Purpose | Runs On |
|---------|---------|---------|
| `push` | Validate all commits | All branches |
| `pull_request` | PR validation and reporting | Main/master |
| `workflow_dispatch` | Manual execution | Any time |
| `schedule` | Periodic tasks (dependency updates) | Weekly |
| `release` (tags) | Build and publish releases | Version tags |

## Workflow Matrix

### cluster-config (Platform GitOps)

| Workflow | Triggers | Purpose | Duration |
|----------|----------|---------|----------|
| **pre-commit.yml** | push, PR | Pre-commit hooks | ~2 min |
| **validate-kubernetes.yml** | push, PR | K8s resource validation | ~3 min |
| **pr-validation.yml** | PR | PR checks and reporting | ~2 min |
| **auto-label.yml** | PR | Automatic labeling | <1 min |
| **dependency-update.yml** | schedule, manual | Update dependencies | ~3 min |

**Key Features**:
- Kubernetes YAML validation (kubeval)
- ArgoCD application validation
- Tekton pipeline checks
- Constitutional compliance (no secrets, no :latest in prod)
- RBAC least privilege checks

### aap-config-as-code (AAP Configuration)

| Workflow | Triggers | Purpose | Duration |
|----------|----------|---------|----------|
| **pre-commit.yml** | push, PR | Pre-commit hooks | ~2 min |
| **ansible-lint.yml** | push, PR | Ansible linting (production profile) | ~2 min |
| **pr-validation.yml** | PR | PR validation | ~3 min |
| **deploy-dev.yml** | manual | Deploy to AAP Dev | ~5 min |
| **auto-label.yml** | PR | Automatic labeling | <1 min |

**Key Features**:
- Ansible-lint production profile
- Playbook syntax validation
- Inventory validation
- No plain secrets check
- Environment-specific validation
- Idempotency checks

### automation-collection-example (Ansible Collection)

| Workflow | Triggers | Purpose | Duration |
|----------|----------|---------|----------|
| **pre-commit.yml** | push, PR | Pre-commit hooks | ~3 min |
| **ansible-test.yml** | push, PR | Ansible + Python tests | ~5 min |
| **molecule-test.yml** | push, PR, manual | Molecule testing | ~10 min |
| **pr-validation.yml** | PR | Collection validation | ~2 min |
| **release.yml** | tags, manual | Build and release collection | ~5 min |
| **auto-label.yml** | PR | Automatic labeling | <1 min |

**Key Features**:
- Ansible-lint + Python linting (black, isort, flake8, pylint)
- Bandit security scanning
- Ansible sanity tests
- Molecule tests (all scenarios)
- Unit tests with coverage
- Collection build and publish
- Version consistency checks

### automation-ee-example (Execution Environment)

| Workflow | Triggers | Purpose | Duration |
|----------|----------|---------|----------|
| **pre-commit.yml** | push, PR | Pre-commit hooks | ~2 min |
| **validate-ee.yml** | push, PR | EE definition validation | ~3 min |
| **build-ee.yml** | push, PR, manual | Build EE image | ~15 min |
| **release-ee.yml** | tags, manual | Release EE to registry | ~20 min |
| **auto-label.yml** | PR | Automatic labeling | <1 min |

**Key Features**:
- ansible-builder validation
- Version pinning checks
- Base image validation
- Image security scanning (Trivy)
- Build and push to Quay.io
- Image digest tracking

### automation-release-manifest (Release Management)

| Workflow | Triggers | Purpose | Duration |
|----------|----------|---------|----------|
| **pre-commit.yml** | push, PR | Pre-commit hooks | ~2 min |
| **validate-manifest.yml** | push, PR | Manifest validation | ~2 min |
| **create-release.yml** | tags, manual | Create release | ~3 min |
| **auto-label.yml** | PR | Automatic labeling | <1 min |

**Key Features**:
- Manifest structure validation
- Commit SHA format validation (40 chars)
- Image digest validation (sha256:...)
- Semantic versioning checks
- No :latest/:main/:master in production
- Duplicate version detection

## Repository-Specific Workflows

### 1. cluster-config Workflows

#### Pre-commit (`pre-commit.yml`)

```yaml
on: [push, pull_request]
```

**What it does**:
- Runs all pre-commit hooks
- YAML linting
- Secret detection (detect-secrets + gitleaks)
- Constitutional compliance checks

**Constitutional Compliance**:
- ✅ Article V: No secrets in Git
- ✅ Article IV: Production-grade quality

#### Validate Kubernetes (`validate-kubernetes.yml`)

```yaml
on:
  push:
    paths: ['aap-instances/**', 'argocd/**', 'tekton/**']
```

**What it does**:
- Validates Kubernetes YAML syntax
- Runs kubeval on resources
- Validates ArgoCD applications
- Checks for secrets
- Constitutional compliance (no :latest in prod)

**Constitutional Compliance**:
- ✅ Article III: No :latest tags in production
- ✅ Article V: Least privilege RBAC

#### PR Validation (`pr-validation.yml`)

```yaml
on:
  pull_request:
    branches: [main, master]
```

**What it does**:
- Lists changed files
- Checks PR size
- Validates PR title (semantic)
- Checks documentation updates
- Approval checks
- Merge conflict detection

### 2. aap-config-as-code Workflows

#### Ansible Lint (`ansible-lint.yml`)

```yaml
on:
  push:
    paths: ['**/*.yml', '**/*.yaml']
```

**What it does**:
- Runs ansible-lint with production profile
- Syntax checks all playbooks
- Validates inventory
- Generates lint reports

**Constitutional Compliance**:
- ✅ Article IV: Production-grade quality
- ✅ Idempotency enforced

#### PR Validation (`pr-validation.yml`)

**What it does**:
- Detects environment changes (dev/qa/prod)
- Checks for hardcoded secrets
- Validates AAP config structure
- Idempotency checks
- Production safety checks

**Production Safety**:
- Extra checks for prod changes
- Requires approval comments
- Checks for test data in prod config

#### Deploy to Dev (`deploy-dev.yml`)

```yaml
on: workflow_dispatch
```

**Manual deployment workflow** (template):
- Requires confirmation input
- Supports dry-run mode
- Connects to AAP Dev
- Runs playbook with dispatch role

**Note**: In production, use Tekton pipelines triggered by webhooks.

### 3. automation-collection-example Workflows

#### Ansible Test (`ansible-test.yml`)

**What it does**:
- **Ansible Lint**: Production profile
- **Python Lint**: black, isort, flake8, pylint
- **Sanity Tests**: ansible-test sanity
- **Unit Tests**: pytest with coverage
- **Build Collection**: Creates tarball artifact

#### Molecule Test (`molecule-test.yml`)

**What it does**:
- Discovers all Molecule scenarios
- Runs tests in parallel (matrix strategy)
- Tests all roles
- Generates test summary

**Performance**:
- Parallel execution for speed
- fail-fast: false (test all scenarios)

#### Release (`release.yml`)

```yaml
on:
  push:
    tags: ['v*.*.*']
```

**What it does**:
- Validates version (galaxy.yml vs tag)
- Builds collection
- Tests installation
- Extracts changelog
- Creates GitHub release
- (Optional) Publishes to Ansible Galaxy

**Constitutional Compliance**:
- ✅ Article III: Version locked
- ✅ Article IV: All tests passed

### 4. automation-ee-example Workflows

#### Validate EE (`validate-ee.yml`)

**What it does**:
- Validates execution-environment.yml
- Checks for required files
- Validates version pinning (collections + Python)
- Checks base image (official AAP images)
- YAML structure validation

#### Build EE (`build-ee.yml`)

**What it does**:
- Builds EE with ansible-builder
- Sets dynamic tags (dev-SHA, pr-NUMBER)
- Tests built image
- Security scanning with Trivy
- Saves image artifact
- (Optional) Pushes to Quay.io

**Tagging Strategy**:
- `dev-<sha>` for main branch
- `pr-<number>` for PRs
- `test-<timestamp>` for manual runs

#### Release EE (`release-ee.yml`)

```yaml
on:
  push:
    tags: ['v*.*.*']
```

**What it does**:
- Builds EE with version tag
- Tests image
- Captures image digest
- Pushes to Quay.io (version + latest)
- Creates GitHub release with digest

**Constitutional Compliance**:
- ✅ Article III: Image digest captured
- ✅ Article V: Security scanned

### 5. automation-release-manifest Workflows

#### Validate Manifest (`validate-manifest.yml`)

**What it does**:
- Validates YAML syntax
- Checks manifest structure (required fields)
- Validates semantic versioning
- Checks for duplicate versions
- Validates commit SHA format (40 chars)
- Validates image digest format (sha256:...)
- Production safety (no :latest/:main/:master)
- Validates helper scripts

**Constitutional Compliance**:
- ✅ Article III: Atomic promotion enforced
- ✅ Full commit SHAs required
- ✅ Image digests required

#### Create Release (`create-release.yml`)

```yaml
on:
  push:
    tags: ['v*.*.*']
  workflow_dispatch:
```

**What it does**:
- Validates release inputs
- Creates manifest file
- Validates created manifest
- Commits and pushes manifest
- Creates GitHub release

**Manual Dispatch Inputs**:
- `version`: Release version
- `aap_config_commit`: Full 40-char SHA
- `collection_commit`: Full 40-char SHA
- `ee_image_digest`: sha256:... digest

## Secrets Management

### Required Secrets

Each repository requires certain secrets configured in GitHub Settings → Secrets and variables → Actions.

#### cluster-config

No secrets required (validation only).

#### aap-config-as-code

For manual deployment workflow (optional):
- `AAP_DEV_HOST`: AAP Dev URL
- `AAP_DEV_USERNAME`: AAP Dev username
- `AAP_DEV_PASSWORD`: AAP Dev password

#### automation-collection-example

For Ansible Galaxy publish (optional):
- `GALAXY_API_KEY`: Ansible Galaxy API key

#### automation-ee-example

For image push:
- `QUAY_USERNAME`: Quay.io username
- `QUAY_PASSWORD`: Quay.io password/token

#### automation-release-manifest

No additional secrets (uses default `GITHUB_TOKEN`).

### Setting Secrets

```bash
# Using GitHub CLI
gh secret set QUAY_USERNAME --body "your-username" --repo owner/repo
gh secret set QUAY_PASSWORD --body "your-token" --repo owner/repo

# Or via GitHub UI:
# Repository → Settings → Secrets and variables → Actions → New repository secret
```

### Constitutional Compliance

✅ **Article V**: Secrets stored in GitHub, never in code
✅ Referenced at runtime only
✅ No secrets in any YAML files

## Badge Configuration

Add workflow status badges to README.md files:

### Syntax

```markdown
![Workflow Name](https://github.com/OWNER/REPO/actions/workflows/WORKFLOW_FILE/badge.svg)
```

### Examples

#### cluster-config

```markdown
![Pre-commit](https://github.com/djdanielsson/rh1-cluster-config/actions/workflows/pre-commit.yml/badge.svg)
![Validate K8s](https://github.com/djdanielsson/rh1-cluster-config/actions/workflows/validate-kubernetes.yml/badge.svg)
```

#### aap-config-as-code

```markdown
![Pre-commit](https://github.com/djdanielsson/rh1-aap-config-as-code/actions/workflows/pre-commit.yml/badge.svg)
![Ansible Lint](https://github.com/djdanielsson/rh1-aap-config-as-code/actions/workflows/ansible-lint.yml/badge.svg)
```

#### automation-collection-example

```markdown
![Tests](https://github.com/djdanielsson/rh1-custom-collection/actions/workflows/ansible-test.yml/badge.svg)
![Molecule](https://github.com/djdanielsson/rh1-custom-collection/actions/workflows/molecule-test.yml/badge.svg)
```

## Troubleshooting

### Common Issues

#### 1. Pre-commit Hook Failures

**Problem**: Pre-commit checks fail in CI but pass locally

**Solution**:
```bash
# Update pre-commit hooks
pre-commit autoupdate

# Run with same version as CI
pre-commit run --all-files

# Check Python version matches CI
python --version  # Should be 3.11
```

#### 2. Secrets Not Found

**Problem**: `Error: Secret QUAY_PASSWORD not found`

**Solution**:
```bash
# List secrets
gh secret list --repo owner/repo

# Set missing secret
gh secret set QUAY_PASSWORD --repo owner/repo
```

#### 3. Permission Denied

**Problem**: `Error: Resource not accessible by integration`

**Solution**:
- Check workflow permissions in repository settings
- Ensure `GITHUB_TOKEN` has required permissions
- Add permissions block to workflow:

```yaml
permissions:
  contents: write
  pull-requests: write
```

#### 4. Workflow Not Triggering

**Problem**: Push doesn't trigger workflow

**Solution**:
- Check `paths` filter matches changed files
- Ensure branch name matches trigger
- Check if workflows are enabled in repo settings

#### 5. Matrix Job Failures

**Problem**: One matrix job fails, others succeed

**Solution**:
- Check specific job logs
- Test locally with same parameters
- Consider `fail-fast: false` for debugging

### Debugging Workflows

#### Enable Debug Logging

Set repository secrets:
- `ACTIONS_RUNNER_DEBUG`: `true`
- `ACTIONS_STEP_DEBUG`: `true`

#### Re-run with Debug

```bash
# Using GitHub CLI
gh run rerun <run-id> --debug

# Or via UI: Actions → Select run → Re-run jobs → Enable debug logging
```

#### View Logs

```bash
# List workflow runs
gh run list --workflow=pre-commit.yml

# View specific run
gh run view <run-id> --log

# Download logs
gh run download <run-id>
```

### Performance Optimization

#### Cache Dependencies

All workflows use caching for speed:

```yaml
- name: Cache pre-commit
  uses: actions/cache@v3
  with:
    path: ~/.cache/pre-commit
    key: pre-commit-${{ hashFiles('.pre-commit-config.yaml') }}
```

#### Parallel Jobs

Use matrix strategy for parallel execution:

```yaml
strategy:
  matrix:
    scenario: [default, centos, ubuntu]
  fail-fast: false
```

#### Conditional Execution

Skip jobs when not needed:

```yaml
on:
  push:
    paths:
      - 'roles/**'  # Only run if roles changed
```

## Best Practices

### 1. PR Workflow

```
Developer:
1. Create feature branch
2. Make changes
3. Run pre-commit locally
4. Push branch
5. Create PR

CI:
1. Pre-commit checks ✓
2. Linting ✓
3. Tests ✓
4. Security scans ✓
5. Auto-label

Reviewer:
1. Review code
2. Check CI status
3. Approve or request changes

Merge:
1. All checks pass
2. Approvals received
3. Squash and merge
```

### 2. Release Workflow

```
1. Ensure all tests pass on main
2. Update version in metadata files
3. Update CHANGELOG
4. Create release tag (26.1.5-0)
5. CI builds and publishes
6. Create release manifest
7. Promote to QA
8. Validate in QA
9. Promote to Prod
```

### 3. Constitutional Compliance

Every workflow enforces:
- ✅ **Article I**: GitOps First - All config in Git
- ✅ **Article III**: Atomic Promotion - Version locking
- ✅ **Article IV**: Production Quality - Comprehensive testing
- ✅ **Article V**: Zero Trust - No secrets, security scanning

## Links

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Pre-commit Hooks Guide](./PRE-COMMIT-SETUP.md)
- [Project Specification](../.specify/memory/specification.md)
- [Constitution](../.specify/memory/constitution.md)
