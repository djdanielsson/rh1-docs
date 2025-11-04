# Ansible Content Actions Guide

**Complete guide to using `ansible/ansible-content-actions` in GitHub Actions workflows**

## Overview

The [ansible-content-actions](https://github.com/ansible/ansible-content-actions) repository provides official, reusable GitHub Actions workflows and actions for testing, building, and releasing Ansible content (collections, roles, playbooks).

### Benefits

- ✅ **Official Ansible support** - Maintained by the Ansible team
- ✅ **Best practices built-in** - Follow Ansible development standards
- ✅ **Comprehensive testing** - Sanity, units, integration tests
- ✅ **Automated releases** - Publish to Galaxy and Automation Hub
- ✅ **Matrix testing** - Multiple Ansible and Python versions
- ✅ **Coverage reporting** - Integrated code coverage

---

## Available Actions & Workflows

### 1. ansible-lint Action

**Repository**: `ansible/ansible-lint`

Runs ansible-lint with proper configuration.

```yaml
- name: Run ansible-lint
  uses: ansible/ansible-lint@main
  with:
    args: "--profile production --force-color"
```

### 2. ansible-test-gh-action

**Repository**: `ansible-community/ansible-test-gh-action`

Runs ansible-test for sanity, units, and integration testing.

```yaml
- name: Perform sanity testing
  uses: ansible-community/ansible-test-gh-action@release/v1
  with:
    ansible-core-version: stable-2.16
    testing-type: sanity
    python-version: '3.11'
```

### 3. ansible-build-action

**Repository**: `ansible/ansible-build-action`

**Note**: Not used in this project - building is handled by Tekton pipelines.

In traditional workflows, this action builds Ansible collections. However, in this GitOps platform:
- Tekton handles all building
- Ensures consistent build environment
- Builds are part of release pipeline

### 4. Release Workflow (Reusable)

**Repository**: `ansible/ansible-content-actions/.github/workflows/release.yaml`

Complete release workflow to publish to Galaxy/Automation Hub.

```yaml
jobs:
  release:
    uses: ansible/ansible-content-actions/.github/workflows/release.yaml@main
    with:
      environment: release
    secrets:
      ansible_galaxy_api_key: ${{ secrets.ANSIBLE_GALAXY_API_KEY }}
```

---

## Implementation in This Project

### Updated Workflows

#### 1. ansible-lint.yml (aap-config-as-code)

**Before**:
```yaml
- name: Install Ansible and ansible-lint
  run: pip install ansible-core ansible-lint

- name: Run ansible-lint
  run: ansible-lint --profile production
```

**After**:
```yaml
- name: Run ansible-lint
  uses: ansible/ansible-lint@main
  with:
    args: "--profile production --force-color"
```

#### 2. ansible-test.yml (automation-collection-example)

**Before**:
```yaml
- name: Install Ansible
  run: pip install ansible-core

- name: Run sanity tests
  run: ansible-test sanity --python 3.11
```

**After**:
```yaml
- name: Run ansible-test sanity
  uses: ansible/ansible-test-gh-action@main
  with:
    ansible-core-version: stable-2.16
    testing-type: sanity
    python-version: '3.11'
```

#### 3. New: test-sanity-units.yml

Comprehensive testing with matrix for multiple Ansible and Python versions:

```yaml
jobs:
  sanity:
    strategy:
      matrix:
        ansible: [stable-2.15, stable-2.16, stable-2.17, devel]
        python-version: ['3.10', '3.11', '3.12']
    steps:
      - uses: ansible-community/ansible-test-gh-action@release/v1
        with:
          ansible-core-version: ${{ matrix.ansible }}
          testing-type: sanity
          python-version: ${{ matrix.python-version }}
```

#### 4. Releases via Tekton

**Note**: Collection releases are managed by Tekton pipelines, not GitHub Actions.

GitHub Actions in this project focus on:
- ✅ Testing (sanity, units, integration)
- ✅ Linting (ansible-lint, Python linters)
- ❌ Building (handled by Tekton)
- ❌ Publishing/Releases (handled by Tekton)

---

## Scope: Testing Only

**Important**: GitHub Actions in this project are used for **testing and validation only**.

### Why Not GitHub Actions for Releases?

This platform uses **Tekton pipelines** for releases because:
- ✅ **Constitutional Article III**: Atomic Promotion via release manifests
- ✅ **GitOps-native**: Tekton runs in-cluster on OpenShift
- ✅ **Coordinated releases**: Multiple components released together atomically
- ✅ **Platform loop**: ArgoCD + Tekton for complete GitOps
- ✅ **Separation of duties**: Developers test, platform releases

### GitHub Actions Responsibilities

- **Pre-commit validation**: Fast feedback loop
- **PR validation**: Comprehensive testing before merge
- **Continuous testing**: Validate main branch changes
- **Quality gates**: Block merges if tests fail
- **Linting**: ansible-lint, Python linters
- **Testing only**: Sanity, units, integration tests

### Tekton Responsibilities

- **Building**: All production builds (collections, EEs)
- **Publishing**: Release to registries (Galaxy, Quay.io, etc.)
- **Promotion**: Move between environments (dev → qa → prod)
- **Release manifests**: Create atomic release bundles
- **Artifact generation**: Tarballs, container images

---

## Configuration Requirements

### 1. Collection Structure

For ansible-test actions to work, your repository must follow the standard collection structure:

```
ansible_collections/
└── myorg/
    └── custom_collection/
        ├── galaxy.yml
        ├── plugins/
        ├── roles/
        └── tests/
```

**Important**: When checking out code, use `path` to place it correctly:

```yaml
- name: Checkout code
  uses: actions/checkout@v4
  with:
    path: ansible_collections/myorg/custom_collection
```

### 2. GitHub Secrets

#### Required Secrets for Testing

Since releases are handled by Tekton, minimal secrets are needed:

- `CODECOV_TOKEN` (optional) - For coverage reporting to Codecov
- Any test-specific credentials (if needed for integration tests)

**Note**: Release credentials (Galaxy API keys, registry tokens) are stored in:
- OpenShift Secrets (for Tekton)
- Not in GitHub repository secrets

### 3. galaxy.yml Configuration

Ensure your `galaxy.yml` has proper metadata:

```yaml
namespace: myorg
name: custom_collection
version: 1.0.0
readme: README.md
authors:
  - Your Name <your.email@example.com>
description: Description of your collection
license:
  - MIT
tags:
  - automation
  - configuration
repository: https://github.com/your-org/your-repo
documentation: https://docs.example.com
homepage: https://example.com
issues: https://github.com/your-org/your-repo/issues
```

---

## Testing Strategies

### Sanity Tests

Validate code structure, imports, documentation:

```yaml
- uses: ansible-community/ansible-test-gh-action@release/v1
  with:
    ansible-core-version: stable-2.16
    testing-type: sanity
    test-deps: >-
      ansible.posix
      ansible.utils
    python-version: '3.11'
```

**What it checks**:
- Python syntax
- Ansible module documentation
- Import statements
- Code quality (pep8, pylint)
- Ansible-specific rules

### Unit Tests

Test individual modules and plugins:

```yaml
- uses: ansible-community/ansible-test-gh-action@release/v1
  with:
    ansible-core-version: stable-2.16
    testing-type: units
    coverage: auto
    python-version: '3.11'
```

**Requirements**:
- Unit tests in `tests/unit/`
- Test files named `test_*.py`
- Use pytest or unittest

### Integration Tests

End-to-end testing of roles and playbooks:

```yaml
- uses: ansible-community/ansible-test-gh-action@release/v1
  with:
    ansible-core-version: stable-2.16
    testing-type: integration
    target: ""  # Run all integration tests
    python-version: '3.11'
```

**Requirements**:
- Integration tests in `tests/integration/targets/`
- Each target has its own directory
- Contains `tasks/main.yml`

---

## Matrix Testing

Test against multiple Ansible and Python versions:

```yaml
strategy:
  fail-fast: false
  matrix:
    ansible:
      - stable-2.15
      - stable-2.16
      - stable-2.17
      - devel
    python-version:
      - '3.10'
      - '3.11'
      - '3.12'
    exclude:
      # Exclude unsupported combinations
      - ansible: stable-2.15
        python-version: '3.12'
```

**Benefits**:
- Test compatibility across versions
- Catch version-specific issues early
- Ensure forward/backward compatibility
- Meet Ansible collection requirements

---

## Release Process

### Releases via Tekton

**Note**: Releases in this platform are handled by **Tekton pipelines** as part of the GitOps workflow, not GitHub Actions.

- Tekton pipelines manage the release process
- Release manifests track versions across all components
- Atomic promotion follows Constitutional Article III
- GitHub Actions focus on **testing and validation only**

For release workflow details, see:
- `cluster-config/tekton/pipelines/` - Tekton pipeline definitions
- `automation-release-manifest/` - Release manifest management
- **[Platform Specification](./.specify/memory/specification.md)** - Release workflow details

---

## Branch Protection

Use the `check` job to gate merges:

```yaml
jobs:
  sanity:
    # ... sanity tests
  
  units:
    # ... unit tests
  
  check:
    if: always()
    needs: [sanity, units]
    runs-on: ubuntu-latest
    steps:
      - uses: re-actors/alls-green@release/v1
        with:
          jobs: ${{ toJSON(needs) }}
```

**In GitHub Settings**:
1. Settings → Branches → Branch protection rules
2. Add rule for `main` branch
3. Require status checks: **Test Status Check**
4. This ensures all tests pass before merge

---

## Coverage Reporting

### Upload to Codecov

```yaml
- name: Perform unit testing
  uses: ansible-community/ansible-test-gh-action@release/v1
  with:
    testing-type: units
    coverage: auto

- name: Upload Coverage
  uses: codecov/codecov-action@v4
  with:
    files: ./tests/output/reports/coverage.xml
    flags: units
    name: units-${{ matrix.ansible }}
```

### Requirements

1. **Enable Codecov** in repository
2. **Add CODECOV_TOKEN** secret (public repos don't need this)
3. **Coverage files** generated by ansible-test

---

## Troubleshooting

### Collection Not Found

**Problem**: `ERROR: Collection not found`

**Solution**: Ensure checkout path is correct:
```yaml
- uses: actions/checkout@v4
  with:
    path: ansible_collections/namespace/collection_name
```

### Import Errors in Sanity Tests

**Problem**: Import errors for dependencies

**Solution**: Add dependencies to `test-deps`:
```yaml
with:
  test-deps: >-
    ansible.posix
    ansible.utils
    community.general
```

### Python Version Mismatch

**Problem**: Tests fail on specific Python version

**Solution**: Use matrix exclusions:
```yaml
matrix:
  ansible: [stable-2.15, stable-2.16]
  python: ['3.10', '3.11', '3.12']
  exclude:
    - ansible: stable-2.15
      python: '3.12'
```

### Release Fails

**Problem**: Release workflow fails to publish

**Solution**: Check:
1. `ANSIBLE_GALAXY_API_KEY` secret is set
2. Version in `galaxy.yml` matches tag
3. All required fields in `galaxy.yml` are present
4. Use `environment: test` first to validate

---

## Best Practices

### 1. Always Use Versions

```yaml
# Good - pinned version
uses: ansible-community/ansible-test-gh-action@release/v1

# Bad - unpinned
uses: ansible-community/ansible-test-gh-action@main
```

### 2. Pull Request Change Detection

Enable to only test changed files:
```yaml
with:
  pull-request-change-detection: true
```

### 3. Test Multiple Versions

Always test against:
- Current stable Ansible (2.16)
- Previous stable (2.15)
- Next stable or devel
- Python 3.10, 3.11, 3.12

### 4. Separate Workflows

- **Fast feedback**: `ansible-lint.yml` (quick linting)
- **Comprehensive tests**: `test-sanity-units.yml` (matrix testing)
- **Integration**: `integration-tests.yml` (slower, on main only)
- **Releases**: Handled by Tekton pipelines (not GitHub Actions)

### 5. Cache Dependencies

```yaml
- name: Set up Python
  uses: actions/setup-python@v5
  with:
    python-version: '3.11'
    cache: 'pip'
```

---

## Resources

### Official Documentation

- [ansible-content-actions](https://github.com/ansible/ansible-content-actions)
- [ansible-test-gh-action](https://github.com/ansible-community/ansible-test-gh-action)
- [ansible-lint Action](https://github.com/ansible/ansible-lint)
- [Ansible Dev Tools](https://ansible.readthedocs.io/projects/dev-tools/)

### Ansible Testing

- [ansible-test Documentation](https://docs.ansible.com/ansible/latest/dev_guide/testing.html)
- [Collection Requirements](https://docs.ansible.com/ansible/latest/dev_guide/collections_requirements.html)
- [Testing Collections](https://docs.ansible.com/ansible/latest/dev_guide/testing_collections.html)

### Examples

- [community.general](https://github.com/ansible-collections/community.general)
- [ansible.posix](https://github.com/ansible-collections/ansible.posix)
- [ansible.utils](https://github.com/ansible-collections/ansible.utils)

---

## Summary

**Ansible Content Actions Provide** (for Testing):
- ✅ **Standardized testing** across Ansible versions
- ✅ **Best practices** built-in for test workflows
- ✅ **Matrix testing** for compatibility
- ✅ **Coverage reporting** integration
- ✅ **Constitutional compliance** (Article IV: Production-Grade Quality)

**Implementation Status**:
- ✅ ansible-lint action integrated
- ✅ ansible-test-gh-action for sanity/units/integration
- ✅ Matrix testing configured
- ✅ Branch protection compatible
- ❌ **Building removed** (handled by Tekton)
- ❌ **Release workflows removed** (handled by Tekton)

**Separation of Concerns**:

| Responsibility | Tool | Location |
|----------------|------|----------|
| **Testing** | GitHub Actions | `.github/workflows/` |
| **Linting** | GitHub Actions | `.github/workflows/` |
| **Building** | Tekton | `cluster-config/tekton/` |
| **Releasing** | Tekton | `cluster-config/tekton/` |
| **Promotion** | Tekton | `cluster-config/tekton/` |
| **Deployment** | ArgoCD | `cluster-config/argocd/` |

**Next Steps**:
1. Update collection namespace in test workflows
2. Test workflows on feature branch
3. Enable branch protection with check job
4. Configure Tekton pipelines for releases (separate task)
5. Create release manifests via Tekton (separate task)

---

**Constitutional Alignment**:
- ✅ Article I: GitOps First - All automation in Git
- ✅ Article IV: Production-Grade Quality - Comprehensive testing
- ✅ Article V: Zero-Trust Security - Automated security scanning

