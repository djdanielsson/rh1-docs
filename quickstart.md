# Quickstart Guide: Cloud-Native Ansible Lifecycle

**Purpose**: Complete bootstrap and operational guide for the GitOps Ansible platform
**Audience**: Platform operators, release managers, developers
**Prerequisites**: OpenShift cluster admin access

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Bootstrap Process](#bootstrap-process)
3. [Validation](#validation)
4. [Developer Workflow](#developer-workflow)
5. [Release Workflow](#release-workflow)
6. [Rollback Procedure](#rollback-procedure)
7. [Troubleshooting](#troubleshooting)
8. [Security Model](#security-model)

---

## Practical Examples and Use Cases

### Example 1: Web Application Deployment

**Scenario**: Deploy Apache web server with custom configuration across dev/qa/prod environments.

**Step 1: Add Role to Existing Collection**
```bash
# For this example, we'll add a role to the existing automation-collection-example
# (See "Developer Workflow" section below for creating new collections from scratch)

cd automation-collection-example
ansible-creator add resource role webserver_deploy

# Edit roles/webserver_deploy/tasks/main.yml
cat > roles/webserver_deploy/tasks/main.yml << 'EOF'
---
- name: Install Apache
  ansible.builtin.package:
    name: httpd
    state: present

- name: Configure virtual host
  ansible.builtin.template:
    src: vhost.conf.j2
    dest: /etc/httpd/conf.d/{{ app_name }}.conf
  notify: restart_httpd

- name: Deploy application files
  ansible.builtin.copy:
    src: "{{ app_source }}"
    dest: "/var/www/{{ app_name }}"

- name: Start and enable Apache
  ansible.builtin.service:
    name: httpd
    state: started
    enabled: true
EOF
```

**Step 2: Configure AAP Job Template**
```yaml
# aap-config-as-code/group_vars/aap_dev/job_templates.yml
controller_job_templates_dev_web:
  - name: "Deploy Web App (Dev)"
    description: "Deploy web application to dev servers"
    job_type: run
    organization: Applications
    inventory: Dev Servers
    project: Web Applications
    playbook: playbooks/deploy_webapp.yml
    execution_environment: Web EE (Dev)
    credentials:
      - Dev SSH Key
    ask_variables_on_launch: true
    extra_vars:
      app_name: "mywebapp"
      app_source: "/project/files/"
```

**Step 3: Promote to Production**
```bash
# Create release manifest
cd automation-release-manifest
cat > releases/release-26.01.06.0.yml << EOF
version: "26.01.06.0"
components:
  aap_configuration: "$(git rev-parse HEAD:aap-config-as-code)"
  execution_environment: "$(git rev-parse HEAD:automation-ee-example)"
  collections: "$(git rev-parse HEAD:automation-collection-example)"
EOF

# Tag and promote
git add releases/release-26.01.06.0.yml
git commit -m "Release 26.01.06.0 - Web app deployment"
git tag 26.01.06.0
git push origin 26.01.06.0
# Automatic promotion to QA, then manual to prod
```

### Example 2: Database Backup Automation

**Scenario**: Automated PostgreSQL backups with encryption and cloud storage.

**Step 1: Create Backup Role**
```yaml
# roles/database_backup/tasks/main.yml
---
- name: Install PostgreSQL client
  ansible.builtin.package:
    name: postgresql-client
    state: present

- name: Create backup directory
  ansible.builtin.file:
    path: "{{ backup_dir }}"
    state: directory
    mode: '0750'

- name: Perform database backup
  ansible.builtin.command:
    cmd: >
      pg_dump -h {{ db_host }} -U {{ db_user }} -d {{ db_name }}
      --format=custom --compress=9 --file={{ backup_dir }}/{{ db_name }}_{{ ansible_date_time.iso8601 }}.backup
    environment:
      PGPASSWORD: "{{ db_password }}"

- name: Encrypt backup
  ansible.builtin.command:
    cmd: openssl enc -aes-256-cbc -salt -in {{ backup_file }} -out {{ backup_file }}.enc -k {{ encryption_key }}

- name: Upload to S3
  amazon.aws.aws_s3:
    bucket: "{{ s3_bucket }}"
    object: "backups/{{ db_name }}/{{ ansible_date_time.iso8601 }}.backup.enc"
    src: "{{ backup_file }}.enc"
    mode: put
    aws_access_key: "{{ aws_access_key }}"
    aws_secret_key: "{{ aws_secret_key }}"

- name: Cleanup local files
  ansible.builtin.file:
    path: "{{ item }}"
    state: absent
  loop:
    - "{{ backup_file }}"
    - "{{ backup_file }}.enc"
```

**Step 2: Schedule Automated Backups**
```yaml
# group_vars/aap_prod/schedules.yml
controller_schedules_prod_backup:
  - name: "Daily Database Backup"
    description: "Automated backup of production databases"
    job_template: "Database Backup"
    rrule: "DTSTART;TZID=America/New_York:20260106T020000 RRULE:FREQ=DAILY;INTERVAL=1"
    enabled: true
    extra_vars:
      db_name: "prod_database"
      s3_bucket: "prod-backups-secure"
```

---

## Prerequisites

### 1. OpenShift Cluster Requirements

**Minimum Cluster Resources**:
- **Nodes**: 3 worker nodes (for HA)
- **CPU**: 40 cores total (5 dev + 10 qa + 20 prod + 5 platform)
- **Memory**: 80Gi total (10Gi dev + 20Gi qa + 40Gi prod + 10Gi platform)
- **Storage**: 200Gi total for PVCs
- **OpenShift Version**: 4.12+

**Check Cluster Capacity**:
```bash
# View node resources
oc get nodes
oc describe nodes | grep -A 5 "Allocated resources"

# Check available storage classes
oc get storageclass
```

### 2. Git Repositories Created

All 5 repositories must exist and be accessible:

| Repository | Purpose | URL Pattern |
|------------|---------|-------------|
| `cluster-config` | Platform GitOps (ArgoCD) | `https://github.com/djdanielsson/rh1-cluster-config.git` |
| `aap-config-as-code` | Application GitOps (AAP CaC) | `https://github.com/djdanielsson/rh1-aap-config-as-code.git` |
| `automation-collection-example` | Collection template | `https://github.com/djdanielsson/rh1-custom-collection.git` |
| `automation-ee-example` | Execution environment template | `https://github.com/djdanielsson/rh1-custom-ee.git` |
| `automation-release-manifest` | Release BOM | `https://github.com/djdanielsson/rh1-release-manifest.git` |

**Create Repositories**:
```bash
# Clone locally (you'll populate these during Phase 2-15)
git clone git@github.com:org/cluster-config.git
git clone git@github.com:org/aap-config-as-code.git
# ... etc
```

### 3. No Pre-Deployment Secrets Required! ✨

**Everything is automated:**
- ✅ Namespaces created by ArgoCD (Wave -3)
- ✅ AAP admin passwords auto-generated by operator
- ✅ GitHub webhook secret created post-deployment (when you need it)

**Optional - External PostgreSQL** (for QA/Prod, if desired):
```bash
# Only if using external PostgreSQL instead of embedded
# Create after namespaces exist (after ArgoCD sync)
oc create secret generic aap-postgres-config \
  --from-literal=host='postgres.example.com' \
  --from-literal=port='5432' \
  --from-literal=database='aap_qa' \
  --from-literal=username='aap_user' \
  --from-literal=password='<db-password>' \
  --from-literal=sslmode='require' \
  --from-literal=type='unmanaged' \
  -n aap-qa

# Repeat for prod if needed
```

### 4. CLI Tools Installed

**Required Tools**:
```bash
# OpenShift CLI
oc version
# Should show: Client Version: 4.12.0 or later

# Git
git --version

# yq (YAML processor)
yq --version

# Optional but recommended
# - ansible (for local testing)
# - ansible-lint
# - molecule
# - tkn (Tekton CLI)
```

**Install Missing Tools**:
```bash
# OpenShift CLI
curl -LO https://mirror.openshift.com/pub/openshift-v4/clients/ocp/latest/openshift-client-linux.tar.gz
tar -xzf openshift-client-linux.tar.gz
sudo mv oc kubectl /usr/local/bin/

# Tekton CLI
curl -LO https://github.com/tektoncd/cli/releases/download/v0.32.0/tkn_0.32.0_Linux_x86_64.tar.gz
tar -xzf tkn_0.32.0_Linux_x86_64.tar.gz
sudo mv tkn /usr/local/bin/

# yq
sudo wget https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64 -O /usr/local/bin/yq
sudo chmod +x /usr/local/bin/yq
```

### 5. Cluster Admin Access Verified

```bash
# Login to OpenShift
oc login --server=https://api.cluster.example.com:6443 --username=admin

# Verify admin access (should return 'yes')
oc auth can-i '*' '*' --all-namespaces

# If not cluster-admin, request elevated permissions
oc adm policy add-cluster-role-to-user cluster-admin $(oc whoami)
```

---

## Bootstrap Process

### Phase 1: Install OpenShift GitOps Operator (Manual - One Time)

Only the GitOps operator needs manual installation. ArgoCD will manage all other operators!

```bash
# Install OpenShift GitOps Operator
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
  installPlanApproval: Automatic
EOF

# Wait for operator to be ready (2-3 minutes)
oc wait --for=condition=Ready pod -l name=openshift-gitops-operator \
  -n openshift-operators --timeout=300s

echo "✓ OpenShift GitOps operator is ready"
```

**What ArgoCD will install automatically:**
- ✅ 3x AAP Operators (namespace-scoped: aap-dev, aap-qa, aap-prod)
- ✅ 1x OpenShift Pipelines Operator (cluster-scoped)
- ✅ All namespaces
- ✅ All RBAC, AAP instances, and Tekton resources

### Phase 2: Bootstrap ArgoCD (GitOps Starts Here)

**Constitution Article I**: Single source of truth in Git

```bash
# 1. Create ArgoCD bootstrap Application
# This Application manages all other Applications (App-of-Apps pattern)

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
    syncOptions:
      - CreateNamespace=true
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
EOF

# 2. Watch ArgoCD sync progress
oc get applications -n openshift-gitops -w

# Or use ArgoCD CLI
argocd app list
argocd app get cluster-bootstrap

# Or open ArgoCD UI
oc get route openshift-gitops-server -n openshift-gitops -o jsonpath='{.spec.host}'
# Open in browser, login with OpenShift credentials
```

**What Happens During Bootstrap**:

1. **Wave -3**: Namespaces created (aap-dev, aap-qa, aap-prod, dev-tools)
2. **Wave -2**: Operator subscriptions reconciled (already installed manually)
3. **Wave -1**: RBAC created (ServiceAccounts, Roles, RoleBindings)
4. **Wave 0**: AAP AutomationController CRs created
5. **Wave 1**: Tekton Tasks created
6. **Wave 2**: Tekton Pipelines created
7. **Wave 3**: Tekton Triggers (EventListeners) created
8. **Wave 4**: Dev Spaces configuration created

**Timeline**: 10-15 minutes for complete bootstrap

### Phase 3: Verify AAP Instances Deployed

```bash
# 1. Check AutomationController CRs
oc get automationcontroller -A

# Expected output:
# NAMESPACE   NAME       AGE
# aap-dev     aap-dev    5m
# aap-qa      aap-qa     5m
# aap-prod    aap-prod   5m

# 2. Check AAP pods are running
oc get pods -n aap-dev
oc get pods -n aap-qa
oc get pods -n aap-prod

# Each namespace should have:
# - aap-{env}-web-* (1-3 pods)
# - aap-{env}-task-* (1-3 pods)
# - aap-{env}-postgres-* (1 pod, if embedded)
# - aap-{env}-redis-* (1 pod)

# 3. Get AAP URLs
echo "Dev AAP: https://$(oc get route aap-dev -n aap-dev -o jsonpath='{.spec.host}')"
echo "QA AAP: https://$(oc get route aap-qa -n aap-qa -o jsonpath='{.spec.host}')"
echo "Prod AAP: https://$(oc get route aap-prod -n aap-prod -o jsonpath='{.spec.host}')"

# 4. Test AAP API
DEV_URL=$(oc get route aap-dev -n aap-dev -o jsonpath='{.spec.host}')
curl -k https://${DEV_URL}/api/v2/ping/
# Should return: {"ha": false, "version": "4.4.0", ...}
```

### Phase 4: Configure Initial AAP API Credentials

```bash
# 1. Get auto-generated AAP admin password
DEV_PASSWORD=$(oc get secret aap-dev-admin-password -n aap-dev -o jsonpath='{.data.password}' | base64 -d)

# 2. Generate OAuth token for CaC pipeline
DEV_URL=$(oc get route aap-dev -n aap-dev -o jsonpath='{.spec.host}')

# Login and get token
curl -k -X POST https://${DEV_URL}/api/v2/tokens/ \
  -u admin:${DEV_PASSWORD} \
  -H "Content-Type: application/json" \
  -d '{"description":"CaC Pipeline Token","scope":"write"}' \
  | jq -r '.token'

# Save token output

# 3. Create AAP API credentials secret for CaC pipeline
oc create secret generic aap-dev-api-credentials \
  --from-literal=host="https://${DEV_URL}" \
  --from-literal=token="<token-from-previous-step>" \
  -n dev-tools

# Repeat for QA and Prod
# (use respective admin passwords and URLs)

oc create secret generic aap-qa-api-credentials \
  --from-literal=host="https://$(oc get route aap-qa -n aap-qa -o jsonpath='{.spec.host}')" \
  --from-literal=token="<qa-token>" \
  -n dev-tools

oc create secret generic aap-prod-api-credentials \
  --from-literal=host="https://$(oc get route aap-prod -n aap-prod -o jsonpath='{.spec.host}')" \
  --from-literal=token="<prod-token>" \
  -n dev-tools
```

### Phase 5: Run Initial CaC Pipeline

**Constitution Article II**: Application GitOps via Tekton

```bash
# 1. Verify CaC pipeline exists
oc get pipeline -n dev-tools
# Should show: cac-pipeline

# 2. Get current commit SHA from aap-config-as-code repo
cd /path/to/aap-config-as-code
git rev-parse HEAD
# Copy this SHA

# 3. Create PipelineRun to configure Dev AAP
oc create -f - <<EOF
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: cac-dev-initial-
  namespace: dev-tools
spec:
  pipelineRef:
    name: cac-pipeline
  params:
  - name: git_commit
    value: "<commit-sha-from-step-2>"
  - name: target_environment
    value: "dev"
  workspaces:
  - name: source
    volumeClaimTemplate:
      spec:
        accessModes: [ReadWriteOnce]
        resources:
          requests:
            storage: 1Gi
  - name: aap-credentials
    secret:
      secretName: aap-dev-api-credentials
EOF

# 4. Watch pipeline execution
tkn pipelinerun logs -f -n dev-tools <pipelinerun-name>

# Or view in OpenShift Console:
# Pipelines → PipelineRuns → Select run

# 5. Verify AAP configuration applied
# Open Dev AAP UI, login as admin
# Check: Projects, Credentials, Job Templates are created
```

**Repeat for QA and Prod**:
```bash
# Configure QA
oc create -f - <<EOF
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: cac-qa-initial-
  namespace: dev-tools
spec:
  pipelineRef:
    name: cac-pipeline
  params:
  - name: git_commit
    value: "<commit-sha>"
  - name: target_environment
    value: "qa"
  workspaces:
  - name: source
    volumeClaimTemplate: {spec: {accessModes: [ReadWriteOnce], resources: {requests: {storage: 1Gi}}}}
  - name: aap-credentials
    secret: {secretName: aap-qa-api-credentials}
EOF

# Configure Prod (similar)
```

---

## Validation

### Checklist: Bootstrap Complete

- [ ] All 3 operators installed and running
- [ ] ArgoCD bootstrap Application synced successfully
- [ ] All 4 namespaces created (aap-dev, aap-qa, aap-prod, dev-tools)
- [ ] All 3 AAP instances running and accessible via routes
- [ ] All Tekton pipelines created (cac, inner-loop, pr-validation, promotion)
- [ ] All Tekton triggers (EventListeners) created and exposed
- [ ] AAP API credentials secrets created for all environments
- [ ] Initial CaC pipeline run succeeded for all environments
- [ ] AAP instances show configured projects, credentials, job templates

### Smoke Tests

```bash
# Test 1: ArgoCD managing resources
oc get applications -n openshift-gitops
# Should show cluster-bootstrap and child applications

# Test 2: AAP instances healthy
for env in dev qa prod; do
  echo "Testing AAP ${env}..."
  oc get automationcontroller aap-${env} -n aap-${env} -o jsonpath='{.status.conditions[?(@.type=="Running")].status}'
  # Should output: True
done

# Test 3: Tekton pipelines exist
oc get pipeline -n dev-tools
# Should show: cac-pipeline, inner-loop-pipeline, pr-validation-pipeline, promotion-pipeline

# Test 4: EventListeners exposed
oc get route -n dev-tools | grep el-
# Should show routes for webhook endpoints

# Test 5: CaC pipeline works
# Create simple test run (already done in Phase 5)

# Test 6: Git audit trail
cd /path/to/cluster-config
git log --oneline -10
# Should show commit history of all applied resources
```

---

## Developer Workflow

### Scenario: Develop New Ansible Collection

**Note**: This section shows how to create a new collection from scratch. For adding roles to existing collections, see the practical examples above.

**Constitution Article IV**: Test-first, modular development

#### Step 1: Clone Collection Template

```bash
# Clone the template repository
git clone git@github.com:org/automation-collection-example.git my-new-collection
cd my-new-collection

# Initialize collection structure
ansible-creator init collection myorg.my_collection

# Create role with Molecule tests
cd roles
ansible-creator add resource role my_role
cd my_role
molecule init scenario default --driver-name docker
```

#### Step 2: Write Tests First (TDD)

```bash
# Edit molecule/default/converge.yml
cat > molecule/default/converge.yml <<'EOF'
---
- name: Converge
  hosts: all
  tasks:
    - name: Include my_role
      include_role:
        name: my_role
      vars:
        my_var: test_value
EOF

# Edit molecule/default/verify.yml
cat > molecule/default/verify.yml <<'EOF'
---
- name: Verify
  hosts: all
  tasks:
    - name: Check my_role created file
      stat:
        path: /tmp/my_file
      register: result

    - name: Assert file exists
      assert:
        that:
          - result.stat.exists
EOF

# Run tests (should FAIL - not implemented yet)
molecule test
```

#### Step 3: Implement Role

```bash
# Edit roles/my_role/tasks/main.yml
cat > tasks/main.yml <<'EOF'
---
- name: Create test file
  copy:
    content: "{{ my_var }}"
    dest: /tmp/my_file
    mode: '0644'
EOF

# Run tests again (should PASS now)
molecule test
```

#### Step 4: Create Pull Request

```bash
# Commit and push
git add .
git commit -m "Add my_role with Molecule tests"
git push origin main

# Create feature branch
git checkout -b feature/my-new-role
git push origin feature/my-new-role

# Create PR on GitHub
gh pr create --title "Add my_role" --body "Implements XYZ functionality with tests"
```

**Automatic PR Validation**:
- GitHub webhook triggers `pr-validation-pipeline`
- Pipeline runs: ansible-lint + molecule test + secret scan
- Results posted back to PR
- **If pass**: PR can be merged
- **If fail**: Fix issues, push again (automatic re-test)

#### Step 5: Test in Dev AAP (Inner Loop)

```bash
# After PR merged, test in Dev AAP before release
# Trigger inner loop pipeline via CLI
oc create -f - <<EOF
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: inner-loop-test-
  namespace: dev-tools
spec:
  pipelineRef:
    name: inner-loop-pipeline
  params:
  - name: git_repo_url
    value: "https://github.com/org/my-new-collection.git"
  - name: git_branch
    value: "main"
  - name: project_name
    value: "My Collection Project"
  workspaces:
  - name: aap-credentials
    secret:
      secretName: aap-dev-api-credentials
EOF

# Watch execution
tkn pipelinerun logs -f -n dev-tools <run-name>

# Check Dev AAP UI - job should be running
# Review output, verify behavior
```

---

## Release Workflow

### Scenario: Promote Collection to QA/Prod

**Constitution Article III**: Atomic promotion via Release Manifest

#### Step 1: Create Release Manifest

```bash
cd /path/to/automation-release-manifest

# Get commit SHAs for all components
AAP_CAC_SHA=$(cd ../aap-config-as-code && git rev-parse HEAD)
EE_SHA=$(cd ../automation-ee-example && git rev-parse HEAD)
COLLECTION_SHA=$(cd ../my-new-collection && git rev-parse HEAD)

# Create manifest file
cat > releases/release-26.01.06.0.yml <<EOF
version: "26.01.06.0"

components:
  # Required components
  aap_configuration: "${AAP_CAC_SHA}"
  execution_environment: "${EE_SHA}"

  # Application components
  my_new_collection: "${COLLECTION_SHA}"

metadata:
  release_date: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  approver: "$(git config user.name) <$(git config user.email)>"
  changelog_url: "https://github.com/org/automation-release-manifest/releases/tag/26.01.06.0"
  target_environments: ["qa", "prod"]
  jira_ticket: "INFRA-1234"
  notes: |
    Initial release including:
    - New my_collection with my_role
    - Updated EE with required collections
    - AAP configuration for QA/Prod environments

    Tested in Dev: 2025-10-27
    Approved for QA: 2025-10-27
EOF

# Validate manifest
yq eval '.' releases/release-26.01.06.0.yml
# Check: valid YAML, all SHAs are 40 characters

# Commit and push
git add releases/release-26.01.06.0.yml
git commit -m "Release 26.01.06.0 - Initial production release"
git push origin main
```

#### Step 2: Tag Release

```bash
# Create and push Git tag
git tag -a 26.01.06.0 -m "Release 26.01.06.0"
git push origin 26.01.06.0

# This triggers promotion-pipeline webhook
```

**Automatic Promotion to QA**:
- GitHub webhook triggers `promotion-pipeline`
- Parameters: `release_tag=26.01.06.0`, `target_environment=qa`
- Pipeline executes:
  1. Parse manifest, extract commit SHAs
  2. Clone EE repo at `${EE_SHA}`, build image
  3. Push image to registry: `web-ee:1.0.0`
  4. Clone CaC repo at `${AAP_CAC_SHA}`, run playbook for QA
  5. Update QA AAP projects to `${COLLECTION_SHA}`
  6. Launch QA validation workflow

#### Step 3: Monitor Promotion

```bash
# Watch promotion pipeline
tkn pipelinerun list -n dev-tools | grep promotion
tkn pipelinerun logs -f -n dev-tools <promotion-run-name>

# Check QA AAP
QA_URL=$(oc get route aap-qa -n aap-qa -o jsonpath='{.spec.host}')
echo "QA AAP: https://${QA_URL}"
# Login, verify:
# - New EE version appears
# - Projects synced to correct commits
# - Jobs can launch successfully
```

#### Step 4: Validate in QA

```bash
# Run validation tests in QA AAP
# - Execute job templates
# - Check output logs
# - Verify expected behavior

# If issues found:
# - Fix in Git (new commit)
# - Create 26.01.06.1 manifest
# - Re-promote

# If validation passes:
# - Proceed to Prod promotion
```

#### Step 5: Promote to Prod

```bash
# Option 1: Re-trigger promotion pipeline with prod parameter
oc create -f - <<EOF
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: promotion-26.01.06.0-
  namespace: dev-tools
spec:
  pipelineRef:
    name: promotion-pipeline
  params:
  - name: release_tag
    value: "26.01.06.0"
  - name: target_environment
    value: "prod"  # Changed from qa to prod
  workspaces:
  - name: manifest-source
    volumeClaimTemplate: {spec: {accessModes: [ReadWriteOnce], resources: {requests: {storage: 1Gi}}}}
  - name: ee-source
    volumeClaimTemplate: {spec: {accessModes: [ReadWriteOnce], resources: {requests: {storage: 5Gi}}}}
  - name: cac-source
    volumeClaimTemplate: {spec: {accessModes: [ReadWriteOnce], resources: {requests: {storage: 1Gi}}}}
  - name: aap-credentials
    secret: {secretName: aap-prod-api-credentials}
  - name: registry-credentials
    secret: {secretName: ocp-registry-credentials}
EOF

# Watch deployment
tkn pipelinerun logs -f -n dev-tools <run-name>
```

**CRITICAL**: Same manifest, same commits - atomic promotion guarantee (Article III)

---

## Rollback Procedure

### Scenario: Production Issue Requires Rollback

**Constitution Article III.3**: Rollback is re-promotion of previous manifest

#### Step 1: Identify Issue

```bash
# Current production: 26.01.06.0 (broken)
# Previous production: 25.12.31.0 (known good)

# Verify previous manifest exists
cd /path/to/automation-release-manifest
git show 25.12.31.0:releases/release-25.12.31.0.yml
```

#### Step 2: Execute Rollback

**Option A: Re-promote Previous Version** (Recommended)

```bash
# Simply promote 25.12.31.0 to prod
oc create -f - <<EOF
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: rollback-25.12.31.0-
  namespace: dev-tools
spec:
  pipelineRef:
    name: promotion-pipeline
  params:
  - name: release_tag
    value: "25.12.31.0"  # Previous good version
  - name: target_environment
    value: "prod"
  workspaces:
  - name: manifest-source
    volumeClaimTemplate: {spec: {accessModes: [ReadWriteOnce], resources: {requests: {storage: 1Gi}}}}
  - name: ee-source
    volumeClaimTemplate: {spec: {accessModes: [ReadWriteOnce], resources: {requests: {storage: 5Gi}}}}
  - name: cac-source
    volumeClaimTemplate: {spec: {accessModes: [ReadWriteOnce], resources: {requests: {storage: 1Gi}}}}
  - name: aap-credentials
    secret: {secretName: aap-prod-api-credentials}
  - name: registry-credentials
    secret: {secretName: ocp-registry-credentials}
EOF
```

**Option B: Create New Manifest Pointing to Old Commits** (Better audit trail)

```bash
# Copy 25.12.31.0 manifest to 26.01.06.1
cp releases/release-25.12.31.0.yml releases/release-26.01.06.1.yml

# Update metadata
yq eval -i '.version = "26.01.06.1"' releases/release-26.01.06.1.yml
yq eval -i '.metadata.release_date = "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"' releases/release-26.01.06.1.yml
yq eval -i '.metadata.approver = "'$(git config user.name)' <'$(git config user.email)>'>"' releases/release-26.01.06.1.yml
yq eval -i '.metadata.notes = "ROLLBACK: Revert to 25.12.31.0 due to production issue in 26.01.06.0"' releases/release-26.01.06.1.yml

# Commit, tag, push
git add releases/release-26.01.06.1.yml
git commit -m "Release 26.01.06.1 - Rollback to 25.12.31.0 components"
git tag -a 26.01.06.1 -m "Rollback release"
git push origin main 26.01.06.1

# Automatic promotion triggered by webhook
```

#### Step 3: Verify Rollback

```bash
# Watch rollback pipeline
tkn pipelinerun logs -f -n dev-tools <rollback-run-name>

# Verify prod AAP
PROD_URL=$(oc get route aap-prod -n aap-prod -o jsonpath='{.spec.host}')
echo "Prod AAP: https://${PROD_URL}"

# Check:
# - EE reverted to 25.12.31.0 version
# - Projects synced to 25.12.31.0 commits
# - Jobs running successfully
# - Issue resolved
```

**Timeline**: Rollback completes in <5 minutes (same as promotion)

---

## Troubleshooting

For comprehensive troubleshooting guidance, see the **[Troubleshooting Guide](./docs/TROUBLESHOOTING-GUIDE.md)** which covers:

- ArgoCD application sync issues
- AAP instance startup problems
- Pipeline failures and diagnostics
- GitOps configuration drift
- Emergency procedures

Common quick fixes:
- **ArgoCD not syncing**: `oc patch application <app-name> -n openshift-gitops --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{}}}'`
- **Pipeline stuck**: `tkn pipelinerun cancel <run-name> -n dev-tools`
- **Check logs**: `tkn pipelinerun logs <run-name> -n dev-tools -f`

---

## Security Model

The platform implements a comprehensive **zero-trust security model** based on Constitution Article V. For complete security guidance, see the **[Security Guide](./docs/SECURITY-GUIDE.md)** which covers:

- Secret management and rotation procedures
- RBAC enforcement and service account permissions
- Network policy implementation
- Audit logging and compliance validation
- Multi-layer security architecture

**Key Security Principles**:
- ✅ **No secrets in Git** - All secrets stored in OCP or HashiCorp Vault
- ✅ **Least privilege** - ServiceAccounts have minimal required permissions
- ✅ **Complete audit trail** - All changes tracked in Git and pipeline logs
- ✅ **Automated validation** - Pre-commit hooks and CI/CD security scanning

---

**Quickstart Version**: 1.0.0
**Last Updated**: 2025-10-27
**Next Review**: After first production deployment

**Questions/Issues**: File issue in `cluster-config` repository

