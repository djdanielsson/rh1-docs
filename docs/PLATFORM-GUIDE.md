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
| **QA/Prod** | `:YY.MM.DD.PATCH` (tag) | Locked to exact image tag in release manifest. Immutable. |

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

**Create/Update argument specification:**

Every role must have an argument specification file for proper validation and documentation.

```yaml
# roles/my_new_role/meta/argument_specs.yml
---
argument_specs:
  main:
    short_description: Install and configure my new role
    description:
      - This role installs and configures my new application/service
    author: Your Name (@your_username)
    options:
      my_new_role_packages:
        type: list
        elements: str
        required: false
        default: ["httpd"]
        description: List of packages to install

      my_new_role_config_path:
        type: str
        required: false
        default: "/etc/httpd/conf/httpd.conf"
        description: Path to the configuration file

      my_new_role_enabled:
        type: bool
        required: false
        default: true
        description: Whether to enable and start the service
```

```bash
# Validate the argument spec
ansible-playbook --check -i localhost, --connection=local \
  -e "my_new_role_packages=['nginx']" \
  roles/my_new_role/tasks/main.yml
```

📘 **More details**: [Ansible Best Practices](./ANSIBLE-BEST-PRACTICES.md) | [Code Style Guide](./CODE-STYLE-GUIDE.md) | [Naming Conventions](./NAMING-CONVENTIONS.md)

---

### Step 2: Create Molecule Tests

Every role needs Molecule tests. Use the modern approach of centralized molecule scenarios in `extensions/molecule/` rather than role-specific test directories.

```bash
cd automation-collection-example

# Create a new molecule scenario for your role
molecule init scenario db_server

# This creates scenario files in: extensions/molecule/db_server/
```

**Configure the scenario:**

```yaml
# extensions/molecule/db_server/molecule.yml
---
dependency:
  name: galaxy
driver:
  name: podman
platforms:
  - name: instance
    image: quay.io/centos/centos:stream9
    pre_build_image: true
provisioner:
  name: ansible
  inventory:
    group_vars:
      all:
        database_name: testdb
        database_user: testuser
verifier:
  name: ansible
```

**Write convergence tests:**

```yaml
# extensions/molecule/db_server/converge.yml
---
- name: Converge
  hosts: all
  tasks:
    - name: Include database role
      ansible.builtin.include_role:
        name: myorg.custom_collection.database
```

**Write verification tests:**

```yaml
# extensions/molecule/db_server/verify.yml
---
- name: Verify
  hosts: all
  tasks:
    - name: Check PostgreSQL service is running
      ansible.builtin.service_facts:

    - name: Assert PostgreSQL is active
      ansible.builtin.assert:
        that: ansible_facts.services['postgresql.service'].state == 'running'

    - name: Verify database exists
      community.postgresql.postgresql_db:
        name: "{{ database_name }}"
        state: present
      check_mode: true
      register: db_check

    - name: Assert database was created
      ansible.builtin.assert:
        that: not db_check.changed
```

**Benefits of centralized molecule scenarios:**
- All test scenarios in one place for easy management
- Shared configurations across role tests
- Better separation of concerns
- Easier CI/CD integration

📘 **More details**: [Testing Guide](./TESTING-GUIDE.md)

---

### Step 3: Lint Test Files

Lint your role and Molecule test files—catch issues before running tests.

```bash
cd automation-collection-example

# Lint the collection
ansible-lint

# Fix any issues before proceeding to tests
```

**Common issues caught at this stage:**
- Missing FQCNs (fully qualified collection names)
- Incorrect indentation
- Missing `name` on tasks
- Deprecated modules
- Test file quality issues

**Ensure both your role and tests follow the same quality standards.**

📘 **More details**: [Pre-commit Guide](./PRE-COMMIT-GUIDE.md) | [Code Style Guide](./CODE-STYLE-GUIDE.md)

---

### Step 4: Run Molecule Tests

Execute Molecule tests to verify your role works correctly using the centralized scenarios.

```bash
cd automation-collection-example

# Run tests for your specific scenario
molecule test -s db_server

# Or step-by-step for debugging:
molecule create -s db_server    # Spin up test container
molecule converge -s db_server  # Run the role
molecule verify -s db_server    # Run verification tests
molecule destroy -s db_server   # Clean up

# List all available scenarios
molecule list
```

**All tests must pass before proceeding.**

**Available molecule commands:**
- `molecule test -s <scenario>` - Run full test cycle
- `molecule converge -s <scenario>` - Apply role only
- `molecule verify -s <scenario>` - Run verification only
- `molecule login -s <scenario>` - SSH into test container
- `molecule reset -s <scenario>` - Reset scenario state

📘 **More details**: [Testing Guide](./TESTING-GUIDE.md)

---

### Step 5: Final Quality Gate - Lint & Scan All

Run comprehensive linting and security scanning on the entire codebase.

```bash
cd automation-collection-example

# Run pre-commit hooks (primarily secret scanning)
pre-commit run --all-files

# Pre-commit only runs:
# - detect-secrets (secret leak detection)
#
# Note: Other checks (linting, formatting, etc.) are handled by GitHub Actions or run manually
```

**Pre-commit hooks run automatically on commit**, but running manually ensures clean commits.

📘 **More details**: [Pre-commit Guide](./PRE-COMMIT-GUIDE.md) | [Validation & Quality](./VALIDATION-QUALITY-GUIDE.md)

---

### Step 6: Update Execution Environment

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

**For Releases**: The release manifest will lock the specific `:YY.MM.DD.PATCH` tags.

📘 **More details**: [EE Versioning Strategy](./EE-VERSIONING-STRATEGY.md)

