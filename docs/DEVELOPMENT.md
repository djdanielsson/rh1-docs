# Development Guide

Development workflow for Ansible collections using `ansible-creator` and Molecule.

---

## Quick Start

```bash
# Activate virtual environment
source ~/workspace/ansible/bin/activate

# Install dependencies
pip install ansible ansible-creator molecule pytest

# Install collection dependencies
ansible-galaxy collection install -r requirements.txt
pip install -r test-requirements.txt
```

---

## Creating Collections & Roles

### New Collection

```bash
ansible-creator init collection myorg.my_collection
```

### New Role

```bash
cd automation-collection-example
ansible-creator add resource role webserver
```

---

## Testing with Molecule

### Run Tests

```bash
cd roles/webserver
molecule test              # Full test sequence
molecule converge          # Run role only
molecule verify            # Run verification
molecule destroy           # Clean up
```

### Add New Scenario

```bash
molecule init scenario centos
```

### Molecule Configuration

```yaml
# molecule/default/molecule.yml
driver:
  name: docker
platforms:
  - name: instance
    image: docker.io/geerlingguy/docker-rockylinux9-ansible:latest
    pre_build_image: true
provisioner:
  name: ansible
verifier:
  name: ansible
```

---

## Linting

```bash
# Ansible
ansible-lint
ansible-lint --profile production

# YAML
yamllint .

# Python (for modules/plugins)
black --line-length=100 plugins/
flake8 plugins/
```

---

## Building Collections

```bash
# Build tarball
ansible-galaxy collection build

# Install locally
ansible-galaxy collection install myorg-collection-*.tar.gz --force
```

---

## Development Workflow

1. **Create branch**: `git checkout -b feature/new-role`
2. **Add role**: `ansible-creator add resource role new_role`
3. **Write tests first**: Edit `molecule/default/verify.yml`
4. **Implement**: Edit `tasks/main.yml`
5. **Test**: `molecule test`
6. **Lint**: `ansible-lint`
7. **Commit**: `git commit -am "Add new_role"`
8. **PR**: `gh pr create`

---

## Best Practices

### Role Design

```yaml
# defaults/main.yml - prefixed variables
webserver_port: 80
webserver_ssl_enabled: false

# tasks/main.yml - descriptive names
- name: Install Apache web server packages
  ansible.builtin.package:
    name: "{{ webserver_packages }}"
    state: present
```

### Molecule Tests

```yaml
# molecule/default/converge.yml
- name: Converge
  hosts: all
  tasks:
    - name: Include role
      ansible.builtin.include_role:
        name: webserver

# molecule/default/verify.yml
- name: Verify
  hosts: all
  tasks:
    - name: Check httpd is running
      ansible.builtin.service:
        name: httpd
        state: started
      check_mode: true
      register: result
      failed_when: result.changed
```

---

## Versioning

Follow Semantic Versioning in `galaxy.yml`:

```yaml
version: 1.2.3
# MAJOR.MINOR.PATCH
```

- **MAJOR**: Breaking changes
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes

---

## Links

- [Molecule Documentation](https://molecule.readthedocs.io/)
- [Ansible-lint](https://ansible-lint.readthedocs.io/)
- [Ansible Best Practices](./ANSIBLE-BEST-PRACTICES.md)
