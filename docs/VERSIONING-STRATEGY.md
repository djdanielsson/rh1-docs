# Versioning Strategy

**Standard**: YY.MM.DD.PATCH (Calendar Versioning with Patch)

**Status**: 🟢 Active  
**Effective Date**: 2025-01-05  
**Applies To**: All repositories and components

---

## Overview

This platform uses **YY.MM.DD.PATCH** versioning across all components. This format provides:

- ✅ **Instant Date Visibility** - Know exactly when something was released
- ✅ **Hotfix Support** - PATCH allows multiple releases per day
- ✅ **Consistency** - Single format across all repos
- ✅ **Simplicity** - No subjective decisions about version bumps
- ✅ **Ops-Friendly** - Clear for deployment tracking

---

## Version Format

```
YY.MM.DD.PATCH
```

### Components

| Component | Description | Values | Example |
|-----------|-------------|--------|---------|
| **YY** | Two-digit year | `00-99` | `25` (2025) |
| **MM** | Two-digit month | `01-12` | `01` (January) |
| **DD** | Two-digit day | `01-31` | `05` (5th) |
| **PATCH** | Patch/hotfix number | `0-N` | `0` (first), `1` (hotfix) |

### Examples

```
25.01.05.0    # January 5, 2025 - Initial release
25.01.05.1    # January 5, 2025 - Hotfix 1
25.01.05.2    # January 5, 2025 - Hotfix 2
25.01.06.0    # January 6, 2025 - New release
25.02.15.0    # February 15, 2025 - New release
26.01.01.0    # January 1, 2026 - New year
```

---

## Git Tag Format

**Simple, unified format across all environments:**

```
YY.MM.DD.PATCH
```

**Examples:**
```bash
25.01.05.0    # Initial release
25.01.05.1    # Hotfix 1
25.01.05.2    # Hotfix 2
25.01.06.0    # Next day release
25.02.15.0    # February release
```

**Key Points:**
- ✅ **Same tag used across all environments** (dev, qa, prod)
- ✅ **Promotes atomically** - one tag, multiple environments
- ✅ **Simplified management** - no environment-specific tags
- ✅ **Clear promotion path** - track which version is where via release manifest

### Tag Characteristics

**All Tags:**
- Created manually when ready for release
- Immutable (never deleted or moved)
- Used across dev → qa → prod promotion
- Triggers deployment pipelines based on environment config

---

## Version Bumping Rules

### New Release (PATCH = 0)

Start a new version when:
- New day begins
- New features are ready
- Starting fresh deployment cycle

```bash
# Today is January 5, 2025
git tag qa-25.01.05.0 -m "Release January 5, 2025"
```

### Hotfix (PATCH++)

Increment PATCH when:
- Fixing bugs in same-day release
- Emergency patches needed
- Multiple releases same day

```bash
# Same day, need a hotfix
git tag prod-25.01.05.1 -m "Hotfix: Critical security patch"
git tag prod-25.01.05.2 -m "Hotfix: Additional fix"
```

### Next Day

Always start with PATCH=0 on new calendar date:

```bash
# January 6, 2025 - back to .0
git tag qa-25.01.06.0 -m "Release January 6, 2025"
```

---

## Component Versioning

All components use the same YY.MM.DD.PATCH format:

### 1. Ansible Collections

```yaml
# galaxy.yml
namespace: myorg
name: custom_collection
version: "25.01.05.0"
```

**Update Process:**
```bash
# Edit galaxy.yml
version: "25.01.06.0"

# Build collection
ansible-galaxy collection build

# Publish
ansible-galaxy collection publish myorg-custom_collection-25.01.06.0.tar.gz
```

---

### 2. Execution Environments

**Image Tags:**
```bash
quay.io/myorg/automation-ee:25.01.05.0
quay.io/myorg/automation-ee:25.01.05.1  # Hotfix
```

**With SHA Digest (recommended for prod):**
```bash
quay.io/myorg/automation-ee@sha256:abc123...
```

**AAP Configuration:**
```yaml
controller_execution_environments:
  - name: "Automation EE - 25.01.05.0"
    image: "quay.io/myorg/automation-ee:25.01.05.0"
    pull: missing
```

---

### 3. AAP Configuration (CaC)

**Git Tags:**
```bash
git tag prod-25.01.05.0
```

