# Security & Validation Guide

Comprehensive guide to security, validation, and quality assurance for the platform.

---

## Zero-Trust Security Model

Based on **Constitutional Article V: Zero-Trust Security**.

### Core Principles

1. **No secrets in Git** - Use OCP secrets or HashiCorp Vault
2. **Least privilege RBAC** - Minimal required permissions
3. **Continuous scanning** - Vulnerability and secret detection
4. **Immutable artifacts** - Version-locked, digest-referenced images
5. **Complete audit trail** - Git and pipeline history

---

## Secret Management

### Rules

- **Never** commit secrets to Git
- Use `{{ lookup('env', 'VAR') }}` or Ansible Vault
- AAP credentials reference secrets by name only
- Tekton mounts secrets as files (not env vars)

### Secret Rotation

```bash
# Rotate AAP admin password
NEW_PASSWORD=$(openssl rand -base64 32)
oc patch secret aap-admin-password -n aap-prod \
  --type merge -p "{\"data\":{\"password\":\"$(echo -n ${NEW_PASSWORD} | base64)\"}}"

# Restart AAP to pick up new password
oc delete pod -n aap-prod -l app.kubernetes.io/component=web
```

---

## RBAC Enforcement

### ServiceAccounts

| ServiceAccount | Namespace | Permissions | Used By |
|----------------|-----------|-------------|---------|
| `argocd-application-controller` | `openshift-gitops` | Create/update K8s resources | ArgoCD sync |
| `tekton-cac-sa` | `dev-tools` | Read secrets, run pods | CaC pipeline |
| `tekton-promotion-sa` | `dev-tools` | Read secrets, push images | Promotion |
| `tekton-pr-sa` | `dev-tools` | Run pods (no secret access) | PR validation |

### Verify RBAC

```bash
oc auth can-i --as=system:serviceaccount:dev-tools:tekton-cac-sa \
  create pods -n dev-tools
```

---

## Validation Layers

```
Pre-commit → PR Validation → Release Validation → Production Deployment
  <1 sec       <5 min          <15 min              Validated
```

---

## Release Manifest Validation

### Required Fields

```yaml
apiVersion: v1
kind: ReleaseManifest
metadata:
  name: release-25.01.05.0
  version: "25.01.05.0"
  environment: prod
  createdAt: "2024-01-15T10:30:00Z"
spec:
  components:
    - name: automation-collection
      type: collection
      version: "25.01.05.0"
```

### Validation Rules

| Check | Requirement |
|-------|-------------|
| Version format | `YY.MM.DD.PATCH` |
| Commit SHAs | 40 characters |
| Image references | `sha256:...` digest |
| Production | Security scan, approvals, rollback target |

### Validate

```bash
./scripts/validate-manifest-schema.py releases/release-25.01.05.0.yaml --verbose
```

---

## AAP Configuration Validation

```bash
./scripts/validate-aap-config.py --environment prod
./scripts/validate-aap-config.py --all-environments
```

### Checks

| Category | Validation |
|----------|------------|
| Credentials | No hardcoded secrets, vault/lookup only |
| Projects | Git SCM type, valid URLs |
| Job Templates | Valid references, no :latest |
| EE | No :latest tags, prefer digests |

---

## SBOM Generation

Generate Software Bill of Materials for container images:

```bash
# All formats
./scripts/generate-sbom.sh localhost/ansible-ee:latest

# Specific format
syft localhost/ansible-ee:latest -o spdx-json > sbom-spdx.json
syft localhost/ansible-ee:latest -o cyclonedx-json > sbom-cyclonedx.json
```

---

## Vulnerability Scanning

### Using Grype

```bash
./scripts/scan-vulnerabilities.sh localhost/ansible-ee:latest

# Direct usage
grype localhost/ansible-ee:latest
grype localhost/ansible-ee:latest --fail-on critical
grype localhost/ansible-ee:latest -o sarif > report.sarif
```

### Using Trivy

```bash
trivy image localhost/ansible-ee:latest
trivy image --severity CRITICAL,HIGH localhost/ansible-ee:latest
```

### Severity Thresholds

| Environment | Threshold | Policy |
|-------------|-----------|--------|
| Development | Low | Warn only |
| QA | Medium | Warn, track |
| Production | High/Critical | Fail deployment |

---

## Python Dependency Scanning

```bash
# Audit dependencies
pip-audit -r requirements.txt

# Security check
safety check -r requirements.txt

# Security analysis
bandit -r plugins/
```

---

## Audit Trail

### Git Audit

```bash
git log --all --oneline
git log --all --grep="25.01.05.0"
git log -- group_vars/aap_prod.yml
git log --all --pretty=format:'%h|%an|%ae|%ad|%s' --date=iso > audit.csv
```

### Tekton Audit

```bash
tkn pipelinerun list -n dev-tools --limit 100
oc get pipelineruns -n dev-tools -o json > pipelinerun-audit.json
```

---

## Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-from-other-namespaces
  namespace: aap-prod
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
  - from:
    - podSelector: {}
    - namespaceSelector:
        matchLabels:
          name: dev-tools
```

---

## Best Practices

### For Developers

1. Never commit secrets - use OCP secrets or Vault
2. Use parameterized credentials in AAP
3. Follow RBAC principles - request minimal permissions
4. Run validators locally before commit

### For Operators

1. Rotate secrets regularly
2. Monitor audit logs
3. Implement namespace isolation
4. Keep components updated

### For Production

1. Zero critical vulnerabilities policy
2. Digest-based image references only
3. SBOM generation for all releases
4. Regular security reviews

---

## Tools Installation

```bash
# SBOM
brew install syft

# Vulnerability scanning
brew install grype
brew install aquasecurity/trivy/trivy

# Python security
pip install pip-audit safety bandit
```

---

## References

- [Syft Documentation](https://github.com/anchore/syft)
- [Grype Documentation](https://github.com/anchore/grype)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)

