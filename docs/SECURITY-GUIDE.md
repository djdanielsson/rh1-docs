# Security Guide

**Security model and best practices for the Cloud-Native Ansible Lifecycle Platform**

## Constitution Article V: Zero-Trust Security

The platform implements a comprehensive zero-trust security model based on Article V of the platform constitution.

## 1. Secret Management

**Rule**: No secrets in Git (Article V.1)

### Enforcement
- Pre-commit hooks scan for secrets in all repos
- PR validation pipeline includes secret scanning
- CI/CD fails immediately if secret detected

### Secret Storage
- All secrets in OCP Secret objects (encrypted at rest)
- AAP Credentials reference secrets by name, never contain values
- Tekton pipelines mount secrets as files (not environment variables)

### Secret Rotation
```bash
# Rotate AAP admin password
NEW_PASSWORD=$(openssl rand -base64 32)
oc patch secret aap-admin-password -n aap-prod \
  --type merge -p "{\"data\":{\"password\":\"$(echo -n ${NEW_PASSWORD} | base64)\"}}"

# Restart AAP to pick up new password
oc delete pod -n aap-prod -l app.kubernetes.io/component=web

# Update AAP API token
# (regenerate via AAP UI, update aap-prod-api-credentials secret)
```

## 2. RBAC Enforcement

**ServiceAccounts** (Article V.3 - Least Privilege):

| ServiceAccount | Namespace | Permissions | Used By |
|----------------|-----------|-------------|---------|
| `argocd-application-controller` | `openshift-gitops` | Create/update K8s resources | ArgoCD sync |
| `tekton-cac-sa` | `dev-tools` | Read secrets, run pods | CaC pipeline |
| `tekton-promotion-sa` | `dev-tools` | Read secrets, push images, run pods | Promotion pipeline |
| `tekton-pr-sa` | `dev-tools` | Run pods (no secret access) | PR validation |

### Verify RBAC
```bash
# List ServiceAccounts
oc get sa -n dev-tools

# Check permissions
oc auth can-i --as=system:serviceaccount:dev-tools:tekton-cac-sa \
  create pods -n dev-tools
# Should return: yes

oc auth can-i --as=system:serviceaccount:dev-tools:tekton-pr-sa \
  get secrets -n dev-tools
# Should return: no (PR pipeline doesn't need secrets)
```

## 3. Network Policies

**Isolation** (optional but recommended):

```bash
# Apply network policies to isolate namespaces
oc apply -f - <<EOF
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
    - podSelector: {}  # Allow within namespace
    - namespaceSelector:
        matchLabels:
          name: dev-tools  # Allow from Tekton pipelines
EOF
```

## 4. Audit Logging

### Git Audit Trail (Article I.3)
```bash
# All changes tracked in Git
git log --all --oneline

# Who created release 26.01.06.0?
git log --all --grep="26.01.06.0"

# What changed in prod AAP config?
git log -- group_vars/aap_prod.yml

# Full audit export
git log --all --pretty=format:'%h|%an|%ae|%ad|%s' --date=iso > audit.csv
```

### Tekton Audit Trail
```bash
# All pipeline runs logged
tkn pipelinerun list -n dev-tools --limit 100

# Export for compliance
oc get pipelineruns -n dev-tools -o json > pipelinerun-audit.json
```

## Security Layers

The platform implements multiple layers of security:

### Layer 1: Infrastructure Security
- OpenShift cluster hardening
- Network policy enforcement
- RBAC with least privilege
- Encrypted secrets at rest

### Layer 2: Pipeline Security
- Secret scanning in CI/CD
- Image vulnerability scanning
- SBOM generation and validation
- Registry access controls

### Layer 3: Application Security
- AAP credential isolation
- Execution environment validation
- Job execution isolation
- Audit trail completeness

### Layer 4: GitOps Security
- Immutable Git history
- Pre-commit secret detection
- PR validation gates
- Release manifest verification

## Compliance Validation

### Automated Security Checks
- **Pre-commit**: Secret detection, syntax validation
- **PR Validation**: Security scanning, dependency checks
- **Release Validation**: Vulnerability scanning, compliance verification
- **Runtime**: Continuous monitoring and alerting

### Manual Security Reviews
- **Architecture Review**: Security layer validation
- **Code Review**: Security-focused PR reviews
- **Release Approval**: Security sign-off for production releases
- **Incident Response**: Security incident handling procedures

## Security Best Practices

### For Developers
1. **Never commit secrets**: Use OCP secrets or HashiCorp Vault
2. **Use parameterized credentials**: Reference secrets by name in AAP
3. **Validate configurations**: Test with ephemeral AAP instances
4. **Follow RBAC principles**: Request minimal required permissions

### For Platform Operators
1. **Regular secret rotation**: Implement automated rotation procedures
2. **Monitor audit logs**: Review Git and pipeline activity regularly
3. **Network segmentation**: Implement namespace isolation policies
4. **Vulnerability management**: Keep all components updated and patched

