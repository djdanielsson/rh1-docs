# Documentation Index

Complete documentation for the Cloud-Native Ansible Lifecycle Platform.

---

## 🚀 Quick Start

| Document | Description |
|----------|-------------|
| [Getting Started](./GETTING-STARTED.md) | First steps - bootstrap the platform |
| [Development Guide](./DEVELOPMENT.md) | Development workflow and setup |
| [Platform README](../README.md) | Project overview |

---

## 📚 Documentation by Category

### 🏗️ Architecture & Design

| Document | Description |
|----------|-------------|
| [Architecture Diagrams](./diagrams/README.md) | Diagram index with all visual docs |
| [Platform Architecture](./diagrams/PLATFORM-ARCHITECTURE.md) | Overall system design |
| [GitOps Loops](./diagrams/GITOPS-LOOPS.md) | Dual GitOps loop architecture |
| [Promotion Flow](./diagrams/PROMOTION-FLOW.md) | Release promotion process |
| [Repository Structure](./diagrams/REPOSITORY-STRUCTURE.md) | Git repository organization |

### 🛠️ Development Guides

| Document | Description |
|----------|-------------|
| [Ansible Best Practices](./ANSIBLE-BEST-PRACTICES.md) | ⭐ Ansible, AAP, code style, naming conventions |
| [Dev Containers Guide](./DEV-CONTAINERS-GUIDE.md) | Development environment setup |
| [Testing Guide](./TESTING-GUIDE.md) | Testing strategies and tools |

### 🔄 CI/CD & Release Management

| Document | Description |
|----------|-------------|
| [CI/CD Guide](./CICD-GUIDE.md) | ⭐ GitHub Actions, Tekton, pre-commit hooks |
| [Git Workflow](./GIT-WORKFLOW.md) | ⭐ Branching, CalVer versioning, EE versioning |
| [Security & Validation](./SECURITY-VALIDATION-GUIDE.md) | Security model, validation, scanning |

### 🔧 Operations & Maintenance

| Document | Description |
|----------|-------------|
| [Disaster Recovery](./DISASTER-RECOVERY.md) | DR procedures and runbooks |
| [AAP Upgrade Guide](./AAP-UPGRADE-GUIDE.md) | AAP version upgrade procedures |
| [Multi-Cluster Guide](./MULTI-CLUSTER-GUIDE.md) | Multi-cluster deployment |
| [Troubleshooting Guide](./TROUBLESHOOTING-GUIDE.md) | Platform troubleshooting |

### 📖 Governance

| Document | Description |
|----------|-------------|
| [Constitution](../.specify/memory/constitution.md) | 5 immutable principles |
| [Specification](../.specify/memory/specification.md) | Technical requirements |

---

## 🗂️ Documentation Structure

```
docs/
├── INDEX.md                      # This file
├── GETTING-STARTED.md            # Quick start guide
├── DEVELOPMENT.md                # Development workflow
│
├── diagrams/                     # Architecture diagrams
│   ├── README.md
│   ├── PLATFORM-ARCHITECTURE.md
│   ├── GITOPS-LOOPS.md
│   ├── PROMOTION-FLOW.md
│   └── REPOSITORY-STRUCTURE.md
│
├── ANSIBLE-BEST-PRACTICES.md     # ⭐ Ansible + Style + Naming
├── DEV-CONTAINERS-GUIDE.md
├── TESTING-GUIDE.md
│
├── CICD-GUIDE.md                 # ⭐ CI/CD + Pre-commit
├── GIT-WORKFLOW.md               # ⭐ Git + Versioning + EE
├── SECURITY-VALIDATION-GUIDE.md  # Security + Validation
│
├── DISASTER-RECOVERY.md
├── AAP-UPGRADE-GUIDE.md
├── MULTI-CLUSTER-GUIDE.md
└── TROUBLESHOOTING-GUIDE.md
```

---

## 🎓 Learning Paths

### New Developer

1. [Getting Started](./GETTING-STARTED.md)
2. [Development Guide](./DEVELOPMENT.md)
3. [Dev Containers Guide](./DEV-CONTAINERS-GUIDE.md)
4. [Ansible Best Practices](./ANSIBLE-BEST-PRACTICES.md)

### Release Manager

1. [Git Workflow](./GIT-WORKFLOW.md)
2. [CI/CD Guide](./CICD-GUIDE.md)
3. [Promotion Flow](./diagrams/PROMOTION-FLOW.md)

### Operations

1. [Disaster Recovery](./DISASTER-RECOVERY.md)
2. [AAP Upgrade Guide](./AAP-UPGRADE-GUIDE.md)
3. [Troubleshooting Guide](./TROUBLESHOOTING-GUIDE.md)

---

## 📱 Quick Reference

```bash
# Pre-commit
pre-commit install && pre-commit run --all-files

# Create release
tkn pipeline start create-release -p VERSION=25.01.05.0

# Promote
tkn pipeline start promote -p VERSION=25.01.05.0 -p FROM_ENVIRONMENT=dev -p TO_ENVIRONMENT=qa

# Rollback
tkn pipeline start rollback -p TARGET_VERSION=25.01.04.0 -p ENVIRONMENT=prod
```

**Version Format**: `YY.MM.DD.PATCH` (e.g., `25.01.05.0`)
