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

Visual documentation and architectural concepts.

| Document | Description |
|----------|-------------|
| [Architecture Diagrams](./diagrams/README.md) | Diagram index with all visual docs |
| [Platform Architecture](./diagrams/PLATFORM-ARCHITECTURE.md) | Overall system design |
| [GitOps Loops](./diagrams/GITOPS-LOOPS.md) | Dual GitOps loop architecture |
| [Promotion Flow](./diagrams/PROMOTION-FLOW.md) | Release promotion process |
| [Repository Structure](./diagrams/REPOSITORY-STRUCTURE.md) | Git repository organization |
| [Workflow Diagrams](./diagrams/WORKFLOW-DIAGRAMS.md) | Git workflow and pipeline diagrams |

### 🛠️ Development Guides

Essential guides for developers.

| Document | Description |
|----------|-------------|
| [Ansible Best Practices](./ANSIBLE-BEST-PRACTICES.md) | ⭐ Must-read - complete Ansible & AAP guide |
| [Dev Containers Guide](./DEV-CONTAINERS-GUIDE.md) | Development environment setup |
| [Testing Guide](./TESTING-GUIDE.md) | Testing strategies and tools |
| [Pre-commit Guide](./PRE-COMMIT-GUIDE.md) | Pre-commit hooks setup |

### 📋 Standards & Conventions

Code standards and naming conventions.

| Document | Description |
|----------|-------------|
| [Code Style Guide](./CODE-STYLE-GUIDE.md) | YAML, Python, shell style standards |
| [Naming Conventions](./NAMING-CONVENTIONS.md) | Naming standards for all resources |
| [Git Workflow](./GIT-WORKFLOW.md) | ⭐ Branching, CalVer versioning, promotion |

### 🔄 CI/CD & Release Management

Continuous integration, deployment, and release processes.

| Document | Description |
|----------|-------------|
| [CI/CD Guide](./CICD-GUIDE.md) | GitHub Actions and Tekton workflows |
| [Validation & Quality](./VALIDATION-QUALITY-GUIDE.md) | Validation and security scanning |
| [EE Versioning Strategy](./EE-VERSIONING-STRATEGY.md) | Execution Environment versioning |

### 🔧 Operations & Maintenance

Production operations, upgrades, and disaster recovery.

| Document | Description |
|----------|-------------|
| [Disaster Recovery](./DISASTER-RECOVERY.md) | DR procedures and runbooks |
| [AAP Upgrade Guide](./AAP-UPGRADE-GUIDE.md) | AAP version upgrade procedures |
| [Multi-Cluster Guide](./MULTI-CLUSTER-GUIDE.md) | Multi-cluster deployment |
| [Security Guide](./SECURITY-GUIDE.md) | Zero-trust security model |
| [Troubleshooting Guide](./TROUBLESHOOTING-GUIDE.md) | Platform troubleshooting |

### 📖 Governance

Project principles and specifications.

| Document | Description |
|----------|-------------|
| [Constitution](../.specify/memory/constitution.md) | 5 immutable principles |
| [Specification](../.specify/memory/specification.md) | Technical requirements |

---

## 🗂️ Documentation Structure

```
docs/
├── INDEX.md                      # This file
│
├── GETTING-STARTED.md            # Quick start guide
├── DEVELOPMENT.md                # Development workflow
│
├── diagrams/                     # Architecture diagrams
│   ├── README.md                 # Diagram index
│   ├── PLATFORM-ARCHITECTURE.md
│   ├── GITOPS-LOOPS.md
│   ├── PROMOTION-FLOW.md
│   ├── REPOSITORY-STRUCTURE.md
│   └── WORKFLOW-DIAGRAMS.md
│
├── ANSIBLE-BEST-PRACTICES.md     # ⭐ Essential - Ansible & AAP guide
├── DEV-CONTAINERS-GUIDE.md
├── TESTING-GUIDE.md
├── PRE-COMMIT-GUIDE.md
│
├── CODE-STYLE-GUIDE.md
├── NAMING-CONVENTIONS.md
├── GIT-WORKFLOW.md               # ⭐ Branching + versioning + promotion
│
├── CICD-GUIDE.md
├── VALIDATION-QUALITY-GUIDE.md
├── EE-VERSIONING-STRATEGY.md
│
├── DISASTER-RECOVERY.md
├── AAP-UPGRADE-GUIDE.md
└── MULTI-CLUSTER-GUIDE.md
```

---

## 🎓 Learning Paths

### New Developer

1. [Getting Started](./GETTING-STARTED.md)
2. [Development Guide](./DEVELOPMENT.md)
3. [Dev Containers Guide](./DEV-CONTAINERS-GUIDE.md)
4. [Pre-commit Guide](./PRE-COMMIT-GUIDE.md)
5. [Ansible Best Practices](./ANSIBLE-BEST-PRACTICES.md)

### Platform Understanding

1. [Platform README](../README.md)
2. [Architecture Diagrams](./diagrams/README.md)
3. [Constitution](../.specify/memory/constitution.md)
4. [GitOps Loops](./diagrams/GITOPS-LOOPS.md)

### Release Manager

1. [Git Workflow](./GIT-WORKFLOW.md)
3. [Promotion Flow](./diagrams/PROMOTION-FLOW.md)
4. [CI/CD Guide](./CICD-GUIDE.md)

### Operations

1. [Disaster Recovery](./DISASTER-RECOVERY.md)
2. [AAP Upgrade Guide](./AAP-UPGRADE-GUIDE.md)
3. [Multi-Cluster Guide](./MULTI-CLUSTER-GUIDE.md)

---

## 📱 Quick Reference

### Pre-commit Commands

```bash
pre-commit install           # Install hooks
pre-commit run --all-files   # Run all hooks
```

### Tekton Pipeline Commands

```bash
# Create release
tkn pipeline start create-release -p VERSION=25.01.05.0

# Promote
tkn pipeline start promote -p VERSION=25.01.05.0 -p FROM_ENVIRONMENT=dev -p TO_ENVIRONMENT=qa

# Rollback
tkn pipeline start rollback -p TARGET_VERSION=25.01.04.0 -p ENVIRONMENT=prod
```

### Version Format

```
YY.MM.DD.PATCH
25.01.05.0  # January 5, 2025, initial release
25.01.05.1  # January 5, 2025, hotfix
```

---

**Last Updated**: 2025-01-05  
**Maintained By**: Platform Team