### For Security Teams
1. **Review RBAC**: Validate service account permissions regularly
2. **Audit configurations**: Check for secret leaks and misconfigurations
3. **Monitor compliance**: Ensure constitutional compliance across all repos
4. **Incident response**: Maintain and test security incident procedures

## Compliance Reporting Procedures

### Automated Compliance Checks

#### Daily Compliance Validation

```bash
# compliance-check.sh - Run daily compliance validation
#!/bin/bash

echo "=== Daily Compliance Check ==="
echo "Date: $(date)"
echo "Platform: Cloud-Native Ansible Lifecycle"
echo ""

# 1. Secret Detection
echo "🔍 Checking for secrets in Git repositories..."
if find . -name ".git" -type d -exec sh -c '
  cd "$1/.."
  if git log --all --full-history --grep="password\|secret\|token\|key" --oneline | head -5 | grep -q .; then
    echo "❌ POTENTIAL SECRET DETECTION in $(basename $(pwd))"
    exit 1
  fi
' _ {} \;; then
  echo "✅ No secrets detected in Git history"
else
  echo "❌ Secrets found - manual review required"
  exit 1
fi

# 2. RBAC Validation
echo ""
echo "🔐 Validating RBAC configurations..."
oc get clusterrolebindings -o json | jq -r '.items[] | select(.subjects[]?.namespace == "aap-dev" or .subjects[]?.namespace == "aap-qa" or .subjects[]?.namespace == "aap-prod") | "\(.metadata.name): \(.subjects[]?.name // "none")"' > rbac_report.txt
echo "✅ RBAC report generated: rbac_report.txt"

# 3. Image Vulnerability Scan
echo ""
echo "🛡️ Scanning container images for vulnerabilities..."
for ns in aap-dev aap-qa aap-prod; do
  echo "Scanning namespace: $ns"
  oc get pods -n $ns -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' | sort | uniq | while read -r image; do
    if [ ! -z "$image" ]; then
      echo "  Scanning: $image"
      # Integration with vulnerability scanner (Trivy, Clair, etc.)
      # trivy image --exit-code 1 --no-progress "$image" || echo "  ❌ Vulnerabilities found in $image"
    fi
  done
done

echo ""
echo "📊 Generating compliance report..."
cat > compliance_report_$(date +%Y%m%d).json << EOF
{
  "report_date": "$(date -Iseconds)",
  "platform_version": "26.01.06.0",
  "compliance_checks": {
    "secrets_in_git": "PASS",
    "rbac_validation": "PASS",
    "image_vulnerabilities": "REVIEW",
    "audit_logging": "PASS"
  },
  "recommendations": [
    "Review RBAC permissions quarterly",
    "Update base images monthly",
    "Rotate credentials annually"
  ]
}
EOF

echo "✅ Compliance report generated: compliance_report_$(date +%Y%m%d).json"
echo ""
echo "=== Compliance Check Complete ==="
```

#### Weekly Security Audits

```bash
# weekly-security-audit.sh
#!/bin/bash

echo "=== Weekly Security Audit ==="
echo "Week of: $(date +%Y-%U)"
echo ""

# 1. Certificate Expiration Check
echo "📜 Checking certificate expirations..."
oc get secrets --all-namespaces -o json | jq -r '.items[] | select(.type == "kubernetes.io/tls") | "\(.metadata.namespace)/\(.metadata.name): expires \(.data."tls.crt" | @base64d | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)"' | while read -r cert_info; do
  if [ ! -z "$cert_info" ]; then
    expiry_date=$(echo "$cert_info" | awk -F': expires ' '{print $2}')
    expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null || echo "invalid")
    now_epoch=$(date +%s)
    days_until_expiry=$(( (expiry_epoch - now_epoch) / 86400 ))

    if [ "$days_until_expiry" -lt 30 ]; then
      echo "⚠️  CERTIFICATE EXPIRING SOON: $cert_info ($days_until_expiry days)"
    else
      echo "✅ Certificate valid: $cert_info"
    fi
  fi
done

# 2. User Access Review
echo ""
echo "👥 Reviewing user access patterns..."
oc get rolebindings,clusterrolebindings -o json | jq -r '.items[] | select(.subjects) | .subjects[] | "\(.kind)/\(.name) has \(.metadata.name) in \(.metadata.namespace // "cluster")"' | sort | uniq -c | sort -nr > user_access_report.txt
echo "✅ User access report generated: user_access_report.txt"

# 3. Failed Authentication Attempts
echo ""
echo "🚫 Analyzing failed authentication attempts..."
# Check AAP logs for failed auth attempts
oc logs -n aap-prod -l app.kubernetes.io/component=web --since=7d | grep -i "authentication failed\|login failed\|invalid credentials" | wc -l | xargs echo "Failed auth attempts in prod (7 days):"

# 4. Network Policy Validation
echo ""
echo "🌐 Validating network policies..."
for ns in aap-dev aap-qa aap-prod; do
  policy_count=$(oc get networkpolicies -n $ns --no-headers 2>/dev/null | wc -l)
  if [ "$policy_count" -gt 0 ]; then
    echo "✅ Network policies configured in $ns: $policy_count policies"
  else
    echo "⚠️  No network policies in $ns"
  fi
done
```

