# Documentation Index

**Complete index of all platform documentation**

---

## 🚀 Quick Start

**New to the platform?** Start here:

1. **[Platform README](../README.md)** - Project overview
2. **[Architecture Diagrams](./diagrams/README.md)** - Visual overview
3. **[Constitution](../.specify/memory/constitution.md)** - Core principles (5 articles)
4. **[Getting Started](../GETTING-STARTED.md)** - Quick start guide

**Ready to develop?** Continue with:

5. **[Pre-commit Guide](./PRE-COMMIT-GUIDE.md)** - Install quality tools
6. **[Ansible Best Practices](./ANSIBLE-BEST-PRACTICES.md)** - Essential reading
7. **[Development Guide](../DEVELOPMENT.md)** - Development workflow

---

## 📚 Core Documentation

### 🏗️ Architecture & Design

| Document | Purpose | Diagrams | Audience |
|----------|---------|----------|----------|
| [Architecture Diagrams](./diagrams/README.md) | Visual documentation (index) | 39 | Everyone |
| [Platform Architecture](./diagrams/PLATFORM-ARCHITECTURE.md) | Overall system design | 8 | Architects, stakeholders |
| [GitOps Loops](./diagrams/GITOPS-LOOPS.md) | Dual GitOps loops | 10 | DevOps, operations |
| [Promotion Flow](./diagrams/PROMOTION-FLOW.md) | Release process | 12 | Release managers |
| [Repository Structure](./diagrams/REPOSITORY-STRUCTURE.md) | Git organization | 9 | All developers |

### 🛠️ Development

| Document | Purpose | Audience |
|----------|---------|----------|
| [Development Guide](../DEVELOPMENT.md) | Development workflow | Developers |
| [Dev Containers Guide](./DEV-CONTAINERS-GUIDE.md) | Container development environments | All developers |
| [Ansible Best Practices](./ANSIBLE-BEST-PRACTICES.md) | Ansible-specific practices ⭐ | Ansible developers |
| [Code Style Guide](./CODE-STYLE-GUIDE.md) | Style standards (YAML, Python, Shell) | All developers |
| [Naming Conventions](./NAMING-CONVENTIONS.md) | Naming standards | All developers |

### ✅ Quality & Testing

| Document | Purpose | Audience |
|----------|---------|----------|
| [Pre-commit Guide](./PRE-COMMIT-GUIDE.md) | Pre-commit hooks installation & usage | All developers |
| [Testing Guide](./TESTING-GUIDE.md) | Testing strategies & practices | Developers, QA |
| [Validation & Quality Guide](./VALIDATION-QUALITY-GUIDE.md) | Validation & security scanning | Developers, DevOps |

### 🔄 CI/CD & Release Management

| Document | Purpose | Audience |
|----------|---------|----------|
| [CI/CD Guide](./CICD-GUIDE.md) | Complete workflow documentation | DevOps, developers |
| [Branching Strategy](./BRANCHING-STRATEGY.md) | Trunk-based dev with Git tags | All developers, release managers |
| [EE Versioning Strategy](./EE-VERSIONING-STRATEGY.md) | Execution Environment version locking | DevOps, release managers |

### 📖 Governance

| Document | Purpose | Audience |
|----------|---------|----------|
| [Constitution](../.specify/memory/constitution.md) | Immutable principles (5 articles) | Everyone |
| [Specification](../.specify/memory/specification.md) | Technical requirements | Architects, developers |

---

## 📖 Documentation by Use Case

### "I want to start developing"

1. [Architecture Diagrams](./diagrams/README.md) - Understand the system
2. [Getting Started](../GETTING-STARTED.md) - Quick start
3. [Development Guide](../DEVELOPMENT.md) - Development workflow
4. [Dev Containers Guide](./DEV-CONTAINERS-GUIDE.md) - Setup environment
5. [Pre-commit Guide](./PRE-COMMIT-GUIDE.md) - Install quality tools
6. [Ansible Best Practices](./ANSIBLE-BEST-PRACTICES.md) - Coding standards

### "I need to understand the platform"

1. [Platform README](../README.md) - Overview
2. [Architecture Diagrams](./diagrams/README.md) - Visual documentation
3. [Constitution](../.specify/memory/constitution.md) - Core principles
4. [Specification](../.specify/memory/specification.md) - Detailed requirements

### "I'm doing code review"

1. [Constitution](../.specify/memory/constitution.md) - Compliance check
2. [Ansible Best Practices](./ANSIBLE-BEST-PRACTICES.md) - What to look for
3. [Code Style Guide](./CODE-STYLE-GUIDE.md) - Style validation
4. [Naming Conventions](./NAMING-CONVENTIONS.md) - Naming validation

### "I'm writing tests"

1. [Testing Guide](./TESTING-GUIDE.md) - Complete testing guide
2. [Dev Containers Guide](./DEV-CONTAINERS-GUIDE.md) - Test environment setup
3. [CI/CD Guide](./CICD-GUIDE.md) - CI testing workflows

