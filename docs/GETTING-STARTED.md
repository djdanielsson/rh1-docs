# Getting Started

Quick start guide for deploying and using the Cloud-Native Ansible Lifecycle Platform.

---

## Prerequisites

### Cluster Requirements

- **OpenShift**: 4.12+
- **Nodes**: 3 workers (HA)
- **Resources**: 40 cores, 80Gi RAM, 200Gi storage

```bash
oc get nodes
oc describe nodes | grep -A 5 "Allocated resources"
oc get storageclass
```

### CLI Tools

**Required**: `oc`, `git`, `yq`

**Recommended**: `ansible`, `ansible-creator`, `ansible-lint`, `molecule`, `tkn`

---

## Bootstrap Process

### Step 1: Install OpenShift GitOps Operator

```bash
oc apply -f - <<EOF
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-gitops-operator
  namespace: openshift-operators
spec:
  channel: latest
  name: openshift-gitops-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

oc wait --for=condition=Ready pod -l name=openshift-gitops-operator \
  -n openshift-operators --timeout=300s
```

### Step 2: Bootstrap ArgoCD

```bash
oc apply -f - <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cluster-bootstrap
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: https://github.com/org/cluster-config.git
    targetRevision: main
    path: argocd
  destination:
    server: https://kubernetes.default.svc
    namespace: openshift-gitops
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
EOF
```

### Step 3: Verify Deployment

```bash
# Watch applications sync
oc get applications -n openshift-gitops

# Check AAP instances
oc get automationcontroller -A
oc get pods -n aap-dev
oc get pods -n aap-qa
oc get pods -n aap-prod
```

### Step 4: Get AAP Credentials

```bash
# Get admin password
DEV_PASSWORD=$(oc get secret aap-dev-admin-password -n aap-dev \
  -o jsonpath='{.data.password}' | base64 -d)

# Get URL
DEV_URL=$(oc get route aap-dev -n aap-dev -o jsonpath='{.spec.host}')

echo "URL: https://${DEV_URL}"
echo "Password: ${DEV_PASSWORD}"
```

### Step 5: Create API Token

```bash
curl -k -X POST https://${DEV_URL}/api/v2/tokens/ \
  -u admin:${DEV_PASSWORD} \
  -H "Content-Type: application/json" \
  -d '{"description":"CaC Pipeline Token","scope":"write"}' | jq -r '.token'
```

---

## Deployment Timeline

| Phase | Duration | What Happens |
|-------|----------|--------------|
| GitOps Operator | 2-3 min | Install operator |
| Root Application | 30 sec | Apply bootstrap |
| Namespaces | 30 sec | Create aap-dev/qa/prod |
| Operators | 5-7 min | Install AAP + Pipelines |
| RBAC | 30 sec | ServiceAccounts, Roles |
| AAP Instances | 3-5 min | Deploy 3 environments |
| Tekton | 2-3 min | Tasks, Pipelines, Triggers |

**Total**: ~20 minutes

---

## Validation

```bash
# Check all applications
oc get applications -n openshift-gitops

# Check pipelines
oc get pipeline -n dev-tools

# Check webhook route
oc get route -n dev-tools | grep el-

# Smoke test
ansible-playbook tests/test-playbooks/smoke-test.yml
```

---

## Developer Workflows

### Create New Collection

```bash
cd automation-collection-example
ansible-creator add resource role my_new_role
cd roles/my_new_role
molecule test
```

### Modify AAP Configuration

```bash
cd aap-config-as-code
vi group_vars/aap_dev/job_templates.yml
git commit -am "Add new job template"
git push  # Webhook triggers CaC pipeline
```

### Create Release

```bash
cd automation-release-manifest
cat > releases/release-26.01.06.0.yaml <<EOF
version: "26.01.06.0"
components:
  aap_configuration: "$(git -C ../aap-config-as-code rev-parse HEAD)"
  execution_environment: "$(git -C ../automation-ee-example rev-parse HEAD)"
  collections: "$(git -C ../automation-collection-example rev-parse HEAD)"
EOF

git add releases/
git commit -m "Release 26.01.06.0"
git tag 26.01.06.0
git push origin 26.01.06.0
```

---

## Troubleshooting

### ArgoCD Not Syncing

```bash
oc describe application cluster-bootstrap -n openshift-gitops
oc logs -n openshift-gitops -l app.kubernetes.io/name=openshift-gitops-application-controller

# Force sync
oc patch application cluster-bootstrap -n openshift-gitops \
  --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'
```

### AAP Not Starting

```bash
oc describe automationcontroller aap-dev -n aap-dev
oc get pods -n aap-dev
oc logs <pod-name> -n aap-dev
```

### Pipeline Failures

```bash
tkn pipelinerun logs <run-name> -n dev-tools
tkn pipelinerun describe <run-name> -n dev-tools
```

---

## Next Steps

1. **[Ansible Best Practices](./ANSIBLE-BEST-PRACTICES.md)** - Essential reading
2. **[Git Workflow](./GIT-WORKFLOW.md)** - Versioning and promotion
3. **[CI/CD Guide](./CICD-GUIDE.md)** - Automation setup
4. **[Testing Guide](./TESTING-GUIDE.md)** - Testing strategies

---

## Help

```bash
# Check status
oc get applications -n openshift-gitops

# View logs
oc logs -n openshift-gitops \
  -l app.kubernetes.io/name=openshift-gitops-application-controller

# Quick reference
cat cluster-config/QUICKREF.md
```
