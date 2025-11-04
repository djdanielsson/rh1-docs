# Development Containers Guide

**Complete guide to using development containers and dev spaces for the Cloud-Native Ansible Lifecycle Platform**

## Table of Contents

- [Overview](#overview)
- [Technologies](#technologies)
- [Getting Started](#getting-started)
- [Repository-Specific Containers](#repository-specific-containers)
- [OpenShift Dev Spaces](#openshift-dev-spaces)
- [Troubleshooting](#troubleshooting)
- [Best Practices](#best-practices)

---

## Overview

Development containers provide consistent, reproducible development environments for all contributors. This aligns with **Constitutional Article IV: Production-Grade Quality** by ensuring all developers work in identical environments.

### Benefits

- **Consistency**: Same environment for all developers
- **Speed**: Pre-configured with all tools and dependencies
- **Isolation**: No conflicts with local machine
- **Cloud-Native**: Works in VS Code, Cursor, and OpenShift Dev Spaces
- **Security**: Sandboxed environment with controlled access

### What's Included

Each repository has:
- **`.devcontainer/devcontainer.json`**: VS Code/Cursor container definition
- **`.devcontainer/post-create.sh`**: Automatic environment setup
- **`devfile.yaml`**: OpenShift Dev Spaces / Eclipse Che definition

---

## Technologies

### VS Code Dev Containers

- Works with **VS Code** and **Cursor**
- Uses Docker or Podman for containerization
- Full IDE integration
- Extension marketplace support

### OpenShift Dev Spaces

- Cloud-based development environment
- Kubernetes-native
- Browser-based VS Code
- Team collaboration features

---

## Getting Started

### Prerequisites

Choose your development approach:

#### Option 1: Local Development (VS Code/Cursor)

```bash
# Required
- VS Code or Cursor IDE
- Docker Desktop or Podman
- VS Code Dev Containers extension

# Install Dev Containers extension
code --install-extension ms-vscode-remote.remote-containers
```

#### Option 2: Cloud Development (OpenShift Dev Spaces)

```bash
# Required
- OpenShift cluster with Dev Spaces operator
- Access to OpenShift Dev Spaces instance
- Web browser
```

### Quick Start (Local)

1. **Open repository in VS Code/Cursor**:
   ```bash
   cd cluster-config  # or any repository
   code .
   ```

2. **Reopen in container**:
   - Press `F1` or `Cmd/Ctrl+Shift+P`
   - Type: `Dev Containers: Reopen in Container`
   - Wait for container to build (first time takes 2-5 minutes)

3. **Start developing**:
   - All tools are pre-installed
   - Git is configured
   - Pre-commit hooks are installed

### Quick Start (OpenShift Dev Spaces)

1. **Navigate to Dev Spaces dashboard**
2. **Create workspace from devfile**:
   ```
   https://your-devspaces-instance/dashboard/#/create-workspace
   ```
3. **Provide Git repository URL**:
   ```
   https://github.com/your-org/rh1_ansible_code_lifecycle
   ```
4. **Select subdirectory** (e.g., `cluster-config`)
5. **Start workspace**

---

## Repository-Specific Containers

### cluster-config

**Purpose**: Kubernetes/OpenShift configuration development

**Container Image**: `quay.io/devfile/universal-developer-image:latest`

**Pre-installed Tools**:
- `kubectl` - Kubernetes CLI
- `oc` - OpenShift CLI
- `yq` - YAML processor
- `kustomize` - Kubernetes customization
- `kubeconform` - YAML validation
- `tkn` - Tekton CLI
- `argocd` - ArgoCD CLI
- `yamllint` - YAML linting
- `pre-commit` - Git hooks

**Quick Commands**:
```bash
# Validate all manifests
validate-all

# Check Kubernetes resources
kubeconform -strict namespaces/*.yaml

# Validate Tekton tasks
tkn task validate -f tekton/tasks/*.yaml

# Run linters
yamllint .
```

**Extensions**:
- Kubernetes Tools
- YAML Language Support
- GitLens

### aap-config-as-code

**Purpose**: Ansible Automation Platform configuration development

**Container Image**: `quay.io/ansible/creator-ee:latest`

**Pre-installed Tools**:
- `ansible` - Ansible CLI
- `ansible-playbook` - Playbook execution
- `ansible-lint` - Ansible linting
- `ansible-navigator` - EE runner
- `ansible-vault` - Secret management
- `yamllint` - YAML linting
- `yq` - YAML processor
- `pre-commit` - Git hooks

**Quick Commands**:
```bash
# Validate playbook syntax
ansible-playbook playbook.yml --syntax-check

# Run linters
lint-all

# Dry run for dev environment
dry-run-dev

# Validate inventory
ansible-inventory -i inventory.yml --list
```

**Extensions**:
- Ansible Language Support
- YAML Language Support
- Jinja2 Syntax Highlighting

### automation-collection-example

**Purpose**: Ansible collection development

**Container Image**: `quay.io/ansible/creator-ee:latest`

**Pre-installed Tools**:
- `ansible-core` - Ansible CLI
- `ansible-creator` - Collection scaffolding
- `ansible-test` - Testing framework
- `molecule` - Role testing
- `pytest` - Python testing
- `black`, `isort`, `flake8`, `pylint` - Python quality tools
- `bandit` - Security scanning
- `pre-commit` - Git hooks

**Quick Commands**:
```bash
# Run all tests
test-all

# Run molecule tests
molecule-test

# Format Python code
format-python

# Lint everything
lint-all

# Build collection
build-collection
```

**Extensions**:
- Ansible Language Support
- Python Language Support
- Python Debugger
- Black Formatter

### automation-ee-example

**Purpose**: Execution environment development

**Container Image**: `quay.io/ansible/ansible-builder:latest`

**Pre-installed Tools**:
- `ansible-builder` - EE builder
- `ansible-navigator` - EE runner
- `docker` / `podman` - Container runtime
- `syft` - SBOM generation
- `grype` - Vulnerability scanning
- `yamllint` - YAML linting
- `pre-commit` - Git hooks

**Quick Commands**:
```bash
# Build execution environment
build-ee

# Validate EE definition
validate-ee

# Test built image
test-ee-local localhost/ansible-ee:latest

# Generate SBOM
generate-sbom localhost/ansible-ee:latest

# Scan vulnerabilities
scan-vulnerabilities localhost/ansible-ee:latest
```

**Extensions**:
- Docker Support
- YAML Language Support

---

## OpenShift Dev Spaces

### Creating a Workspace

#### Method 1: From Dashboard

1. **Navigate to Dev Spaces**:
   ```
   https://devspaces.apps.your-cluster.example.com
   ```

2. **Create New Workspace**:
   - Click "Create Workspace"
   - Select "Git Repository"
   - Enter repository URL
   - Select branch
   - Choose subdirectory (optional)

3. **Wait for Startup**:
   - Dev Spaces creates workspace
   - Clones repository
   - Builds container
   - Runs post-start commands

#### Method 2: From URL

Use a factory URL:
```
https://devspaces.apps.your-cluster.example.com/#https://github.com/your-org/rh1_ansible_code_lifecycle?dir=cluster-config
```

#### Method 3: From devfile

Create workspace from devfile directly:
```bash
# Using DevSpaces CLI
dsc workspace:create --devfile=https://raw.githubusercontent.com/your-org/rh1_ansible_code_lifecycle/main/cluster-config/devfile.yaml
```

### Workspace Management

**List workspaces**:
```bash
dsc workspace:list
```

**Start/Stop workspace**:
```bash
dsc workspace:start <workspace-id>
dsc workspace:stop <workspace-id>
```

**Delete workspace**:
```bash
dsc workspace:delete <workspace-id>
```

### Customizing Workspaces

Edit `devfile.yaml` to customize:

```yaml
# Add custom commands
commands:
  - id: my-custom-task
    exec:
      label: "My Custom Task"
      component: tools
      commandLine: ./my-script.sh
      group:
        kind: build

# Add environment variables
components:
  - name: tools
    container:
      env:
        - name: MY_VAR
          value: my-value

# Add volumes
components:
  - name: my-volume
    volume:
      size: 5Gi
```

---

## Troubleshooting

### Common Issues

#### Container Build Fails

**Problem**: Container fails to build or start

**Solutions**:
```bash
# Rebuild container without cache
Dev Containers: Rebuild Without Cache

# Check Docker/Podman
docker ps
docker images

# Check logs
docker logs <container-id>

# Verify Docker resources (CPU, Memory)
docker system info
```

#### Tools Not Available

**Problem**: Command not found after container starts

**Solutions**:
```bash
# Reload window to reload PATH
Dev Containers: Rebuild Container

# Manually run post-create script
./.devcontainer/post-create.sh

# Check if script ran
cat /tmp/post-create.log
```

#### Slow Performance

**Problem**: Container is slow

**Solutions**:
```bash
# Increase Docker resources
# Docker Desktop → Settings → Resources
# - CPUs: 4+
# - Memory: 8 GB+
# - Swap: 2 GB+

# Use mounted volumes sparingly
# Edit devcontainer.json:
"workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached"
```

#### Pre-commit Hooks Fail

**Problem**: Git operations fail with pre-commit errors

**Solutions**:
```bash
# Reinstall pre-commit
pre-commit uninstall
pre-commit install

# Update hooks
pre-commit autoupdate

# Run manually to debug
pre-commit run --all-files --verbose
```

### Dev Spaces Issues

#### Workspace Won't Start

**Problem**: Workspace stuck in "Starting" state

**Solutions**:
1. Check Dev Spaces operator logs
2. Verify resource quotas
3. Check devfile syntax
4. Review workspace events:
   ```bash
   kubectl get devworkspace -n <user-namespace>
   kubectl describe devworkspace <workspace-name> -n <user-namespace>
   ```

#### Can't Connect to Cluster Resources

**Problem**: Cannot access OpenShift/Kubernetes from workspace

**Solutions**:
```bash
# Verify service account permissions
kubectl auth can-i --list

# Check network policies
kubectl get networkpolicies -n <namespace>

# Verify Dev Spaces network configuration
```

---

## Best Practices

### Development Workflow

1. **Always use containers** for development
2. **Commit devcontainer changes** when updating tools
3. **Test post-create scripts** before committing
4. **Keep containers lightweight** - only essential tools
5. **Use extensions** for language-specific support

### Container Hygiene

```bash
# Periodically clean up
docker system prune -a

# Remove unused images
docker image prune -a

# Check disk usage
docker system df
```

### Performance Optimization

#### Local Development

```json
{
  "workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=cached",
  "mounts": [
    "source=${localEnv:HOME}/.ssh,target=/root/.ssh,type=bind,consistency=cached,readonly"
  ]
}
```

#### Dev Spaces

```yaml
components:
  - name: tools
    container:
      memoryLimit: 4Gi
      memoryRequest: 1Gi
      cpuLimit: 2000m
      cpuRequest: 500m
```

### Security Considerations

**Constitutional Article V: Zero-Trust Security**

1. **Never commit secrets** to devcontainer configuration
2. **Use environment variables** for sensitive data
3. **Mount credentials** from host when needed
4. **Limit container privileges**
5. **Scan container images** regularly

```bash
# Scan devcontainer image
docker scan quay.io/ansible/creator-ee:latest

# Check for vulnerabilities
grype quay.io/ansible/creator-ee:latest
```

---

## Additional Resources

### Documentation

- [VS Code Dev Containers Docs](https://code.visualstudio.com/docs/devcontainers/containers)
- [OpenShift Dev Spaces Docs](https://access.redhat.com/documentation/en-us/red_hat_openshift_dev_spaces)
- [Devfile Specification](https://devfile.io/)

### Examples

- [Devfile Registry](https://registry.devfile.io/)
- [VS Code Dev Container Definitions](https://github.com/microsoft/vscode-dev-containers)

### Tools

- [Docker Desktop](https://www.docker.com/products/docker-desktop)
- [Podman Desktop](https://podman-desktop.io/)
- [DevSpaces CLI](https://github.com/redhat-developer/devspaces-chectl)

---

## Summary

Development containers provide:
- ✅ **Consistent environments** across team
- ✅ **Fast onboarding** for new developers
- ✅ **Cloud-native workflow** with Dev Spaces
- ✅ **Production parity** with same tools as CI/CD
- ✅ **Constitutional compliance** with quality standards

**Next Steps**:
1. Choose local (VS Code) or cloud (Dev Spaces) development
2. Open a repository in container
3. Start developing with pre-configured environment
4. Customize devcontainer for your needs

**Constitutional Alignment**:
- ✅ Article I: GitOps First - Git-based configuration
- ✅ Article IV: Production-Grade Quality - Consistent tooling
- ✅ Article V: Zero-Trust Security - Isolated environments

