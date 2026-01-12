# Cloud-Native Ansible Lifecycle Platform - Project Workspace

This is the project workspace containing all repositories and planning documentation for the Cloud-Native Ansible Lifecycle platform.

## Quick Links

### 🚀 Get Started
- **[Platform Guide](./docs/PLATFORM-GUIDE.md)** - Complete platform overview and development workflow

### 📖 Core Documents
- **[Constitution](./.specify/memory/constitution.md)** - Project principles (5 articles)
- **[Specification](./.specify/memory/specification.md)** - Detailed requirements
- **[Git Workflow](./docs/GIT-WORKFLOW.md)** - Branching, versioning, and promotion

### 🛠️ Developer Resources
- **[Ansible Best Practices](./docs/ANSIBLE-BEST-PRACTICES.md)** ⭐ Essential reading
- **[Pre-commit Guide](./docs/PRE-COMMIT-GUIDE.md)** - Quality tools
- **[Testing Guide](./docs/TESTING-GUIDE.md)** - Testing strategies
- **[Dev Containers Guide](./docs/DEV-CONTAINERS-GUIDE.md)** - Development environments

### 📚 Reference
- **[Naming Conventions](./docs/NAMING-CONVENTIONS.md)** - Naming standards
- **[Code Style](./docs/CODE-STYLE-GUIDE.md)** - Style guide
- **[CI/CD Guide](./docs/CICD-GUIDE.md)** - GitHub Actions and Tekton pipelines

## Repository Structure

```
rh1_ansible_code_lifecycle/              # Project workspace repo (docs + component repos)
├── README.md                            # This file - platform overview
├── docs/                                # All documentation
│   ├── PLATFORM-GUIDE.md                # Platform guide and documentation index
│   ├── diagrams/                        # Architecture and workflow diagrams
│   ├── GIT-WORKFLOW.md                  # Branching, versioning, promotion
│   ├── CICD-GUIDE.md                    # CI/CD workflows
│   └── ...                              # 12+ guides
├── .specify/memory/                     # Project specifications
│   ├── constitution.md                  # Project principles
│   └── specification.md                 # Technical requirements
├── tests/                               # Platform-wide tests
│
├── cluster-config/                      # Git Repo 1: Platform GitOps
├── aap-config-as-code/                  # Git Repo 2: AAP Configuration
├── automation-playbooks/                # Git Repo 3: Ansible Playbooks
├── automation-collection-example/       # Git Repo 4: Ansible Collection
├── automation-ee-example/               # Git Repo 5: Execution Environment
└── automation-release-manifest/         # Git Repo 6: Release Management
```

## The Six Git Repositories

### 1. cluster-config (Platform GitOps)
- **Repository**: https://github.com/djdanielsson/rh1-cluster-config.git
- **Purpose**: Deploy and manage AAP + Tekton on OpenShift via ArgoCD
- **Contents**: Kubernetes manifests, operator subscriptions, AAP CRs for 3 environments
- **Pattern**: ApplicationSet with auto-discovery
- **Managed by**: ArgoCD (OpenShift GitOps)
- **[View README](./cluster-config/README.md)**

### 2. aap-config-as-code (Application GitOps)
- **Repository**: https://github.com/djdanielsson/rh1-aap-config-as-code.git
- **Purpose**: Configure AAP via API using `infra.aap_configuration` collection
- **Contents**: Job templates, projects, inventories, group_vars for dev/qa/prod
- **Pattern**: dispatch role with wildcard variables
- **Managed by**: Tekton pipelines
- **[View README](./aap-config-as-code/README.md)**

### 3. automation-playbooks (Ansible Playbooks)
- **Repository**: https://github.com/djdanielsson/rh1-automation-playbooks.git
- **Purpose**: Centralized repository for Ansible playbooks called by AAP Job Templates
- **Contents**: Playbook files that orchestrate role execution from collections
- **Pattern**: Role-based playbooks with variable abstraction
- **Managed by**: Tekton pipelines (via AAP projects)
- **[View README](./automation-playbooks/README.md)**

### 4. automation-collection-example (Ansible Collection)
- **Repository**: https://github.com/djdanielsson/rh1-custom-collection.git
- **Purpose**: Example custom Ansible collection with roles, modules, plugins
- **Contents**: 4 roles, 2 modules, 4 filters, 2 lookups, Molecule tests
- **Created with**: ansible-creator
- **Testing**: Molecule scenarios, ansible-test sanity
- **[View README](./automation-collection-example/README.md)**

### 5. automation-ee-example (Execution Environment)
- **Repository**: https://github.com/djdanielsson/rh1-custom-ee.git
- **Purpose**: Custom Execution Environment container image
- **Contents**: execution-environment.yml, requirements.yml/txt, bindep.txt
- **Built with**: ansible-builder
- **Base**: registry.redhat.io/ansible-automation-platform-26/ee-minimal-rhel9
- **[View README](./automation-ee-example/README.md)**

