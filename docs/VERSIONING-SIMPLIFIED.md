# Simplified Versioning: YY.MM.DD.PATCH

**Single Tag Across All Environments** 🎯

---

## Key Decision: No Environment Prefixes

Instead of:
```bash
❌ dev-25.01.05.0
❌ qa-25.01.05.0  
❌ prod-25.01.05.0
```

We use:
```bash
✅ 25.01.05.0  # Same tag for all environments
```

---

## Benefits

### 1. **Massive Simplification**
- **One tag instead of three** per release
- Reduces tag sprawl by 66%
- Clearer git tag history

### 2. **True Atomic Promotion**
- Same artifact promoted through all environments
- No risk of environment-specific builds
- Genuine "promote what was tested"

### 3. **Simpler Mental Model**
- Tag = release version
- Environment = deployment state (tracked in release manifest)
- No confusion about which tag belongs where

### 4. **Easier Rollback**
- One version to track
- Release manifest shows where it's deployed
- Simple to see version history

---

## How It Works

### Creating a Release

```bash
# 1. Create ONE tag
git tag -a 25.01.05.0 -m "Release January 5, 2025

Features:
- Monitoring role
- Database backup

Tests: All passed"

git push origin 25.01.05.0

# That's it! No separate qa- or prod- tags needed
```

### Promoting Through Environments

**Promotion is managed via Release Manifest, not separate tags:**

```yaml
# automation-release-manifest/releases/release-25.01.05.0.yaml
version: "25.01.05.0"
created: "2025-01-05T10:00:00Z"

components:
  aap_configuration:
    tag: "25.01.05.0"  # Single tag reference
    
environments:
  dev:
    deployed_at: "2025-01-05T09:00:00Z"
    deployed_by: "tekton-pipeline"
    
  qa:
    deployed_at: "2025-01-05T11:00:00Z"
    deployed_by: "release-team"
    validated: true
    validated_by: "qa-team"
    
  prod:
    deployed_at: "2025-01-05T15:00:00Z"
    deployed_by: "release-manager"
    approved_by: "CAB"
    approved_at: "2025-01-05T14:00:00Z"
    change_ticket: "CHG0001234"
```

**The release manifest tracks WHERE the tag is deployed, not the tag itself.**

---

## Workflow

### Standard Release

```bash
# Day 1: Create release
git tag -a 25.01.05.0 -m "Release description"
git push origin 25.01.05.0

# Pipeline automatically:
# 1. Deploys to Dev → test
# 2. After validation, deploys to QA → test
# 3. After approval, deploys to Prod

# All using the SAME tag: 25.01.05.0
```

### Hotfix

```bash
# Same day hotfix - increment PATCH
git tag -a 25.01.05.1 -m "Hotfix: Fix port binding"
git push origin 25.01.05.1

# Promotes through same pipeline
# Replaces 25.01.05.0 in all environments
```

### Next Day

```bash
# New day = new version, PATCH back to 0
git tag -a 25.01.06.0 -m "Release description"
git push origin 25.01.06.0
```

---

## AAP Configuration

All environments reference the same tag:

```yaml
# Dev Environment
controller_projects:
  - name: "Automation Collection - Dev"
    scm_branch: "25.01.05.0"  # Same tag
    
# QA Environment  
controller_projects:
  - name: "Automation Collection - QA"
    scm_branch: "25.01.05.0"  # Same tag
    
# Prod Environment
controller_projects:
  - name: "Automation Collection - Prod"
    scm_branch: "25.01.05.0"  # Same tag
```

**Each environment just points to a different AAP controller, but uses the same code version.**

---

## Git Tag History (Simplified)

### Old Way (Environment Prefixes)
```bash
$ git tag --list
dev-25.01.05.0-abc1234
qa-25.01.05.0
prod-25.01.05.0
dev-25.01.05.1-def5678
qa-25.01.05.1
prod-25.01.05.1
dev-25.01.06.0-ghi9012
qa-25.01.06.0
prod-25.01.06.0
# 9 tags for 3 releases!
```

### New Way (Single Tag)
```bash
$ git tag --list
25.01.05.0
25.01.05.1
25.01.06.0
# 3 tags for 3 releases!
```

---

## Pipeline Behavior

### Tag Trigger

