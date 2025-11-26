# Constitution - Cloud-Native Ansible Lifecycle Platform

This document defines the immutable principles that govern all technical decisions in this project.

## Article I: GitOps First

**Law**: All configuration must be declarative and stored in Git.

### Mandates:
1. **Single Source of Truth**: Git repositories are the only source of truth for all configuration
2. **No Manual Changes**: Manual changes to running systems are forbidden
3. **Auditability**: Every change must be traceable through Git history

### Violations:
- ❌ Manual `oc apply` commands (except bootstrap)
- ❌ Manual AAP UI configuration changes
- ❌ Secrets stored in Git

### Compliance:
- ✅ ArgoCD manages all platform resources
- ✅ Tekton pipelines apply all AAP configuration
- ✅ Git commits are the audit trail

## Article II: Separation of Duties

**Law**: Platform operations and application operations must be separated.

### Mandates:
1. **Platform GitOps** (ArgoCD): Manages Kubernetes resources, operators, CRDs
2. **Application GitOps** (Tekton): Manages application-level configuration via APIs
3. **Single-Purpose Tools**: Each tool does one thing well

### Violations:
- ❌ Using ArgoCD to configure AAP via API
- ❌ Using Tekton to manage Kubernetes resources
- ❌ Mixed responsibilities in single pipeline

### Compliance:
- ✅ ArgoCD deploys AAP CR, Tekton, RBAC
- ✅ Tekton configures AAP via infra.aap_configuration
- ✅ Clear boundaries between platform and application

## Article III: Atomic Promotion

**Law**: All components must be promoted together as a single, version-locked unit.

### Mandates:
1. **Release Manifests**: Define exact versions of all components
2. **Atomicity**: EE + CaC + Code promoted together
3. **Atomic Rollback**: Rollback to previous manifest restores entire system

### Violations:
- ❌ Promoting individual components separately
- ❌ Using "latest" tags in QA/Prod
- ❌ Manual version selection

### Compliance:
- ✅ Release manifest locks all Git SHAs and image tags
- ✅ Promotion pipeline reads manifest and deploys everything
- ✅ Rollback uses previous manifest

## Article IV: Production-Grade Quality

**Law**: All automation must meet production-grade quality standards.

### Mandates:
1. **Idempotency**: All playbooks/roles must be idempotent
2. **Testing**: All code must have automated tests (molecule, ansible-lint)
3. **Modularity**: Roles and collections must be reusable
4. **Configuration Abstraction**: No hardcoded values

### Violations:
- ❌ Non-idempotent tasks
- ❌ Code without tests
- ❌ Hardcoded IP addresses, passwords, URLs

### Compliance:
- ✅ All roles tested with Molecule
- ✅ Ansible-lint enforced in CI
- ✅ Variables abstracted in group_vars
- ✅ Playbooks safe to run multiple times

## Article V: Zero-Trust Security

**Law**: No secrets in Git, least-privilege access, immutable infrastructure.

### Mandates:
1. **No Secrets in Git**: Secrets referenced by name, stored in OCP Secrets
2. **Reference by Name**: Code references secret names, not values
3. **Least Privilege**: ServiceAccounts have minimum required permissions

### Violations:
- ❌ Passwords, tokens, keys in Git
- ❌ Cluster-admin permissions
- ❌ Secrets in environment variables in Git

### Compliance:
- ✅ Secrets in OCP, referenced by Tekton
- ✅ AAP operator auto-generates admin passwords
- ✅ ServiceAccounts with Role-based permissions
- ✅ Credentials mounted as env vars at runtime

---

## Enforcement

All Pull Requests must pass constitution compliance checks:
- CI pipelines enforce linting and testing
- Code reviews verify GitOps and security principles
- Documentation must explain constitutional compliance

## Amendment Process

This constitution can only be amended through:
1. Team consensus (unanimous)
2. Documentation of rationale
3. Update to all affected systems

---

**Ratified**: 2025-10-27
**Last Amended**: 2025-10-29

