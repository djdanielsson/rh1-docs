# Cloud-Native Ansible Lifecycle Platform

**A GitOps-driven platform for developing, testing, and promoting Ansible automation across environments.**

---

## Platform Overview

This platform implements a complete automation lifecycle using GitOps principles. Everything flows through Git—from Ansible roles and collections to AAP configuration to Kubernetes infrastructure.

### How It Works

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           PLATFORM ARCHITECTURE                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│   ┌──────────────┐         ┌──────────────┐         ┌──────────────┐        │
│   │   PLAYBOOK   │────────▶│  COLLECTION  │────────▶│  EXECUTION   │        │
│   │ (Orchestrate)│  uses   │   (Roles)    │ built   │  ENVIRONMENT │        │
│   └──────────────┘         └──────────────┘  into   │   (Runtime)  │        │
│          │                                          └──────────────┘        │
│          │                                                 │                │
│          │  referenced by                                  │  registered    │
│          │  project in AAP                                 │  in AAP        │
│          │                                                 │                │
│          │                 ┌──────────────┐                │                │
│          └────────────────▶│    AAP       │◀───────────────┘                │
│                            │   CONFIG     │                                 │
│                            │(JT+Proj+EE)  │                                 │
│                            └──────────────┘                                 │
│                                   │                                         │
│                                   ▼                                         │
│                        ┌──────────────────┐                                 │
│                        │ RELEASE MANIFEST │ ◀── Locks all versions          │
│                        │   (26.01.06.0)   │     (Playbook + Coll + EE +     │
│                        └──────────────────┘      AAP Config SHAs/digests)   │
│                                   │                                         │
│            ┌──────────────────────┼──────────────────────┐                  │
│            ▼                      ▼                      ▼                  │
│     ┌──────────────┐       ┌──────────────┐       ┌──────────────┐          │
│     │     DEV      │──────▶│     QA       │──────▶│    PROD      │          │
│     │  (auto-sync) │       │ (manual gate)│       │  (approval)  │          │
│     └──────────────┘       └──────────────┘       └──────────────┘          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

**Complete dependency tree**: [Dependency Tree](./diagrams/DEPENDENCY-TREE.md)

### Core Concepts

| Concept | Description |
|---------|-------------|
| **Dual GitOps Loops** | ArgoCD manages platform resources; Tekton manages application configuration |
| **Atomic Promotion** | All components (EE + CaC + Playbooks + Collections) promote together as one versioned unit |
| **Release Manifest** | YAML file that version-locks all component Git SHAs and image digests |
| **CalVer Versioning** | Releases use `YY.MM.DD.PATCH` format (e.g., `26.01.06.0`) |

### The Six Repositories

| Repository | Purpose | Managed By |
|------------|---------|------------|
| **cluster-config** | Platform GitOps—Kubernetes manifests, operators, AAP instances | ArgoCD |
| **aap-config-as-code** | AAP configuration—job templates, inventories, credentials, projects | Tekton |
| **automation-playbooks** | Ansible playbooks that orchestrate role execution | Tekton |
| **automation-collection-example** | Ansible content—roles, modules, plugins called by playbooks | Tekton (CI) |
| **automation-ee-example** | Execution Environment container definition | Tekton (build) |
| **automation-release-manifest** | Release version tracking and promotion pipelines | Tekton |

📘 **Detailed architecture**: [Platform Architecture](./diagrams/PLATFORM-ARCHITECTURE.md) | [Repository Structure](./diagrams/REPOSITORY-STRUCTURE.md)

---

## Building New Automation

This section walks through the complete lifecycle of creating new automation and moving it through all environments.

### Execution Environments: Dev vs Release

Before diving into the workflow, understand how EEs work across environments:

| Environment | EE Tag | Behavior |
|-------------|--------|----------|
| **Dev** | `:dev` or `:latest` | Auto-rebuilt on every collection/EE repo merge. Uses `pull: always` to get latest. |
| **QA/Prod** | `@sha256:...` (digest) | Locked to exact image digest in release manifest. Immutable. |