---

### Step 7: Create or Update Playbook

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

**Lint and scan the playbook:**

```bash
ansible-lint playbooks/deploy-myapp.yml
pre-commit run --all-files  # Secret scanning
```

📘 **More details**: [automation-playbooks README](../automation-playbooks/README.md)

---

### Step 8: Configure AAP Resources (Config as Code)

Now that you have the playbook, create a Job Template bundle file that defines the EE, Project, and JT together.

```bash
cd aap-config-as-code/inventory/group_vars/all

# Create a new JT bundle file for your role
# File naming: jt_{org}_{action}_{target}.yml
# Example: jt_plat_configure_database.yml
```

**Create Job Template Bundle File:**

```yaml
# jt_plat_configure_database.yml
---
# Platform organization PostgreSQL database configuration
# Contains only tightly coupled resources: EE + Project + JT
# Shared resources (credentials, inventories) are in their respective files
#
# Variable suffix: _plat_configure_database (includes org for uniqueness)

# Execution Environment for Platform Database Configuration
controller_execution_environments_plat_configure_database:
  - name: "plat_database_admin_ee_26.01.06.0"
    description: "Platform database administration execution environment"
    image: "quay.io/company/plat-ee@sha256:26.01.06.0"
    pull: "missing"
    credential: "plat_registry_svc_builder_quay_io"

# Project for Platform Database Configuration
controller_projects_plat_configure_database:
  - name: "plat_database_config_playbooks"
    description: "Platform database configuration playbooks"
    scm_type: git
    scm_url: "https://github.com/company/automation-playbooks.git"
    scm_branch: main
    scm_clean: true
    scm_delete_on_update: true
    credential: "plat_scm_git_github_main"
    timeout: 0
    organization: "platform"

# Job Template for Platform Database Configuration
# References shared resources from credentials.yml and inventories.yml
controller_templates_plat_configure_database:
  - name: "plat_configure_database_prod"
    description: "Configure PostgreSQL database on production servers"
    job_type: "run"
    inventory: "plat_databases_prod"           # → Defined in inventories.yml
    project: "plat_database_config_playbooks"  # → Defined above
    playbook: "playbooks/configure-database.yml" # → Playbook you created
    execution_environment: "plat_database_admin_ee_26.01.06.0" # → Defined above
    credentials:
      - "plat_machine_svc_ansible_linux"      # → Defined in credentials.yml
    organization: "platform"
    ask_variables_on_launch: true
    extra_vars: |
      ---
      database_name: "appdb"
      database_user: "app_user"
      database_port: 5432
      database_configure_firewall: true
...
```

**Verify Shared Resources Exist:**

Ensure the shared resources your JT references are defined in their respective files:

```yaml
# credentials.yml - Machine and source control credentials
controller_credentials_all:
  - name: "plat_machine_svc_ansible_linux"    # Referenced in JT
  - name: "plat_scm_git_github_main"          # Referenced in project

# inventories.yml - Target inventories
controller_inventories_all:
  - name: "plat_databases_prod"               # Referenced in JT
```

**JT Bundle Structure:**
- **EE**: Tightly coupled with the collection version
- **Project**: Points to the playbook repository
- **JT**: References shared resources and defines execution parameters
- **Variable Suffix**: `{org}_{action}_{target}` for uniqueness

**Dependency Chain:**
- **Job Template** references **Project** (playbooks) + **Execution Environment**
- **Playbook** calls **Roles** from collections (bundled in EE)
- **EE** contains collections + Python packages + system deps

📘 **More details**: [aap-config-as-code README](../aap-config-as-code/README.md)

---

### Step 9: Create Pull Requests

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

### Step 10: Merge to Main → Auto-Deploy to Dev

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

### Step 11: Test in Dev Environment

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

### Step 12: Create Release Manifest for QA

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
    repository: "https://github.com/djdanielsson/rh1-ee.git"
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

### Step 13: Promote to QA

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

### Step 14: Promote to Production

After QA validation, production promotion is handled automatically through the release pipeline with required approvals.

**Pipeline Process:**
1. **Automatic Trigger**: Release pipeline detects successful QA deployment
2. **Approval Gate**: Requires manual approval from release managers
3. **Automated Promotion**: Pipeline promotes the same release manifest to production
4. **Verification**: Production deployment validated automatically

**Approval Requirements:**
- ✅ QA validation complete and signed off
- ✅ Change management approval obtained
- ✅ Production backup verification
- ✅ Security team review (if applicable)

**No Manual CLI Commands**: Production promotion is fully automated through the CI/CD pipeline to ensure consistency and auditability.

**Monitoring**: Track promotion progress through the pipeline dashboard or release manifest updates.

📘 **More details**: [Disaster Recovery](./DISASTER-RECOVERY.md) | [Security Guide](./SECURITY-GUIDE.md)

---

### Rollback (if needed)

Rollback to any previous release through the pipeline system.

**Pipeline Rollback Process:**
1. **Select Previous Release**: Choose a stable release tag from the release manifest history
2. **Pipeline Trigger**: Initiate rollback through the pipeline interface (not CLI)
3. **Automated Rollback**: Pipeline promotes the previous release manifest to production
4. **Verification**: Automated validation ensures rollback success

**Key Benefits:**
- **Atomic Rollback**: Release manifest ensures ALL components rollback together
- **Auditable**: Full traceability through pipeline logs
- **Safe**: Same approval gates and validation as regular deployments
- **Fast**: Automated process reduces recovery time

**Emergency Rollback**: For critical issues, rollback can be fast-tracked with emergency approval.

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

# Run pre-commit checks (secret scanning only)
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
