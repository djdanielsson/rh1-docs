# Validation & Quality Guide

**Comprehensive guide to validation, quality assurance, and security scanning for the Cloud-Native Ansible Lifecycle Platform**

## Table of Contents

- [Overview](#overview)
- [Release Manifest Validation](#release-manifest-validation)
- [AAP Configuration Validation](#aap-configuration-validation)
- [SBOM Generation](#sbom-generation)
- [Vulnerability Scanning](#vulnerability-scanning)
- [Dependency Management](#dependency-management)
- [Integration with CI/CD](#integration-with-cicd)
- [Best Practices](#best-practices)

---

## Overview

Quality and security validation ensures **Constitutional Article IV: Production-Grade Quality** and **Article V: Zero-Trust Security** compliance across the platform.

### Validation Layers

```
┌─────────────────────────────────────────────┐
│         Pre-Commit Validation               │
│  (Local development, immediate feedback)    │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│           PR Validation                     │
│    (Automated checks in CI/CD)              │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│       Release Validation                    │
│  (Schema validation, security scans)        │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│      Production Deployment                  │
│   (Final checks before promotion)           │
└─────────────────────────────────────────────┘
```

### Tools & Technologies

| Tool | Purpose | Scope |
|------|---------|-------|
| **JSON Schema** | Release manifest validation | Release manifests |
| **Python Validators** | AAP config validation | AAP configurations |
| **Syft** | SBOM generation | Container images, packages |
| **Grype** | Vulnerability scanning | Images, dependencies |
| **Trivy** | Alternative vulnerability scanner | Images, filesystems |
| **Safety** | Python security checks | Python packages |
| **pip-audit** | Python dependency audit | Python packages |
| **Dependabot** | Automated dependency updates | GitHub repositories |

---

## Release Manifest Validation

### Overview

Release manifests use **JSON Schema** for structure validation and **Python validators** for business logic.

### JSON Schema Location

```
automation-release-manifest/schemas/release-manifest-schema.json
```

### Schema Features

- **Semantic versioning** validation
- **Git commit SHA** format checking
- **Container image digest** validation
- **Environment-specific rules** (dev/qa/prod)
- **Constitutional compliance** checks

### Using the Validator

#### Command Line

```bash
cd automation-release-manifest

# Validate a single manifest
./scripts/validate-manifest-schema.py releases/release-25.01.05.0.yaml

# Validate with verbose output
./scripts/validate-manifest-schema.py releases/release-25.01.05.0.yaml --verbose

# Use custom schema
./scripts/validate-manifest-schema.py releases/release-25.01.05.0.yaml --schema custom-schema.json
```

#### Python API

```python
from pathlib import Path
from scripts.validate_manifest_schema import validate_manifest_file

manifest_path = Path("releases/release-25.01.05.0.yaml")
schema_path = Path("schemas/release-manifest-schema.json")

success = validate_manifest_file(manifest_path, schema_path, verbose=True)

if success:
    print("Validation passed!")
else:
    print("Validation failed!")
```

### Validation Rules

#### Required Fields

```yaml
apiVersion: v1
kind: ReleaseManifest
metadata:
  name: release-25.01.05.0      # Pattern: release-*
  version: "25.01.05.0"         # CalVer YY.MM.DD.PATCH
  environment: prod              # dev, qa, or prod
  createdAt: "2024-01-15T10:30:00Z"
spec:
  components:
    - name: automation-collection
      type: collection
      version: "25.01.05.0"
```

#### Production-Specific Rules

For `environment: prod`, the validator checks:

- ✅ **Security scan** results present and passing
- ✅ **Approvals** from required roles
- ✅ **Test results** present and passing
- ✅ **Rollback target** specified
- ⚠️  No failing tests or security scans

#### Example Output

```
🔍 Validating Release Manifest
Manifest: releases/release-25.01.05.0.yaml
Schema:   schemas/release-manifest-schema.json

✅ Schema validation passed

⚠️  Additional warnings:
   ⚠️  Production release should specify rollbackTarget

✅ Validation complete!
Environment: prod
Version:     25.01.05.0
Components:  3
```

---

## AAP Configuration Validation

### Overview

AAP configuration validator ensures:
- **Correct structure** for all AAP resources
- **Valid cross-references** between resources
- **Security best practices** (no hardcoded secrets)
- **Environment-specific rules**

### Using the Validator

```bash
cd aap-config-as-code

# Validate dev environment
./scripts/validate-aap-config.py --environment dev

# Validate production environment
./scripts/validate-aap-config.py --environment prod

# Validate all environments
./scripts/validate-aap-config.py --all-environments
```

### Validation Checks

#### Organizational Structure

- ✅ Organizations defined
- ✅ Teams with proper RBAC (Article II: Separation of Duties)
- ✅ Descriptions present
- ⚠️  Organization references valid

#### Credentials (Article V: Zero-Trust Security)

- ✅ No hardcoded secrets
- ✅ Ansible Vault or lookup references only
- ✅ Credential types specified
- ✅ Organization assignments
- ❌ **Fails** on unencrypted sensitive fields

#### Projects (Article I: GitOps First)

- ✅ Git SCM type
- ✅ Valid Git URLs
- ✅ Branch specifications
- ⚠️  Non-Git projects flagged

#### Job Templates

- ✅ Project references valid
- ✅ Inventory references valid
- ✅ Playbook specified
- ⚠️  Production templates with variable prompts flagged
- ⚠️  Fact caching recommended

#### Execution Environments

- ✅ Image specified
- ✅ No `:latest` tags
- ⚠️  Production should use digest-based references

### Example Output

```
🔍 Validating AAP Configuration
Environment: prod

Validating credentials.yml...
Validating projects.yml...
Validating inventories.yml...
Validating job_templates.yml...
Validating cross-references...

📊 Validation Results

❌ Errors (2):
   Credential 'my-cred' has unencrypted 'password' - use ansible-vault
   Job Template 'deploy' missing inventory

⚠️  Warnings (1):
   Execution Environment 'ansible-ee' uses 'latest' tag - use specific version

ℹ️  Information:
   Found 2 organization(s)
   Found 5 credential(s)
   Found 3 project(s)

❌ Validation failed with 2 error(s)
```

---

## SBOM Generation

### Overview

Software Bill of Materials (SBOM) provides complete inventory of components in container images and packages.

**Constitutional Article V: Zero-Trust Security** - Track all components for security and compliance.

### Using Syft

#### Generate SBOM for Execution Environment

```bash
cd automation-ee-example

# Build EE first
ansible-builder build -t localhost/ansible-ee:latest

# Generate SBOM (all formats)
./scripts/generate-sbom.sh localhost/ansible-ee:latest

# Generate specific format
./scripts/generate-sbom.sh localhost/ansible-ee:latest spdx
./scripts/generate-sbom.sh localhost/ansible-ee:latest cyclonedx
./scripts/generate-sbom.sh localhost/ansible-ee:latest syft
```

#### Direct Syft Usage

```bash
# SPDX format (industry standard)
syft localhost/ansible-ee:latest -o spdx-json > sbom-spdx.json

# CycloneDX format (OWASP standard)
syft localhost/ansible-ee:latest -o cyclonedx-json > sbom-cyclonedx.json

# Table format (human-readable)
syft localhost/ansible-ee:latest -o table

# JSON format (Syft native)
syft localhost/ansible-ee:latest -o json > sbom.json
```

### SBOM Output

```
📦 Generating SBOM for Execution Environment
Image: localhost/ansible-ee:latest
Format: all

→ Generating SPDX format...
✅ SPDX SBOM: sbom/ansible-ee_latest_20241115_143022.spdx.json

→ Generating CycloneDX format...
✅ CycloneDX SBOM: sbom/ansible-ee_latest_20241115_143022.cyclonedx.json

→ Generating human-readable summary...
✅ Summary: sbom/ansible-ee_latest_20241115_143022.txt

📊 SBOM Statistics

Package counts by type:
  python: 127
  rpm: 245
  go-module: 12

Top packages by size:
  glibc (2.34): 12582912 bytes
  python3.11 (3.11.5): 8388608 bytes

Licenses found:
  MIT
  Apache-2.0
  GPL-2.0
  BSD-3-Clause

✅ SBOM generation complete!
```

### SBOM Storage

Store SBOMs in:
- **Artifact repository** (Artifactory, Nexus)
- **Security platform** (Anchore Enterprise, Snyk)
- **Compliance system** (GRC tools)
- **Git repository** (if not too large)

---

## Vulnerability Scanning

### Overview

Continuous vulnerability scanning identifies security issues in:
- Container images
- Python packages
- Ansible collections
- System packages

### Using Grype (Recommended)

#### Scan Execution Environment

```bash
cd automation-ee-example

# Build EE first
ansible-builder build -t localhost/ansible-ee:latest

# Scan for vulnerabilities
./scripts/scan-vulnerabilities.sh localhost/ansible-ee:latest

# Scan with different scanner
./scripts/scan-vulnerabilities.sh localhost/ansible-ee:latest trivy

# Set failure threshold
./scripts/scan-vulnerabilities.sh localhost/ansible-ee:latest grype critical
./scripts/scan-vulnerabilities.sh localhost/ansible-ee:latest grype high
```

#### Direct Grype Usage

```bash
# Scan image
grype localhost/ansible-ee:latest

# JSON output
grype localhost/ansible-ee:latest -o json > vulnerability-report.json

# SARIF output (for GitHub Security)
grype localhost/ansible-ee:latest -o sarif > vulnerability-report.sarif

# Filter by severity
grype localhost/ansible-ee:latest --fail-on critical
```

### Using Trivy (Alternative)

```bash
# Scan image
trivy image localhost/ansible-ee:latest

# JSON output
trivy image --format json localhost/ansible-ee:latest

# SARIF output
trivy image --format sarif localhost/ansible-ee:latest

# Filter by severity
trivy image --severity CRITICAL,HIGH localhost/ansible-ee:latest
```

### Scan Output

```
🔍 Scanning Execution Environment for Vulnerabilities
Image:    localhost/ansible-ee:latest
Scanner:  grype
Fail on:  high

Running vulnerability scan...
→ Scanning with Grype...
✅ Scan results saved

🔒 Vulnerability Scan Results

┌─────────────┬───────┐
│ Severity    │ Count │
├─────────────┼───────┤
│ Critical    │     0 │
│ High        │     3 │
│ Medium      │    12 │
│ Low         │    45 │
├─────────────┼───────┤
│ Total       │    60 │
└─────────────┴───────┘

Detailed reports:
  JSON:  scan-results/ansible-ee_latest_20241115_143022_grype.json
  Table: scan-results/ansible-ee_latest_20241115_143022_grype.txt
  SARIF: scan-results/ansible-ee_latest_20241115_143022_grype.sarif
```

### Severity Thresholds

| Environment | Threshold | Policy |
|-------------|-----------|--------|
| **Development** | Low | Warn only |
| **QA** | Medium | Warn, track |
| **Production** | High/Critical | Fail deployment |

### Remediation Workflow

1. **Review scan results**: Check detailed reports
2. **Update dependencies**: Upgrade affected packages
3. **Rebuild image**: Create new EE with updates
4. **Re-scan**: Verify fixes
5. **Document exceptions**: If patches unavailable

---

## Dependency Management

### Overview

Automated dependency management keeps the platform secure and up-to-date.

### Dependabot Configuration

Location: `.github/dependabot.yml`

**Configured for**:
- Python packages (pip)
- GitHub Actions
- Docker base images
- Ansible collections (manual)

### Dependabot Features

- ✅ **Weekly scans** (customizable)
- ✅ **Automated PRs** for updates
- ✅ **Grouped updates** by ecosystem
- ✅ **Security advisories** prioritized
- ✅ **Version compatibility** checks

### Manual Dependency Checks

```bash
# Check all dependencies
./scripts/check-dependencies.sh

# Check Python packages
cd automation-collection-example
pip-audit -r requirements.txt

# Check for outdated packages
pip list --outdated

# Check with safety
safety check -r requirements.txt
```

### Python Security Tools

#### pip-audit

```bash
# Audit dependencies
pip-audit -r requirements.txt

# JSON output
pip-audit -r requirements.txt --format json

# Fix vulnerabilities automatically
pip-audit -r requirements.txt --fix
```

#### Safety

```bash
# Check dependencies
safety check -r requirements.txt

# JSON output
safety check -r requirements.txt --json

# Use policy file
safety check -r requirements.txt --policy-file .safety-policy.yml
```

### Safety Policy

Location: `automation-collection-example/.safety-policy.yml`

```yaml
security:
  continue-on-vulnerability-error: false
  ignore-vulnerabilities:
    # Document exceptions with justification
    # 12345:
    #   reason: "Only affects dev environment"
    #   expires: "2025-12-31"

reject-licenses:
  - GPL-3.0
  - AGPL-3.0

accept-licenses:
  - MIT
  - Apache-2.0
  - BSD-3-Clause
```

---

## Integration with CI/CD

### GitHub Actions Workflows

#### SBOM Generation

Workflow: `.github/workflows/sbom-generation.yml`

**Triggers**:
- Push to main/develop
- Pull requests
- Weekly schedule
- Manual dispatch

**Outputs**:
- SBOM artifacts (SPDX, CycloneDX)
- Vulnerability reports (JSON, SARIF)
- GitHub Security tab integration

#### Dependency Scanning

Workflow: `automation-collection-example/.github/workflows/dependency-scan.yml`

**Checks**:
- Python package vulnerabilities (pip-audit, safety)
- Ansible collection updates
- License compliance
- Supply chain security

### Pre-commit Integration

Validation runs automatically on commit:

```bash
# Install hooks
pre-commit install

# Run manually
pre-commit run --all-files

# Update hooks
pre-commit autoupdate
```

### CI/CD Pipeline Integration

```yaml
# Example: Release pipeline validation
- name: Validate Release Manifest
  run: |
    ./scripts/validate-manifest-schema.py releases/release-${VERSION}.yaml

- name: Generate SBOM
  run: |
    syft ${{ env.IMAGE_NAME }} -o spdx-json > sbom.json

- name: Scan Vulnerabilities
  run: |
    grype ${{ env.IMAGE_NAME }} --fail-on high

- name: Upload to Security
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: vulnerability-report.sarif
```

---

## Best Practices

### Development

1. **Run validators locally** before committing
2. **Review scan reports** regularly
3. **Update dependencies** promptly
4. **Document exceptions** when accepting risks
5. **Use pre-commit hooks** for immediate feedback

### Production

1. **Zero critical vulnerabilities** policy
2. **Digest-based image references** only
3. **SBOM generation** for all releases
4. **Automated scanning** in CI/CD
5. **Regular security reviews**

### Security

**Constitutional Article V: Zero-Trust Security**

1. **Never commit secrets** (use Ansible Vault)
2. **Scan all dependencies** before deployment
3. **Track component inventory** with SBOMs
4. **Monitor security advisories**
5. **Patch vulnerabilities** quickly

### Compliance

1. **Document all validations**
2. **Store SBOM artifacts**
3. **Track vulnerability remediation**
4. **Audit dependency licenses**
5. **Maintain security baselines**

---

## Tools Installation

### Syft (SBOM Generation)

```bash
# Linux/macOS
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# Homebrew
brew install syft

# Verify
syft version
```

### Grype (Vulnerability Scanning)

```bash
# Linux/macOS
curl -sSfL https://raw.githubusercontent.com/anchore/grype/main/install.sh | sh -s -- -b /usr/local/bin

# Homebrew
brew install grype

# Verify
grype version
```

### Trivy (Alternative Scanner)

```bash
# Homebrew
brew install aquasecurity/trivy/trivy

# Verify
trivy version
```

### Python Security Tools

```bash
# pip-audit
pip install pip-audit

# Safety
pip install safety

# Bandit
pip install bandit

# All together
pip install pip-audit safety bandit
```

---

## Summary

**Validation & Quality Ensures**:
- ✅ **Structural correctness** (JSON Schema, validators)
- ✅ **Security compliance** (vulnerability scanning, SBOM)
- ✅ **Dependency hygiene** (automated updates, auditing)
- ✅ **Constitutional alignment** (GitOps, zero-trust)
- ✅ **Production readiness** (comprehensive checks)

**Key Tools**:
- **Validators**: JSON Schema, Python scripts
- **SBOM**: Syft
- **Scanning**: Grype, Trivy, pip-audit, Safety
- **Automation**: Dependabot, GitHub Actions

**Constitutional Compliance**:
- ✅ Article III: Atomic Promotion - Manifest validation
- ✅ Article IV: Production-Grade Quality - Comprehensive checks
- ✅ Article V: Zero-Trust Security - Continuous scanning

**Next Steps**:
1. Install validation tools locally
2. Run validators before committing
3. Review scan reports regularly
4. Enable Dependabot for repositories
5. Integrate into CI/CD pipelines