**Why this matters**: Collections are bundled *inside* the EE at build time. When you change a collection, you must rebuild the EE before those changes are available in AAP. In Dev, this happens automatically. For releases, the manifest locks the exact digest.

```
Collection Change → EE Rebuild → New EE Image Available → CaC references new EE
```

---

### Step 1: Develop Your Content

Create or modify roles in the `automation-collection-example` repository.

```bash
# Navigate to the collection
cd automation-collection-example

# Create a new role using ansible-creator
ansible-creator add resource role my_new_role

# This creates:
# roles/my_new_role/
#   ├── tasks/main.yml
#   ├── defaults/main.yml
#   ├── handlers/main.yml
#   ├── meta/main.yml
#   └── molecule/default/  (test scenario)
```

**Write your automation:**

```yaml
# roles/my_new_role/tasks/main.yml
---
- name: Install required packages
  ansible.builtin.package:
    name: "{{ my_new_role_packages }}"
    state: present

- name: Configure application
  ansible.builtin.template:
    src: config.j2
    dest: "{{ my_new_role_config_path }}"
  notify: restart_service
```

**Define defaults:**

```yaml
# roles/my_new_role/defaults/main.yml
---
my_new_role_packages:
  - httpd
my_new_role_config_path: /etc/httpd/conf/httpd.conf
```

📘 **More details**: [Ansible Best Practices](./ANSIBLE-BEST-PRACTICES.md) | [Code Style Guide](./CODE-STYLE-GUIDE.md) | [Naming Conventions](./NAMING-CONVENTIONS.md)

---

### Step 2: Lint Your Content

Lint immediately after writing code—catch issues early before writing tests.

```bash
cd automation-collection-example

# Run ansible-lint on your new role
ansible-lint roles/my_new_role

# Run yamllint for YAML syntax
yamllint roles/my_new_role

# Fix any issues before proceeding to tests
```

**Common issues caught at this stage:**
- Missing FQCNs (fully qualified collection names)
- Incorrect indentation
- Missing `name` on tasks
- Deprecated modules

📘 **More details**: [Pre-commit Guide](./PRE-COMMIT-GUIDE.md) | [Code Style Guide](./CODE-STYLE-GUIDE.md)

---

### Step 3: Create Molecule Tests

Every role needs Molecule tests. Write tests for your role.

```yaml
# roles/my_new_role/molecule/default/converge.yml
---
- name: Converge
  hosts: all
  tasks:
    - name: Include my_new_role
      ansible.builtin.include_role:
        name: my_new_role
```

```yaml
# roles/my_new_role/molecule/default/verify.yml
---
- name: Verify
  hosts: all
  tasks:
    - name: Check service is running
      ansible.builtin.service_facts:

    - name: Assert service is active
      ansible.builtin.assert:
        that: ansible_facts.services['httpd.service'].state == 'running'
```

📘 **More details**: [Testing Guide](./TESTING-GUIDE.md)

---

### Step 4: Lint Test Files

Lint your Molecule test files—tests are code too.

```bash
cd automation-collection-example

# Lint the molecule test playbooks
ansible-lint roles/my_new_role/molecule/

# Lint YAML syntax
yamllint roles/my_new_role/molecule/
```

**Ensure tests follow the same quality standards as the role itself.**

---

### Step 5: Run Molecule Tests

Execute Molecule tests to verify your role works correctly.

```bash
cd roles/my_new_role
molecule test

# Or step-by-step for debugging:
molecule create    # Spin up test container
molecule converge  # Run the role
molecule verify    # Run verification tests
molecule destroy   # Clean up
```

**All tests must pass before proceeding.**

📘 **More details**: [Testing Guide](./TESTING-GUIDE.md)

---

### Step 6: Final Quality Gate - Lint & Scan All

Run comprehensive linting and security scanning on the entire codebase.