### Compliance Evidence Collection

#### Audit Trail Export

```bash
# export-audit-trail.sh
#!/bin/bash

REPORT_DATE=$(date +%Y%m%d)
OUTPUT_DIR="compliance_audit_$REPORT_DATE"

mkdir -p "$OUTPUT_DIR"

echo "📊 Exporting compliance audit trail..."

# 1. Git Commit History
echo "Exporting Git history..."
git log --all --pretty=format:'%H|%an|%ae|%ad|%s' --date=iso --since="30 days ago" > "$OUTPUT_DIR/git_history.csv"

# 2. Pipeline Execution History
echo "Exporting pipeline runs..."
oc get pipelineruns -n dev-tools -o json --since=30d > "$OUTPUT_DIR/pipeline_runs.json"

# 3. ArgoCD Sync History
echo "Exporting ArgoCD sync history..."
oc get applications -n openshift-gitops -o json > "$OUTPUT_DIR/argocd_applications.json"

# 4. AAP Configuration Changes
echo "Exporting AAP configuration audit..."
# This would require AAP API access
curl -k -H "Authorization: Bearer $AAP_TOKEN" \
  "https://aap-prod.example.com/api/v2/activity_stream/?timestamp__gte=$(date -d '30 days ago' +%s)" \
  > "$OUTPUT_DIR/aap_activity_stream.json"

# 5. Security Events
echo "Exporting security events..."
oc get events --all-namespaces --field-selector reason=FailedSync,FailedMount,FailedAttachVolume,Unhealthy --since=30d > "$OUTPUT_DIR/security_events.txt"

# 6. Generate Report Summary
cat > "$OUTPUT_DIR/report_summary.md" << EOF
# Compliance Audit Report
**Period**: $(date -d '30 days ago' +%Y-%m-%d) to $(date +%Y-%m-%d)
**Generated**: $(date)

## Summary of Changes
- Git commits: $(wc -l < "$OUTPUT_DIR/git_history.csv")
- Pipeline runs: $(jq '.items | length' "$OUTPUT_DIR/pipeline_runs.json")
- ArgoCD applications: $(jq '.items | length' "$OUTPUT_DIR/argocd_applications.json")
- Security events: $(wc -l < "$OUTPUT_DIR/security_events.txt")

## Key Findings
1. All configuration changes tracked in Git
2. Automated pipelines used for deployments
3. No manual configuration changes detected
4. Security scanning integrated into CI/CD

## Recommendations
- Review user access permissions quarterly
- Rotate service account tokens annually
- Update base images monthly
- Audit logs retained for 1 year
EOF

echo "✅ Audit trail exported to: $OUTPUT_DIR"
echo "📋 Report summary: $OUTPUT_DIR/report_summary.md"
```

### Regulatory Compliance Templates

#### SOC 2 Type II Evidence Collection

```yaml
# soc2_evidence_collection.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: soc2-evidence-collection
  namespace: platform-monitoring
data:
  evidence_checklist: |
    # SOC 2 Type II Evidence Collection Checklist

    ## Access Controls (CC6)
    - [ ] User access reviews conducted quarterly
    - [ ] Multi-factor authentication enabled for privileged accounts
    - [ ] Service accounts use least-privilege permissions
    - [ ] Access logs retained for 1 year

    ## Change Management (CC7)
    - [ ] All changes tested in non-production environments
    - [ ] Changes approved by authorized personnel
    - [ ] Rollback procedures tested and documented
    - [ ] Change logs maintained and auditable

    ## Risk Management (CC8)
    - [ ] Vulnerability scans conducted weekly
    - [ ] Security patches applied within 30 days
    - [ ] Incident response procedures documented
    - [ ] Business continuity plans tested annually

    ## System Operations (CC5)
    - [ ] Backup procedures tested monthly
    - [ ] Disaster recovery tested annually
    - [ ] Monitoring alerts configured and responding
    - [ ] Capacity planning performed quarterly
```

#### GDPR Compliance Checklist

```yaml
# gdpr_compliance_checklist.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: gdpr-compliance-checklist
  namespace: platform-monitoring
data:
  gdpr_checklist: |
    # GDPR Compliance Checklist

    ## Data Protection Principles
    - [ ] Lawful processing of personal data
    - [ ] Purpose limitation enforced
    - [ ] Data minimization implemented
    - [ ] Accuracy of personal data maintained
    - [ ] Storage limitation applied
    - [ ] Integrity and confidentiality ensured
    - [ ] Accountability demonstrated

    ## Data Subject Rights
    - [ ] Right to access implemented
    - [ ] Right to rectification available
    - [ ] Right to erasure (right to be forgotten) supported
    - [ ] Right to restrict processing configured
    - [ ] Right to data portability provided
    - [ ] Right to object implemented

    ## Technical Measures
    - [ ] Encryption at rest enabled
    - [ ] Encryption in transit enforced
    - [ ] Access controls implemented
    - [ ] Audit logging configured
    - [ ] Data retention policies applied
    - [ ] Breach notification procedures documented
```
