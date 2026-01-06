# Multi-Cluster Deployment Guide

Deploying the platform across multiple OpenShift clusters.

---

## Architecture Options

### Option 1: Single Cluster per Environment (Recommended)

```
Cluster A (Dev)      Cluster B (QA)       Cluster C (Prod)
├── aap-dev          ├── aap-qa           ├── aap-prod
├── Tekton CI        └── ArgoCD           └── ArgoCD
└── ArgoCD
```

**Pros**: Complete isolation | **Cons**: More clusters to manage

### Option 2: Multi-Environment per Cluster

```
Cluster A (Non-Prod)         Cluster B (Prod)
├── aap-dev                  ├── aap-prod
├── aap-qa                   └── ArgoCD
└── ArgoCD + Tekton
```

**Pros**: Fewer clusters | **Cons**: Less isolation

---

## Deploying to Additional Clusters

Same Git repository, different cluster - GitOps makes it identical:

```bash
# Connect to new cluster
oc login --server=https://api.cluster-b.example.com:6443

# Bootstrap (same as initial install)
oc apply -f bootstrap-openshift-gitops/openshift-gitops-operator-subscription.yml

# Wait for operator...
oc wait --for=condition=Ready pod \
  -l name=openshift-gitops-operator \
  -n openshift-operators --timeout=300s

# Apply ApplicationSet
oc apply -f bootstrap-openshift-gitops/cluster-applicationset.yml
```

### Environment-Specific Deployment

To deploy only certain environments on certain clusters:

```yaml
# cluster-applicationset.yml for Prod-only cluster
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
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

### Hub and Spoke Pattern

```
Hub Cluster (Management)
├── ArgoCD (manages all clusters)
└── Central dashboards

Spoke Cluster 1          Spoke Cluster 2
├── AAP Dev              ├── AAP Prod
└── (No local ArgoCD)    └── (No local ArgoCD)
```

**Add spoke cluster to hub ArgoCD**:

```yaml
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
    {"bearerToken": "<sa-token>", "tlsClientConfig": {"insecure": false}}
```

### Independent Clusters (Recommended for DR)

- Each cluster has its own ArgoCD
- All sync from same Git repository
- Git ensures consistent state

---

## Regional Configuration

Use Kustomize overlays for regional differences:

```
cluster-config/applications/aap-prod/
├── base/
│   └── kustomization.yaml
└── overlays/
    ├── us-east/
    │   └── kustomization.yaml
    └── us-west/
        └── kustomization.yaml
```

---

## Secrets Management

### HashiCorp Vault (Recommended)

Each cluster connects to the same Vault:

```yaml
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

**Vault path structure**:

```
secret/
├── aap-prod/
│   ├── common/     # Shared across clusters
│   ├── us-east/    # Region-specific
│   └── us-west/
```

---

## Disaster Recovery

### Active-Passive

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
# 4. EE images from registry mirror
```

---

## Best Practices

1. **Same Git repository for all clusters** - Ensures consistency
2. **Pin versions in production** - No `:latest` tags
3. **Cluster-scoped secrets** - Region/cluster specific where needed
4. **Central monitoring** - Single dashboard for all clusters
5. **Regular DR testing** - Quarterly failover exercises

---

## Related Documents

- [DISASTER-RECOVERY.md](./DISASTER-RECOVERY.md)
- [GIT-WORKFLOW.md](./GIT-WORKFLOW.md)
