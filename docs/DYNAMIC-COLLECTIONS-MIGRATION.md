# Dynamic Collections Architecture - Migration Guide

**Architecture Change: From Embedded Collections to Dynamic Collection Management**

---

## Overview

This document describes the architectural change from building Ansible collections into Execution Environments (EE) to dynamically pulling collections at runtime using `requirements.yml` files in the playbooks repository.

## Benefits of Dynamic Collection Management

### Time Savings
- **Before**: Collection update requires 15-20 minute EE rebuild
- **After**: Collection update requires 1 minute requirements.yml update
- **Savings**: ~95% reduction in collection update time

### Reduced Complexity
- **Before**: Manage separate EE images for each collection version
- **After**: Single EE image with dynamic collection management
- **Benefit**: Fewer EE versions to track and maintain

### Improved Flexibility
- **Before**: All environments must use same collection versions (tied to EE)
- **After**: Different environments can use different collection versions via playbooks repo tags
- **Benefit**: More granular control over environment-specific versions

### Separation of Concerns
- **Before**: EE contains both infrastructure (Python/system packages) AND application logic (collections)
- **After**: EE contains only infrastructure, collections are application-specific
- **Benefit**: Clearer responsibility boundaries

---

## What Changed

### Execution Environment (EE) Repository

**File: `automation-ee-example/requirements.yml`**

**Before** (Collections built into EE):
```yaml
collections:
  - name: ansible.posix
    version: "1.5.4"
  - name: community.general
    version: "8.1.0"
  - name: myorg.custom_collection
    version: "1.1.0"
  - name: community.postgresql
    version: "2.4.0"
```

**After** (Only base infrastructure collections):
```yaml
collections:
  - name: ansible.posix
    version: "1.5.4"
  - name: ansible.utils
    version: "3.1.0"
  # Application collections moved to playbooks repo
```

### Playbooks Repository

**File: `automation-playbooks/requirements.yml`** (NEW)

```yaml
---
collections:
  # Custom organization collections
  - name: myorg.custom_collection
    version: "1.1.0"
    source: https://galaxy.ansible.com
  
  # Or from private automation hub
  - name: myorg.internal_collection
    version: "2.0.0"
    source: https://automation-hub.example.com/api/galaxy/
  
  # Community collections
  - name: community.general
    version: "8.1.0"
  
  - name: community.postgresql
    version: "2.4.0"
```

### Release Manifest

**File: `automation-release-manifest/releases/release-26.1.6-0.yaml`**

**Before**:
```yaml
components:
  execution_environment:
    image: "quay.io/org/ee@sha256:..."
    collections:
      - name: myorg.custom_collection
        version: "1.1.0"
      - name: community.general
        version: "8.1.0"
```

**After**:
```yaml
components:
  execution_environment:
    image: "quay.io/org/ee@sha256:..."
    base_collections:
      - name: ansible.posix
        version: "1.5.4"
      - name: ansible.utils
        version: "3.1.0"
  
  playbooks:
    ref: "26.1.6-0"
    collections_manifest:
      source_file: "requirements.yml"
      collections:
        - name: myorg.custom_collection
          version: "1.1.0"
        - name: community.general
          version: "8.1.0"
```

---

## Migration Steps

### Step 1: Create requirements.yml in Playbooks Repo

```bash
cd automation-playbooks

# Create requirements.yml with all application collections
cat > requirements.yml <<EOF
---
collections:
  - name: myorg.custom_collection
    version: "1.1.0"
    source: https://galaxy.ansible.com
  
  - name: community.general
    version: "8.1.0"
  
  - name: community.postgresql
    version: "2.4.0"
EOF

git add requirements.yml
git commit -m "Add dynamic collection management via requirements.yml"
git push origin main
```

### Step 2: Update EE requirements.yml

```bash
cd automation-ee-example

# Keep only base infrastructure collections
cat > requirements.yml <<EOF
---
collections:
  - name: ansible.posix
    version: "1.5.4"
  - name: ansible.utils
    version: "3.1.0"
EOF

git add requirements.yml
git commit -m "Remove application collections from EE (now in playbooks repo)"
git push origin main
```

### Step 3: Update AAP Projects

Ensure AAP projects have `scm_update_on_launch: true` so collections are refreshed:

```yaml
# File: aap-config-as-code/group_vars/aap_dev/projects.yml

controller_projects:
  - name: "Automation Playbooks"
    organization: "Platform"
    scm_type: git
    scm_url: "https://github.com/myorg/automation-playbooks.git"
    scm_branch: main
    scm_clean: true
    scm_delete_on_update: true
    scm_update_on_launch: true  # Ensures latest requirements.yml
    credential: "GitHub Token"
```

### Step 4: Test in Dev Environment

1. Sync AAP project
2. Run a job template
3. Verify collections are installed from requirements.yml:
   - Check job stdout for collection installation messages
   - Should see: "Installing collections from requirements file"

### Step 5: Update Release Manifest Template

Update your release manifest creation scripts to include the new structure:

```yaml
playbooks:
  repository: "github.com/myorg/automation-playbooks"
  ref: "{{ version_tag }}"
  commit: "{{ playbooks_commit_sha }}"
  
  collections_manifest:
    source_file: "requirements.yml"
    collections:
      # Extract from requirements.yml
```

### Step 6: Update CI/CD Pipelines

**Update EE Build Triggers** to only run when needed:

```yaml
# Only trigger EE build on these file changes:
paths:
  - 'requirements.txt'
  - 'bindep.txt'
  - 'execution-environment.yml'
# NOT on collection changes
```

---

## Verification

### Verify Collections Are Loaded Dynamically

Run a job in AAP and check the stdout:

```
TASK [Install collections] *****************************************************
changed: [localhost] => (item={'name': 'myorg.custom_collection', 'version': '1.1.0'})
changed: [localhost] => (item={'name': 'community.general', 'version': '8.1.0'})
```

### Verify EE Size Reduced

```bash
# Check EE image size before and after
podman images quay.io/myorg/automation-ee

# After removing collections, image should be smaller
```

### Verify Faster Iteration

```bash
# Time a collection update cycle:

# Before: ~20 minutes
# 1. Update collection code (2 min)
# 2. Trigger EE rebuild (15 min)
# 3. Push to registry (2 min)
# 4. Update CaC (1 min)

# After: ~3 minutes
# 1. Update collection code (2 min)
# 2. Update playbooks/requirements.yml (1 min)
# 3. Done!
```

---

## Troubleshooting

### Collection Not Found

**Issue**: Job fails with "Collection not found"

**Solution**:
1. Check `requirements.yml` exists in playbooks repo root
2. Verify collection name is correct: `namespace.name`
3. Ensure collection version exists on Galaxy/automation hub
4. Check AAP organization has Galaxy credentials configured

### Wrong Collection Version Used

**Issue**: Job uses wrong collection version

**Solution**:
1. Verify AAP project uses correct Git branch/tag
2. Check requirements.yml at that specific branch/tag
3. Ensure project sync ran successfully
4. Clear project cache if needed

### EE Rebuild Triggered Unnecessarily

**Issue**: EE rebuilds on every collection change

**Solution**:
1. Update CI/CD pipeline triggers
2. Only trigger on `requirements.txt`, `bindep.txt`, or `execution-environment.yml` changes
3. Do NOT trigger on collection repository changes

---

## Rollback Plan

If issues occur, you can temporarily revert:

1. **Re-add collections to EE requirements.yml**
2. **Rebuild EE with collections embedded**
3. **Remove requirements.yml from playbooks repo**
4. **Revert release manifest format**

However, this is not recommended as it loses all the benefits.

---

## FAQ

### Q: When should I rebuild the EE now?

**A**: Only when:
- Python package dependencies change (`requirements.txt`)
- System package dependencies change (`bindep.txt`)
- Base image updates (`execution-environment.yml`)
- Ansible core version changes

NOT when:
- Collections are updated
- Collection versions change

### Q: Can I mix embedded and dynamic collections?

**A**: Technically yes, but not recommended. Choose one approach:
- **Embedded**: All collections in EE (old way)
- **Dynamic**: All application collections in playbooks repo (new way)

You can keep base infrastructure collections in the EE.

### Q: What about private collections?

**A**: Same approach - specify private automation hub in requirements.yml:

```yaml
collections:
  - name: myorg.internal_collection
    version: "2.0.0"
    source: https://automation-hub.example.com/api/galaxy/
```

Ensure AAP organization has automation hub credentials configured.

### Q: How do I roll back collection versions?

**A**: 
1. Update `requirements.yml` with previous version
2. Commit and push
3. AAP will install the specified version at next job run

For atomic rollback across all components, use Git tags:
```bash
git checkout 26.1.5-0  # Previous release
# requirements.yml now at previous version
```

### Q: Does this work with Ansible Galaxy?

**A**: Yes! AAP automatically installs collections from:
- Public Ansible Galaxy (galaxy.ansible.com)
- Private automation hub (specify URL in requirements.yml)
- Git repositories (specify git URL)

### Q: What about collection dependencies?

**A**: AAP handles dependencies automatically. When you specify a collection in requirements.yml, AAP installs all its dependencies as defined in the collection's `galaxy.yml`.

---

## Related Documentation

- [PLATFORM-GUIDE.md](./PLATFORM-GUIDE.md) - Updated workflow
- [EE-VERSIONING-STRATEGY.md](./EE-VERSIONING-STRATEGY.md) - New EE versioning approach
- [ANSIBLE-BEST-PRACTICES.md](./ANSIBLE-BEST-PRACTICES.md) - Collection management best practices
- [TROUBLESHOOTING-GUIDE.md](./TROUBLESHOOTING-GUIDE.md) - Collection troubleshooting

---

## Summary

This architectural change significantly improves the development workflow by:

✅ **Reducing EE rebuild frequency by ~95%**  
✅ **Enabling faster iteration cycles (minutes vs. hours)**  
✅ **Providing better separation between infrastructure and application logic**  
✅ **Allowing environment-specific collection versions**  
✅ **Simplifying rollback procedures**  

The migration is straightforward and can be completed in less than an hour with minimal disruption.
