# Multi-Cluster Deployment Guide

**Purpose**: Deploying the platform across multiple OpenShift clusters
**Last Updated**: 2025-01-05

---

## Overview

The Cloud-Native Ansible Lifecycle platform is designed to be deployed identically across any number of OpenShift clusters. Since all configuration is in Git, the same process works regardless of cluster count or location.

---

## Architecture Options

### Option 1: Single Cluster per Environment (Recommended)

```
Cluster A (Dev)      Cluster B (QA)       Cluster C (Prod)
├── aap-dev          ├── aap-qa           ├── aap-prod
├── Tekton CI        └── (optional CI)    └── (minimal CI)
└── ArgoCD                                    
```

**Pros**: Complete isolation, easier security boundaries
**Cons**: More clusters to manage

### Option 2: Multi-Environment per Cluster

```
Cluster A (Non-Prod)         Cluster B (Prod)
├── aap-dev                  ├── aap-prod
├── aap-qa                   └── ArgoCD
├── Tekton CI
└── ArgoCD
```

**Pros**: Fewer clusters, shared resources
**Cons**: Less isolation

### Option 3: Regional Clusters

```
US-East Cluster              US-West Cluster
├── aap-prod-east            ├── aap-prod-west
└── ArgoCD                   └── ArgoCD
```

**Pros**: Geographic redundancy, latency optimization
**Cons**: Configuration drift risk

---

## Detailed Deployment Procedures

### Prerequisites for Multi-Cluster Setup

#### 1. Cluster Requirements

Each cluster must meet the minimum requirements:

```bash
# Verify cluster version
oc version --client

# Check cluster capacity
oc get nodes
oc describe nodes | grep -A 5 "Allocated resources"

# Verify storage classes
oc get storageclass

# Check network connectivity between clusters (if needed)
curl -k https://api.<cluster-name>.<domain>:6443/version
```

#### 2. Git Repository Setup

Use separate branches or repositories for multi-cluster configurations:

```
Option A: Single Repo, Multiple Branches
cluster-config/
├── main (shared config)
├── cluster-east/
└── cluster-west/

Option B: Separate Repos
├── cluster-config-east/
├── cluster-config-west/
└── cluster-config-shared/
```

#### 3. ArgoCD Configuration

Configure ArgoCD for each cluster:

```yaml
# argocd/cluster-bootstrap.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: cluster-bootstrap
  namespace: openshift-gitops
spec:
  project: default
  source:
    repoURL: https://github.com/org/cluster-config-east.git  # Cluster-specific repo
    targetRevision: main
    path: applications
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### Cluster-Specific Configuration

#### Environment-Specific Variables

Create cluster-specific configuration files:

```yaml
# applications/aap-prod/cluster-vars.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cluster-specific-vars
  namespace: aap-prod
data:
  CLUSTER_NAME: "production-east"
  CLUSTER_REGION: "us-east-1"
  CLUSTER_ENVIRONMENT: "prod"
  EXTERNAL_DNS_ZONE: "prod.example.com"
  DATABASE_HOST: "postgres-prod-east.example.com"
```

#### Network Policies

Implement cluster-specific network isolation:

```yaml
# applications/aap-prod/network-policies.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: aap-prod-isolation
  namespace: aap-prod
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          environment: prod
          cluster: east
    - podSelector:
        matchLabels:
          app: tekton-pipelines-controller
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-cross-cluster
  namespace: aap-prod
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          cluster: east  # Only allow same cluster
```

### Multi-Cluster Promotion Strategy

#### Release Manifest Adaptation

Modify release manifests for multi-cluster deployments:

```yaml
# automation-release-manifest/releases/release-26.1.6-0.yaml
version: "26.1.6-0"
metadata:
  release_date: "2026-01-06T10:00:00Z"
  approver: "Platform Team"
  target_clusters:
    - name: "prod-east"
      environment: "prod"
      region: "us-east"
    - name: "prod-west"
      environment: "prod"
      region: "us-west"
components:
  aap_configuration: "abc123def..."
  execution_environment: "def456ghi..."
  collections: "ghi789jkl..."
cluster_overrides:
  prod-east:
    database_host: "postgres-prod-east.example.com"
    external_url: "aap-prod-east.example.com"
  prod-west:
    database_host: "postgres-prod-west.example.com"
    external_url: "aap-prod-west.example.com"
```

#### Cluster-Specific Pipelines

Create cluster-aware promotion pipelines:

```yaml
# tekton/pipelines/cluster-promotion-pipeline.yaml
apiVersion: tekton.dev/v1beta1
kind: Pipeline
metadata:
  name: cluster-promotion-pipeline