### "I need to configure CI/CD"

1. [CI/CD Guide](./CICD-GUIDE.md) - Complete guide with quick start
2. [Pre-commit Guide](./PRE-COMMIT-GUIDE.md) - Local validation
3. [Validation & Quality Guide](./VALIDATION-QUALITY-GUIDE.md) - Security scanning

### "I'm onboarding a new team member"

1. [Platform README](../README.md) - Overview
2. [Architecture Diagrams](./diagrams/README.md) - Visual learning
3. [Getting Started](../GETTING-STARTED.md) - Quick start
4. [Dev Containers Guide](./DEV-CONTAINERS-GUIDE.md) - Setup environment
5. [Pre-commit Guide](./PRE-COMMIT-GUIDE.md) - Install tools
6. [Ansible Best Practices](./ANSIBLE-BEST-PRACTICES.md) - Coding standards

---

## 🗂️ Documentation Structure

```
rh1_ansible_code_lifecycle/
├── README.md                              # Project overview
├── GETTING-STARTED.md                     # Quick start guide
├── DEVELOPMENT.md                         # Development workflow
│
├── .specify/memory/                       # Governance
│   ├── constitution.md                    # 5 articles
│   └── specification.md                   # Requirements
│
├── docs/                                  # Core documentation
│   ├── INDEX.md                           # This file
│   │
│   ├── diagrams/                          # Architecture diagrams (39 total)
│   │   ├── README.md                      # Diagram index
│   │   ├── PLATFORM-ARCHITECTURE.md       # System design (8 diagrams)
│   │   ├── GITOPS-LOOPS.md                # GitOps loops (10 diagrams)
│   │   ├── PROMOTION-FLOW.md              # Release process (12 diagrams)
│   │   └── REPOSITORY-STRUCTURE.md        # Git organization (9 diagrams)
│   │
│   ├── DEV-CONTAINERS-GUIDE.md           # Development environments
│   ├── VALIDATION-QUALITY-GUIDE.md       # Validation & security
│   │
│   ├── PRE-COMMIT-GUIDE.md               # Pre-commit hooks (consolidated)
│   ├── CICD-GUIDE.md                     # CI/CD workflows (with quick start)
│   ├── BRANCHING-STRATEGY.md             # Git workflow (trunk-based + tags)
│   ├── EE-VERSIONING-STRATEGY.md         # Execution Environment version locking
│   ├── TESTING-GUIDE.md                  # Testing strategies
│   │
│   ├── ANSIBLE-BEST-PRACTICES.md         # Ansible practices ⭐
│   ├── CODE-STYLE-GUIDE.md               # Style standards
│   └── NAMING-CONVENTIONS.md             # Naming standards
│
└── templates/                             # Configuration templates
    └── aap-config/
        └── complete-example.yml           # Complete AAP config
```

---

## 📊 Documentation Statistics

- **Core Documents**: 12 files
- **Diagram Documents**: 5 files (39 diagrams)
- **Total Lines**: ~27,000 lines
- **Code Examples**: 250+
- **Diagrams**: 40+ Mermaid.js diagrams
- **External References**: 30+
- **Internal Cross-refs**: 85+

---

## 🎓 Learning Paths

### Beginner Path (Developers)

```
1. README.md
   ↓
2. Architecture Diagrams (visual overview)
   ↓
3. GETTING-STARTED.md
   ↓
4. Dev Containers Guide (setup)
   ↓
5. Pre-commit Guide (quality tools)
   ↓
6. Ansible Best Practices
   ↓
7. Testing Guide
```

### Advanced Path (Architects)

```
1. Constitution (principles)
   ↓
2. Specification (requirements)
   ↓
3. Architecture Diagrams (all 4 docs)
   ↓
4. CI/CD Guide (automation)
   ↓
5. Validation & Quality Guide (security)
```

### Operations Path (DevOps)

```
1. GitOps Loops diagram
   ↓
2. Promotion Flow diagram
   ↓
3. CI/CD Guide
   ↓
4. Testing Guide
   ↓
5. Validation & Quality Guide
```

---

## 🔍 Finding Information

### By Topic

- **Architecture**: [diagrams/](./diagrams/)
- **Development Environment**: [DEV-CONTAINERS-GUIDE.md](./DEV-CONTAINERS-GUIDE.md)
- **Pre-commit hooks**: [PRE-COMMIT-GUIDE.md](./PRE-COMMIT-GUIDE.md)
- **CI/CD**: [CICD-GUIDE.md](./CICD-GUIDE.md)
- **Testing**: [TESTING-GUIDE.md](./TESTING-GUIDE.md)
- **Validation & Security**: [VALIDATION-QUALITY-GUIDE.md](./VALIDATION-QUALITY-GUIDE.md)
- **Ansible Standards**: [ANSIBLE-BEST-PRACTICES.md](./ANSIBLE-BEST-PRACTICES.md)
- **Code Style**: [CODE-STYLE-GUIDE.md](./CODE-STYLE-GUIDE.md)
- **Naming**: [NAMING-CONVENTIONS.md](./NAMING-CONVENTIONS.md)
- **Templates**: `../templates/aap-config/`