```bash
cd automation-collection-example

# Run all pre-commit hooks (lint, format, scan)
pre-commit run --all-files

# This runs:
# - ansible-lint (entire collection)
# - yamllint
# - check-yaml
# - end-of-file-fixer
# - trailing-whitespace
# - detect-secrets
# - check-executables-have-shebangs
```

**Pre-commit hooks run automatically on commit**, but running manually ensures clean commits.

📘 **More details**: [Pre-commit Guide](./PRE-COMMIT-GUIDE.md) | [Validation & Quality](./VALIDATION-QUALITY-GUIDE.md)

---

### Step 7: Update Execution Environment

Since collections are bundled *inside* the EE, you must rebuild it after collection changes.

```bash
cd automation-ee-example

# The EE pulls your collection via requirements.yml
# If you added new Python deps in your role, add them:
vi requirements.txt
# Add: my-new-package>=1.0.0

# If you need system packages:
vi bindep.txt
# Add: my-system-package

# Commit and push to trigger EE rebuild
git commit -am "Update deps for my_new_role"
git push origin main

# Tekton automatically builds new EE with:
# - Your updated collection (from main branch)
# - Any new dependencies
# - Tagged as :dev for development use
```

**For Dev environment**: EE is tagged `:dev` and auto-rebuilds. AAP pulls latest on each job run.

**For Releases**: The release manifest will lock the specific `@sha256:...` digest.

📘 **More details**: [EE Versioning Strategy](./EE-VERSIONING-STRATEGY.md)

---

### Step 8: Create or Update Playbook

If you need a new playbook to orchestrate your role, create it in `automation-playbooks`.

```bash
cd automation-playbooks
vi playbooks/deploy-myapp.yml
```

```yaml
---
# deploy-myapp.yml
- name: Deploy My Application
  hosts: webservers
  gather_facts: true

  pre_tasks:
    - name: Validate required variables
      ansible.builtin.assert:
        that:
          - app_name is defined
        fail_msg: "Required variable app_name must be defined"

  roles:
    - role: myorg.custom_collection.my_new_role
      vars:
        app_name: "{{ app_name }}"
        my_new_role_packages: "{{ app_packages | default(['httpd']) }}"

  post_tasks:
    - name: Verify deployment
      ansible.builtin.uri:
        url: "http://{{ ansible_host }}:8080"
        status_code: 200
```

**Lint the playbook:**

```bash
ansible-lint playbooks/deploy-myapp.yml
pre-commit run --all-files
```

📘 **More details**: [automation-playbooks README](../automation-playbooks/README.md)

---

### Step 9: Configure AAP Resources (Config as Code)

Now that you have the playbook, configure AAP to use it along with the rebuilt EE.

```bash
cd aap-config-as-code
```

**1. Verify Execution Environment is configured:**

```yaml
# inventory/group_vars/aap_dev/execution_environments.yml
controller_execution_environments:
  - name: "Custom EE"
    description: "Custom Execution Environment with org collections"
    image: "quay.io/myorg/custom-ee:dev"  # :dev tag auto-updates
    pull: "always"  # Always pull latest for dev
    credential: "Container Registry"
```

**2. Configure Project (if new playbook repo needed):**

```yaml
# inventory/group_vars/aap_dev/projects.yml
controller_projects:
  - name: "Automation Playbooks"
    description: "Centralized automation playbooks"
    scm_type: git
    scm_url: https://github.com/djdanielsson/rh1-automation-playbooks.git
    scm_branch: main
    credential: "GitHub Token"
```

**3. Add Job Template for your new automation:**

```yaml
# inventory/group_vars/aap_dev/job_templates.yml
controller_job_templates:
  - name: "Deploy My App"
    description: "Deploy my application using my_new_role"
    job_type: run
    organization: Default
    inventory: "Dev Servers"
    project: "Automation Playbooks"        # → References playbooks repo
    playbook: "playbooks/deploy-myapp.yml" # → Playbook you just created
    execution_environment: "Custom EE"     # → EE rebuilt with your collection
    credentials:
      - "Dev SSH Key"
    ask_variables_on_launch: true
    extra_vars:
      app_name: "myapp"
```

