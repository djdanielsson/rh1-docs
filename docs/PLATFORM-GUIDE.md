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

### Step 1: Develop Your Role

Create or modify roles in the `automation-collection-example` repository.

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

### Step 2: Write Tests

Every role needs Molecule tests. Test-driven development is enforced.

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

**Run tests locally:**

```bash
cd roles/my_new_role
molecule test

# Or step-by-step:
molecule create    # Spin up test container
molecule converge  # Run the role
molecule verify    # Run verification tests
molecule destroy   # Clean up
```

📘 **More details**: [Testing Guide](./TESTING-GUIDE.md)

---

### Step 3: Create or Update Playbook

Create or modify playbooks in the `automation-playbooks` repository to orchestrate your role.

```bash
# Navigate to playbooks repository
cd automation-playbooks

# Create a new playbook
vi playbooks/deploy-myapp.yml
```

**Example playbook that calls your role:**

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

📘 **More details**: [automation-playbooks README](../automation-playbooks/README.md)

---

### Step 4: Configure AAP Resources

Add or update AAP resources in the `aap-config-as-code` repository. This includes execution environments, projects, and job templates.

```bash
# Navigate to AAP config
cd aap-config-as-code
```

**1. Configure Execution Environment in AAP:**

```yaml
# inventory/group_vars/aap_dev/execution_environments.yml
controller_execution_environments:
  - name: "Custom EE (Dev)"
    description: "Custom Execution Environment with org collections"
    image: "quay.io/myorg/custom-ee:dev"  # Built from automation-ee-example
    pull: "missing"  # or "always" for latest
    credential: "Container Registry"  # Optional: for private registries
```

**2. Configure Project (references playbooks repo):**

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

**3. Configure Job Template (ties everything together):**

```yaml
# inventory/group_vars/aap_dev/job_templates.yml
controller_job_templates:
  - name: "Deploy My App (Dev)"
    description: "Deploy my application using my_new_role"
    job_type: run
    organization: Default
    inventory: "Dev Servers"
    project: "Automation Playbooks"        # → References playbooks repo
    playbook: "playbooks/deploy-myapp.yml" # → Playbook in that repo
    execution_environment: "Custom EE (Dev)" # → EE defined above
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

### Step 5: Update Execution Environment (if needed)

If your role requires new dependencies, update the `automation-ee-example` repository.

```bash
# Check if new dependencies are needed
cd automation-ee-example

# Update Python packages
vi requirements.txt
# Add: my-new-package>=1.0.0

# Update Ansible collections
vi requirements.yml
# Add your collection dependency

# Update system packages if needed
vi bindep.txt
# Add: my-system-package
```

Push changes to trigger EE rebuild:

```bash
git commit -am "Add dependencies for my_new_role"
git push origin main
# Tekton automatically builds new EE image
```

📘 **More details**: [EE Versioning Strategy](./EE-VERSIONING-STRATEGY.md)

---

### Step 6: Validate Quality

Run linting and quality checks before committing.

```bash
# Run ansible-lint
ansible-lint roles/my_new_role

# Run yamllint
yamllint roles/my_new_role

# Run all pre-commit hooks
pre-commit run --all-files
```

**Pre-commit hooks run automatically on commit**, catching issues before they reach CI.

📘 **More details**: [Pre-commit Guide](./PRE-COMMIT-GUIDE.md) | [Validation & Quality](./VALIDATION-QUALITY-GUIDE.md)

---

### Step 7: Create Pull Request

Push your changes and create a PR. CI runs automatically.

```bash
# Create feature branch
git checkout -b feature/my-new-role

# Commit changes
git add roles/my_new_role
git commit -m "Add my_new_role for application deployment"

# Push and create PR
git push origin feature/my-new-role
gh pr create --title "Add my_new_role" --body "Adds deployment automation for XYZ"
```

**CI Pipeline runs:**
1. ✅ ansible-lint
2. ✅ yamllint  
3. ✅ molecule test (all scenarios)
4. ✅ Secret scanning
5. ✅ Collection build verification

📘 **More details**: [CI/CD Guide](./CICD-GUIDE.md) | [Git Workflow](./GIT-WORKFLOW.md)

---

### Step 8: Merge to Main → Auto-Deploy to Dev

After PR approval and merge, changes automatically deploy to the Dev environment.

```
PR Merged → Webhook → Tekton Pipeline → Dev AAP Updated
                                              │
                                              ▼
                                    Test in Dev Environment
```

The inner loop is fast—typically under 1 minute from merge to deployment.

📘 **More details**: [GitOps Loops](./diagrams/GITOPS-LOOPS.md)

---


---


---


When ready to promote to QA, create a release manifest that locks all component versions.

```yaml
# automation-release-manifest/releases/release-26.01.06.0.yaml
---
version: "26.01.06.0"
created: "2026-01-06T10:00:00Z"
components:
  aap_configuration:
    repository: "https://github.com/djdanielsson/rh1-aap-config-as-code.git"
    ref: "abc123def456..."  # Git SHA
  execution_environment:
    repository: "https://github.com/djdanielsson/rh1-custom-ee.git"
    ref: "789ghi012jkl..."
    image: "quay.io/org/custom-ee@sha256:..."  # Image digest
  collections:
    repository: "https://github.com/djdanielsson/rh1-custom-collection.git"
    ref: "mno345pqr678..."
```

📘 **More details**: [Promotion Flow](./diagrams/PROMOTION-FLOW.md) | [automation-release-manifest README](../automation-release-manifest/README.md)

---

### Step 9: Promote to QA

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
# 2. Builds/pulls exact versions
# 3. Deploys to QA AAP
```

**All components deploy atomically**—same versions of EE, CaC, and collections.

📘 **More details**: [Git Workflow](./GIT-WORKFLOW.md)

---

### Step 10: Promote to Production

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
