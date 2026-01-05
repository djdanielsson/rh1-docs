# AAP Upgrade Guide

**Purpose**: Procedures for upgrading Ansible Automation Platform versions
**Last Updated**: 2025-01-05

---

## Overview

AAP upgrades follow the standard promotion path: **Dev → QA → Prod**. This ensures upgrades are tested before reaching production.

---

## Upgrade Strategy

### Phase 1: Dev Environment

1. **Update Dev AAP CR** with new version
2. **Test thoroughly** in Dev
3. **Validate all workflows** work correctly
4. **Document any breaking changes**

### Phase 2: QA Environment

1. **Update QA AAP CR** with same version
2. **Run full test suite**
3. **QA team validates**
4. **Get sign-off**

### Phase 3: Prod Environment

1. **Schedule maintenance window**
2. **Update Prod AAP CR**
3. **Monitor closely**
4. **Rollback if issues**

---

## Pre-Upgrade Checklist

```markdown
## AAP Upgrade Checklist - Version X.Y.Z

### Planning
- [ ] Review AAP release notes
- [ ] Identify breaking changes
- [ ] Check collection compatibility
- [ ] Verify EE base image compatibility
- [ ] Schedule maintenance windows
- [ ] Notify stakeholders

### Dev Environment
- [ ] Backup Dev AAP database
- [ ] Update operator subscription channel
- [ ] Update AAP CR image version
- [ ] Verify operator upgrades successfully
- [ ] Run smoke tests
- [ ] Test all job templates
- [ ] Verify webhooks working
- [ ] Test EE pulling

### QA Environment (after Dev success)
- [ ] Backup QA AAP database
- [ ] Update QA operator and CR
- [ ] Run full integration tests
- [ ] QA team validation
- [ ] Sign-off obtained

### Prod Environment (after QA success)
- [ ] Backup Prod AAP database
- [ ] Maintenance window confirmed
- [ ] Update Prod operator and CR
- [ ] Monitor upgrade progress
- [ ] Verify all job templates
- [ ] Test critical workflows
- [ ] Close maintenance window
```

---

## Upgrade Procedures

### Step 1: Update Operator Subscription

```yaml
# cluster-config/applications/aap-dev/aap-dev-subscription.yml
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: ansible-automation-platform-operator
  namespace: aap-dev
spec:
  channel: 'stable-2.5'  # Change to new channel, e.g., stable-2.6
  installPlanApproval: Automatic
  name: ansible-automation-platform-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
```

### Step 2: Commit and Push (Dev First)

```bash
cd cluster-config

# Update Dev subscription
vi applications/aap-dev/aap-dev-subscription.yml
# Change channel to new version

git add applications/aap-dev/
git commit -m "Upgrade AAP Dev to 2.6

- Updated operator channel to stable-2.6
- Testing before QA/Prod rollout"

git push origin main

# ArgoCD will sync and upgrade Dev automatically
```

### Step 3: Verify Dev Upgrade

```bash
# Watch operator upgrade
oc get csv -n aap-dev -w

# Check AAP status
oc describe ansibleautomationplatform aap-dev -n aap-dev

# Verify pods are running
oc get pods -n aap-dev

# Get AAP version
curl -k https://$(oc get route aap-dev -n aap-dev -o jsonpath='{.spec.host}')/api/v2/ping/
```

### Step 4: Test Dev Environment

```bash
# Run smoke tests
ansible-playbook tests/test-playbooks/smoke-test.yml

# Test CaC pipeline
cd aap-config-as-code
ansible-playbook playbooks/playbook.yml --limit aap_dev --check

# Verify job templates work
# (manually trigger some jobs in AAP UI)
```

### Step 5: Promote to QA

After Dev is validated (typically 1-2 weeks):

```bash
cd cluster-config

# Update QA subscription
vi applications/aap-qa/aap-qa-subscription.yml
# Change channel to match Dev

git add applications/aap-qa/
git commit -m "Upgrade AAP QA to 2.6

- Dev tested for 2 weeks
- All smoke tests passing
- Ready for QA validation"

git push origin main
```

### Step 6: Promote to Prod

After QA validation and sign-off:

```bash
cd cluster-config

# Update Prod subscription
vi applications/aap-prod/aap-prod-subscription.yml
# Change channel to match Dev/QA

git add applications/aap-prod/
git commit -m "Upgrade AAP Prod to 2.6

- Dev tested: 2025-01-05 to 2025-01-19
- QA tested: 2025-01-19 to 2025-01-26
- QA sign-off: Jane Doe
- CAB approval: CHG0001234
- Maintenance window: 2025-01-27 02:00-04:00 UTC"

git push origin main
```

---

## Rollback Procedures

If upgrade fails:

### Operator Rollback

```yaml
# Revert to previous channel
spec:
  channel: 'stable-2.5'  # Previous version
```

### Full Rollback

```bash
cd cluster-config

# Revert the upgrade commit
git revert HEAD
git push origin main

# ArgoCD will sync to previous state
```

---

## Collection Compatibility

When upgrading AAP, verify collection compatibility:

```yaml
# automation-ee-example/requirements.yml
collections:
  - name: infra.aap_configuration
    version: ">=2.9.0,<3.0.0"  # Check compatibility with new AAP version

  - name: ansible.controller
    version: ">=4.6.0"  # Check compatibility
```

### Testing Collections

```bash
# After AAP upgrade, test CaC playbook
cd aap-config-as-code
ansible-playbook playbooks/playbook.yml --limit aap_dev --check

# If issues, may need to upgrade collections
cd automation-ee-example
vi requirements.yml  # Update versions
# Rebuild EE with new collections
```

---

## Execution Environment Updates

AAP upgrades may require EE base image updates:

```yaml
# automation-ee-example/execution-environment.yml
images:
  base_image:
    # Update to match AAP version
    name: registry.redhat.io/ansible-automation-platform-26/ee-minimal-rhel9:latest
```

### Rebuild EE After AAP Upgrade

```bash
cd automation-ee-example

# Update base image version
vi execution-environment.yml

# Build and test
ansible-builder build -t test-ee:upgrade-test

# Test the EE works
podman run -it test-ee:upgrade-test ansible --version

# Commit and push to trigger CI
git add execution-environment.yml
git commit -m "Update EE base image for AAP 2.6"
git push origin main
```

---

## Testing Strategy

### Smoke Tests (All Environments)

```yaml
# Basic functionality verification
- Verify AAP UI accessible
- Verify API responding
- Verify job execution works
- Verify webhook triggers work
- Verify inventory sync works
```

### Integration Tests (QA)

```yaml
# Full integration testing
- Run all existing job templates
- Test complex workflows
- Verify scheduled jobs
- Test notification integrations
- Verify LDAP/SAML auth
```

### Regression Tests (QA)

```yaml
# Verify nothing broke
- Compare job output before/after
- Check performance metrics
- Verify logs and auditing
- Test rollback procedures
```

---

## Communication Plan

### Pre-Upgrade

- **1 week before**: Notify teams of upcoming upgrade
- **1 day before**: Reminder with maintenance window

### During Upgrade

- **Start**: Announce upgrade beginning
- **Issues**: Communicate any problems
- **Complete**: Announce upgrade complete

### Post-Upgrade

- **Same day**: Send summary of changes
- **1 week after**: Solicit feedback

---

## Related Documents

- [VERSIONING-STRATEGY.md](./VERSIONING-STRATEGY.md) - Version management
- [DISASTER-RECOVERY.md](./DISASTER-RECOVERY.md) - Rollback procedures
- [EE-VERSIONING-STRATEGY.md](./EE-VERSIONING-STRATEGY.md) - EE updates


