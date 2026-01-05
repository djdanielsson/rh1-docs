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
- [VERSIONING-STRATEGY.md](./VERSIONING-STRATEGY.md) - Version management