**AAP Project Configuration:**
```yaml
controller_projects:
  - name: "Automation Collection - Prod"
    scm_url: "https://github.com/org/aap-config-as-code"
    scm_branch: "prod-25.01.05.0"  # Specific tag
    scm_update_on_launch: false
```

---

### 4. Release Manifests

```yaml
# automation-release-manifest/releases/release-25.01.05.0.yaml
---
version: "25.01.05.0"
created: "2025-01-05T10:00:00Z"
created_by: "platform-team"
description: "Production release January 5, 2025"

components:
  aap_configuration:
    repository: "https://github.com/org/aap-config-as-code.git"
    commit: "abc123def456..."
    tag: "prod-25.01.05.0"

  collections:
    namespace: "myorg"
    name: "custom_collection"
    version: "25.01.05.0"
    tag: "25.01.05.0"
    commit: "def456abc123..."

  execution_environment:
    registry: "quay.io"
    repository: "myorg/automation-ee"
    tag: "25.01.05.0"
    digest: "sha256:fedcba987654..."

environments:
  qa:
    deployed: "2025-01-05T09:00:00Z"
    validated: true
  prod:
    deployed: "2025-01-05T10:00:00Z"
    validated: true
```

---

## Workflow Examples

### Standard Release Flow

```bash
# === Day 1: January 5, 2025 ===

# 1. Developer merges feature to main
git checkout main
git pull

# 2. Create release tag
git tag -a 25.01.05.0 -m "Release January 5, 2025

Features:
- Add monitoring role
- Update database backup

Tests: All molecule tests passed"
git push origin 25.01.05.0

# 3. Tag triggers deployment to Dev automatically
# Dev environment deploys and tests

# 4. After dev validation, promote to QA
# Update release manifest to mark deployed to QA
# QA pipeline deploys same tag (25.01.05.0) to QA

# 5. QA team validates
# Runs smoke tests, integration tests

# 6. After QA approval, promote to production
# Update release manifest with CAB approval
# Production pipeline deploys same tag (25.01.05.0) to prod

# 7. Production deployed successfully
```

---

### Hotfix Flow (Same Day)

```bash
# === Still January 5, 2025 ===

# Issue found in production
# 25.01.05.0 has a bug

# 1. Create hotfix branch
git checkout -b hotfix/critical-fix 25.01.05.0

# 2. Fix the issue
git commit -m "fix: correct port binding in webserver"

# 3. Merge to main
git checkout main
git merge hotfix/critical-fix

# 4. Create hotfix tag (increment PATCH)
git tag -a 25.01.05.1 -m "Hotfix 1 - Fix port binding

Issue: Port binding error in webserver
Fix: Correct port configuration
Emergency CAB: CHG0001235"
git push origin 25.01.05.1

# 5. Deploy to dev first for quick validation
# Then promote through QA → prod with same tag

# 6. Multiple hotfixes same day? Keep incrementing PATCH
git tag -a 25.01.05.2 -m "Hotfix 2 - Additional fix"
```

---

### Next Day Release

```bash
# === Day 2: January 6, 2025 ===

# New day = new version with PATCH=0

git tag -a 25.01.06.0 -m "Release January 6, 2025

Features:
- Database optimization
- New logging features"
git push origin 25.01.06.0

# Same tag promotes through all environments
```

---

## Synchronization Across Components

**All components must use the same date-based version:**

```yaml
# ✅ CORRECT - All components synchronized
Release: 25.01.05.0
  ├── AAP Config Tag:   25.01.05.0
  ├── Collection:       25.01.05.0
  ├── EE Image:         25.01.05.0
  └── Git Commit:       abc123...

# ❌ WRONG - Mismatched versions
Release: 25.01.05.0
  ├── AAP Config Tag:   25.01.05.0
  ├── Collection:       25.01.04.0  # ❌ Wrong date
  ├── EE Image:         25.01.05.1  # ❌ Wrong patch
  └── Git Commit:       abc123...
```

---

## Automation and Tooling

### Automatic Version Generation

**Script to generate current version:**

```bash
#!/bin/bash
# automation-release-manifest/scripts/generate-version.sh

PATCH=${1:-0}  # Default to 0 if not provided

# Generate YY.MM.DD
VERSION=$(date +"%y.%m.%d")

# Append PATCH
FULL_VERSION="${VERSION}.${PATCH}"

echo "${FULL_VERSION}"

# Example usage:
# ./generate-version.sh     # Output: 25.01.05.0
# ./generate-version.sh 1   # Output: 25.01.05.1
```

