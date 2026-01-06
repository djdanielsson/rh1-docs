# Cloud-Native Ansible Lifecycle Platform

Project workspace containing all repositories and documentation for the Cloud-Native Ansible Lifecycle platform.

## Quick Links

### 🚀 Get Started
- **[Getting Started](./docs/GETTING-STARTED.md)** - Quick start guide
- **[Documentation Index](./docs/INDEX.md)** - Complete documentation index
- **[Development Guide](./docs/DEVELOPMENT.md)** - Development workflow

### 📖 Core Documents
- **[Constitution](./.specify/memory/constitution.md)** - Project principles (5 articles)
- **[Git Workflow](./docs/GIT-WORKFLOW.md)** - Branching, versioning, and promotion

### 🛠️ Developer Resources
- **[Ansible Best Practices](./docs/ANSIBLE-BEST-PRACTICES.md)** ⭐ Essential (includes code style + naming)
- **[CI/CD Guide](./docs/CICD-GUIDE.md)** - Pipelines and pre-commit hooks
- **[Testing Guide](./docs/TESTING-GUIDE.md)** - Testing strategies
- **[Dev Containers Guide](./docs/DEV-CONTAINERS-GUIDE.md)** - Development environments

## Repository Structure

```
rh1_ansible_code_lifecycle/
├── README.md                            # This file
├── docs/                                # All documentation
│   ├── INDEX.md                         # Documentation index
│   ├── GETTING-STARTED.md
│   ├── DEVELOPMENT.md
│   ├── diagrams/                        # Architecture diagrams
│   └── ...                              # 11 consolidated guides
├── .specify/memory/                     # Project specifications
│   ├── constitution.md
│   └── specification.md
├── tests/                               # Platform-wide tests
│
├── cluster-config/                      # Git Repo 1: Platform GitOps
├── aap-config-as-code/                  # Git Repo 2: AAP Configuration
├── automation-collection-example/       # Git Repo 3: Ansible Collection
├── automation-ee-example/               # Git Repo 4: Execution Environment
└── automation-release-manifest/         # Git Repo 5: Release Management
```

## The Five Git Repositories

| Repository | Purpose | Managed By |
|------------|---------|------------|
| **cluster-config** | Platform GitOps - Deploy AAP + Tekton via ArgoCD | ArgoCD |
| **aap-config-as-code** | Configure AAP via `infra.aap_configuration` | Tekton |
| **automation-collection-example** | Custom Ansible collection (roles, modules, plugins) | Molecule + CI |
| **automation-ee-example** | Custom Execution Environment container | ansible-builder |
| **automation-release-manifest** | Version-lock components for atomic promotion | Tekton |

## Constitution Compliance

All repositories follow the five articles:

- ✅ **Article I**: GitOps First - All configuration in Git
- ✅ **Article II**: Separation of Duties - ArgoCD for platform, Tekton for apps
- ✅ **Article III**: Atomic Promotion - Release manifests lock versions
- ✅ **Article IV**: Production-Grade Quality - Idempotent, tested, documented
- ✅ **Article V**: Zero-Trust Security - No secrets in Git

## Quick Start

```bash
# 1. Install GitOps operator
oc create -f gitops-operator-subscription.yaml

# 2. Bootstrap everything
oc apply -f cluster-config/argocd/root-app.yaml
# ArgoCD deploys everything automatically
```

## Key Workflows

### Platform Changes (cluster-config)
```bash
cd cluster-config/
git commit -am "Update K8s resources" && git push
# ArgoCD syncs automatically
```

### AAP Configuration (aap-config-as-code)
```bash
cd aap-config-as-code/
git commit -am "Add job template" && git push
# Webhook triggers CaC pipeline
```

### Collection Development (automation-collection-example)
```bash
cd automation-collection-example/roles/run
molecule test
# Create PR, CI runs tests
```

### Atomic Promotion
```bash
# Create + tag release
git tag 26.01.06.0 && git push origin 26.01.06.0
# Promotion pipeline deploys to QA
```

## Architecture

- **Platform Loop (ArgoCD)**: Manages Kubernetes resources
- **Application Loop (Tekton)**: Manages AAP configuration
- **Atomic Promotion**: All components version-locked together
- **Zero Secrets**: All secrets in OCP, referenced by name

## What Can Be Done Without Infrastructure

✅ Develop content (roles, modules, filters, lookups)
✅ Enforce quality (pre-commit, CI/CD)
✅ Test everything (unit, integration, Molecule)
✅ Validate configs (test playbooks)
✅ Learn best practices (comprehensive docs)

**See [Documentation Index](./docs/INDEX.md) for complete documentation.**

## External Resources

- [OpenShift GitOps](https://docs.openshift.com/gitops/latest/)
- [Tekton](https://tekton.dev/)
- [infra.aap_configuration](https://github.com/redhat-cop/infra.aap_configuration)
- [ansible-creator](https://ansible.readthedocs.io/projects/creator/)
- [Red Hat CoP Automation Good Practices](https://redhat-cop.github.io/automation-good-practices/)