spec:
  params:
  - name: release_tag
    type: string
  - name: target_cluster
    type: string
  tasks:
  - name: parse-manifest
    taskRef:
      name: parse-release-manifest
    params:
    - name: release_tag
      value: $(params.release_tag)
    - name: target_cluster
      value: $(params.target_cluster)
  - name: deploy-cluster-config
    taskRef:
      name: deploy-to-cluster
    params:
    - name: cluster_name
      value: $(params.target_cluster)
    - name: manifest_data
      value: $(tasks.parse-manifest.results.cluster_config)
  - name: validate-deployment
    taskRef:
      name: validate-cluster-health
    params:
    - name: cluster_name
      value: $(params.target_cluster)
```

### Monitoring and Observability

#### Cross-Cluster Monitoring

Set up monitoring across clusters:

```yaml
# applications/monitoring/cluster-monitoring.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: prometheus-config
  namespace: openshift-monitoring
data:
  prometheus.yml: |
    global:
      scrape_interval: 15s
    scrape_configs:
    - job_name: 'federate-east'
      honor_labels: true
      metrics_path: '/federate'
      params:
        'match[]':
          - '{job=~".+"}'
      static_configs:
      - targets:
        - 'prometheus-prod-east.example.com:9090'
    - job_name: 'federate-west'
      honor_labels: true
      metrics_path: '/federate'
      params:
        'match[]':
          - '{job=~".+"}'
      static_configs:
      - targets:
        - 'prometheus-prod-west.example.com:9090'
```

#### Centralized Logging

Configure centralized log aggregation:

```yaml
# applications/logging/cluster-logging.yaml
apiVersion: logging.openshift.io/v1
kind: ClusterLogForwarder
metadata:
  name: instance
  namespace: openshift-logging
spec:
  outputs:
  - name: elasticsearch-east
    type: elasticsearch
    url: https://elasticsearch-prod-east.example.com:9200
    secret:
      name: elasticsearch-east-secret
  - name: elasticsearch-west
    type: elasticsearch
    url: https://elasticsearch-prod-west.example.com:9200
    secret:
      name: elasticsearch-west-secret
  pipelines:
  - name: application-logs-east
    inputRefs:
    - application
    - infrastructure
    outputRefs:
    - elasticsearch-east
    labels:
      cluster: "east"
  - name: application-logs-west
    inputRefs:
    - application
    - infrastructure
    outputRefs:
    - elasticsearch-west
    labels:
      cluster: "west"
```

### Disaster Recovery for Multi-Cluster

#### Cross-Cluster Failover

Implement failover procedures:

```bash
# failover.sh
#!/bin/bash
PRIMARY_CLUSTER="prod-east"
SECONDARY_CLUSTER="prod-west"
RELEASE_TAG="26.1.6-0"

echo "Initiating failover from $PRIMARY_CLUSTER to $SECONDARY_CLUSTER..."

# Scale down primary
oc --context=$PRIMARY_CLUSTER scale deployment aap-prod --replicas=0 -n aap-prod

# Promote to secondary with same release
oc --context=$SECONDARY_CLUSTER create -f - <<EOF
apiVersion: tekton.dev/v1beta1
kind: PipelineRun
metadata:
  generateName: failover-promotion-
  namespace: dev-tools
spec:
  pipelineRef:
    name: cluster-promotion-pipeline
  params:
  - name: release_tag
    value: "$RELEASE_TAG"
  - name: target_cluster
    value: "$SECONDARY_CLUSTER"
  - name: failover_mode
    value: "true"
EOF

# Update DNS to point to secondary
# (Integration with external DNS provider needed)

echo "Failover complete. Traffic routed to $SECONDARY_CLUSTER"
```

#### Data Synchronization

Ensure data consistency across clusters:

```yaml
# applications/database/cluster-data-sync.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: database-sync
  namespace: aap-prod
spec:
  schedule: "*/30 * * * *"  # Every 30 minutes
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: sync-job
            image: postgres:13
            command:
            - /bin/bash
            - -c
            - |
              # Database synchronization logic
              pg_dump -h $PRIMARY_DB -U $DB_USER $DB_NAME | \
              psql -h $SECONDARY_DB -U $DB_USER $DB_NAME
          env:
          - name: PRIMARY_DB
            value: "postgres-prod-east.example.com"
          - name: SECONDARY_DB
            value: "postgres-prod-west.example.com"
          - name: DB_USER
            valueFrom:
              secretKeyRef:
                name: database-credentials
                key: username
          restartPolicy: Never
```

---

## Best Practices for Multi-Cluster Deployments

## Deploying to Additional Clusters

### Same Configuration, Different Cluster

The beauty of GitOps: same Git repository, different cluster.

```bash
# Connect to new cluster
oc login --server=https://api.cluster-b.example.com:6443

# Bootstrap is identical
oc apply -f bootstrap-openshift-gitops/openshift-gitops-operator-subscription.yml

# Wait for operator...
oc wait --for=condition=Ready pod \
  -l name=openshift-gitops-operator \
  -n openshift-operators \
  --timeout=300s

