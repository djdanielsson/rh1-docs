# Cloud-Native Ansible Lifecycle - Feature Specification

**Feature ID**: 001
**Status**: Implementation Phase
**Created**: 2025-10-27
**Updated**: 2025-10-29

## Quick Links

- [Constitution](../../.specify/memory/constitution.md) - Project principles and laws
- [Specification](../../.specify/memory/specification.md) - Detailed requirements
- [Implementation Plan](./plan.md) - This feature's implementation plan
- [Tasks](./tasks.md) - Detailed task breakdown
- [Quickstart](./quickstart.md) - Quick start guide

## Overview

Building a production-grade, end-to-end CI/CD and GitOps framework for Ansible automation on OpenShift. The system manages a multi-tenant Ansible Automation Platform (AAP) deployment across Dev/QA/Prod environments with atomic promotion capabilities.

## Architecture Summary

### Dual GitOps Loops

1. **Platform Loop** (ArgoCD)
   - Repository: `cluster-config/`
   - Manages: Kubernetes resources, AAP CRs, Tekton Pipelines, RBAC

2. **Application Loop** (Tekton)
   - Repository: `aap-config-as-code/`
   - Manages: AAP configuration via API (Job Templates, Projects, Credentials)

### Repository Ecosystem

- **`cluster-config/`** - Platform GitOps (ArgoCD)
  - Location: https://github.com/djdanielsson/rh1-cluster-config.git
  - Purpose: Deploy AAP, Tekton, RBAC on OpenShift

- **`aap-config-as-code/`** - Application GitOps (Tekton)
  - Location: https://github.com/djdanielsson/rh1-aap-config-as-code.git
  - Purpose: Configure AAP via infra.aap_configuration collection

- **`automation-collection-example/`** - Ansible Collection template
  - Location: https://github.com/djdanielsson/rh1-custom-collection.git
  - Purpose: Custom Ansible collection with roles, modules, playbooks

- **`automation-ee-example/`** - Execution Environment template
  - Location: https://github.com/djdanielsson/rh1-custom-ee.git
  - Purpose: Container image with Ansible + dependencies

- **`automation-release-manifest/`** - Release Bill of Materials
  - Location: https://github.com/djdanielsson/rh1-release-manifest.git
  - Purpose: Version-lock all components for atomic promotion

## Constitution Compliance

All five articles of the Constitution are validated:

- ✓ **Article I**: GitOps (Single Source of Truth, No Manual Changes, Auditability)
- ✓ **Article II**: Separation of Duties (Platform vs Application, Single-Purpose Tools)
- ✓ **Article III**: Atomic Promotion (Release Manifests, Atomicity, Atomic Rollback)
- ✓ **Article IV**: Production-Grade Quality (Idempotency, Testing, Modularity, Config Abstraction)
- ✓ **Article V**: Zero-Trust Security (No Secrets in Git, Reference by Name, Least Privilege)

## Key Workflows

1. **Platform Bootstrap** - Single ArgoCD root-app.yaml bootstraps entire system
2. **Application CaC** - Webhook-triggered pipeline applies AAP configuration
3. **Developer Inner Loop** - <1min feedback on feature branches
4. **PR Validation** - Mandatory ansible-lint + molecule tests
5. **Atomic Promotion** - Version-locked release of EE + CaC + Code to QA/Prod

## Current Phase

**Phase 1**: Repository Setup & Content Generation ✅
- ✅ cluster-config repository created and populated
- ✅ aap-config-as-code repository created with dispatch/wildcard pattern
- 🔄 automation-collection-example (next)
- ⏳ automation-ee-example
- ⏳ automation-release-manifest

## Repository Status

### ✅ Completed
1. **cluster-config/** - Complete with ArgoCD, Tekton, AAP CRs
   - ArgoCD Application-of-Applications pattern
   - Namespace-scoped AAP operators
   - Tekton Tasks, Pipelines, Triggers
   - Comprehensive documentation

2. **aap-config-as-code/** - Complete with dispatch pattern
   - Using infra.aap_configuration dispatch role
   - Wildcard variable merging (_dev, _qa, _prod suffixes)
   - Organized group_vars by environment
   - Custom credential types with !unsafe tags

### 🔄 In Progress
3. **automation-collection-example/** - To be created as subdirectory
   - Use ansible-creator to generate structure
   - Add molecule testing scenarios
   - Example roles and playbooks

### ⏳ Pending
4. **automation-ee-example/**
5. **automation-release-manifest/**

## Next Actions

1. Create `automation-collection-example/` subdirectory as separate git repo
2. Use `ansible-creator init collection` to generate structure
3. Add molecule testing with `molecule init scenario`
4. Create example roles and documentation
5. Move to automation-ee-example
6. Finally create release-manifest repository

## Success Metrics

- Sub-5min atomic promotion
- <1min inner loop feedback
- Zero secrets in Git (100% compliance)
- 100% idempotent playbooks
- Complete audit trail via Git log

## Directory Structure

```
rh1_ansible_code_lifecycle/              # Project workspace (not a git repo)
├── specs/                               # Project specifications and planning
│   └── 001-cloud-native-ansible-lifecycle/
│       ├── README.md                    # This file
│       ├── quickstart.md                # Getting started guide
│       ├── plan.md                      # Implementation plan
│       └── tasks.md                     # Task breakdown
├── .specify/                            # Constitution and specifications
│   └── memory/
│       ├── constitution.md
│       └── specification.md
├── cluster-config/                      # Git repo 1
├── aap-config-as-code/                  # Git repo 2
├── automation-collection-example/       # Git repo 3 (to create)
├── automation-ee-example/               # Git repo 4 (to create)
└── automation-release-manifest/         # Git repo 5 (to create)
```

---

**Maintained by**: Infrastructure Team
**Last Updated**: 2025-10-29