### By Role

- **Developer**: Development Guide, Ansible Best Practices, Code Style Guide, Repository Structure
- **Reviewer**: Constitution, Ansible Best Practices, Code Style Guide, Naming Conventions
- **Tester**: Testing Guide, Dev Containers Guide
- **DevOps**: CI/CD Guide, Pre-commit Guide, GitOps Loops, Promotion Flow, Validation & Quality Guide
- **Architect**: Constitution, Specification, All Architecture Diagrams
- **Release Manager**: Promotion Flow, Validation & Quality Guide
- **New Team Member**: README, Architecture Diagrams, Getting Started, Dev Containers Guide, Pre-commit Guide

---

## 🌟 Key Documents (Must Read)

### Top 5 for Developers

1. **[Ansible Best Practices](./ANSIBLE-BEST-PRACTICES.md)** ⭐ - Essential reading
2. **[Pre-commit Guide](./PRE-COMMIT-GUIDE.md)** - First setup step
3. **[Architecture Diagrams](./diagrams/README.md)** - Understand the system
4. **[Testing Guide](./TESTING-GUIDE.md)** - How to test
5. **[Naming Conventions](./NAMING-CONVENTIONS.md)** - Name things correctly

### Top 5 for Platform Understanding

1. **[Architecture Diagrams](./diagrams/README.md)** ⭐ - Visual overview (start here!)
2. **[Constitution](../.specify/memory/constitution.md)** - The why
3. **[Specification](../.specify/memory/specification.md)** - The what
4. **[GitOps Loops](./diagrams/GITOPS-LOOPS.md)** - How it works
5. **[CI/CD Guide](./CICD-GUIDE.md)** - The automation

---

## 📱 Quick Reference

### Code Review Checklist

- ✅ Follows [Naming Conventions](./NAMING-CONVENTIONS.md)
- ✅ Adheres to [Code Style Guide](./CODE-STYLE-GUIDE.md)
- ✅ Implements [Ansible Best Practices](./ANSIBLE-BEST-PRACTICES.md)
- ✅ Passes pre-commit hooks
- ✅ Has appropriate tests
- ✅ Complies with [Constitution](../.specify/memory/constitution.md)

### Pre-commit Quick Commands

```bash
pre-commit install                  # Install hooks
pre-commit run --all-files         # Run all hooks
pre-commit autoupdate              # Update hook versions
```

See: [Pre-commit Guide](./PRE-COMMIT-GUIDE.md)

### Testing Quick Commands

```bash
# Run all tests
./tests/run-tests.sh

# Run specific test type
pre-commit run molecule-test
ansible-test sanity --docker
```

See: [Testing Guide](./TESTING-GUIDE.md)

---

## 🔄 Document Updates

### Recent Changes (v2.0 - 2025-01-04)

**Consolidation & Cleanup**:
- ✅ Merged PRE-COMMIT-SETUP + PRE-COMMIT-REFERENCE → **PRE-COMMIT-GUIDE.md**
- ✅ Added quick start to **CICD-GUIDE.md**
- ✅ Removed 6 redundant summary/completion docs
- ✅ Streamlined from ~20 docs to **10 core docs** (+ 5 diagram docs)
- ✅ Improved documentation navigation and discoverability

**Key Improvements**:
- Eliminated redundancy between docs
- Consolidated related information
- Added quick start sections
- Improved cross-referencing
- Cleaner, more maintainable structure

### Version History

- **v2.0** (2025-01-04): Documentation consolidation
  - Reduced from 20+ to 10 core documents
  - Merged redundant guides
  - Added quick start sections
  - Improved organization and navigation
  
- **v1.2** (2025-01-04): Architecture documentation
  - Added 39 Mermaid.js diagrams
  - Created comprehensive visual documentation
  
- **v1.1** (2025-11-04): Development tooling & validation
  - Added development containers guide
  - Added validation & quality guide
  
- **v1.0** (2025-10-30): Initial complete documentation set
  - All core guides created
  - Standards documented
  - Examples provided

---

## 💡 Tips

- **Bookmark this index** for quick navigation
- **Use Ctrl+F** to search for specific topics
- **Check "Quick Reference"** sections in each guide
- **Follow external links** for deeper understanding
- **Start with diagrams** for visual learners

---

**Last Updated**: 2025-01-04  
**Version**: 2.0 (Consolidated)  
**Maintained By**: Platform Team  
**Total Content**: 15 documents (10 core + 5 diagrams), 39 diagrams, ~23,000 lines  
**Feedback**: File issues or submit PRs to improve documentation