**Located in**: `automation-release-manifest/scripts/generate-version.sh`

---

### CI/CD Pipeline Integration

**Tekton Pipeline Parameter:**

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: build-and-deploy
spec:
  params:
    - name: version
      description: "Version in YY.MM.DD.PATCH format"
      default: "$(date +%y.%m.%d).0"
```

---

### Tag Validation Regex

```bash
# Regex for YY.MM.DD.PATCH
^[0-9]{2}\.(0[1-9]|1[0-2])\.(0[1-9]|[12][0-9]|3[01])\.[0-9]+$

# Examples that match:
# 25.01.05.0 ✅
# 25.12.31.99 ✅
# 26.02.29.0 ✅

# Examples that don't match:
# 25.1.5.0 ❌ (missing leading zeros)
# 25.13.01.0 ❌ (invalid month)
# 25.01.32.0 ❌ (invalid day)
```

**Validation Script:**

```bash
#!/bin/bash
# automation-release-manifest/scripts/validate-version.sh

VERSION=$1

if [[ ! "$VERSION" =~ ^[0-9]{2}\.(0[1-9]|1[0-2])\.(0[1-9]|[12][0-9]|3[01])\.[0-9]+$ ]]; then
  echo "❌ Invalid version format: $VERSION"
  echo "Expected: YY.MM.DD.PATCH (e.g., 25.01.05.0)"
  exit 1
fi

echo "✅ Valid version: $VERSION"
```

**Located in**: `automation-release-manifest/scripts/validate-version.sh`

---

## Rollback Strategy

Rollback to a previous version by using its tag:

```bash
# Current: 25.01.05.1 (has issues)
# Previous: 25.01.05.0 (known good)

# Option 1: Point to previous tag in release manifest
# Update release manifest to deploy 25.01.05.0 to prod
# This is fast but doesn't create audit trail in git tags

# Option 2: Create new rollback release (recommended for audit trail)
git tag -a 25.01.06.0 -m "Rollback to 25.01.05.0 state

Rolled back from: 25.01.05.1
Reason: Critical issue in webserver
Based on commit: <sha-of-25.01.05.0>
Rollback approved: CHG0001236"

# The new release (25.01.06.0) points to same commit as 25.01.05.0
# This creates a clear audit trail
```

---

## Best Practices

### 1. Always Use Full Format

```bash
# ✅ GOOD
25.01.05.0

# ❌ BAD
25.1.5.0     # Missing leading zeros
25.01.05     # Missing PATCH
```

---

### 2. Meaningful Tag Messages

```bash
# ✅ GOOD
git tag -a 25.01.05.0 -m "Release January 5, 2025

Features:
- Monitoring role with Prometheus
- Database backup automation

Testing:
- All molecule tests passed
- Security scan: PASS
- Performance test: PASS

Approvals:
- QA: Jane Doe (2025-01-05)
- Security: John Smith (2025-01-05)
- CAB: CHG0001234

Rollback: Revert to 25.01.04.0 if issues"

# ❌ BAD
git tag 25.01.05.0  # No message
```

---

### 3. Document PATCH Increments

Track why PATCH was incremented:

```bash
git tag -a 25.01.05.1 -m "Hotfix 1: Fix port binding issue

Parent: 25.01.05.0
Issue: JIRA-1234
Emergency CAB: CHG0001235"
```

---

### 4. Synchronize All Components

Before tagging, ensure all components are ready:

```bash
# Checklist before creating release tag:
# [ ] Collection galaxy.yml updated to 25.01.05.0
# [ ] EE built with tag 25.01.05.0
# [ ] Release manifest created with version 25.01.05.0
# [ ] All tests passed
# [ ] Approvals obtained

# Then tag:
git tag prod-25.01.05.0
```

---

### 5. Use Scripts for Consistency

```bash
# automation-release-manifest/scripts/create-release-tag.sh
#!/bin/bash
set -e

PATCH=${1:-0}
MESSAGE=$2

# Generate version
VERSION=$(date +"%y.%m.%d").${PATCH}