# Apply ApplicationSet - will deploy same configuration
oc apply -f bootstrap-openshift-gitops/cluster-applicationset.yml
```

### Environment-Specific Deployment

If you only want certain environments on certain clusters, use ArgoCD selectors:

```yaml
# cluster-applicationset.yml for Prod-only cluster
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: cluster
spec:
  generators:
    - git:
        repoURL: https://github.com/djdanielsson/rh1-cluster-config.git
        directories:
          - path: applications/aap-prod  # Only prod
          - path: applications/openshift-pipelines
```

---

## Managing Multiple Clusters

### ArgoCD Hub and Spoke

For centralized management, use ArgoCD in hub-and-spoke pattern:

```
Hub Cluster (Management)
├── ArgoCD (manages all clusters)
└── Central dashboards

Spoke Cluster 1          Spoke Cluster 2
├── AAP Dev              ├── AAP Prod
└── (No ArgoCD)          └── (No ArgoCD)
```

**Configuration**:
```yaml
# Add spoke clusters to hub ArgoCD
apiVersion: v1
kind: Secret
metadata:
  name: cluster-spoke-1
  namespace: openshift-gitops
  labels:
    argocd.argoproj.io/secret-type: cluster
stringData:
  name: spoke-cluster-1
  server: https://api.spoke-1.example.com:6443
  config: |
    {
      "bearerToken": "<service-account-token>",
      "tlsClientConfig": {"insecure": false}
    }
```

### Independent Clusters

For fully independent clusters (recommended for true DR):

- Each cluster has its own ArgoCD
- All clusters sync from same Git repository
- Consistent state guaranteed by Git

---

## Regional Considerations

### Configuration Variations by Region

Use Kustomize overlays for regional differences:

```
cluster-config/
├── applications/
│   └── aap-prod/
│       ├── base/
│       │   └── kustomization.yaml
│       ├── overlays/
│       │   ├── us-east/
│       │   │   └── kustomization.yaml
│       │   └── us-west/
│       │       └── kustomization.yaml
```

### DNS and Ingress

Each cluster will have its own routes:
- `aap-prod.apps.us-east.example.com`
- `aap-prod.apps.us-west.example.com`

Consider:
- Global load balancer (F5, Cloudflare, etc.)
- DNS-based failover
- Active-active or active-passive

---

## Secrets Management Across Clusters

### HashiCorp Vault Integration

Each cluster connects to the same Vault instance:

```yaml
# ExternalSecret (per cluster)
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: aap-credentials
  namespace: aap-prod
spec:
  secretStoreRef:
    name: vault-backend
    kind: ClusterSecretStore
  target:
    name: aap-credentials
  data:
    - secretKey: admin-password
      remoteRef:
        key: secret/data/aap-prod
        property: admin-password
```

### Cluster-Specific Secrets

For cluster-specific secrets (API endpoints, etc.):

```yaml
# Vault path structure
secret/
├── aap-prod/
│   ├── common/          # Shared across all clusters
│   ├── us-east/         # US-East specific
│   └── us-west/         # US-West specific
```

---

## Sync and Drift Management

### Ensuring Consistency

1. **Single Git Source**: All clusters sync from same repository
2. **Auto-sync Enabled**: ArgoCD automatically corrects drift
3. **Self-heal Enabled**: Manual changes reverted automatically

### Monitoring Drift

```bash
# Check all clusters for sync status
for cluster in cluster-a cluster-b cluster-c; do
  echo "=== $cluster ==="
  oc --context=$cluster get applications -n openshift-gitops
done
```

---

## Disaster Recovery Across Clusters

### Active-Active

Both clusters serve traffic, automatic failover via DNS/LB:

```
Users → Global LB → [Cluster A] or [Cluster B]
```

### Active-Passive

Primary cluster serves traffic, standby ready:

```
Users → Cluster A (active)
        Cluster B (standby, synced via GitOps)
```

### Cross-Region Failover

```bash
# If Cluster A fails:
# 1. Update DNS to point to Cluster B
# 2. Cluster B already has identical config (GitOps)
# 3. Secrets available from Vault
# 4. EE images available from registry mirror
```

---

## Best Practices

1. **Use same Git repository for all clusters** - Ensures consistency
2. **Pin versions in production clusters** - No `:latest` tags
3. **Implement cluster-scoped secrets** - Region/cluster specific where needed
4. **Monitor all clusters centrally** - Single dashboard for visibility
5. **Test failover regularly** - Quarterly DR exercises
6. **Document cluster differences** - If any exist, document why

---

## Related Documents

- [DISASTER-RECOVERY.md](./DISASTER-RECOVERY.md) - DR procedures
- [DEPLOYMENT.md](../cluster-config/DEPLOYMENT.md) - Initial deployment
- [GIT-WORKFLOW.md](./GIT-WORKFLOW.md) - Versioning and promotion


