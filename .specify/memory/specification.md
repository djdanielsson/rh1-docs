# Project Specification - Cloud-Native Ansible Lifecycle Platform

## Executive Summary

Build a production-grade, end-to-end CI/CD and GitOps framework for Ansible automation on OpenShift, managing multi-tenant AAP deployments with atomic promotion capabilities.

---

## Goals

1. **GitOps Everything**: All configuration in Git, no manual changes
2. **Atomic Promotion**: EE + CaC + Code promoted together via release manifests
3. **Fast Feedback**: <1min inner loop, <5min promotion
4. **Zero Secrets in Git**: All secrets in OCP/Vault, referenced by name
5. **Production Quality**: 100% idempotent, tested, documented

---

## System Architecture

### Component Overview

| Component | Purpose | Technology |
|-----------|---------|------------|
| cluster-config | Platform GitOps | ArgoCD (ApplicationSet) |
| aap-config-as-code | App GitOps | Tekton + infra.aap_configuration |
| automation-collection-example | Custom content | Ansible Collection |
| automation-ee-example | Runtime environment | ansible-builder |
| automation-release-manifest | Version locking | YAML manifests + Tekton pipelines |

### Dual GitOps Loops

**Platform Loop (ArgoCD)**:
- Manages: Namespaces, Operators, AAP CRs, Tekton, RBAC
- Triggered: Git commit → ArgoCD sync
- Scope: Kubernetes resources

**Application Loop (Tekton)**:
- Manages: AAP configuration (projects, templates, credentials)
- Triggered: Git commit → Webhook → Tekton
- Scope: AAP API calls

---

## Repository Specifications

### 1. cluster-config
- **URL**: https://github.com/djdanielsson/rh1-cluster-config.git
- **Purpose**: Deploy AAP + Tekton on OpenShift
- **Pattern**: ArgoCD ApplicationSet with auto-discovery
- **Key Directories**:
  - `bootstrap-openshift-gitops/` - GitOps operator + ApplicationSet
  - `applications/aap-dev/`, `aap-qa/`, `aap-prod/` - AAP environments
  - `applications/openshift-pipelines/` - Tekton operator

### 2. aap-config-as-code
- **URL**: https://github.com/djdanielsson/rh1-aap-config-as-code.git
- **Purpose**: Configure AAP via API
- **Pattern**: dispatch role with wildcard variables
- **Key Files**:
  - `playbooks/playbook.yml` - Uses infra.aap_configuration.dispatch
  - `inventory/group_vars/all/*` - Common config
  - `inventory/group_vars/aap_dev/*` - Dev-specific config

### 3. automation-collection-example
- **URL**: https://github.com/djdanielsson/rh1-custom-collection.git
- **Purpose**: Custom Ansible content
- **Pattern**: ansible-creator collection
- **Contents**:
  - 4 roles with Molecule tests
  - 2 custom modules
  - 4 filter plugins
  - 2 lookup plugins

### 4. automation-ee-example
- **URL**: https://github.com/djdanielsson/rh1-custom-ee.git
- **Purpose**: Custom execution environment
- **Pattern**: ansible-builder
- **Base Image**: registry.redhat.io/ansible-automation-platform-26/ee-minimal-rhel9

### 5. automation-release-manifest
- **URL**: https://github.com/djdanielsson/rh1-release-manifest.git
- **Purpose**: Version-lock all components
- **Pattern**: YAML manifests with Tekton pipelines
- **Tekton Pipelines**:
  - `create-release` - Create new release manifest
  - `promote` - Promote between environments
  - `rollback` - Rollback to previous version

---

## Versioning

### Standard: CalVer YY.MM.DD.PATCH

```
25.01.05.0  # January 5, 2025, initial release
25.01.05.1  # January 5, 2025, hotfix
25.01.06.0  # January 6, 2025, new release
```

Applied consistently across:
- Git tags
- Collection versions (galaxy.yml)
- EE image tags
- Release manifest versions

---

## Workflows

### 1. Platform Bootstrap
```
1. Install GitOps operator
2. oc apply -f bootstrap-openshift-gitops/cluster-applicationset.yml
3. ArgoCD creates everything automatically:
   - Namespaces (aap-dev, aap-qa, aap-prod)
   - AAP operators (namespace-scoped)
   - AAP instances
   - Tekton pipelines
```

### 2. Developer Inner Loop
```
1. Edit collection code
2. git push to feature branch
3. PR validation pipeline runs:
   - ansible-lint
   - molecule test
4. <1min feedback
```

### 3. Configuration as Code
```
1. Edit group_vars/aap_dev/job_templates.yml
2. git push to main
3. Webhook triggers CaC pipeline
4. Pipeline runs playbook with dispatch role
5. Changes applied to Dev AAP
```

### 4. Atomic Promotion
```
1. Create release:
   tkn pipeline start create-release -p VERSION=25.01.05.0
2. Promote to QA:
   tkn pipeline start promote -p VERSION=25.01.05.0 -p FROM=dev -p TO=qa
3. After QA validation, promote to Prod:
   tkn pipeline start promote -p VERSION=25.01.05.0 -p FROM=qa -p TO=prod
```

### 5. Rollback
```
1. Issue detected in production
2. Rollback to previous version:
   tkn pipeline start rollback -p TARGET_VERSION=25.01.04.0 -p ENVIRONMENT=prod
3. All components restored atomically
```

---

## Success Criteria

- ✅ Single `oc apply` bootstraps entire platform
- ✅ <1min PR validation feedback
- ✅ <5min atomic promotion to QA
- ✅ Zero secrets in any Git repository
- ✅ 100% idempotent automation
- ✅ Complete audit trail via Git log
- ✅ Atomic rollback capability via Tekton pipeline

---

## Non-Functional Requirements

### Performance
- Inner loop: <1 minute
- CaC pipeline: <3 minutes
- Atomic promotion: <5 minutes

### Reliability
- All automation idempotent
- Automatic retry on transient failures
- Rollback capability for all changes

### Security
- No secrets in Git (enforced by pre-commit)
- Least-privilege RBAC
- Secrets mounted at runtime only
- Audit trail for all changes

### Maintainability
- Comprehensive documentation in `docs/`
- Self-documenting code
- Consistent patterns across all repos

---

**Version**: 1.1  
**Status**: Implementation Phase  
**Last Updated**: 2025-01-05