# Check if tag exists
if git rev-parse "$VERSION" >/dev/null 2>&1; then
  echo "❌ Tag already exists: $VERSION"
  echo "Use: $0 $((PATCH + 1)) to create hotfix"
  exit 1
fi

echo "Creating tag: ${VERSION}"

if [ -z "$MESSAGE" ]; then
  git tag -a "${VERSION}" -m "Release ${VERSION}"
else
  git tag -a "${VERSION}" -m "${MESSAGE}"
fi

git push origin "${VERSION}"

echo "✅ Created and pushed tag: ${VERSION}"
```

**Located in**: `automation-release-manifest/scripts/create-release-tag.sh`

---

## Migration from SemVer

### Existing Tags

**Old tags remain unchanged** - no need to delete or recreate:

```bash
# Old tags (keep as-is)
v1.0.0
v1.1.0
qa-v1.1.0
prod-v1.0.0

# New tags (use new format going forward)
25.01.05.0
25.01.06.0
```

### Mapping Strategy

For reference, here's how old versions might map:

| Old SemVer | New CalVer | Date |
|------------|------------|------|
| `v1.0.0` | `25.01.05.0` | First release under new scheme |
| `v1.0.1` | `25.01.05.1` | Hotfix |
| `v1.1.0` | `25.01.15.0` | Next feature (new day) |
| `v2.0.0` | Document as breaking in release notes |

### Communicating Breaking Changes

Without MAJOR version, document breaking changes clearly:

```bash
git tag -a 25.02.01.0 -m "⚠️  BREAKING CHANGES ⚠️

This release contains breaking changes:
- Removed deprecated inventory format
- Changed role variable names
- Requires Ansible Core 2.16+

See CHANGELOG.md for migration guide
Migration window: 2 weeks"
```

---

## Troubleshooting

### Wrong Date Used

```bash
# If you tagged with wrong date (e.g., typo)
# Do NOT move tag - create new one with correct date

# Wrong
git tag 25.01.05.0  # Oops, today is Jan 6

# Correct approach
git tag -d 25.01.05.0  # Delete local only (if not pushed)
git tag 25.01.06.0     # Create correct tag

# If already pushed (don't delete remote tags!)
# Just create a new one:
git tag 25.01.06.0 -m "Correct date release (supersedes 25.01.05.0)"
```

---

### Multiple Releases Per Day

Perfectly fine - use PATCH:

```bash
25.01.05.0   # Morning release
25.01.05.1   # Afternoon hotfix
25.01.05.2   # Evening additional fix
```

---

### Forgot to Increment PATCH

```bash
# Cannot reuse same tag
# Create next PATCH number

# Already have: 25.01.05.0
# Need another same day: 25.01.05.1
git tag 25.01.05.1 -m "Additional release (missed PATCH increment)"
```

---

## FAQs

### Q: What about breaking changes?

**A:** Document breaking changes prominently in:
- Git tag message (use ⚠️ WARNING)
- CHANGELOG
- Release notes
- Release manifest metadata

---

### Q: Can I skip days?

**A:** Yes, version = release date, not sequential days.

```bash
# January 5 release
25.01.05.0

# Next release is January 10 (skipped 6-9)
25.01.10.0
```

---

### Q: What about year 2000 problem?

**A:** Two-digit year works until 2099. For year 2100+, update format to YYYY.MM.DD.PATCH.

---

### Q: How do I compare versions?

**A:** Lexicographic sorting works:

```bash
# Correct sort order
25.01.05.0
25.01.05.1
25.01.06.0
25.02.01.0
26.01.01.0
```

---

### Q: What if I release multiple components on different days?

**A:** Wait until all components are ready, then use release date for all:

```bash
# Collect changes over week, then release all together
git tag 25.01.05.0  # Release date: Jan 5
# Even if some code was written Jan 2-4
```

---

## References

- **CalVer Spec**: https://calver.org/
- **Ubuntu Versioning**: https://ubuntu.com/about/release-cycle
- **pip Versioning**: https://pip.pypa.io/en/stable/news/
- **Branching Strategy**: [BRANCHING-STRATEGY.md](./BRANCHING-STRATEGY.md)
- **EE Versioning**: [EE-VERSIONING-STRATEGY.md](./EE-VERSIONING-STRATEGY.md)

---

**Version**: 1.0  
**Effective**: 2025-01-05  
**Last Updated**: 2025-01-05  
**Status**: 🟢 Active

