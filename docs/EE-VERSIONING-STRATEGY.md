# Execution Environment Versioning Strategy

**Immutable, Version-Locked EE Images Synchronized with Code Releases**

**Version Format**: YY.M.D-PATCH (Calendar Versioning)

---

## 🎯 Overview

Execution Environments (EE) must be **version-locked** using **YY.M.D-PATCH** format to match code release tags, ensuring that Ansible playbooks and their runtime dependencies are always synchronized.

### Core Principle

> **Every code release tag has a corresponding EE image tag using YY.M.D-PATCH format**

```
Code Tag: 26.1.5-0  →  EE Image: my-registry/my-ee:26.1.5-0
```

### Important Architectural Change

**Collections are NOT bundled inside the EE**. Instead, they are dynamically pulled at runtime using `requirements.yml` files in the playbooks repository. This means:

- ✅ **EE rebuilds only when Python packages or system dependencies change**
- ✅ **Collection updates don't require EE rebuilds**
- ✅ **Significantly reduced EE release frequency**
- ✅ **Faster iteration cycles for automation development**

**Benefits**:
- ✅ **Reproducibility**: Same runtime environment with dynamic collection management
- ✅ **Rollback Safety**: Roll back EE + playbooks (with requirements.yml) together as a unit
- ✅ **Version Clarity**: Easy to identify what's running where
- ✅ **Immutability**: Tagged images never change
- ✅ **Traceability**: Clear audit trail from code to runtime
- ✅ **Reduced Overhead**: Fewer EE rebuilds means faster development cycles

---

## 📋 Table of Contents

