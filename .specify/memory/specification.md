# Project Specification - Cloud-Native Ansible Lifecycle Platform

## Executive Summary

Build a production-grade, end-to-end CI/CD and GitOps framework for Ansible automation on OpenShift, managing multi-tenant AAP deployments with atomic promotion capabilities.

## Goals

1. **GitOps Everything**: All configuration in Git, no manual changes
2. **Atomic Promotion**: EE + CaC + Code promoted together
3. **Fast Feedback**: <1min inner loop, <5min promotion
4. **Zero Secrets in Git**: All secrets in OCP, referenced by name
5. **Production Quality**: 100% idempotent, tested, documented

## System Architecture

### Component Overview

| Component | Purpose | Technology |
|-----------|---------|------------|
| cluster-config | Platform GitOps | ArgoCD |
| aap-config-as-code | App GitOps | Tekton + infra.aap_configuration |
| automation-collection-example | Custom content | Ansible Collection |
| automation-ee-example | Runtime environment | ansible-builder |
| automation-release-manifest | Version locking | YAML manifests |

### Dual GitOps Loops

**Platform Loop (ArgoCD)**:
- Manages: Namespaces, Operators, AAP CRs, Tekton, RBAC
- Triggered: Git commit → ArgoCD sync
- Scope: Kubernetes resources

**Application Loop (Tekton)**:
- Manages: AAP configuration (projects, templates, credentials)
- Triggered: Git commit → Webhook → Tekton
- Scope: AAP API calls

## Repository Specifications

### 1. cluster-config
- **URL**: https://github.com/djdanielsson/rh1-cluster-config.git
- **Purpose**: Deploy AAP + Tekton on OpenShift
- **Pattern**: ArgoCD Application-of-Applications
- **Key Files**:
  - `argocd/root-app.yaml` - Bootstrap everything
  - `operators/aap-operator.yaml` - Namespace-scoped AAP operators
  - `aap-instances/*.yaml` - AAP CRs for dev/qa/prod
  - `tekton/pipelines/*.yaml` - CI/CD pipelines

### 2. aap-config-as-code
- **URL**: https://github.com/djdanielsson/rh1-aap-config-as-code.git
- **Purpose**: Configure AAP via API
- **Pattern**: dispatch role with wildcard variables
- **Key Files**:
  - `playbook.yml` - Uses infra.aap_configuration.dispatch
  - `group_vars/all/*` - Common config
  - `group_vars/aap_dev/*` - Dev-specific config

### 3. automation-collection-example
- **URL**: https://github.com/djdanielsson/rh1-custom-collection.git
- **Purpose**: Custom Ansible content
- **Pattern**: ansible-creator collection
- **Key Features**:
  - Roles with Molecule tests
  - Custom modules, filters, plugins
  - CI/CD integration

### 4. automation-ee-example
- **URL**: https://github.com/djdanielsson/rh1-custom-ee.git
- **Purpose**: Custom execution environment
- **Pattern**: ansible-builder
- **Contents**: Base image + collections + dependencies

### 5. automation-release-manifest
- **URL**: https://github.com/djdanielsson/rh1-release-manifest.git
- **Purpose**: Version-lock all components
- **Pattern**: YAML manifests with Git SHAs
- **Format**:
  ```yaml
  version: "1.0.0"
  components:
    aap_configuration: "abc123..."
    execution_environment: "def456..."
    collections: "ghi789..."
  ```

## Workflows

### 1. Platform Bootstrap
```
1. Install GitOps operator
2. oc apply -f argocd/root-app.yaml
3. ArgoCD creates everything automatically:
   - Namespaces
   - AAP operators
   - AAP instances
   - Tekton
   - RBAC
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
1. Create release manifest with locked versions
2. git tag v1.0.0
3. Promotion pipeline:
   - Reads manifest
   - Builds EE with exact collections
   - Deploys to QA
   - Runs validation
   - Waits for approval
   - Deploys to Prod
```

## Success Criteria

- ✅ Single `oc apply` bootstraps entire platform
- ✅ <1min PR validation feedback
- ✅ <5min atomic promotion to QA
- ✅ Zero secrets in any Git repository
- ✅ 100% idempotent automation
- ✅ Complete audit trail via Git log
- ✅ Atomic rollback capability

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
- Comprehensive documentation
- Self-documenting code
- Consistent patterns across all repos

---

**Version**: 1.0  
**Status**: Implementation Phase  
**Last Updated**: 2025-10-29