```yaml
# Tekton EventListener
apiVersion: triggers.tekton.dev/v1beta1
kind: TriggerBinding
metadata:
  name: git-tag-binding
spec:
  params:
    - name: git-tag
      value: $(body.ref)  # e.g., refs/tags/25.01.05.0
```

### Deployment Logic

```yaml
# Pipeline decides target environment based on:
# 1. Current deployment state (from release manifest)
# 2. Manual approval gates
# 3. Test results

# NOT based on tag prefix (because there isn't one!)
```

### Example Pipeline

```yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: deploy-release
spec:
  params:
    - name: version  # e.g., "25.01.05.0"
    
  tasks:
    - name: deploy-dev
      # Deploy to dev automatically
      
    - name: test-dev
      runAfter: [deploy-dev]
      # Run tests in dev
      
    - name: deploy-qa
      runAfter: [test-dev]
      when:
        - input: "$(tasks.test-dev.results.status)"
          operator: in
          values: ["passed"]
      # Deploy to QA after dev tests pass
      
    - name: test-qa
      runAfter: [deploy-qa]
      # Run tests in QA
      
    - name: deploy-prod
      runAfter: [test-qa]
      when:
        - input: "$(tasks.test-qa.results.status)"
          operator: in
          values: ["passed"]
        - input: "$(params.approved)"
          operator: in
          values: ["true"]
      # Deploy to prod after QA tests + approval
```

---

## Tracking Deployment Status

### Query: "What's deployed where?"

```bash
# Check release manifest
cat automation-release-manifest/releases/release-25.01.05.0.yaml

# See environments section:
environments:
  dev: 
    deployed_at: "2025-01-05T09:00:00Z"
  qa:
    deployed_at: "2025-01-05T11:00:00Z"
  prod:
    deployed_at: null  # Not yet deployed
```

### Query: "What's the current prod version?"

```bash
# Check prod AAP project configuration
# OR check latest release manifest with prod.deployed_at set

# Find most recent prod deployment
ls -t automation-release-manifest/releases/*.yaml | \
  xargs -I {} sh -c 'yq eval ".environments.prod.deployed_at" {} | grep -v null && echo {}'
```

---

## Migration Impact

### What Changes

1. **Git tags** - No more `dev-`, `qa-`, `prod-` prefixes
2. **CI/CD pipelines** - Update tag regex validation
3. **Documentation** - Reflect single-tag approach
4. **Scripts** - Simplified (already updated!)

### What Doesn't Change

1. **Version format** - Still YY.MM.DD.PATCH
2. **Release manifest** - Still tracks everything
3. **Promotion flow** - Still dev → qa → prod
4. **Approval gates** - Still required for prod

---

## FAQs

### Q: How do I know if a tag is "ready" for prod?

**A:** Check the release manifest `environments.prod.approved` field.

### Q: Can I have different code in dev vs prod?

**A:** No - that's the point! Same tag = same code everywhere = true promotion.

### Q: What if I want to test something only in dev?

**A:** Use a branch, not a tag. Tags are for releases that go through full promotion.

### Q: How do I see what's in prod right now?

**A:** Check AAP prod project `scm_branch` setting, or query release manifest.

### Q: What if qa and prod get out of sync?

**A:** They can't - they both use tags. Update AAP project `scm_branch` to align.

---

## Quick Reference

```bash
# All scripts located in automation-release-manifest/scripts/

# Create release
cd automation-release-manifest
./scripts/create-release-tag.sh        # 25.01.05.0

# Create hotfix
./scripts/create-release-tag.sh 1      # 25.01.05.1

# Validate version
./scripts/validate-version.sh 25.01.05.0

# Check what's deployed
yq eval '.environments' releases/release-25.01.05.0.yaml
```

---

## Summary

| Aspect | Old (Env Prefixes) | New (Single Tag) |
|--------|-------------------|------------------|
| **Tags per release** | 3 (dev, qa, prod) | 1 |
| **Tag format** | `env-YY.MM.DD.PATCH` | `YY.MM.DD.PATCH` |
| **Promotion** | Create new tag per env | Update manifest |
| **Atomic** | Separate builds possible | Truly atomic |
| **Complexity** | Higher | Lower |
| **Audit trail** | Git tags | Release manifest |

---

**Decision**: Single Tag Approach ✅  
**Effective**: 2025-01-05  
**Simplicity**: Maximum 🎯