### 6. automation-release-manifest (Release Management)
- **Repository**: https://github.com/djdanielsson/rh1-release-manifest.git
- **Purpose**: Version-lock all components for atomic promotion between environments
- **Contents**: Release manifests (YAML), Tekton pipelines, JSON schema
- **Versioning**: CalVer YY.MM.DD.PATCH
- **Pipelines**: create-release, promote, rollback (all Tekton)
- **[View README](./automation-release-manifest/README.md)**

## Constitution Compliance

All repositories follow the five articles:

- ✅ **Article I**: GitOps First - All configuration in Git
- ✅ **Article II**: Separation of Duties - ArgoCD for platform, Tekton for apps
- ✅ **Article III**: Atomic Promotion - Release manifests lock versions
- ✅ **Article IV**: Production-Grade Quality - Idempotent, tested, documented
- ✅ **Article V**: Zero-Trust Security - No secrets in Git

## Getting Started

1. **Read the Platform Guide**: `./docs/INDEX.md`
2. **Understand the Principles**: `./.specify/memory/constitution.md`
3. **Develop Content**: Add roles to automation-collection-example
4. **Configure AAP**: Push changes to aap-config-as-code
5. **Promote**: Create release manifest and promote to QA/Prod

## Development Workflow

### For Platform Changes (cluster-config)
```bash
cd cluster-config/
# Edit Kubernetes resources
git add .
git commit -m "Description"
git push origin main
# ArgoCD syncs automatically
```

### For AAP Configuration (aap-config-as-code)
```bash
cd aap-config-as-code/
# Edit group_vars
git add .
git commit -m "Description"
git push origin main
# Webhook triggers CaC pipeline
```

### For Collection Development (automation-collection-example)
```bash
cd automation-collection-example/
# Develop roles
cd roles/run
molecule test
# Create PR, CI runs tests
```

## Key Workflows

### Platform Bootstrap
```bash
# 1. Install GitOps operator
oc create -f gitops-operator-subscription.yaml

# 2. Bootstrap everything
oc apply -f cluster-config/argocd/root-app.yaml

# That's it! ArgoCD deploys everything
```

### Configuration as Code
```bash
# Edit AAP configuration
vi aap-config-as-code/group_vars/aap_dev/job_templates.yml

# Commit and push
git commit -am "Add new job template"
git push

# Webhook triggers pipeline, changes applied automatically
```

### Atomic Promotion
```bash
# Create release manifest
cat > automation-release-manifest/releases/26.01.06.0.yaml <<EOF
version: "26.01.06.0"
components:
  aap_configuration: "abc123..."
  execution_environment: "def456..."
  collections: "ghi789..."
EOF

# Tag and push
git tag 26.01.06.0
git push origin 26.01.06.0

# Promotion pipeline deploys to QA
```

## Architecture

- **Platform Loop (ArgoCD)**: Manages Kubernetes resources
- **Application Loop (Tekton)**: Manages AAP configuration
- **Atomic Promotion**: All components version-locked together
- **Zero Secrets**: All secrets in OCP, referenced by name

## Success Metrics

- ✅ Single `oc apply` bootstraps entire platform
- ✅ <1min developer inner loop feedback
- ✅ <5min atomic promotion to QA
- ✅ Zero secrets in any Git repository
- ✅ 100% idempotent automation
- ✅ Complete audit trail via Git

## 🎯 What Can Be Done Without Infrastructure

The platform is **production-ready** even without OpenShift or AAP running:

✅ **Develop Content** - 4 example roles, custom modules, filters, lookups
✅ **Enforce Quality** - Pre-commit hooks, CI/CD workflows
✅ **Test Everything** - Multi-level testing (unit, integration, Molecule, E2E)
✅ **Follow Standards** - Red Hat CoP aligned, ansible-lint compliant
✅ **Ensure Security** - Secret detection, vulnerability scanning
✅ **Validate Configs** - Test playbooks for all repositories
✅ **Learn Best Practices** - Comprehensive documentation

See **[Platform Guide](./docs/PLATFORM-GUIDE.md)** for complete documentation.

## 📊 Platform Statistics

- **Documentation**: 13 comprehensive guides + 6 architecture diagrams
- **Pre-commit Hooks**: 85 hooks across 6 repositories
- **CI/CD Workflows**: 15 GitHub Actions workflows
- **Test Coverage**: Unit, integration, Molecule, validation
- **Example Content**: 4 roles, 2 modules, 4 filters, 2 lookups
- **Standards**: Aligned with Red Hat CoP and ansible-lint rules
- **Ready**: ✅ Production-ready, constitutional compliant

## External Resources

### Platform Technologies
- [OpenShift GitOps](https://docs.openshift.com/gitops/latest/)
- [Tekton](https://tekton.dev/)
- [AAP Operator](https://access.redhat.com/documentation/en-us/red_hat_ansible_automation_platform/)
- [infra.aap_configuration](https://github.com/redhat-cop/infra.aap_configuration)
- [ansible-creator](https://ansible.readthedocs.io/projects/creator/)

### Best Practices & Standards
- [Red Hat CoP Automation Good Practices](https://redhat-cop.github.io/automation-good-practices/)
- [Ansible-lint Rules](https://ansible.readthedocs.io/projects/lint/rules/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html)
