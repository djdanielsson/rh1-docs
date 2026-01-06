# Development Containers Guide

Consistent, reproducible development environments using containers.

---

## Quick Start

### VS Code / Cursor

```bash
cd cluster-config  # or any repository
code .

# Press F1 → "Dev Containers: Reopen in Container"
# First build takes 2-5 minutes
```

### OpenShift Dev Spaces

1. Navigate to Dev Spaces dashboard
2. Click "Create Workspace"
3. Enter repository URL
4. Start workspace

---

## Environment Options

| Environment | Best For | Requirements |
|-------------|----------|--------------|
| **VS Code Dev Containers** | Local development | Docker/Podman |
| **OpenShift Dev Spaces** | Cloud development | Browser only |
| **Ansible Dev Tools (ADT)** | CLI workflows | Python, pip |

---

## Container Images by Repository

| Repository | Image | Key Tools |
|------------|-------|-----------|
| cluster-config | `quay.io/devfile/universal-developer-image` | kubectl, oc, tkn, argocd |
| aap-config-as-code | `quay.io/ansible/creator-ee` | ansible, ansible-lint, vault |
| automation-collection | `quay.io/ansible/creator-ee` | ansible-creator, molecule, pytest |
| automation-ee | `quay.io/ansible/ansible-builder` | ansible-builder, syft, grype |

---

## Repository-Specific Commands

### cluster-config

```bash
validate-all                           # Validate manifests
kubeconform -strict namespaces/*.yaml  # K8s validation
yamllint .                             # Lint YAML
```

### aap-config-as-code

```bash
ansible-playbook playbook.yml --syntax-check
lint-all
dry-run-dev
```

### automation-collection

```bash
test-all        # All tests
molecule-test   # Molecule
format-python   # Black + isort
build-collection
```

### automation-ee

```bash
build-ee
validate-ee
test-ee-local localhost/ansible-ee:latest
generate-sbom localhost/ansible-ee:latest
```

---

## Ansible Development Tools (ADT)

Alternative CLI-focused approach:

```bash
# Install
pip install ansible-dev-tools

# Create collection
adt collection init myorg.mycollection

# Create role
adt role init my_role

# Run tests
adt test all
```

---

## VS Code Ansible Extension

Install `redhat.ansible` for:
- Syntax highlighting
- IntelliSense for modules
- Integrated ansible-lint
- Execution Environment support

```json
// .vscode/settings.json
{
  "ansible.validation.enabled": true,
  "ansible.validation.lint.enabled": true,
  "ansible.executionEnvironment.enabled": true
}
```

---

## Windows Setup (WSL)

Use WSL 2 for native Linux environment on Windows:

```powershell
# Install WSL with Ubuntu
wsl --install -d Ubuntu-22.04
```

```bash
# In WSL - setup Docker
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER

# Open project
cd ~/projects/repo
code .
```

**Important**: Work in `/home/` (fast), not `/mnt/c/` (slow).

See [WSL Documentation](https://docs.microsoft.com/en-us/windows/wsl/) for full setup.

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Container build fails | `Dev Containers: Rebuild Without Cache` |
| Tools not available | Run `.devcontainer/post-create.sh` |
| Slow performance | Increase Docker resources (4+ CPUs, 8+ GB) |
| Pre-commit fails | `pre-commit uninstall && pre-commit install` |

```bash
# Check Docker
docker ps

# Clean up
docker system prune -a
```

---

## References

- [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)
- [OpenShift Dev Spaces](https://access.redhat.com/documentation/en-us/red_hat_openshift_dev_spaces)
- [Ansible Dev Tools](https://ansible.readthedocs.io/projects/dev-tools/)