**Dependency chain:**
- **Job Template** references **Project** (playbooks) + **Execution Environment**
- **Playbook** calls **Roles** from collections (bundled in EE)
- **EE** contains collections + Python packages + system deps

📘 **More details**: [aap-config-as-code README](../aap-config-as-code/README.md)

---

### Step 10: Create Pull Requests

Push changes to all modified repositories and create PRs. CI runs automatically.

```bash
# For each repository with changes:
git checkout -b feature/my-new-role
git add .
git commit -m "Add my_new_role for application deployment"
git push origin feature/my-new-role
gh pr create --title "Add my_new_role" --body "Adds deployment automation for XYZ"
```

**CI Pipeline runs on each PR:**
1. ✅ ansible-lint
2. ✅ yamllint
3. ✅ molecule test (all scenarios)
4. ✅ Secret scanning
5. ✅ Collection build verification

📘 **More details**: [CI/CD Guide](./CICD-GUIDE.md) | [Git Workflow](./GIT-WORKFLOW.md)

---

### Step 11: Merge to Main → Auto-Deploy to Dev

After PR approvals and merges, changes automatically deploy to the Dev environment.

```
Collection PR Merged → EE Rebuild Triggered → New :dev image pushed
                                                      │
CaC PR Merged → Tekton Pipeline → Dev AAP Updated ◀───┘
                                        │
                                        ▼
                              Ready for Dev Testing
```

**Order matters for merging:**
1. First: Collection changes (triggers EE rebuild)
2. Second: EE changes (if any direct changes needed)
3. Third: Playbook changes
4. Fourth: Config-as-Code changes (references the new EE)

The inner loop is fast—typically under 5 minutes from final merge to full deployment.

📘 **More details**: [GitOps Loops](./diagrams/GITOPS-LOOPS.md)

---

### Step 12: Test in Dev Environment

Validate your automation works in the Dev AAP instance.

```bash
# Via AAP UI:
# 1. Navigate to Job Templates
# 2. Launch "Deploy My App"
# 3. Verify successful execution

# Via AAP API/CLI:
awx job_templates launch "Deploy My App" --extra_vars '{"app_name": "test"}'
```

**Verify:**
- ✅ Job completes successfully
- ✅ Target systems are configured correctly
- ✅ No unexpected changes (idempotency)
- ✅ Logs show expected behavior

**Fix any issues** by returning to Step 1 and iterating.

---

### Step 13: Create Release Manifest for QA

When Dev testing passes, create a release manifest that locks all component versions.

```yaml
# automation-release-manifest/releases/release-26.01.06.0.yaml
---
version: "26.01.06.0"
created: "2026-01-06T10:00:00Z"
components:
  aap_configuration:
    repository: "https://github.com/djdanielsson/rh1-aap-config-as-code.git"
    ref: "abc123def456..."  # Exact Git SHA from dev
  execution_environment:
    repository: "https://github.com/djdanielsson/rh1-custom-ee.git"
    ref: "789ghi012jkl..."
    image: "quay.io/org/custom-ee@sha256:..."  # Exact image digest (not :dev tag!)
  playbooks:
    repository: "https://github.com/djdanielsson/rh1-automation-playbooks.git"
    ref: "stu901vwx234..."
  collections:
    repository: "https://github.com/djdanielsson/rh1-custom-collection.git"
    ref: "mno345pqr678..."
```

**Key**: Use `@sha256:...` digest for EE, not `:dev` tag. This ensures QA/Prod get the exact same image.

📘 **More details**: [Promotion Flow](./diagrams/PROMOTION-FLOW.md) | [automation-release-manifest README](../automation-release-manifest/README.md)

---

### Step 14: Promote to QA

Tag and push to trigger promotion to QA.

