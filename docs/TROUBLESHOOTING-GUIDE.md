# Troubleshooting Guide

**Comprehensive troubleshooting guide for the Cloud-Native Ansible Lifecycle Platform**

## Table of Contents

- [Common Issues](#common-issues)
- [ArgoCD Issues](#argocd-issues)
- [AAP Issues](#aap-issues)
- [Pipeline Issues](#pipeline-issues)
- [GitOps Issues](#gitops-issues)

---

## Common Issues

### ArgoCD Application Not Syncing

**Symptoms**: `oc get applications -n openshift-gitops` shows "OutOfSync"

**Diagnosis**:
```bash
# Check application status
oc describe application cluster-bootstrap -n openshift-gitops

# Check ArgoCD logs
oc logs -n openshift-gitops -l app.kubernetes.io/name=openshift-gitops-application-controller
```

**Solutions**:
- **Invalid Git URL**: Fix URL in Application spec
- **Authentication failure**: Add Git credentials secret
- **Sync wave conflicts**: Check annotations on resources
- **Manual sync needed**: `oc patch application cluster-bootstrap -n openshift-gitops --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'`

### AAP Instance Not Starting

**Symptoms**: AAP pods in CrashLoopBackOff or Pending

**Diagnosis**:
```bash
# Check AutomationController status
oc describe automationcontroller aap-dev -n aap-dev

# Check pod status
oc get pods -n aap-dev
oc describe pod <failing-pod> -n aap-dev
oc logs <failing-pod> -n aap-dev
```

**Solutions**:
- **Admin secret missing**: Create `aap-admin-password` secret
- **Database connection failure**: Check `aap-postgres-config` secret
- **Insufficient resources**: Increase node capacity or reduce resource requests
- **Image pull failure**: Check operator subscription and image registry access

### CaC Pipeline Fails

**Symptoms**: PipelineRun shows "Failed" status

**Diagnosis**:
```bash
# View pipeline logs
tkn pipelinerun logs <run-name> -n dev-tools

# Check specific task
tkn pipelinerun describe <run-name> -n dev-tools
```

**Solutions**:
- **Authentication error**: Regenerate AAP API token, update secret
- **Ansible syntax error**: Fix YAML in group_vars/
- **Collection not found**: Update requirements.yml in CaC repo
- **Timeout**: Increase task timeout or check AAP API responsiveness

### Promotion Pipeline Fails

**Symptoms**: Promotion PipelineRun fails during EE build or CaC application

**Diagnosis**:
```bash
# Check which task failed
tkn pipelinerun describe <promotion-run> -n dev-tools

# View logs for failed task
tkn pipelinerun logs <promotion-run> -n dev-tools -t <task-name>
```

**Solutions**:
- **EE build failure**: Check dependencies in execution-environment.yml
- **Manifest parse error**: Validate YAML syntax in manifest file
- **Commit not found**: Verify commit SHAs exist in repositories
- **Registry push failure**: Check registry credentials secret
- **CaC application failure**: See "CaC Pipeline Fails" above

### Webhook Not Triggering Pipeline

**Symptoms**: Push to Git doesn't trigger expected pipeline

**Diagnosis**:
```bash
# Check EventListener is running
oc get pods -n dev-tools -l eventlistener.tekton.dev/eventlistener

# Check EventListener logs
oc logs -n dev-tools -l eventlistener.tekton.dev/eventlistener=github-webhook-listener

# Test webhook manually
WEBHOOK_URL=$(oc get route el-github-webhook-listener -n dev-tools -o jsonpath='{.spec.host}')
curl -X POST https://${WEBHOOK_URL} \
  -H "X-GitHub-Event: push" \
  -H "X-Hub-Signature: sha1=xxx" \
  -d '{"ref":"refs/heads/main","repository":{"name":"aap-config-as-code"}}'
```

**Solutions**:
- **EventListener not exposed**: Check Route exists and is accessible
- **Webhook secret mismatch**: Regenerate secret, update GitHub webhook config
- **Incorrect event type**: Check EventListener interceptor filters
- **Firewall blocking**: Verify GitHub can reach OpenShift Route

---

## ArgoCD Issues

### Application Stuck in Progress

**Symptoms**: Application shows "Progressing" indefinitely

**Diagnosis**:
```bash
# Check sync status
oc get applications -n openshift-gitops

# Check application events
oc describe application <app-name> -n openshift-gitops
```

**Solutions**:
- **Resource conflicts**: Check for conflicting resources in different sync waves
- **Dependency issues**: Ensure dependencies are deployed before dependent resources
- **RBAC issues**: Verify ArgoCD has permissions to create resources

### Application Shows Degraded

**Symptoms**: Application status is "Degraded"

**Diagnosis**:
```bash
# Check application health
oc describe application <app-name> -n openshift-gitops

# Check resource status
oc get all -n <target-namespace>
```

**Solutions**:
- **Resource failures**: Check individual resource status and logs
- **Image pull issues**: Verify image registry access and credentials
- **Configuration errors**: Validate YAML syntax and values

---

## AAP Issues

### Jobs Failing with Authentication Errors

**Symptoms**: AAP jobs fail with authentication/authorization errors

**Diagnosis**:
```bash
# Check AAP credentials
oc get secrets -n <aap-namespace> | grep credential

# Check credential validity
oc describe secret <credential-name> -n <aap-namespace>
```

**Solutions**:
- **Expired credentials**: Rotate credentials and update secrets
- **Permission issues**: Verify credential permissions in target systems
- **Secret mounting**: Ensure secrets are properly mounted in AAP

### Execution Environment Not Available

**Symptoms**: Jobs fail because EE is not found

**Diagnosis**:
```bash
# Check EE in AAP
curl -k -H "Authorization: Bearer <token>" \
  https://<aap-url>/api/v2/execution_environments/

# Check image registry
podman/docker pull <ee-image>
```

**Solutions**:
- **Image not pushed**: Ensure EE build pipeline completed successfully
- **Registry access**: Verify AAP can access the registry
- **Image name mismatch**: Check EE name matches between build and AAP config

---

## Pipeline Issues

### Pipeline Runs Hanging

**Symptoms**: PipelineRun shows "Running" but no progress

**Diagnosis**:
```bash
# Check pipeline run status
tkn pipelinerun describe <run-name> -n dev-tools

# Check task status
tkn pipelinerun logs <run-name> -n dev-tools -f
```

**Solutions**:
- **Resource constraints**: Check cluster resource availability
- **Timeout settings**: Increase timeouts for long-running tasks
- **Deadlock conditions**: Restart pipeline with different parameters

### Pipeline Authentication Failures

**Symptoms**: Tasks fail with authentication errors

**Diagnosis**:
```bash
# Check secret existence
oc get secrets -n dev-tools

# Check secret contents (if accessible)
oc describe secret <secret-name> -n dev-tools
```

**Solutions**:
- **Missing secrets**: Ensure all required secrets are created
- **Secret rotation**: Update secrets after rotation
- **Permission scope**: Verify secret contains correct credentials

---

## GitOps Issues

### Configuration Drift

**Symptoms**: Manual changes are overwritten by ArgoCD

**Diagnosis**:
```bash
# Check application sync status
oc get applications -n openshift-gitops

# Compare Git vs cluster state
oc diff -f <resource-file>
```

**Solutions**:
- **Document manual changes**: Update Git repository with required changes
- **Use annotations**: Mark resources that should not be managed by GitOps
- **Review processes**: Implement approval processes for configuration changes

### Sync Conflicts

**Symptoms**: ArgoCD shows sync conflicts or errors

**Diagnosis**:
```bash
# Check application status
oc describe application <app-name> -n openshift-gitops

# Check resource conflicts
oc get events -n <target-namespace> --sort-by=.metadata.creationTimestamp
```

**Solutions**:
- **Resolve conflicts**: Choose between Git and cluster state
- **Sync options**: Use appropriate sync options (prune, replace)
- **Dependency ordering**: Ensure proper sync wave ordering

---

## Emergency Procedures

### Force Sync Application

```bash
# Force sync with replace
oc patch application <app-name> -n openshift-gitops --type merge \
  -p '{"spec":{"syncPolicy":{"syncOptions":["Replace=true"]}}}'

# Manual sync
argocd app sync <app-name>
```

### Restart Failing Pods

```bash
# Restart specific pod
oc delete pod <pod-name> -n <namespace>

# Restart deployment
oc rollout restart deployment <deployment-name> -n <namespace>
```

### Emergency Pipeline Stop

```bash
# Cancel pipeline run
tkn pipelinerun cancel <run-name> -n dev-tools

# Force delete if needed
oc delete pipelinerun <run-name> -n dev-tools --force
```

