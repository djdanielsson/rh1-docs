# AAP Upgrade Guide

Procedures for upgrading Ansible Automation Platform versions.

---

## Upgrade Strategy

AAP upgrades follow: **Dev → QA → Prod** (same as all changes)

| Phase | Duration | Activities |
|-------|----------|------------|
| Dev | 1-2 weeks | Test all workflows, document breaking changes |
| QA | 1 week | Full test suite, QA validation, sign-off |
| Prod | 1 day | Maintenance window, deploy, verify |

---

## Pre-Upgrade Checklist

```markdown
- [ ] Review AAP release notes
- [ ] Check collection compatibility (infra.aap_configuration, ansible.controller)
- [ ] Verify EE base image compatibility
- [ ] Schedule maintenance windows
- [ ] Notify stakeholders
```

---

## Upgrade Procedure

### Step 1: Update Dev Operator

```yaml
# cluster-config/applications/aap-dev/aap-dev-subscription.yml
spec:
  channel: 'stable-2.6'  # Change from stable-2.5
```

```bash
git add applications/aap-dev/
git commit -m "Upgrade AAP Dev to 2.6"
git push origin main
# ArgoCD syncs automatically
```

### Step 2: Verify Dev

```bash
# Watch upgrade
oc get csv -n aap-dev -w

# Check status
oc describe ansibleautomationplatform aap-dev -n aap-dev

# Test CaC
ansible-playbook playbooks/playbook.yml --limit aap_dev --check
```

### Step 3: Promote to QA (after 1-2 weeks)

```bash
vi applications/aap-qa/aap-qa-subscription.yml  # Change channel
git commit -am "Upgrade AAP QA to 2.6 - Dev tested"
git push origin main
```

### Step 4: Promote to Prod (after QA sign-off)

```bash
vi applications/aap-prod/aap-prod-subscription.yml
git commit -am "Upgrade AAP Prod to 2.6

- Dev tested: 2025-01-05 to 2025-01-19
- QA sign-off: Jane Doe
- CAB: CHG0001234"
git push origin main
```

---

## Rollback

```bash
# Revert to previous channel
spec:
  channel: 'stable-2.5'

# Or git revert
git revert HEAD && git push
```

---

## Collection & EE Updates

After AAP upgrade, verify and update if needed:

```yaml
# automation-ee-example/requirements.yml
collections:
  - name: infra.aap_configuration
    version: ">=2.9.0,<3.0.0"

# automation-ee-example/execution-environment.yml
images:
  base_image:
    name: registry.redhat.io/ansible-automation-platform-26/ee-minimal-rhel9:latest
```

```bash
# Rebuild EE
ansible-builder build -t test-ee:upgrade-test
git commit -am "Update EE base image for AAP 2.6"
git push origin main
```

---

## Related Documents

- [GIT-WORKFLOW.md](./GIT-WORKFLOW.md) - Versioning and promotion
- [DISASTER-RECOVERY.md](./DISASTER-RECOVERY.md) - Rollback procedures