```bash
cd automation-release-manifest

# Commit the manifest
git add releases/release-26.01.06.0.yaml
git commit -m "Release 26.01.06.0"

# Tag triggers promotion
git tag 26.01.06.0
git push origin main --tags

# Tekton promotion pipeline runs:
# 1. Parses manifest
# 2. Pulls exact versions (by SHA/digest)
# 3. Deploys to QA AAP
```

**All components deploy atomically**—same versions of EE, CaC, playbooks, and collections.

**QA Testing:**
- Run job templates in QA environment
- Validate against QA infrastructure
- Document any issues found

📘 **More details**: [Git Workflow](./GIT-WORKFLOW.md)

---

### Step 15: Promote to Production

After QA validation, promote to production with manual approval.

```bash
# Trigger production promotion via Tekton
tkn pipeline start promote \
  -p VERSION=26.01.06.0 \
  -p FROM_ENVIRONMENT=qa \
  -p TO_ENVIRONMENT=prod

# Or via GitHub Actions workflow with approval gate
```

Production deployments require:
- ✅ QA sign-off
- ✅ Change management approval
- ✅ Backup verification

📘 **More details**: [Disaster Recovery](./DISASTER-RECOVERY.md) | [Security Guide](./SECURITY-GUIDE.md)

---

### Rollback (if needed)

Rollback to any previous release by re-promoting that version.

```bash
# Option A: Re-promote previous tag
tkn pipeline start promote \
  -p VERSION=26.01.05.0 \
  -p FROM_ENVIRONMENT=prod \
  -p TO_ENVIRONMENT=prod

# Option B: Create new manifest pointing to old commits
```

The release manifest ensures you roll back **all components together**.

📘 **More details**: [Troubleshooting Guide](./TROUBLESHOOTING-GUIDE.md)

---

## Complete Documentation Reference

### Getting Started & Development

| Document | Description |
|----------|-------------|
| [Ansible Best Practices](./ANSIBLE-BEST-PRACTICES.md) | ⭐ **Essential** - Complete Ansible & AAP development guide |
| [Dev Containers Guide](./DEV-CONTAINERS-GUIDE.md) | Development environment setup with devcontainers |
| [Testing Guide](./TESTING-GUIDE.md) | Testing strategies—Molecule, ansible-test, integration |
| [Pre-commit Guide](./PRE-COMMIT-GUIDE.md) | Pre-commit hooks setup and configuration |

### Standards & Conventions

| Document | Description |
|----------|-------------|
| [Code Style Guide](./CODE-STYLE-GUIDE.md) | YAML, Python, and shell style standards |
| [Naming Conventions](./NAMING-CONVENTIONS.md) | Naming standards for all resources |
| [Git Workflow](./GIT-WORKFLOW.md) | Branching strategy, CalVer versioning, promotion process |

### CI/CD & Release Management

| Document | Description |
|----------|-------------|
| [CI/CD Guide](./CICD-GUIDE.md) | GitHub Actions and Tekton pipeline workflows |
| [Validation & Quality](./VALIDATION-QUALITY-GUIDE.md) | Validation gates and security scanning |
| [EE Versioning Strategy](./EE-VERSIONING-STRATEGY.md) | Execution Environment versioning approach |

### Operations & Maintenance

| Document | Description |
|----------|-------------|
| [Disaster Recovery](./DISASTER-RECOVERY.md) | DR procedures and runbooks |
| [AAP Upgrade Guide](./AAP-UPGRADE-GUIDE.md) | AAP version upgrade procedures |
| [Multi-Cluster Guide](./MULTI-CLUSTER-GUIDE.md) | Multi-cluster deployment strategies |
| [Security Guide](./SECURITY-GUIDE.md) | Zero-trust security model |
| [Troubleshooting Guide](./TROUBLESHOOTING-GUIDE.md) | Common issues and solutions |

### Architecture Diagrams

