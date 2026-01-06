# Git Workflow & Versioning

**Trunk-Based Development with CalVer Tags**

---

## Overview

This platform uses **Trunk-Based Development** with **CalVer (YY.MM.DD.PATCH)** for release management.

- ✅ **Single source of truth** - One `main` branch
- ✅ **Instant date visibility** - Know when something was released
- ✅ **Atomic promotion** - Same tag promotes through all environments
- ✅ **Easy rollback** - Revert to any previous tag

---

## Version Format

```
YY.MM.DD.PATCH
```

| Component | Description | Example |
|-----------|-------------|---------|
| YY | Two-digit year | `25` (2025) |
| MM | Two-digit month | `01` (January) |
| DD | Two-digit day | `05` (5th) |
| PATCH | Hotfix number | `0` (first), `1` (hotfix) |

### Examples

```
25.01.05.0    # January 5, 2025 - Initial
25.01.05.1    # Same day hotfix
25.01.06.0    # Next day release
```

### Rules

| Scenario | Action |
|----------|--------|
| New release | Today's date, PATCH=0 |
| Same-day hotfix | Increment PATCH |
| Next day | New date, PATCH=0 |

---

## Branch Structure

### Main Branch

- **No direct commits** (except initial setup)
- All changes via Pull Request
- Must pass CI/CD checks
- Always releasable

### Feature Branches

**Naming**: `feature/<description>` or `feat/<description>`

**Lifespan**: Short-lived (hours to days)

```bash
git checkout -b feature/add-webserver-role main
# ... develop ...
git push origin feature/add-webserver-role
# Create PR, merge, delete branch
```

### Hotfix Branches

```bash
git checkout -b hotfix/critical-fix 25.01.05.0
git commit -m "fix: patch vulnerability"
git checkout main && git merge hotfix/critical-fix
git tag -a 25.01.05.1 -m "Hotfix: security patch"
git push origin 25.01.05.1
```

---

## Git Tags

### Single Tag Across Environments

**One tag promotes through dev → qa → prod:**

| Environment | Tag |
|-------------|-----|
| Dev | `25.01.05.0` |
| QA | `25.01.05.0` (same) |
| Prod | `25.01.05.0` (same) |

### Tag Rules

- ✅ Created when ready for release
- ✅ **IMMUTABLE** - never deleted or moved
- ✅ Same tag across all environments
- ❌ Never force-push or reuse tags

---

## Promotion Workflow

```
Feature Branch → Main → Tag → Dev → QA → Prod
```

### 1. Development

```bash
git tag -a 25.01.05.0 -m "Release January 5, 2025"
git push origin 25.01.05.0
# Auto-deploys to dev
```

### 2. QA Promotion

```bash
tkn pipeline start promote \
  -p VERSION=25.01.05.0 \
  -p FROM_ENVIRONMENT=dev \
  -p TO_ENVIRONMENT=qa
```

### 3. Production Promotion

```bash
tkn pipeline start promote \
  -p VERSION=25.01.05.0 \
  -p FROM_ENVIRONMENT=qa \
  -p TO_ENVIRONMENT=prod
```

**Production Gates**: QA sign-off, security scan, CAB approval

---

## Component Versioning

All components use the same `YY.MM.DD.PATCH` format:

### Ansible Collections

```yaml
# galaxy.yml
version: "25.01.05.0"
```

### Execution Environments

```bash
quay.io/myorg/automation-ee:25.01.05.0

# With digest (recommended for prod)
quay.io/myorg/automation-ee@sha256:abc123...
```

### AAP Configuration

```yaml
controller_projects:
  - name: "Automation Collection - Prod"
    scm_branch: "25.01.05.0"  # Specific tag, not main
    scm_update_on_launch: false
```

### Release Manifests

```yaml
version: "25.01.05.0"
components:
  aap_configuration:
    commit: "abc123..."
    tag: "25.01.05.0"
  execution_environment:
    tag: "25.01.05.0"
    digest: "sha256:fedcba..."
```

---

## Execution Environment Versioning

### Core Principle

> **Every code release tag has a corresponding EE image tag**

```
Code Tag: 25.01.05.0  →  EE Image: my-registry/ee:25.01.05.0
```

### Tag Types

| Type | Format | Mutable? | Use |
|------|--------|----------|-----|
| Version | `25.01.05.0` | No | All environments |
| SHA | `sha-abc123` | No | Traceability |
| dev-latest | `dev-latest` | Yes | Dev only |

### EE Build Process

```bash
# Build with version tag
ansible-builder build \
  --tag "quay.io/myorg/automation-ee:${VERSION}" \
  --tag "quay.io/myorg/automation-ee:sha-$(git rev-parse HEAD)"

podman push "quay.io/myorg/automation-ee:${VERSION}"
```

### AAP EE Configuration

```yaml
# Lock to specific version
controller_execution_environments:
  - name: "Automation EE - 25.01.05.0"
    image: "quay.io/myorg/automation-ee:25.01.05.0"
    # Or use digest
    # image: "quay.io/myorg/automation-ee@sha256:abc123..."
    pull: "missing"

controller_templates:
  - name: "Deploy Webserver - Prod"
    scm_branch: "25.01.05.0"  # Match code version
    execution_environment: "Automation EE - 25.01.05.0"
```

### Pin Dependencies

```yaml
# requirements.yml - Always pin versions
collections:
  - name: ansible.posix
    version: "1.5.4"

# requirements.txt - Always pin versions
jmespath==1.0.1
netaddr==0.9.0
```

---

## Rollback

### Using Tekton Pipeline

```bash
tkn pipeline start rollback \
  -p TARGET_VERSION=25.01.04.0 \
  -p ENVIRONMENT=prod
```

### Using Git

```bash
# Create new tag pointing to previous state
git tag -a 25.01.06.0 -m "Rollback to 25.01.05.0 state"
```

---

## Complete Workflow Example

```bash
# 1. Create feature branch
git checkout main && git pull
git checkout -b feature/add-webserver-role

# 2. Develop and test
molecule test

# 3. Push and create PR
git push origin feature/add-webserver-role
gh pr create --title "Add webserver role"

# 4. After approval, merge
gh pr merge --squash

# 5. Create release tag
git checkout main && git pull
git tag -a 25.01.05.0 -m "Release: Add webserver role"
git push origin 25.01.05.0

# 6. Promote to QA
tkn pipeline start promote -p VERSION=25.01.05.0 -p FROM=dev -p TO=qa

# 7. After QA validation, promote to prod
tkn pipeline start promote -p VERSION=25.01.05.0 -p FROM=qa -p TO=prod
```

---

## Anti-Patterns

| Anti-Pattern | Instead |
|--------------|---------|
| Long-lived branches (dev, qa, prod) | main + tags |
| `:latest` in production | Specific version tags |
| Moving/deleting tags | Create new PATCH version |
| Mismatched code/EE versions | Same tag for both |
| Unpinned dependencies | Always pin versions |

---

## Best Practices

1. **Keep branches short-lived** (<2 days)
2. **Write meaningful tag messages** with features and rollback info
3. **Always use full format** (`25.01.05.0` not `25.1.5`)
4. **Match EE to code version**
5. **Use digests in production**
6. **Test EE before promotion**

---

## References

- [CalVer](https://calver.org/)
- [Trunk-Based Development](https://trunkbaseddevelopment.com/)
- [Git Tagging](https://git-scm.com/book/en/v2/Git-Basics-Tagging)
