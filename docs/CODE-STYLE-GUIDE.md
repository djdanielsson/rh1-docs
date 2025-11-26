# Code Style Guide - Cloud-Native Ansible Lifecycle Platform

Comprehensive code style standards for YAML, Python, and all other languages used in the platform.

## Table of Contents

- [Overview](#overview)
- [YAML Style](#yaml-style)
- [Ansible Style](#ansible-style)
- [Python Style](#python-style)
- [Shell Script Style](#shell-script-style)
- [Jinja2 Templates](#jinja2-templates)
- [Documentation Style](#documentation-style)

---

## Overview

### Principles

Based on the **Zen of Ansible** by Tim Appnel:

1. **Consistency**: Follow established patterns
2. **Readability**: Code is read more than written  
3. **Simplicity**: Prefer simple over clever
4. **Maintainability**: Think of future maintainers
5. **Declarative Over Imperative**: Most of the time
6. **Clear Over Cluttered**: Readability counts
7. **Focus Avoids Complexity**: Keep it simple

### Standards Alignment

This guide aligns with:
- ✅ **[Red Hat CoP Automation Good Practices](https://redhat-cop.github.io/automation-good-practices/)**
- ✅ **[Ansible-lint Rules](https://ansible.readthedocs.io/projects/lint/rules/)**
- ✅ **Ansible Official Best Practices**
- ✅ **Constitutional Articles (I-V)**

### Enforcement

- **Pre-commit hooks**: Automated checking
- **CI/CD**: Validation on every commit
- **Code reviews**: Human verification
- **Linters**: ansible-lint (production profile), yamllint, flake8, black

### Additional Resources

See also:
- [ANSIBLE-BEST-PRACTICES.md](./ANSIBLE-BEST-PRACTICES.md) - Detailed Ansible-specific practices
- [NAMING-CONVENTIONS.md](./NAMING-CONVENTIONS.md) - Naming standards

---

## YAML Style

### Configuration

Use `.yamllint` configuration:

```yaml
extends: default

rules:
  line-length:
    max: 160
    level: warning
  indentation:
    spaces: 2
    indent-sequences: true
  document-start:
    present: true
  truthy:
    allowed-values: ['true', 'false', 'yes', 'no']
```

### Indentation

```yaml
# Good - 2 spaces
---
- name: Example task
  ansible.builtin.debug:
    msg: "Hello"

# Bad - 4 spaces or tabs
---
-   name: Example task
    ansible.builtin.debug:
        msg: "Hello"
```

### Document Start

```yaml
# Good - Always start with ---
---
- name: My playbook
  hosts: all

# Bad - Missing document start
- name: My playbook
  hosts: all
```

### Lists

```yaml
# Good - Consistent list format
packages:
  - httpd
  - nginx
  - postgresql

# Also acceptable for short lists
packages: ['httpd', 'nginx', 'postgresql']

# Bad - Inconsistent
packages:
- httpd
  - nginx
    - postgresql
```

### Dictionaries

```yaml
# Good - Consistent formatting
web_server:
  port: 80
  ssl_enabled: true
  document_root: /var/www/html

# Bad - Inline for complex structures
web_server: {port: 80, ssl_enabled: true, document_root: /var/www/html}
```

### Strings

```yaml
# Good - Quote when needed
name: "Server with spaces"
path: "/var/www/html"
version: "1.0.0"

# Good - No quotes for simple strings
state: present
enabled: true

# Bad - Inconsistent quoting
name: 'Server with spaces'
path: /var/www/html
version: 1.0.0
```

### Booleans

```yaml
# Good - Use lowercase
enabled: true
ssl_verify: false

# Bad - Inconsistent
enabled: True
ssl_verify: FALSE
enabled: yes  # Avoid, use true/false
```

### Line Length

```yaml
# Prefer to keep under 160 characters
# Break long lines:

# Good
- name: Install packages
  ansible.builtin.package:
    name:
      - httpd
      - mod_ssl
      - httpd-tools
    state: present

# Bad - Too long
- name: Install packages
  ansible.builtin.package:
    name: ['httpd', 'mod_ssl', 'httpd-tools', 'httpd-devel', 'apr', 'apr-util']
    state: present
```

### Comments

```yaml
# Good - Comment above the block
---
# Configure web server
- name: Install Apache
  ansible.builtin.package:
    name: httpd
    state: present

# Bad - Inline comments
- name: Install Apache  # Install web server
  ansible.builtin.package:
    name: httpd  # Apache package
```

---

## Ansible Style

### Playbook Structure

```yaml
---
# Playbook header comment
- name: Descriptive playbook name
  hosts: target_hosts
  become: true  # If needed
  gather_facts: true  # Default, but explicit is good
  
  vars:
    # Playbook variables
    app_version: "1.0.0"
  
  vars_files:
    # External variable files
    - vars/common.yml
  
  pre_tasks:
    # Tasks before roles
    - name: Update cache
      ansible.builtin.apt:
        update_cache: true
  
  roles:
    # Roles to apply
    - role: webserver
      webserver_port: 80
  
  tasks:
    # Main tasks
    - name: Deploy application
      ansible.builtin.copy:
        src: app.jar
        dest: /opt/app/
  
  post_tasks:
    # Tasks after roles
    - name: Verify deployment
      ansible.builtin.uri:
        url: http://localhost
  
  handlers:
    # Handlers for this playbook
    - name: restart application
      ansible.builtin.service:
        name: app
        state: restarted
```

### Task Format

```yaml
# Good - FQCN, descriptive name
- name: Install Apache web server
  ansible.builtin.package:
    name: httpd
    state: present
  become: true
  tags:
    - install
    - webserver

# Bad - No FQCN, vague name
- name: Install package
  package:
    name: httpd
```

### Module Parameters

```yaml
# Good - One parameter per line for readability
- name: Create user account
  ansible.builtin.user:
    name: webapp
    group: webapp
    home: /opt/webapp
    shell: /bin/bash
    create_home: true
    state: present

# Bad - All on one line
- name: Create user
  ansible.builtin.user: name=webapp group=webapp home=/opt/webapp shell=/bin/bash create_home=yes state=present
```

### Conditionals

```yaml
# Good - Clear and readable, no {{ }} in when
- name: Install package
  ansible.builtin.package:
    name: httpd
    state: present
  when:
    - ansible_os_family == "RedHat"
    - ansible_distribution_major_version | int >= 8

# Good - Simple condition
- name: Install package
  ansible.builtin.package:
    name: httpd
  when: ansible_os_family == "RedHat"

# Good - Boolean with bool filter
- name: Configure SSL
  ansible.builtin.template:
    src: ssl.conf.j2
    dest: /etc/ssl.conf
  when: webserver_ssl_enabled | bool

# Bad - Using {{ }} in when (ansible-lint: jinja[invalid])
- name: Install package
  ansible.builtin.package:
    name: httpd
  when: "{{ ansible_os_family == 'RedHat' }}"

# Bad - Comparing to literal boolean
- name: Configure SSL
  ansible.builtin.template:
    src: ssl.conf.j2
  when: webserver_ssl_enabled == true  # Use | bool instead
```

**References**:
- [Ansible-lint: jinja[invalid]](https://ansible.readthedocs.io/projects/lint/rules/jinja/)
- [Ansible-lint: literal-compare](https://ansible.readthedocs.io/projects/lint/rules/literal-compare/)

### Loops

```yaml
# Good - Clear loop variable name
- name: Install packages
  ansible.builtin.package:
    name: "{{ package_name }}"
    state: present
  loop:
    - httpd
    - mod_ssl
    - httpd-tools
  loop_control:
    loop_var: package_name
    label: "{{ package_name }}"

# Bad - Default 'item' can be confusing
- name: Install
  package:
    name: "{{ item }}"
  loop: ['httpd', 'mod_ssl']
```

### Variables

```yaml
# Good - Descriptive, prefixed
webserver_port: 80
webserver_ssl_enabled: true
database_name: webapp
database_user: webapp_user

# Bad - Generic, unprefixed
port: 80
enabled: true
name: webapp
user: webapp_user
```

### Handlers

```yaml
# Good - Descriptive, uses FQCN
handlers:
  - name: restart apache
    ansible.builtin.service:
      name: httpd
      state: restarted
    listen: restart webserver

  - name: reload apache
    ansible.builtin.service:
      name: httpd
      state: reloaded
    listen: restart webserver

# Usage
- name: Update config
  ansible.builtin.template:
    src: httpd.conf.j2
    dest: /etc/httpd/conf/httpd.conf
  notify: restart webserver
```

### Tags

```yaml
# Good - Hierarchical, descriptive
- name: Install Apache
  ansible.builtin.package:
    name: httpd
  tags:
    - install
    - webserver
    - webserver:install

- name: Configure Apache
  ansible.builtin.template:
    src: httpd.conf.j2
    dest: /etc/httpd/conf/httpd.conf
  tags:
    - configure
    - webserver
    - webserver:configure
```

---

## Python Style

### Configuration

Use PEP 8 with these tools:
- **black**: Code formatting (line length: 100)
- **isort**: Import sorting
- **flake8**: Style checking
- **pylint**: Code analysis

### Formatting

```python
# Good - Black formatted
def manage_service(name: str, state: str, enabled: bool = None) -> dict:
    """
    Manage a system service.

    Args:
        name: Service name
        state: Desired state (started/stopped)
        enabled: Enable on boot
        
    Returns:
        dict: Result with changed status
    """
    result = {"changed": False, "name": name}

    if state == "started":
        start_service(name)
        result["changed"] = True

    return result


# Bad - Poor formatting
def manage_service(name,state,enabled=None):
    result={'changed':False,'name':name}
    if state=='started':start_service(name);result['changed']=True
    return result
```

### Imports

```python
# Good - Organized with isort
"""Module docstring."""
from __future__ import absolute_import, division, print_function

__metaclass__ = type

# Standard library
import os
import sys
from typing import Dict, List, Optional

# Third party
from ansible.module_utils.basic import AnsibleModule

# Local
from ansible_collections.myorg.custom_collection.plugins.module_utils import helper


# Bad - Disorganized
import sys
from ansible.module_utils.basic import AnsibleModule
import os
from ansible_collections.myorg.custom_collection.plugins.module_utils import helper
```

### Docstrings

```python
# Good - Complete documentation
def process_data(input_data: List[str], validate: bool = True) -> Dict[str, any]:
    """
    Process input data and return results.

    This function takes a list of strings, optionally validates them,
    and returns a dictionary with processed results.

    Args:
        input_data: List of strings to process
        validate: Whether to validate input (default: True)
        
    Returns:
        dict: Processed results with keys:
            - success (bool): Whether processing succeeded
            - data (list): Processed data items
            - errors (list): Any errors encountered
            
    Raises:
        ValueError: If input_data is empty and validate is True
        
    Example:
        >>> process_data(['item1', 'item2'])
        {'success': True, 'data': ['item1', 'item2'], 'errors': []}
    """
    if validate and not input_data:
        raise ValueError("input_data cannot be empty")

    # Implementation
    pass
```

### Type Hints

```python
# Good - Use type hints
from typing import Dict, List, Optional

def get_config(
    name: str,
    default: Optional[str] = None,
    required: bool = False
) -> Optional[str]:
    """Get configuration value."""
    pass

def process_items(items: List[str]) -> Dict[str, int]:
    """Process items and return counts."""
    pass
```

### Module Structure

```python
#!/usr/bin/python
# -*- coding: utf-8 -*-

# Copyright: (c) 2025, Platform Team
# GNU General Public License v3.0+

from __future__ import absolute_import, division, print_function
__metaclass__ = type

DOCUMENTATION = r'''
---
module: module_name
short_description: Short description
description:
    - Longer description
options:
    name:
        description: Parameter description
        required: true
        type: str
'''

EXAMPLES = r'''
# Example 1
- name: Example usage
  myorg.custom_collection.module_name:
    name: example
'''

RETURN = r'''
result:
    description: Result description
    returned: always
    type: dict
'''

from ansible.module_utils.basic import AnsibleModule


def run_module():
    """Main module function."""
    module_args = dict(
        name=dict(type='str', required=True),
    )

    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )

    result = dict(
        changed=False,
    )

    module.exit_json(**result)


def main():
    """Entry point."""
    run_module()


if __name__ == '__main__':
    main()
```

---

## Shell Script Style

### Shebang and Options

```bash
#!/bin/bash
# Script description
#
# Usage: script.sh [options]

set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Catch errors in pipes
```

### Functions

```bash
# Good - Clear function definition
function install_packages() {
    local package_list=("$@")

    echo "Installing packages: ${package_list[*]}"

    for package in "${package_list[@]}"; do
        if command -v "$package" &> /dev/null; then
            echo "✓ $package already installed"
        else
            echo "Installing $package..."
            apt-get install -y "$package"
        fi
    done
}

# Usage
install_packages "git" "curl" "wget"
```

### Variables

```bash
# Good - Uppercase for constants, lowercase for variables
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly VERSION="1.0.0"

config_file="${HOME}/.config/app.conf"
user_name="${USER}"

# Use quotes
file_path="/path/to/file"
command_output="$(command_here)"
```

### Conditionals

```bash
# Good - Use [[ ]] for conditionals
if [[ -f "$config_file" ]]; then
    echo "Config exists"
elif [[ -d "$config_dir" ]]; then
    echo "Directory exists"
else
    echo "Nothing found"
fi

# Good - Check command success
if command -v git &> /dev/null; then
    echo "Git is installed"
fi
```

---

## Jinja2 Templates

### Whitespace Control

```jinja
{# Good - Clean whitespace #}
{% for item in items -%}
    {{ item }}
{% endfor -%}

{# Bad - Extra whitespace #}
{% for item in items %}
    {{ item }}
{% endfor %}
```

### Comments

```jinja
{# Good - Template comments #}
{# This section configures the web server #}
<VirtualHost *:{{ webserver_port }}>
    ServerName {{ webserver_server_name }}
    DocumentRoot {{ webserver_document_root }}
</VirtualHost>
```

### Filters

```jinja
{# Good - Use filters appropriately #}
{{ variable | default('default_value') }}
{{ list_var | join(', ') }}
{{ string_var | upper }}
{{ dict_var | to_json }}
{{ dict_var | to_nice_yaml }}
```

---

## Documentation Style

### Markdown

```markdown
# Main Heading (H1)

Brief introduction paragraph.

## Section Heading (H2)

Section content.

### Subsection (H3)

Subsection content.

#### Details (H4)

Detailed information.

## Code Blocks

Use fenced code blocks with language:

```yaml
---
key: value
```

## Lists

- Unordered list item
- Another item
  - Nested item

1. Ordered list item
2. Another item
```

### README Structure

```markdown
# Project/Role Name

Brief description (one line).

## Overview

Detailed description (1-2 paragraphs).

## Requirements

- Requirement 1
- Requirement 2

## Installation

```bash
Installation commands
```

## Usage

```yaml
Usage examples
```

## Variables

| Variable | Default | Description |
|----------|---------|-------------|
| var_name | value   | Description |

## Examples

### Example 1

```yaml
Example code
```

## License

MIT

## Author

Platform Team
```

---

**Version**: 1.0  
**Last Updated**: 2025-10-30  
**Status**: ✅ Enforced via linters and pre-commit hooks

