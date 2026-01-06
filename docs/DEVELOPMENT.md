# Development Guide - myorg.custom_collection

This collection was created using `ansible-creator` and includes Molecule for testing.

## Creating New Collections and Roles

### Creating a New Collection

Use `ansible-creator init collection` to create a new collection:

```bash
# Create a new collection
ansible-creator init collection myorg.my_collection

# This creates the complete collection structure with:
# - galaxy.yml (collection metadata)
# - roles/ directory
# - plugins/ directory
# - tests/ directory
# - Molecule configuration
```

### Adding Roles to a Collection

Use `ansible-creator add resource role` to add roles:

```bash
# Add a role to an existing collection
ansible-creator add resource role my_role

# This creates a complete role structure with:
# - tasks/, defaults/, handlers/, etc.
# - Molecule test scenarios
# - Basic role skeleton
```

**Note**: These commands replace the older `ansible-galaxy collection/role init` commands and provide better integration with modern Ansible development workflows.

## Repository Structure

This is the **Custom Ansible Collection** repository (`https://github.com/djdanielsson/rh1-custom-collection.git`) used in the Cloud-Native Ansible Lifecycle platform.

```
rh1_ansible_code_lifecycle/          # This is the collection root
├── README.md                         # Collection overview
├── galaxy.yml                        # Collection metadata
├── roles/
│   └── run/                          # Example role
│       ├── molecule/
│       │   └── default/              # Molecule test scenario
│       │       ├── molecule.yml      # Molecule configuration
│       │       ├── converge.yml      # Test playbook
│       │       ├── verify.yml        # Verification tests
│       │       ├── create.yml        # Create test environment
│       │       └── destroy.yml       # Destroy test environment
│       ├── tasks/
│       ├── defaults/
│       └── meta/
├── plugins/
│   ├── modules/
│   ├── filter/
│   └── lookup/
├── playbooks/
├── tests/
├── aap-config-as-code/               # AAP Configuration repo
├── cluster-config/                   # Platform GitOps repo
└── .specify/memory/                   # Specifications

```

## Development Setup

### 1. Activate Python Virtual Environment

```bash
source ~/workspace/ansible/bin/activate
```

### 2. Install Dependencies

```bash
# Install collection dependencies
ansible-galaxy collection install -r requirements.txt

# Install Python testing dependencies
pip install -r test-requirements.txt
```

### 3. Install Collection Locally

```bash
# Install in development mode
ansible-galaxy collection install . --force
```

## Testing with Molecule

### Running Molecule Tests

```bash
# Activate virtual environment
source ~/workspace/ansible/bin/activate

# Navigate to role directory
cd roles/run

# Run full test sequence
molecule test

# Or run step-by-step:
molecule create      # Create test environment
molecule converge    # Run the role
molecule verify      # Run verification tests
molecule destroy     # Clean up
```

### Adding New Molecule Scenarios

```bash
# Navigate to role directory
cd roles/run

# Create a new scenario (e.g., for different OS)
molecule init scenario centos

# This creates: roles/run/molecule/centos/
```

### Molecule Configuration

Edit `roles/run/molecule/default/molecule.yml` to customize:

```yaml
---
dependency:
  name: galaxy
driver:
  name: docker  # or podman
platforms:
  - name: instance
    image: docker.io/geerlingguy/docker-rockylinux9-ansible:latest
    pre_build_image: true
provisioner:
  name: ansible
verifier:
  name: ansible
```

## Linting and Quality Checks

### Ansible Lint

```bash
# Lint entire collection
ansible-lint

# Lint specific role
ansible-lint roles/run

# Lint with custom rules
ansible-lint -c .ansible-lint
```

### YAML Lint

```bash
# Lint YAML files
yamllint .

# Lint specific directory
yamllint roles/

# Lint with custom config
yamllint -c .yamllint .
```

## Building the Collection

### Build Collection Tarball

```bash
# Build collection
ansible-galaxy collection build

# Result: myorg-custom_collection-X.Y.Z.tar.gz
```

### Install Built Collection

```bash
# Install from tarball
ansible-galaxy collection install myorg-custom_collection-*.tar.gz

# Install with force to overwrite
ansible-galaxy collection install myorg-custom_collection-*.tar.gz --force
```

## CI/CD Integration

### Inner Loop Pipeline (PR Validation)

When you create a Pull Request, the following runs automatically:
1. **ansible-lint** - Validates Ansible best practices
2. **yamllint** - Validates YAML syntax
3. **molecule test** - Runs all molecule scenarios
4. **Collection build** - Ensures collection builds successfully

### Promotion Pipeline

After merge to `main`:
1. Collection version is locked in release manifest
2. Built into custom Execution Environment
3. Deployed atomically with AAP configuration

## Development Workflow

### 1. Create Feature Branch

```bash
git checkout -b feature/new-role
```

### 2. Add New Role

```bash
# Create new role
ansible-creator add resource role my_new_role

# Add molecule tests
cd roles/my_new_role
molecule init scenario default
```

### 3. Develop and Test

```bash
# Edit role
vi roles/my_new_role/tasks/main.yml

# Test with molecule
cd roles/my_new_role
molecule test

# Lint
ansible-lint roles/my_new_role
```

### 4. Commit and Push

```bash
git add roles/my_new_role
git commit -m "Add my_new_role for XYZ functionality"
git push origin feature/new-role
```

### 5. Create Pull Request

```bash
# Using GitHub CLI
gh pr create --title "Add new role for XYZ" --body "Adds functionality for XYZ"

# Or via web interface
```

## Best Practices

### 1. Role Naming

- Use descriptive names: `webserver`, `database_backup`, `network_config`
- Prefix variables: `rolename_variable` (e.g., `webserver_port`)

### 2. Idempotency

Always ensure roles are idempotent:

```yaml
# Good
- name: Ensure package is installed
  ansible.builtin.package:
    name: nginx
    state: present

# Bad
- name: Install package
  ansible.builtin.shell: yum install -y nginx
```

### 3. Molecule Tests

Every role should have molecule tests:

```yaml
# roles/my_role/molecule/default/converge.yml
---
- name: Converge
  hosts: all
  tasks:
    - name: Include role
      ansible.builtin.include_role:
        name: my_role
```

### 4. Documentation

Document all variables in `defaults/main.yml`:

```yaml
---
# Port for application
my_role_port: 8080  # Default: 8080

# Enable debug mode
my_role_debug: false  # Default: false
```

## Versioning

Follow Semantic Versioning in `galaxy.yml`:

```yaml
version: 1.2.3
```

- **MAJOR** (1.x.x): Breaking changes
- **MINOR** (x.2.x): New features, backward compatible
- **PATCH** (x.x.3): Bug fixes

## Links

- **Project Constitution**: `.specify/memory/constitution.md`
- **Technical Specification**: `.specify/memory/specification.md`
- **AAP Config**: `aap-config-as-code/`
- **Platform Config**: `cluster-config/`
- **Molecule Docs**: https://molecule.readthedocs.io/
- **Ansible-Lint**: https://ansible-lint.readthedocs.io/

---

**Last Updated**: 2025-10-29
**Maintained By**: Platform Team