| Diagram | Description |
|---------|-------------|
| [Diagrams Overview](./diagrams/README.md) | Index of all architecture diagrams |
| [Platform Architecture](./diagrams/PLATFORM-ARCHITECTURE.md) | Overall system design and components |
| [GitOps Loops](./diagrams/GITOPS-LOOPS.md) | Dual GitOps loop architecture (ArgoCD + Tekton) |
| [Promotion Flow](./diagrams/PROMOTION-FLOW.md) | Release promotion and rollback process |
| [Repository Structure](./diagrams/REPOSITORY-STRUCTURE.md) | Git repository organization |
| [Dependency Tree](./diagrams/DEPENDENCY-TREE.md) | Complete dependency hierarchy and versioning |
| [Workflow Diagrams](./diagrams/WORKFLOW-DIAGRAMS.md) | Git workflow and pipeline visualizations |

### Governance

| Document | Description |
|----------|-------------|
| [Constitution](../.specify/memory/constitution.md) | 5 immutable platform principles |
| [Specification](../.specify/memory/specification.md) | Detailed technical requirements |

### Repository READMEs

| Repository | Link |
|------------|------|
| Platform Overview | [README.md](../README.md) |
| cluster-config | [cluster-config/README.md](../cluster-config/README.md) |
| aap-config-as-code | [aap-config-as-code/README.md](../aap-config-as-code/README.md) |
| automation-playbooks | [automation-playbooks/README.md](../automation-playbooks/README.md) |
| automation-collection-example | [automation-collection-example/README.md](../automation-collection-example/README.md) |
| automation-ee-example | [automation-ee-example/README.md](../automation-ee-example/README.md) |
| automation-release-manifest | [automation-release-manifest/README.md](../automation-release-manifest/README.md) |

---

## Quick Reference

### Common Commands

```bash
# Create new role
ansible-creator add resource role my_role

# Run Molecule tests
cd roles/my_role && molecule test

# Lint collection
ansible-lint

# Install pre-commit hooks
pre-commit install

# Run all pre-commit checks
pre-commit run --all-files

# Create release
tkn pipeline start create-release -p VERSION=26.01.06.0

# Promote to QA
tkn pipeline start promote -p VERSION=26.01.06.0 -p FROM_ENVIRONMENT=dev -p TO_ENVIRONMENT=qa

# Rollback
tkn pipeline start rollback -p TARGET_VERSION=26.01.05.0 -p ENVIRONMENT=prod
```

### Version Format

```
YY.MM.DD.PATCH
26.01.06.0  # January 6, 2026, initial release
26.01.06.1  # January 6, 2026, hotfix
```

### Constitution Summary

| Article | Principle |
|---------|-----------|
| **I** | GitOps First—all config in Git |
| **II** | Separation of Duties—ArgoCD for platform, Tekton for apps |
| **III** | Atomic Promotion—version-locked releases |
| **IV** | Production-Grade Quality—idempotent, tested, modular |
| **V** | Zero-Trust Security—no secrets in Git |

---

## Learning Paths

### New Developer
1. Start here → [Ansible Best Practices](./ANSIBLE-BEST-PRACTICES.md)
2. Setup → [Dev Containers Guide](./DEV-CONTAINERS-GUIDE.md)
3. Quality → [Pre-commit Guide](./PRE-COMMIT-GUIDE.md)
4. Testing → [Testing Guide](./TESTING-GUIDE.md)

### Platform Engineer
1. Architecture → [Platform Architecture](./diagrams/PLATFORM-ARCHITECTURE.md)
2. GitOps → [GitOps Loops](./diagrams/GITOPS-LOOPS.md)
3. Deployment → [cluster-config README](../cluster-config/README.md)
4. Operations → [Troubleshooting Guide](./TROUBLESHOOTING-GUIDE.md)

### Release Manager
1. Workflow → [Git Workflow](./GIT-WORKFLOW.md)
2. Promotion → [Promotion Flow](./diagrams/PROMOTION-FLOW.md)
3. CI/CD → [CI/CD Guide](./CICD-GUIDE.md)
4. DR → [Disaster Recovery](./DISASTER-RECOVERY.md)
