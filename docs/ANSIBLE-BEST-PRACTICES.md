# Ansible Best Practices

Comprehensive guide incorporating [Red Hat CoP Automation Good Practices](https://redhat-cop.github.io/automation-good-practices/) and [Ansible-lint Rules](https://ansible.readthedocs.io/projects/lint/rules/).

---

## The Zen of Ansible

*By Tim Appnel*

> Ansible is not Python. YAML sucks for coding. Playbooks are not for programming.
> Clear is better than cluttered. Simple is better than complex. Readability counts.
> Declarative is always better than imperative - most of the time.
> If the implementation is hard to explain, it's a bad idea.

---

## Quick Reference

### YAML Style

| Rule | Good | Bad |
|------|------|-----|
| Indentation | 2 spaces | 4 spaces or tabs |
| Document start | `---` at top | Missing `---` |
| Booleans | `true`/`false` | `True`/`yes`/`on` |
| Strings | Quote when needed | Inconsistent quoting |
| Line length | ≤160 chars | Very long lines |

### Task Rules

| Rule | Good | Bad |
|------|------|-----|
| FQCN | `ansible.builtin.copy` | `copy` |
| Task names | `Install Apache web server` | `Install` |
| Conditionals | `when: var \| bool` | `when: "{{ var }}"` |
| Loops | `loop:` with `loop_control` | `with_items:` |
| Shell tasks | Add `changed_when`/`creates` | No idempotency control |

### Variable Rules

| Rule | Good | Bad |
|------|------|-----|
| Prefix | `webserver_port` | `port` |
| Booleans | `enabled: true` | `disabled: false` |
| Type casting | `var \| int` | Direct comparison |
| Defaults | `var \| default('x')` | Assume defined |

---

## Naming Conventions

### Variables

```yaml
# Format: {role}_{category}_{name}
webserver_port: 80
webserver_ssl_enabled: true
database_backup_schedule: "0 2 * * *"

# Boolean - use positive names
enabled: true              # Good
disabled: false            # Avoid negatives
```

### Task Names

```yaml
# Start with verb, be specific
- name: Install Apache web server packages
- name: Configure firewall rules for HTTP traffic
- name: Ensure PostgreSQL service is running

# Prefix in sub-task files
- name: "webserver | Install packages"
- name: "webserver | Configure virtual hosts"
```

### Files & Templates

| Type | Format | Example |
|------|--------|---------|
| Playbooks | `{verb}-{noun}.yml` | `deploy-webapp.yml` |
| Templates | `{name}.{ext}.j2` | `httpd.conf.j2` |
| Roles | lowercase, underscores | `database_backup` |
| Python modules | `{action}_{resource}.py` | `manage_service.py` |

### Git Tags (CalVer)

```
YY.MM.DD.PATCH
25.01.05.0    # January 5, 2025 - Initial
25.01.05.1    # Same day hotfix
```

### AAP Resources

| Type | Format | Example |
|------|--------|---------|
| Organizations | Full name | `Platform Team` |
| Credentials | `{Type} - {Purpose}` | `SSH - Production` |
| Projects | Descriptive | `Infrastructure Playbooks` |
| Job Templates | `{Action} {Target}` | `Deploy Web Application` |
| EE | `{Purpose} EE` | `Production EE` |

---

## AAP Configuration as Code

### Using infra.aap_configuration

```yaml
# collections/requirements.yml
collections:
  - name: infra.aap_configuration
    version: "2.9.0"  # Always pin version

# playbook.yml
- name: Configure AAP
  hosts: aap_dev
  connection: local
  gather_facts: false
  tasks:
    - name: Apply AAP Configuration
      ansible.builtin.include_role:
        name: infra.aap_configuration.dispatch
```

### Configuration Structure

```
aap-config-as-code/
├── playbook.yml
├── inventory.yml
├── group_vars/
│   ├── all/              # Shared: organizations, labels
│   │   └── organizations.yml
│   ├── aap_dev/          # Dev-specific
│   │   ├── credentials.yml
│   │   └── job_templates.yml
│   ├── aap_qa/           # QA-specific
│   └── aap_prod/         # Prod-specific
```

### Example: Job Template

```yaml
# group_vars/aap_dev/job_templates.yml
controller_templates:
  - name: "Deploy Webserver - Dev"
    organization: "Platform"
    inventory: "Dev Infrastructure"
    project: "Automation Collection"
    scm_branch: "main"
    execution_environment: "Automation EE - Latest"
    playbook: "playbooks/deploy-webserver.yml"
    credentials:
      - "Dev SSH Key"
    ask_variables_on_launch: true
    extra_vars:
      webserver_port: 8080
```

### Secrets Management

```yaml
# Never hardcode secrets
controller_credentials:
  - name: "Dev SSH Key"
    credential_type: "Machine"
    inputs:
      username: "ansible"
      ssh_key_data: "{{ lookup('env', 'SSH_PRIVATE_KEY') }}"  # ✅
      # ssh_key_data: "-----BEGIN..."  # ❌ Never do this
```

---

## Inventory Management

### Always Use Dynamic Inventory

**Never use static inventory files.** Configure dynamic sources in AAP:

```yaml
controller_inventory_sources:
  - name: "OCP-V Production VMs"
    inventory: "Production Infrastructure"
    source: "openshift_virtualization"
    source_vars:
      plugin: "kubevirt.core.kubevirt"
      connections:
        - namespaces: [prod-vms]
          network_name: "production-network"
      label_selector: "environment=production"
    credential: "OCP Production Cluster"
    update_on_launch: true
    update_cache_timeout: 300
```

### Supported Sources

| Source | AAP Type | Use Case |
|--------|----------|----------|
| OCP-V | `openshift_virtualization` | OpenShift VMs |
| VMware | `vmware` | vCenter VMs |
| AWS | `ec2` | EC2 instances |
| Azure | `azure_rm` | Azure VMs |
| Satellite | `satellite6` | Satellite hosts |

---

## Role Design

### Structure

```
roles/webserver/
├── defaults/main.yml     # User-configurable (webserver_port: 80)
├── vars/main.yml         # Internal (package maps)
├── tasks/
│   ├── main.yml          # Entry point
│   ├── install.yml       # Logical groupings
│   └── configure.yml
├── handlers/main.yml
├── templates/*.j2
└── meta/
    ├── main.yml
    └── argument_specs.yml  # Validate inputs
```

### Key Rules

1. **Prefix all variables** with role name
2. **Keep playbooks simple** - orchestrate roles, don't contain logic
3. **Use `defaults/` for user API**, `vars/` for internals
4. **Prefix task names** in sub-task files: `"webserver | Install..."`
5. **Minimal dependencies** - avoid deep chains

---

## Task Writing

### Always Use FQCN

```yaml
# Good
- name: Install Apache
  ansible.builtin.package:
    name: httpd
    state: present

# Bad
- name: Install Apache
  package:
    name: httpd
```

### Conditionals

```yaml
# Good - no {{ }} in when, use filters
- name: Install package
  ansible.builtin.package:
    name: httpd
  when:
    - ansible_os_family == "RedHat"
    - ansible_distribution_major_version | int >= 8

# Good - use bool filter
- name: Configure SSL
  ansible.builtin.template:
    src: ssl.conf.j2
    dest: /etc/ssl.conf
  when: webserver_ssl_enabled | bool

# Bad - {{ }} in when
  when: "{{ ansible_os_family == 'RedHat' }}"

# Bad - literal comparison
  when: enabled == true
```

### Loops

```yaml
# Good - custom loop variable and label
- name: Install packages
  ansible.builtin.package:
    name: "{{ pkg }}"
    state: present
  loop:
    - httpd
    - mod_ssl
  loop_control:
    loop_var: pkg
    label: "{{ pkg }}"

# Bad - default 'item', deprecated with_items
- name: Install
  package:
    name: "{{ item }}"
  with_items: "{{ packages }}"
```

### Shell/Command Tasks

```yaml
# Good - explicit change detection
- name: Check service status
  ansible.builtin.command: systemctl is-active httpd
  register: service_status
  changed_when: false
  failed_when: service_status.rc not in [0, 3]

# Good - use creates/removes
- name: Extract archive
  ansible.builtin.shell: tar xzf /tmp/app.tar.gz -C /opt/app
  args:
    creates: /opt/app/bin/app

# Bad - no idempotency control
- name: Extract archive
  ansible.builtin.shell: tar xzf /tmp/app.tar.gz
```

### Error Handling

```yaml
- name: Deploy with rollback
  block:
    - name: Deploy new version
      ansible.builtin.copy:
        src: app-v2.jar
        dest: /opt/app/app.jar
    - name: Start application
      ansible.builtin.service:
        name: myapp
        state: started
  rescue:
    - name: Rollback
      ansible.builtin.copy:
        src: app-v1.jar
        dest: /opt/app/app.jar
  always:
    - name: Log attempt
      ansible.builtin.debug:
        msg: "Deployment attempted"
```

---

## Jinja2 Best Practices

### Format

```yaml
# Good - spaces around filters, multi-line for complex
- name: Process data
  ansible.builtin.set_fact:
    result: "{{
      data |
      selectattr('enabled', 'equalto', true) |
      map(attribute='name') |
      list
      }}"

# Bad - no spaces, single long line
    result: "{{data|selectattr('enabled','equalto',true)|map(attribute='name')|list}}"
```

### Common Filters

```jinja
{{ var | default('default_value') }}
{{ list | join(', ') }}
{{ num | int + 1 }}
{{ dict | to_nice_yaml }}
{{ path | basename }}
```

---

## Module Usage

### Prefer Specific Modules

```yaml
# Good - use file module
- name: Create directory
  ansible.builtin.file:
    path: /opt/app
    state: directory

# Bad - use shell
- name: Create directory
  ansible.builtin.shell: mkdir -p /opt/app
```

### Use template Over copy

```yaml
# Good - template even if no variables yet (easier to add later)
- name: Deploy config
  ansible.builtin.template:
    src: app.conf.j2
    dest: /etc/app/app.conf

# Bad - copy for config files
- name: Deploy config
  ansible.builtin.copy:
    src: app.conf
    dest: /etc/app/app.conf
```

### Avoid lineinfile When Possible

```yaml
# Good - use template for full file control
- name: Configure Apache
  ansible.builtin.template:
    src: httpd.conf.j2
    dest: /etc/httpd/conf/httpd.conf

# Acceptable - single line with validation
- name: Add sudoers line
  ansible.builtin.lineinfile:
    path: /etc/sudoers
    line: "ansible ALL=(ALL) NOPASSWD: ALL"
    validate: /usr/sbin/visudo -cf %s
```

---

## Python Style (for Modules/Plugins)

### Formatting

```python
# Use black (line length 100), isort, flake8
from __future__ import absolute_import, division, print_function
__metaclass__ = type

from typing import Dict, List, Optional
from ansible.module_utils.basic import AnsibleModule
```

### Module Structure

```python
#!/usr/bin/python
# -*- coding: utf-8 -*-

DOCUMENTATION = r'''
---
module: module_name
short_description: Short description
options:
    name:
        description: Parameter description
        required: true
        type: str
'''

EXAMPLES = r'''
- name: Example
  myorg.collection.module_name:
    name: example
'''

RETURN = r'''
result:
    description: Result description
    returned: always
    type: dict
'''

def run_module():
    module_args = dict(name=dict(type='str', required=True))
    module = AnsibleModule(argument_spec=module_args, supports_check_mode=True)
    module.exit_json(changed=False)

if __name__ == '__main__':
    run_module()
```

---

## Shell Script Style

```bash
#!/bin/bash
# Description

set -euo pipefail  # Exit on error, undefined var, pipe failure

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

function install_packages() {
    local package_list=("$@")
    for pkg in "${package_list[@]}"; do
        echo "Installing $pkg..."
    done
}
```

---

## Anti-Patterns to Avoid

| Anti-Pattern | Why Bad | Instead |
|--------------|---------|---------|
| `ignore_errors: true` | Hides problems | Use `failed_when` |
| `local_action:` | Deprecated | Use `delegate_to: localhost` |
| `{{ }}` in `when:` | Syntax error | Bare variable names |
| `with_items:` | Deprecated | Use `loop:` |
| Unprefixed variables | Name conflicts | Prefix with role name |
| Static inventory | Becomes stale | Dynamic inventory |
| `:latest` in prod | Not reproducible | Pin versions |
| Secrets in Git | Security risk | Use vault/OCP secrets |

---

## Checklist Before Commit

- [ ] All modules use FQCN
- [ ] All tasks have descriptive names (start with verb)
- [ ] Variables prefixed with role name
- [ ] Using `template` not `copy` for configs
- [ ] No `{{ }}` in `when` conditions
- [ ] `changed_when` set for shell/command
- [ ] Type filters used (`| int`, `| bool`)
- [ ] Check mode supported
- [ ] Tests included

---

## References

- [Red Hat CoP Automation Good Practices](https://redhat-cop.github.io/automation-good-practices/)
- [Ansible-lint Rules](https://ansible.readthedocs.io/projects/lint/rules/)
- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html)