- [Overview](#overview)
- [Dynamic Collection Management](#dynamic-collection-management)
- [Version Tagging Convention](#version-tagging-convention)
- [Build Process](#build-process)
- [Promotion Workflow](#promotion-workflow)
- [AAP Job Template Configuration](#aap-job-template-configuration)
- [Release Manifest Integration](#release-manifest-integration)
- [CI/CD Integration](#cicd-integration)
- [Rollback Strategy](#rollback-strategy)
- [Best Practices](#best-practices)
- [Anti-Patterns](#anti-patterns)

---

## 🔄 Dynamic Collection Management

### How Collections Are Managed

Collections are **NOT** built into the Execution Environment. Instead, they are:

1. **Defined** in `automation-playbooks/requirements.yml`
2. **Version-locked** with specific version numbers
3. **Dynamically installed** by AAP at job runtime
4. **Environment-specific** via playbooks repo branches/tags

### Benefits of Dynamic Collection Management

| Benefit | Description |
|---------|-------------|
| **Reduced EE Rebuilds** | Only rebuild when Python/system deps change, not for every collection update |
| **Faster Iteration** | Update collections without waiting for EE rebuild pipeline |
| **Better Separation** | Infrastructure (EE) separate from application logic (collections) |
| **Easier Rollback** | Roll back playbooks repo to previous requirements.yml version |
| **Version Flexibility** | Different environments can use different collection versions |

### When to Rebuild the EE

| Scenario | Rebuild EE? | Action |
|----------|-------------|--------|
| Update collection version | ❌ No | Update `playbooks/requirements.yml` only |
| Add new collection | ❌ No | Add to `playbooks/requirements.yml` only |
| Update Python package | ✅ Yes | Update `ee/requirements.txt` and rebuild |
| Update system package | ✅ Yes | Update `ee/bindep.txt` and rebuild |
| Update base image | ✅ Yes | Update `ee/execution-environment.yml` and rebuild |
| Update Ansible core version | ✅ Yes | Update EE base image and rebuild |

### Workflow Comparison

**Old Way (Collections in EE)**:
```
Collection Update → EE Rebuild (15-20 min) → Push to Registry → Update CaC → Deploy
```

**New Way (Dynamic Collections)**:
```
Collection Update → Update playbooks/requirements.yml (1 min) → Deploy
```

**Time Saved**: 15-20 minutes per collection update

---

## 🏷️ Version Tagging Convention

### Tag Format

| Component | Format | Example |
|-----------|--------|---------|
| **Code Tag** | `YY.M.D-PATCH` | `26.1.5-0` |
| **EE Image** | `ee:YY.M.D-PATCH` | `quay.io/myorg/automation-ee:26.1.5-0` |

**Note**: Same tag used for both code and EE image. Same tag promotes through all environments (dev → qa → prod).

### Additional Tags

```bash
# Primary version tag (immutable)
quay.io/myorg/automation-ee:26.1.5-0

# Git commit SHA for traceability
quay.io/myorg/automation-ee:sha-abc123def456

# Convenience tags (mutable, for dev only)
quay.io/myorg/automation-ee:dev-latest      # ⚠️ Dev only, never use in QA/Prod
```

### Tag Immutability Rules

- ✅ **Version tags** (`YY.M.D-PATCH`): **IMMUTABLE** - never overwritten
- ✅ **SHA tags** (`sha-*`): **IMMUTABLE** - permanent record
- ⚠️ **Convenience tags** (`dev-latest`): **MUTABLE** - dev environment only
- ❌ **Never use** `latest` in QA or Production

---

## 🔨 Build Process

### 1. Development Build (Automatic)

**Trigger**: Merge to main branch

```bash
#!/bin/bash
# Triggered by Tekton pipeline on merge to main

# Get version
VERSION=$(date +"%y.%m.%d").0
SHA=$(git rev-parse --short HEAD)
DEV_TAG="dev-${VERSION}-${SHA}"

# Build EE with dev tag
cd automation-ee-example
ansible-builder build \
  --tag "quay.io/myorg/automation-ee:${VERSION}" \
  --tag "quay.io/myorg/automation-ee:sha-$(git rev-parse HEAD)" \
  --tag "quay.io/myorg/automation-ee:dev-latest" \
  --container-runtime podman

# Push to registry
podman push "quay.io/myorg/automation-ee:${VERSION}"
podman push "quay.io/myorg/automation-ee:sha-$(git rev-parse HEAD)"
podman push "quay.io/myorg/automation-ee:dev-latest"

echo "✅ Built and pushed EE: ${VERSION}"
```

### 2. QA Build (Manual Trigger)

**Trigger**: Git tag creation (`YY.M.D-PATCH`)

```bash
#!/bin/bash
# Triggered by Tekton pipeline on git tag creation

# Extract tag from git (e.g., 26.1.5-0)
QA_TAG="${1}"  # Passed from Tekton trigger

# Extract version from tag (remove qa- prefix)
VERSION="${QA_TAG#qa-}"

# Validate tag format
if [[ ! "${VERSION}" =~ ^[0-9]{2}\.(0[1-9]|1[0-2])\.(0[1-9]|[12][0-9]|3[01])\.[0-9]+$ ]]; then
  echo "❌ Invalid QA tag format: ${QA_TAG}"
  exit 1
fi

# Checkout the tagged commit
git checkout "${QA_TAG}"
COMMIT_SHA=$(git rev-parse HEAD)

# Build EE with version tag
cd automation-ee-example
ansible-builder build \
  --tag "quay.io/myorg/automation-ee:${VERSION}" \
  --tag "quay.io/myorg/automation-ee:sha-${COMMIT_SHA}" \
  --container-runtime podman

# Get image digest for immutability tracking
IMAGE_DIGEST=$(podman inspect "quay.io/myorg/automation-ee:${VERSION}" \
  --format '{{.Digest}}')

# Push to registry
podman push "quay.io/myorg/automation-ee:${VERSION}"
podman push "quay.io/myorg/automation-ee:sha-${COMMIT_SHA}"

echo "✅ Built and pushed EE: ${VERSION}"
echo "📦 Image Digest: ${IMAGE_DIGEST}"
```

### 3. Production Build (Manual Trigger with Approval)

**Trigger**: Promotion pipeline + CAB approval

```bash
#!/bin/bash
# Triggered by Tekton pipeline with approval gate

PROD_TAG="${1}"
APPROVAL_TICKET="${2}"  # CAB approval ticket

# Validate tag format
if [[ ! "${VERSION}" =~ ^[0-9]{2}\.[0-9]{2}\.[0-9]{2}\.[0-9]+$ ]]; then
  echo "❌ Invalid Prod tag format: ${PROD_TAG}"
  exit 1
fi

# Verify approval exists (check external system)
if ! verify_cab_approval "${APPROVAL_TICKET}"; then
  echo "❌ No CAB approval found for ${APPROVAL_TICKET}"
  exit 1
fi

# Checkout the tagged commit
git checkout "${PROD_TAG}"
COMMIT_SHA=$(git rev-parse HEAD)

# Build EE with production tag
cd automation-ee-example
ansible-builder build \
  --tag "quay.io/myorg/automation-ee:${PROD_TAG}" \
  --tag "quay.io/myorg/automation-ee:sha-${COMMIT_SHA}" \
  --container-runtime podman

# Get image digest
IMAGE_DIGEST=$(podman inspect "quay.io/myorg/automation-ee:${PROD_TAG}" \
  --format '{{.Digest}}')

# Push to registry
podman push "quay.io/myorg/automation-ee:${PROD_TAG}"
podman push "quay.io/myorg/automation-ee:sha-${COMMIT_SHA}"

# Generate SBOM (Software Bill of Materials)
syft "quay.io/myorg/automation-ee:${PROD_TAG}" \
  -o json > "sbom-${PROD_TAG}.json"

# Scan for vulnerabilities
grype "quay.io/myorg/automation-ee:${PROD_TAG}" \
  -o json > "scan-${PROD_TAG}.json"

echo "✅ Built and pushed EE: ${PROD_TAG}"
echo "📦 Image Digest: ${IMAGE_DIGEST}"
echo "🔒 Approval: ${APPROVAL_TICKET}"
```

---

## 🔄 Promotion Workflow

### Complete Flow: Code → EE → Deployment

```mermaid
graph TB
    subgraph "1. Development"
        CODE1[Merge to main<br/>commit: abc123]
        TAG_DEV[Create tag:<br/>dev-abc123]
        BUILD_DEV[Build EE:<br/>ee:dev-abc123]
        DEPLOY_DEV[Update AAP Dev<br/>Job Template]
    end

    subgraph "2. QA Promotion"
        TAG_QA[Create Git tag:<br/>26.1.5-0]
        BUILD_QA[Build EE:<br/>ee:26.1.5-0]
        MANIFEST_QA[Create Manifest:<br/>release-26.1.5-0.yaml]
        DEPLOY_QA[Update AAP QA<br/>Job Template]
        TEST_QA[QA Testing]
    end

    subgraph "3. Production Promotion"
        APPROVE[CAB Approval]
        TAG_PROD[Same tag promoted:<br/>26.1.5-0]
        BUILD_PROD[Same EE:<br/>ee:26.1.5-0]
        SBOM[Generate SBOM<br/>+ Scan]
        MANIFEST_PROD[Update Manifest:<br/>mark prod deployed]
        DEPLOY_PROD[Update AAP Prod<br/>Job Template]
    end

    CODE1 --> TAG_DEV
    TAG_DEV --> BUILD_DEV
    BUILD_DEV --> DEPLOY_DEV
    DEPLOY_DEV -->|Validated| TAG_QA

    TAG_QA --> BUILD_QA
    BUILD_QA --> MANIFEST_QA
    MANIFEST_QA --> DEPLOY_QA
    DEPLOY_QA --> TEST_QA
    TEST_QA -->|Approved| APPROVE

    APPROVE --> TAG_PROD
    TAG_PROD --> BUILD_PROD
    BUILD_PROD --> SBOM
    SBOM --> MANIFEST_PROD
    MANIFEST_PROD --> DEPLOY_PROD

    style BUILD_DEV fill:#4ecdc4
    style BUILD_QA fill:#ffd93d
    style BUILD_PROD fill:#ff6b6b
```

### Synchronization Example

```yaml
# Step 1: Developer creates Git tag
$ git tag -a 26.1.5-0 -m "Release January 5, 2025"
$ git push origin 26.1.5-0

# Step 2: Tekton pipeline triggered
#   - Builds EE with tag: ee:26.1.5-0
#   - Creates release manifest
#   - Updates AAP QA Job Templates

# Step 3: AAP Job Template (automatically updated via CaC)
---
controller_templates:
  - name: "Deploy Webserver - QA"
    project: "Automation Collection"
    project_version: "26.1.5-0"  # ← Git tag
    execution_environment: "Automation EE QA"
    # ↓ EE configured to use version-tagged image

controller_execution_environments:
  - name: "Automation EE QA"
    image: "quay.io/myorg/automation-ee:26.1.5-0"  # ← Matching EE tag
    pull: missing
```

---

## 🎮 AAP Job Template Configuration

### Version-Locked Job Template

```yaml
# File: aap-config-as-code/group_vars/aap_qa/job_templates.yml

controller_templates:
  - name: "Deploy Webserver - QA"
    description: "Deploy Apache webserver to QA environment"
    organization: "Platform"
    inventory: "QA Infrastructure"
    project: "Automation Collection"

    # ⚠️ CRITICAL: Lock to specific Git tag
    scm_branch: "26.1.5-0"  # NOT 'main', specific tag

    # ⚠️ CRITICAL: Lock to version-tagged EE
    execution_environment: "Automation EE - 26.1.5-0"

    playbook: "playbooks/deploy-webserver.yml"

    credentials:
      - "QA SSH Key"

    # Don't auto-update in QA/Prod
    ask_scm_branch_on_launch: false
    ask_execution_environment_on_launch: false
```

### Execution Environment Definition

```yaml
# File: aap-config-as-code/group_vars/aap_qa/execution_environments.yml

controller_execution_environments:
  - name: "Automation EE - 26.1.5-0"
    description: "Execution Environment (26.1.5-0)"
    organization: "Platform"

    # ⚠️ CRITICAL: Use full image path with version tag
    image: "quay.io/myorg/automation-ee:26.1.5-0"

    # Use digest for ultimate immutability (optional but recommended)
    # image: "quay.io/myorg/automation-ee@sha256:abc123..."

    credential: "Quay.io Registry"
    pull: "missing"  # Don't pull if already present
```

### Production Example with Digest

```yaml
# File: aap-config-as-code/group_vars/aap_prod/execution_environments.yml

controller_execution_environments:
  - name: "Automation EE - 26.1.4-0"
    description: "Production Execution Environment (26.1.4-0)"
    organization: "Platform"

    # Best Practice: Use image digest in production
    image: "quay.io/myorg/automation-ee@sha256:1234567890abcdef..."

    # Or version tag (also acceptable)
    # image: "quay.io/myorg/automation-ee:26.1.4-0"

    credential: "Quay.io Registry"
    pull: "missing"
```

---

## 📦 Release Manifest Integration

### Complete Release Manifest with Dynamic Collections

```yaml
# File: automation-release-manifest/releases/qa/release-26.1.5-0.yaml

version: "26.1.5-0"
created: "2025-01-04T10:30:00Z"
created_by: "tekton-pipeline"
environment: "qa"

components:
  automation_collection:
    repository: "github.com/myorg/automation-collection"
    ref_type: "tag"
    ref: "26.1.5-0"
    commit: "abc1234567890abcdef1234567890abcdef12345"
    galaxy_version: "1.1.0"  # Published to Galaxy
    galaxy_namespace: "myorg"
    galaxy_name: "custom_collection"

  execution_environment:
    name: "automation-ee"
    registry: "quay.io"
    image: "quay.io/myorg/automation-ee:26.1.5-0"
    digest: "sha256:1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
    built_at: "2025-01-04T10:25:00Z"
    base_image: "quay.io/ansible/creator-ee:v0.20.1"
    python_version: "3.11"
    ansible_core_version: "2.16.0"

    # Base collections in EE (infrastructure only)
    base_collections:
      - name: "ansible.posix"
        version: "1.5.4"
      - name: "ansible.utils"
        version: "3.1.0"

    python_packages:
      - name: "jmespath"
        version: "1.0.1"
      - name: "netaddr"
        version: "0.9.0"

    system_packages:
      - "git-2.43.0"
      - "openssh-clients-8.7"

  playbooks:
    repository: "github.com/myorg/automation-playbooks"
    ref_type: "tag"
    ref: "26.1.5-0"
    commit: "def4567890abcdef1234567890abcdef45678901"
    
    # Collections dynamically installed from requirements.yml
    collections_manifest:
      source_file: "requirements.yml"
      collections:
        - name: "myorg.custom_collection"
          version: "1.1.0"
          source: "https://galaxy.ansible.com"
        - name: "community.general"
          version: "8.1.0"
        - name: "community.postgresql"
          version: "2.4.0"

  aap_configuration:
    repository: "github.com/myorg/aap-config-as-code"
    ref_type: "tag"
    ref: "26.1.5-0"
    commit: "ghi7890abcdef1234567890abcdef45678901234"

testing:
  unit_tests: "passed"
  integration_tests: "passed"
  molecule_tests: "passed"
  security_scan: "passed"

approvals:
  - approver: "qa-lead@example.com"
    approved_at: "2025-01-04T14:30:00Z"
    ticket: "QA-1234"

artifacts:
  sbom: "https://artifactory.example.com/sbom/26.1.5-0.json"
  vulnerability_scan: "https://artifactory.example.com/scans/26.1.5-0.json"
  collection_tarball: "https://galaxy.ansible.com/myorg/custom_collection/1.1.0"
```

### Key Differences from Previous Approach

| Aspect | Old (Collections in EE) | New (Dynamic Collections) |
|--------|------------------------|---------------------------|
| **EE Collections** | All collections listed | Only base infrastructure collections |
| **Playbooks Section** | No collection info | Includes `collections_manifest` with requirements.yml content |
| **Collection Tracking** | EE digest tracks everything | Separate tracking: EE for base, playbooks for app collections |
| **Rollback** | Must match EE + playbooks | Playbooks ref includes requirements.yml version |

---

## 🔧 CI/CD Integration

### Tekton Pipeline: Build EE on Tag

```yaml
# File: cluster-config/tekton/pipelines/build-ee-on-tag.yaml

apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: build-ee-on-tag
  namespace: aap-cicd
spec:
  params:
    - name: git-tag
      description: "Git tag (e.g., 26.1.5-0)"
    - name: git-url
      default: "https://github.com/myorg/automation-ee"
    - name: image-registry
      default: "quay.io/myorg"
    - name: image-name
      default: "automation-ee"

  workspaces:
    - name: source
    - name: dockerconfig

  tasks:
    # 1. Clone repo at specific tag
    - name: git-clone
      taskRef:
        name: git-clone
      params:
        - name: url
          value: $(params.git-url)
        - name: revision
          value: $(params.git-tag)
      workspaces:
        - name: output
          workspace: source

    # 2. Validate tag format
    - name: validate-tag
      runAfter: [git-clone]
      taskSpec:
        params:
          - name: tag
        steps:
          - name: validate
            image: alpine:latest
            script: |
              #!/bin/sh
              TAG=$(params.tag)
              if [[ ! "$TAG" =~ ^(dev|qa|prod)-v?[0-9]+\.[0-9]+\.[0-9]+$ ]] && \
                 [[ ! "$TAG" =~ ^dev-[a-f0-9]+$ ]]; then
                echo "❌ Invalid tag format: $TAG"
                exit 1
              fi
              echo "✅ Valid tag: $TAG"
      params:
        - name: tag
          value: $(params.git-tag)

    # 3. Build EE with ansible-builder
    - name: build-ee
      runAfter: [validate-tag]
      taskRef:
        name: ansible-builder-build
      params:
        - name: tag
          value: "$(params.image-registry)/$(params.image-name):$(params.git-tag)"
        - name: context
          value: "automation-ee-example"
      workspaces:
        - name: source
          workspace: source

    # 4. Tag with commit SHA
    - name: tag-with-sha
      runAfter: [build-ee]
      taskSpec:
        workspaces:
          - name: source
        params:
          - name: image
          - name: registry
          - name: name
        steps:
          - name: tag
            image: quay.io/podman/stable:latest
            script: |
              #!/bin/bash
              cd $(workspaces.source.path)
              COMMIT_SHA=$(git rev-parse HEAD)
              SHA_TAG="$(params.registry)/$(params.name):sha-${COMMIT_SHA}"

              podman tag \
                "$(params.image)" \
                "${SHA_TAG}"

              echo "✅ Tagged: ${SHA_TAG}"
      params:
        - name: image
          value: "$(params.image-registry)/$(params.image-name):$(params.git-tag)"
        - name: registry
          value: $(params.image-registry)
        - name: name
          value: $(params.image-name)
      workspaces:
        - name: source
          workspace: source

    # 5. Generate SBOM
    - name: generate-sbom
      runAfter: [tag-with-sha]
      taskRef:
        name: syft-generate-sbom
      params:
        - name: image
          value: "$(params.image-registry)/$(params.image-name):$(params.git-tag)"
        - name: output-file
          value: "sbom-$(params.git-tag).json"
      workspaces:
        - name: source
          workspace: source

    # 6. Scan for vulnerabilities
    - name: scan-vulnerabilities
      runAfter: [generate-sbom]
      taskRef:
        name: grype-scan
      params:
        - name: image
          value: "$(params.image-registry)/$(params.image-name):$(params.git-tag)"
        - name: fail-on
          value: "critical"
      workspaces:
        - name: source
          workspace: source

    # 7. Push to registry
    - name: push-image
      runAfter: [scan-vulnerabilities]
      taskRef:
        name: buildah-push
      params:
        - name: image
          value: "$(params.image-registry)/$(params.image-name):$(params.git-tag)"
      workspaces:
        - name: dockerconfig
          workspace: dockerconfig

    # 8. Create release manifest
    - name: create-manifest
      runAfter: [push-image]
      taskRef:
        name: create-release-manifest
      params:
        - name: version
          value: $(params.git-tag)
        - name: ee-image
          value: "$(params.image-registry)/$(params.image-name):$(params.git-tag)"
      workspaces:
        - name: source
          workspace: source

    # 9. Update AAP via CaC
    - name: update-aap-config
      runAfter: [create-manifest]
      taskRef:
        name: run-aap-cac
      params:
        - name: environment
          value: "$(params.environment)"
        - name: version
          value: $(params.git-tag)
```

### GitHub Actions: Validate EE Definition

```yaml
# File: automation-ee-example/.github/workflows/validate-ee.yml

name: Validate EE Definition

on:
  pull_request:
    paths:
      - 'automation-ee-example/**'
  push:
    branches: [main]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install ansible-builder
        run: pip install ansible-builder

      - name: Validate execution-environment.yml
        working-directory: automation-ee-example
        run: |
          ansible-builder create --verbosity 3

      - name: Check for version pinning
        working-directory: automation-ee-example
        run: |
          # Verify all collections are version-pinned
          if grep -E "^  - [a-z]+\.[a-z]+$" requirements.yml; then
            echo "❌ Found unpinned collections"
            exit 1
          fi

          # Verify all Python packages are version-pinned
          if grep -E "^[a-z]+-*[a-z]*$" requirements.txt 2>/dev/null; then
            echo "❌ Found unpinned Python packages"
            exit 1
          fi

          echo "✅ All dependencies are version-pinned"
```

---

## ↩️ Rollback Strategy

### Rolling Back EE Version

```yaml
# Scenario: Production issue detected, rollback to previous version

# 1. Identify previous working version
$ kubectl get -n aap-prod deployments -o yaml | grep image:
# Previous: quay.io/myorg/automation-ee:26.1.4-0

# 2. Update AAP Job Template (via CaC)
# File: aap-config-as-code/group_vars/aap_prod/job_templates.yml

controller_templates:
  - name: "Deploy Webserver - Prod"
    scm_branch: "26.1.4-0"  # ← Rollback to previous tag
    execution_environment: "Automation EE - 26.1.4-0"  # ← Rollback EE

controller_execution_environments:
  - name: "Automation EE - 26.1.4-0"
    image: "quay.io/myorg/automation-ee:26.1.4-0"  # ← Previous version

# 3. Apply CaC to revert
$ cd aap-config-as-code
$ ansible-playbook playbook.yml -i inventory.yml -l aap_prod

# 4. Verify rollback
$ curl https://aap-prod.example.com/api/v2/job_templates/123/ | \
  jq '.execution_environment'
# Expected: "Automation EE - 26.1.4-0"
```

### Rollback Checklist

- [ ] Identify previous working version (Git tag + EE tag)
- [ ] Verify previous EE image still exists in registry
- [ ] Update Job Template `scm_branch` to previous tag
- [ ] Update Job Template `execution_environment` to previous EE
- [ ] Apply CaC changes
- [ ] Run smoke tests
- [ ] Monitor for 1 hour
- [ ] Document incident and rollback in post-mortem

---

## ✅ Best Practices

### 1. Always Pin Dependencies in EE Definition

**Important**: The EE `requirements.yml` should now only contain **base collections** needed for the execution environment itself (e.g., infrastructure collections like `ansible.posix`). Application-specific collections are managed in the playbooks repository `requirements.yml`.

```yaml
# File: automation-ee-example/requirements.yml

# ✅ GOOD - Base collections for EE infrastructure
collections:
  - name: ansible.posix
    version: "1.5.4"
  - name: ansible.utils
    version: "3.1.0"
  # Note: Application collections moved to playbooks repo

# ❌ BAD - Application collections should not be here
collections:
  - name: myorg.custom_collection  # Move to playbooks repo
    version: "1.1.0"
```

```yaml
# File: automation-playbooks/requirements.yml

# ✅ GOOD - Application collections with versions
collections:
  - name: myorg.custom_collection
    version: "1.1.0"
  - name: community.general
    version: "8.1.0"
  - name: community.postgresql
    version: "2.4.0"
```

```txt
# File: automation-ee-example/requirements.txt

# ✅ GOOD - Version pinned Python packages
jmespath==1.0.1
netaddr==0.9.0
python-dateutil==2.8.2

# ❌ BAD - No version
jmespath
netaddr
```

### Separation of Concerns

| File | Purpose | Managed By | Rebuild Trigger |
|------|---------|------------|-----------------|
| `automation-ee-example/requirements.yml` | Base collections for EE infrastructure | Platform team | EE rebuild |
| `automation-ee-example/requirements.txt` | Python packages | Platform team | EE rebuild |
| `automation-ee-example/bindep.txt` | System packages | Platform team | EE rebuild |
| `automation-playbooks/requirements.yml` | Application collections | App teams | No rebuild needed |

### 2. Use Image Digests in Production

```yaml
# ✅ BEST - Use digest (immutable)
image: "quay.io/myorg/automation-ee@sha256:abc123..."

# ✅ GOOD - Use version tag
image: "quay.io/myorg/automation-ee:26.1.4-0"

# ❌ BAD - Mutable tag
image: "quay.io/myorg/automation-ee:latest"
```

### 3. Match EE Tag to Code Tag

```bash
# When creating QA release
git tag 26.1.5-0
# EE must be built with matching tag
ansible-builder build -t automation-ee:26.1.5-0
```

### 4. Store SBOM and Scan Results

```yaml
# Store in release manifest
artifacts:
  sbom: "https://artifactory.example.com/sbom/26.1.5-0.json"
  vulnerability_scan: "https://artifactory.example.com/scans/26.1.5-0.json"
```

### 5. Test EE Before Promotion

```bash
# Test EE locally before promoting
podman run -it quay.io/myorg/automation-ee:26.1.5-0 /bin/bash

# Verify collections
ansible-galaxy collection list

# Verify Python packages
pip list

# Run a test playbook
ansible-playbook test-playbook.yml
```

### 6. Document EE Changes in Git Tag Message

```bash
git tag -a 26.1.4-0 -m "Production Release 1.0.0

Code Changes:
- Add webserver role

EE Changes:
- Update Python to 3.11
- Add new system package libpq-dev

Note: Collections now managed in playbooks repo requirements.yml
- No collection changes in EE
- Application collections dynamically installed at runtime

Tested: All molecule tests pass
Approved: CHG0001234"
```

### 7. Separate EE per Major Version

```yaml
# v1.x.x series
image: "quay.io/myorg/automation-ee-v1:26.1.4-0"

# v2.x.x series (breaking changes)
image: "quay.io/myorg/automation-ee-v2:26.2.1-0"
```

### 8. Automate EE Builds via Tekton

- ✅ Trigger builds on Git tag creation
- ✅ Run security scans automatically
- ✅ Generate SBOM automatically
- ✅ Update AAP configuration automatically

---

## 🚫 Anti-Patterns

### ❌ Using Mutable Tags in QA/Prod

```yaml
# BAD - 'latest' can change
execution_environment:
  image: "quay.io/myorg/automation-ee:latest"

# BAD - 'dev' tag is overwritten constantly
execution_environment:
  image: "quay.io/myorg/automation-ee:dev"
```

### ❌ Mismatched Code and EE Versions

```yaml
# BAD - Code and EE out of sync
job_template:
  scm_branch: "26.1.5-0"  # Code version 1.1.0
  execution_environment: "automation-ee:26.1.4-0"  # EE version 1.0.0 ❌
```

### ❌ Not Pinning Collection Versions

```yaml
# BAD - Will break when collection updates
# File: automation-playbooks/requirements.yml
collections:
  - name: community.general  # No version = non-reproducible
  - name: myorg.custom_collection  # No version = breaks rollback

# ✅ GOOD - Version pinned in playbooks repo
collections:
  - name: community.general
    version: "8.1.0"
  - name: myorg.custom_collection
    version: "1.1.0"
```

### ❌ Overwriting Version Tags

```bash
# BAD - Never do this!
git tag -d 26.1.4-0
git tag 26.1.4-0 <different-commit>
podman tag automation-ee:26.1.4-0 <new-image>
podman push --force automation-ee:26.1.4-0
```

### ❌ Not Tracking EE in Release Manifest

```yaml
# BAD - Incomplete manifest
components:
  automation_collection:
    tag: "26.1.5-0"
  playbooks:
    tag: "26.1.5-0"
    # ✅ Include collections requirements.yml reference
    collections_manifest: "26.1.5-0"  # Points to requirements.yml version
  # ❌ Missing EE version information
```

### ❌ Mixing Collection Management Between EE and Playbooks

```yaml
# ❌ BAD - Application collections in EE requirements.yml
# File: automation-ee-example/requirements.yml
collections:
  - name: myorg.custom_collection  # Should be in playbooks repo
    version: "1.1.0"

# ✅ GOOD - Only base collections in EE
# File: automation-ee-example/requirements.yml
collections:
  - name: ansible.posix  # Infrastructure collection
    version: "1.5.4"

# ✅ GOOD - Application collections in playbooks repo
# File: automation-playbooks/requirements.yml
collections:
  - name: myorg.custom_collection
    version: "1.1.0"
```

### ❌ Skipping Security Scans

```bash
# BAD - Deploying without scanning
ansible-builder build -t ee:26.1.4-0
podman push ee:26.1.4-0
# ❌ No SBOM, no vulnerability scan
```

---

## 📚 Related Documentation

- [Git Workflow](./GIT-WORKFLOW.md) - Branching and versioning
- [Versioning Rationale](./VERSIONING-RATIONALE.md) - Why CalVer over SemVer (pros/cons)
- [Promotion Flow Diagrams](./diagrams/PROMOTION-FLOW.md) - Visual workflows
- [CI/CD Guide](./CICD-GUIDE.md) - Build automation
- [Release Manifests](./diagrams/REPOSITORY-STRUCTURE.md) - Manifest structure
- [Validation & Quality Guide](./VALIDATION-QUALITY-GUIDE.md) - Security scanning

---

## 🎓 External Resources

- **Ansible Builder**: https://ansible.readthedocs.io/projects/builder/
- **Execution Environments**: https://docs.ansible.com/automation-controller/latest/html/userguide/execution_environments.html
- **Container Image Digests**: https://docs.docker.com/engine/reference/commandline/pull/#pull-an-image-by-digest
- **SBOM with Syft**: https://github.com/anchore/syft
- **Vulnerability Scanning with Grype**: https://github.com/anchore/grype
- **Red Hat CoP**: https://redhat-cop.github.io/automation-good-practices/
