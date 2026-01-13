# Disaster Recovery Guide

**Purpose**: Procedures for recovering from various failure scenarios
**Last Updated**: 2025-01-05

---

## Recovery Philosophy

Since this platform follows GitOps principles (Constitution Article I), recovery is primarily about:
1. **Restoring Git access** - Git is the source of truth
2. **Reapplying configuration** - ArgoCD and Tekton rebuild from Git
3. **Restoring secrets** - From HashiCorp Vault backup

---

## Failure Scenarios

### 1. ArgoCD Goes Down

**Symptoms**: Applications not syncing, ArgoCD UI unavailable

**Recovery Steps**:
```bash
# 1. Check GitOps operator status
oc get csv -n openshift-operators | grep gitops

# 2. If operator is healthy, restart ArgoCD
oc rollout restart deployment/openshift-gitops-server -n openshift-gitops
oc rollout restart deployment/openshift-gitops-application-controller -n openshift-gitops

# 3. If operator is unhealthy, reinstall
oc delete subscription openshift-gitops-operator -n openshift-operators
oc apply -f bootstrap-openshift-gitops/openshift-gitops-operator-subscription.yml

# 4. Reapply ApplicationSet
oc apply -f bootstrap-openshift-gitops/cluster-applicationset.yml
```

**RTO**: ~10 minutes

---

### 2. AAP Instance Corrupted

**Symptoms**: AAP UI unavailable, jobs failing, database errors

**Recovery Steps**:
```bash
# 1. Check AAP CR status
oc describe ansibleautomationplatform aap-dev -n aap-dev

# 2. If operator can recover, delete and let ArgoCD recreate
oc delete ansibleautomationplatform aap-dev -n aap-dev
# ArgoCD will recreate from Git within 3 minutes

# 3. If namespace is corrupted, delete entire namespace
oc delete namespace aap-dev
# ArgoCD will recreate namespace and all resources

# 4. Reapply AAP configuration via Tekton CaC pipeline
# (Or manually run playbook)
cd aap-config-as-code
ansible-playbook playbooks/playbook.yml --limit aap_dev
```

**RTO**: ~15 minutes (AAP operator recreation takes time)

---

### 3. Entire Namespace Deleted

**Symptoms**: Namespace and all resources gone

**Recovery Steps**:
```bash
# ArgoCD will automatically detect drift and recreate
# Just wait ~3 minutes for sync cycle

# To force immediate sync:
oc patch application aap-dev -n openshift-gitops \
  --type merge \
  --patch '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'

# After namespace recreates, reapply CaC
cd aap-config-as-code
ansible-playbook playbooks/playbook.yml --limit aap_dev
```

**RTO**: ~15-20 minutes

---

### 4. Git Repository Unavailable

**Symptoms**: ArgoCD shows "Unknown" status, no syncs happening

**Impact**: New changes cannot be applied, but running workloads continue

**Recovery Steps**:
1. **If GitHub outage**: Wait for GitHub to recover
2. **If repository deleted**: Restore from backup or mirror

**Prevention**:
```bash
# Maintain repository mirrors
git clone --mirror https://github.com/djdanielsson/rh1-cluster-config.git
git clone --mirror https://github.com/djdanielsson/rh1-aap-config-as-code.git
# ... etc

# Consider GitLab or Gitea as secondary Git server
```

**RTO**: Depends on Git provider recovery

---

### 5. Secrets Lost (Vault Unavailable)

**Symptoms**: Pipelines failing with auth errors, AAP can't connect to SCM

**Recovery Steps**:
```bash
# 1. Restore HashiCorp Vault from backup
# (Vault-specific recovery procedures)

# 2. If Vault is permanently lost, regenerate secrets:
#    - GitHub tokens: Create new in GitHub settings
#    - Registry tokens: Create new in Quay.io/registry
#    - AAP tokens: AAP operator regenerates admin password

# 3. Update secrets in Vault

# 4. Restart affected pipelines
tkn pipelinerun delete --all -n aap-config-as-code-ci
# Trigger new run via webhook or manual
```

**RTO**: Depends on Vault recovery and secret regeneration

---

### 6. Complete Cluster Loss

**Symptoms**: Entire OpenShift cluster is gone

**Recovery Steps**:
```bash
# 1. Provision new OpenShift cluster

# 2. Bootstrap from Git (same as initial install)
oc apply -f bootstrap-openshift-gitops/openshift-gitops-operator-subscription.yml
# Wait for operator...
oc apply -f bootstrap-openshift-gitops/cluster-applicationset.yml

# 3. Restore secrets from Vault backup to new cluster

# 4. ArgoCD will recreate everything from Git
# Wait 15-20 minutes for full platform deployment

# 5. Verify all applications synced
oc get applications -n openshift-gitops
```

**RTO**: ~30-60 minutes (cluster provisioning + GitOps sync)

---

## Rollback Procedures

### Application Rollback (AAP Config)

Use the rollback script to deploy a previous version:

```bash
# View available versions
ls automation-release-manifest/releases/

# Rollback to previous version using Tekton pipeline
tkn pipeline start rollback \
  -p TARGET_VERSION=26.1.4-0 \
  -p ENVIRONMENT=prod \
  -p REASON="Rollback due to incident" \
  -w name=source,volumeClaimTemplateFile=pvc-template.yaml \
  -w name=aap-config,volumeClaimTemplateFile=pvc-template.yaml

# This will:
# 1. Validate target version manifest exists
# 2. Extract component versions from manifest
# 3. Checkout exact AAP config commit
# 4. Apply previous CaC configuration
# 5. Record rollback in manifest history
```

### Platform Rollback (Kubernetes Resources)

```bash
# Git revert approach
cd cluster-config
git log --oneline -10  # Find previous good commit
git revert <bad-commit-sha>
git push origin main

# ArgoCD syncs to reverted state automatically
```

---

## Backup Requirements

### What to Backup

| Component | Backup Method | Frequency |
|-----------|---------------|-----------|
| Git repositories | GitHub mirrors, GitLab backup | Continuous |
| HashiCorp Vault | Vault snapshot | Daily |
| AAP Database | PostgreSQL pg_dump | Daily |
| Release Manifests | Already in Git | Continuous |
| Container Images | Registry replication | On push |

### Backup Verification

```bash
# Monthly backup verification
# 1. Spin up test cluster
# 2. Restore from backups
# 3. Verify platform functionality
# 4. Document any issues
```

---

## Contacts

| Role | Contact | Escalation |
|------|---------|------------|
| Platform Team | platform-team@example.com | PagerDuty |
| Vault Admin | vault-admin@example.com | Slack #vault |
| OpenShift Admin | ocp-admin@example.com | PagerDuty |

---

## Related Documents

- [DEPLOYMENT.md](../cluster-config/DEPLOYMENT.md) - Initial deployment
- [GIT-WORKFLOW.md](./GIT-WORKFLOW.md) - Versioning and promotion
- [CICD-GUIDE.md](./CICD-GUIDE.md) - Pipeline operations


