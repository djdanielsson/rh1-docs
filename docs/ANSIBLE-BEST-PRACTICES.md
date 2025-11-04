# Ansible Best Practices - Cloud-Native Ansible Lifecycle Platform

Comprehensive Ansible development guide incorporating [Red Hat CoP Automation Good Practices](https://redhat-cop.github.io/automation-good-practices/) and [Ansible-lint Rules](https://ansible.readthedocs.io/projects/lint/rules/).

## Table of Contents

- [The Zen of Ansible](#the-zen-of-ansible)
- [Role Design](#role-design)
- [Task Writing](#task-writing)
- [Variable Management](#variable-management)
- [Jinja2 Best Practices](#jinja2-best-practices)
- [Module Usage](#module-usage)
- [Common Patterns](#common-patterns)
- [Anti-Patterns to Avoid](#anti-patterns-to-avoid)

---

## The Zen of Ansible

*By Tim Appnel*

```
Ansible is not Python.
YAML sucks for coding.
Playbooks are not for programming.
Ansible users are (most probably) not programmers.
Clear is better than cluttered.
Concise is better than verbose.
Simple is better than complex.
Readability counts.
Helping users get things done matters most.
User experience beats ideological purity.
"Magic" conquers the manual.
When giving users options, always use convention over configuration.
Declarative is always better than imperative - most of the time.
Focus avoids complexity.
Complexity kills productivity.
If the implementation is hard to explain, it's a bad idea.
Every shell command and UI interaction is an opportunity to automate.
Just because something works, doesn't mean it can't be improved.
Friction should be eliminated whenever possible.
Automation is a continuous journey that never ends.
```

**Reference**: [Red Hat CoP - Guiding Principles](https://redhat-cop.github.io/automation-good-practices/#_guiding_principles_for_automation_good_practices)

---

## Role Design

### Use Roles for Reusable Automation

**Principle**: Roles are the primary unit of reusable automation.

```yaml
# Good - Roles contain reusable logic
roles/
  webserver/
    tasks/main.yml
    defaults/main.yml
    handlers/main.yml
    templates/

# Usage in playbook
- hosts: webservers
  roles:
    - role: webserver
      webserver_port: 8080
```

**Reference**: [Red Hat CoP - Define which structure to use](https://redhat-cop.github.io/automation-good-practices/#_define_which_structure_to_use_for_which_purpose)

### Keep Playbooks Simple

**Principle**: Playbooks should orchestrate roles, not contain complex logic.

```yaml
# Good - Simple orchestration
---
- name: Deploy web application
  hosts: webservers
  roles:
    - webserver
    - application

# Bad - Complex logic in playbook
---
- name: Deploy
  hosts: all
  tasks:
    - name: Do complex thing 1
      # ... 50 lines of tasks
```

**Reference**: [Red Hat CoP - Keep playbooks simple](https://redhat-cop.github.io/automation-good-practices/#_keep_your_playbooks_as_simple_as_possible)

### Prefix All Role Variables

**Principle**: Namespace variables with role name to avoid conflicts.

```yaml
# Good - Prefixed with role name
# roles/webserver/defaults/main.yml
webserver_port: 80
webserver_ssl_enabled: true
webserver_document_root: /var/www/html

# Bad - Unprefixed, will conflict
port: 80
ssl_enabled: true
document_root: /var/www/html
```

**Reference**: [Red Hat CoP - Naming parameters](https://redhat-cop.github.io/automation-good-practices/#_naming_parameters)

**Ansible-lint**: [var-naming](https://ansible.readthedocs.io/projects/lint/rules/var-naming/)

### Use Defaults for Public API

**Principle**: Put user-configurable variables in `defaults/`, internal variables in `vars/`.

```yaml
# defaults/main.yml - User can override these
webserver_port: 80
webserver_ssl_enabled: false

# vars/main.yml - Internal, not meant to be overridden
webserver_package_map:
  RedHat: httpd
  Debian: apache2
```

**Reference**: [Red Hat CoP - Vars vs Defaults](https://redhat-cop.github.io/automation-good-practices/#_vars_vs_defaults)

### Prefix Task Names in Sub-task Files

**Principle**: Prefix task names with role name for traceability.

```yaml
# Good - Prefixed task names in roles/webserver/tasks/install.yml
- name: "webserver | Install Apache packages"
  ansible.builtin.package:
    name: "{{ webserver_packages }}"

- name: "webserver | Create document root"
  ansible.builtin.file:
    path: "{{ webserver_document_root }}"

# Bad - No prefix, unclear in output
- name: Install packages
  ansible.builtin.package:
    name: "{{ webserver_packages }}"
```

**Reference**: [Red Hat CoP - Prefix task names](https://redhat-cop.github.io/automation-good-practices/#_prefix_task_names_in_sub_tasks_files_of_roles)

**Benefits**:
- Easier to trace in ansible-playbook output
- Clear which role is executing
- Better for debugging

---

## Task Writing

### Always Use FQCN

**Principle**: Use Fully Qualified Collection Names for all modules.

```yaml
# Good - FQCN
- name: Copy file
  ansible.builtin.copy:
    src: file.txt
    dest: /tmp/file.txt

- name: Install package
  ansible.builtin.package:
    name: httpd

# Bad - No FQCN
- name: Copy file
  copy:
    src: file.txt
    dest: /tmp/file.txt
```

**Ansible-lint**: [fqcn](https://ansible.readthedocs.io/projects/lint/rules/fqcn/)

**Why**: Prevents ambiguity, future-proof, required by ansible-lint.

### All Tasks Must Have Names

**Principle**: Every task must have a descriptive `name:` field.

```yaml
# Good - Descriptive names
- name: Install Apache web server
  ansible.builtin.package:
    name: httpd
    state: present

- name: Ensure web server is started and enabled
  ansible.builtin.service:
    name: httpd
    state: started
    enabled: true

# Bad - No names
- ansible.builtin.package:
    name: httpd
- ansible.builtin.service:
    name: httpd
```

**Ansible-lint**: [name[missing]](https://ansible.readthedocs.io/projects/lint/rules/name/)

**Why**: Improves readability, makes output understandable.

### Use Multi-line Format for Complex Tasks

**Principle**: One parameter per line for complex tasks.

```yaml
# Good - Readable, one param per line
- name: Create user account
  ansible.builtin.user:
    name: webapp
    group: webapp
    home: /opt/webapp
    shell: /bin/bash
    create_home: true
    state: present

# Bad - Single line, hard to read
- name: Create user
  ansible.builtin.user: name=webapp group=webapp home=/opt/webapp shell=/bin/bash create_home=true state=present
```

**Ansible-lint**: [args](https://ansible.readthedocs.io/projects/lint/rules/args/)

### Ensure Idempotency

**Principle**: Tasks should be safe to run multiple times.

```yaml
# Good - Idempotent
- name: Ensure configuration directory exists
  ansible.builtin.file:
    path: /etc/myapp
    state: directory
    mode: '0755'

# Good - Shell with creates
- name: Extract archive
  ansible.builtin.shell: tar xzf /tmp/app.tar.gz -C /opt/app
  args:
    creates: /opt/app/bin/app

# Bad - Not idempotent
- name: Extract archive
  ansible.builtin.shell: tar xzf /tmp/app.tar.gz -C /opt/app
```

**Ansible-lint**: [command-instead-of-module](https://ansible.readthedocs.io/projects/lint/rules/command-instead-of-module/)

**Reference**: [Red Hat CoP - Idempotency](https://redhat-cop.github.io/automation-good-practices/#_idempotency)

### Use Specific Modules Over shell/command

**Principle**: Prefer specific modules over `shell`, `command`, or `raw`.

```yaml
# Good - Use specific modules
- name: Create directory
  ansible.builtin.file:
    path: /opt/app
    state: directory

- name: Install package
  ansible.builtin.package:
    name: httpd
    state: present

- name: Start service
  ansible.builtin.service:
    name: httpd
    state: started

# Bad - Using shell/command
- name: Create directory
  ansible.builtin.shell: mkdir -p /opt/app

- name: Install package
  ansible.builtin.command: yum install -y httpd

- name: Start service
  ansible.builtin.shell: systemctl start httpd
```

**Ansible-lint**: [command-instead-of-module](https://ansible.readthedocs.io/projects/lint/rules/command-instead-of-module/)

**Why**: 
- Better idempotency
- Better error handling
- Clearer intent
- More portable

### When Using shell/command, Use changed_when

**Principle**: Always set `changed_when` for shell/command tasks.

```yaml
# Good - Explicit change detection
- name: Check service status
  ansible.builtin.command: systemctl is-active httpd
  register: service_status
  changed_when: false
  failed_when: service_status.rc not in [0, 3]

- name: Run migration
  ansible.builtin.shell: /opt/app/migrate.sh
  args:
    creates: /opt/app/.migrated
  changed_when: true

# Bad - No changed_when
- name: Check status
  ansible.builtin.command: systemctl is-active httpd
```

**Ansible-lint**: [no-changed-when](https://ansible.readthedocs.io/projects/lint/rules/no-changed-when/)

### Use block/rescue for Error Handling

**Principle**: Group related tasks and handle errors gracefully.

```yaml
# Good - Error handling with block/rescue
- name: Deploy application with rollback
  block:
    - name: Stop application
      ansible.builtin.service:
        name: myapp
        state: stopped

    - name: Deploy new version
      ansible.builtin.copy:
        src: app-v2.jar
        dest: /opt/app/app.jar

    - name: Start application
      ansible.builtin.service:
        name: myapp
        state: started

  rescue:
    - name: Rollback to previous version
      ansible.builtin.copy:
        src: app-v1.jar
        dest: /opt/app/app.jar

    - name: Start application
      ansible.builtin.service:
        name: myapp
        state: started

  always:
    - name: Log deployment attempt
      ansible.builtin.lineinfile:
        path: /var/log/deployments.log
        line: "Deployment attempted at {{ ansible_date_time.iso8601 }}"
```

**Reference**: [Ansible Docs - Error Handling](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_error_handling.html)

---

## Variable Management

### Use Type Casting for Safety

**Principle**: Cast variables to ensure type safety, especially for numeric operations.

```yaml
# Good - Type casting
- name: Check if port is in valid range
  ansible.builtin.assert:
    that:
      - webserver_port | int >= 1
      - webserver_port | int <= 65535

- name: Set timeout
  ansible.builtin.set_fact:
    timeout_seconds: "{{ timeout_minutes | int * 60 }}"

# Bad - No type casting, can fail if string
- name: Check port
  ansible.builtin.assert:
    that: webserver_port >= 1  # Fails if webserver_port is string
```

**Reference**: [Red Hat CoP - Use type filters](https://redhat-cop.github.io/automation-good-practices/#_wrap_longer_lines_of_code)

**Why**: User input may be strings; casting ensures correct type for operations.

### Use default() Filter for Optional Variables

**Principle**: Provide defaults with the `default()` filter.

```yaml
# Good - Safe defaults
- name: Set application port
  ansible.builtin.set_fact:
    app_port: "{{ custom_port | default(8080) }}"

- name: Configure with optional SSL
  ansible.builtin.template:
    src: config.j2
    dest: /etc/app/config.yml
  vars:
    ssl_cert: "{{ app_ssl_cert | default('/etc/pki/tls/certs/default.crt') }}"

# Bad - Variable might be undefined
- name: Set port
  ansible.builtin.set_fact:
    app_port: "{{ custom_port }}"  # Fails if not defined
```

**Ansible-lint**: [var-naming[no-role-prefix]](https://ansible.readthedocs.io/projects/lint/rules/var-naming/)

### Avoid Using host_vars and group_vars Filenames for Groups/Hosts

**Principle**: Don't use group names that conflict with built-in Ansible constructs.

```yaml
# Good - Descriptive group names
[webservers]
web01.example.com
web02.example.com

[databases]
db01.example.com

# Bad - Using 'all', 'ungrouped', etc.
# These have special meaning in Ansible
```

**Reference**: [Red Hat CoP - Don't use host group names](https://redhat-cop.github.io/automation-good-practices/#_dont_use_host_group_names_or_at_least_make_them_a_parameter)

---

## Jinja2 Best Practices

### Wrap Long Jinja Expressions

**Principle**: Break long Jinja expressions across multiple lines for readability.

```yaml
# Good - Multi-line Jinja expression
- name: Process complex data
  ansible.builtin.set_fact:
    processed_data: "{{
      raw_data |
      selectattr('enabled', 'equalto', true) |
      map(attribute='name') |
      list
      }}"

# Good - Complex when condition
- name: Install package
  ansible.builtin.package:
    name: special-package
  when:
    - ansible_distribution == "RedHat"
    - ansible_distribution_major_version | int >= 8
    - special_feature_enabled | bool

# Good - Break long filter chain
- name: Set configuration value
  ansible.builtin.set_fact:
    config_value: "{{
      input_value |
      default('default') |
      lower |
      replace(' ', '-')
      }}"

# Bad - Long single line
- name: Process data
  ansible.builtin.set_fact:
    processed_data: "{{ raw_data | selectattr('enabled', 'equalto', true) | map(attribute='name') | list }}"
```

**Reference**: [Red Hat CoP - Wrap longer lines](https://redhat-cop.github.io/automation-good-practices/#_wrap_longer_lines_of_code)

### Use Spaces in Jinja Expressions

**Principle**: Add spaces around filters and operators for readability.

```yaml
# Good - Spaces around filters and operators
{{ variable | filter }}
{{ value | default('default') }}
{{ count | int + 1 }}
{% if condition %}

# Bad - No spaces
{{variable|filter}}
{{value|default('default')}}
{{count|int+1}}
{%if condition%}
```

**Ansible-lint**: [jinja[spacing]](https://ansible.readthedocs.io/projects/lint/rules/jinja/)

### Don't Compare to Literal True/False

**Principle**: Use `bool` filter or direct comparison.

```yaml
# Good - Use bool filter
when: webserver_enabled | bool

# Good - Direct comparison for strings
when: state == "present"

# Bad - Comparing to literal
when: webserver_enabled == true
when: webserver_enabled is true
```

**Ansible-lint**: [no-literal-bool-comparison](https://ansible.readthedocs.io/projects/lint/rules/literal-compare/)

**Reference**: [Ansible-lint - Literal Compare](https://ansible.readthedocs.io/projects/lint/rules/literal-compare/)

### Use Specific Tests, Not Regex

**Principle**: Use built-in tests instead of regex when possible.

```yaml
# Good - Use specific tests
when: ansible_distribution in ['RedHat', 'CentOS', 'Rocky']
when: variable is defined
when: result is failed
when: path is directory

# Bad - Using regex unnecessarily
when: ansible_distribution is match('RedHat|CentOS|Rocky')
when: variable is defined and variable | regex_search('.*')
```

**Why**: More readable, more efficient, less error-prone.

---

## Module Usage

### Avoid lineinfile When Possible

**Principle**: Use `template`, `copy`, or specific config modules instead of `lineinfile`.

```yaml
# Good - Use template for complex configs
- name: Configure Apache
  ansible.builtin.template:
    src: httpd.conf.j2
    dest: /etc/httpd/conf/httpd.conf

# Good - Use specific module
- name: Configure SSH
  community.general.ssh_config:
    host: example.com
    hostname: 192.168.1.1
    user: ansible

# Acceptable - Simple, justified use
- name: Add line to sudoers
  ansible.builtin.lineinfile:
    path: /etc/sudoers
    line: "ansible ALL=(ALL) NOPASSWD: ALL"
    validate: /usr/sbin/visudo -cf %s
  # Justified: Single line, validation needed

# Bad - Complex lineinfile usage
- name: Configure app
  ansible.builtin.lineinfile:
    path: /etc/app.conf
    regexp: "^PORT="
    line: "PORT={{ app_port }}"
  # Use template instead!
```

**Reference**: [Red Hat CoP - Avoid lineinfile](https://redhat-cop.github.io/automation-good-practices/#_coding_style_good_practices_for_ansible)

**Why**: Templates are more maintainable, show full file structure.

### Use template Over copy for Configuration Files

**Principle**: Use `template` even if nothing is templated yet.

```yaml
# Good - Use template (even if no variables)
- name: Deploy configuration
  ansible.builtin.template:
    src: app.conf.j2
    dest: /etc/app/app.conf

# templates/app.conf.j2
# Even if initially just static content
# Later easy to add {{ variables }}

# Bad - Using copy for config files
- name: Deploy config
  ansible.builtin.copy:
    src: app.conf
    dest: /etc/app/app.conf
  # Harder to add variables later
```

**Reference**: [Red Hat CoP - Use template over copy](https://redhat-cop.github.io/automation-good-practices/#_coding_style_good_practices_for_ansible)

### Template Files Should End in .j2

**Principle**: Append `.j2` to template filenames.

```yaml
# Good - .j2 extension
templates/
  httpd.conf.j2
  index.html.j2
  app.properties.j2

- name: Deploy config
  ansible.builtin.template:
    src: httpd.conf.j2
    dest: /etc/httpd/conf/httpd.conf

# Bad - No .j2 extension
templates/
  httpd.conf
  index.html
```

**Reference**: [Red Hat CoP - Template naming](https://redhat-cop.github.io/automation-good-practices/#_coding_style_good_practices_for_ansible)

**Why**: Editor syntax highlighting, clear intent, distinguishes from static files.

### Use package Module Cautiously

**Principle**: Use specific package managers when package names differ across platforms.

```yaml
# Good - Platform-specific when names differ
- name: Install Apache
  ansible.builtin.yum:
    name: httpd
    state: present
  when: ansible_os_family == "RedHat"

- name: Install Apache
  ansible.builtin.apt:
    name: apache2
    state: present
  when: ansible_os_family == "Debian"

# Acceptable - Package name is same across platforms
- name: Install git
  ansible.builtin.package:
    name: git
    state: present

# Bad - Using package when names differ
- name: Install web server
  ansible.builtin.package:
    name: httpd  # Doesn't exist on Debian!
```

**Reference**: [Red Hat CoP - Using agnostic modules](https://redhat-cop.github.io/automation-good-practices/#_coding_style_good_practices_for_ansible)

---

## Common Patterns

### Multi-Platform Support

**Principle**: Use platform-specific variables and tasks.

```yaml
# defaults/main.yml
webserver_package: "{{ __webserver_package }}"

# vars/RedHat.yml
__webserver_package: httpd

# vars/Debian.yml
__webserver_package: apache2

# tasks/main.yml
- name: Include platform-specific variables
  ansible.builtin.include_vars: "{{ ansible_os_family }}.yml"

- name: Install web server
  ansible.builtin.package:
    name: "{{ webserver_package }}"
    state: present
```

**Reference**: [Red Hat CoP - Platform specific variables](https://redhat-cop.github.io/automation-good-practices/#_platform_specific_variables)

### Check Mode Support

**Principle**: Make roles work with `--check` flag.

```yaml
# Good - Check mode aware
- name: Install packages
  ansible.builtin.package:
    name: httpd
    state: present
  # Package module supports check mode automatically

- name: Run command
  ansible.builtin.command: /opt/app/health-check.sh
  check_mode: false  # Always run, even in check mode
  changed_when: false

# For tasks that can't run in check mode
- name: Get current config
  ansible.builtin.slurp:
    src: /etc/app.conf
  register: current_config
  check_mode: false  # Must read actual state
```

**Reference**: [Red Hat CoP - Check Mode](https://redhat-cop.github.io/automation-good-practices/#_check_mode)

**Ansible-lint**: [no-changed-when](https://ansible.readthedocs.io/projects/lint/rules/no-changed-when/)

### Argument Spec Validation

**Principle**: Define argument specs for role validation.

```yaml
# roles/webserver/meta/argument_specs.yml
---
argument_specs:
  main:
    short_description: Configure Apache web server
    description:
      - Installs and configures Apache HTTP Server
      - Manages firewall rules
      - Deploys custom index page
    
    options:
      webserver_port:
        type: int
        required: false
        default: 80
        description: HTTP port number
      
      webserver_ssl_enabled:
        type: bool
        required: false
        default: false
        description: Enable SSL/TLS
      
      webserver_packages:
        type: list
        elements: str
        required: false
        default:
          - httpd
        description: List of packages to install
```

**Reference**: [Red Hat CoP - Argument Validation](https://redhat-cop.github.io/automation-good-practices/#_argument_validation)

**Ansible-lint**: [args](https://ansible.readthedocs.io/projects/lint/rules/args/)

### Use loop_control for Complex Loops

**Principle**: Use `loop_control` to customize loop behavior.

```yaml
# Good - Custom loop variable and label
- name: Create users
  ansible.builtin.user:
    name: "{{ user_item.name }}"
    groups: "{{ user_item.groups }}"
    state: present
  loop:
    - name: alice
      groups: [developers, sudo]
    - name: bob
      groups: [developers]
  loop_control:
    loop_var: user_item
    label: "{{ user_item.name }}"
    pause: 1  # Pause 1 second between iterations

# Bad - Using default 'item', verbose output
- name: Create users
  ansible.builtin.user:
    name: "{{ item.name }}"
    groups: "{{ item.groups }}"
  loop:
    - name: alice
      groups: [developers, sudo]
    - name: bob
      groups: [developers]
```

**Ansible-lint**: [loop-var-prefix](https://ansible.readthedocs.io/projects/lint/rules/loop-var-prefix/)

**Reference**: [Red Hat CoP - Naming things](https://redhat-cop.github.io/automation-good-practices/#_naming_things)

---

## Anti-Patterns to Avoid

### Don't Use `ignore_errors: true` Without Good Reason

```yaml
# Bad - Hiding errors
- name: Do something
  ansible.builtin.command: /opt/app/script.sh
  ignore_errors: true

# Good - Specific error handling
- name: Check if file exists
  ansible.builtin.stat:
    path: /opt/app/config
  register: config_check
  failed_when: false  # This check should never fail

- name: Do something
  ansible.builtin.command: /opt/app/script.sh
  register: script_result
  failed_when: script_result.rc not in [0, 2]  # 2 is acceptable
```

**Ansible-lint**: [ignore-errors](https://ansible.readthedocs.io/projects/lint/rules/ignore-errors/)

### Don't Use local_action

```yaml
# Good - Use delegate_to
- name: Create local backup
  ansible.builtin.copy:
    src: /remote/file
    dest: /local/backup
  delegate_to: localhost

# Bad - Using local_action
- name: Create backup
  local_action:
    module: copy
    src: /remote/file
    dest: /local/backup
```

**Ansible-lint**: [deprecated-local-action](https://ansible.readthedocs.io/projects/lint/rules/deprecated-local-action/)

### Don't Use {{ }} in when Conditions

```yaml
# Good - No {{ }} in when
- name: Install package
  ansible.builtin.package:
    name: httpd
  when: ansible_os_family == "RedHat"

- name: Complex condition
  ansible.builtin.service:
    name: httpd
    state: started
  when:
    - webserver_enabled | bool
    - ansible_distribution_major_version | int >= 8

# Bad - Using {{ }} in when
- name: Install package
  ansible.builtin.package:
    name: httpd
  when: "{{ ansible_os_family == 'RedHat' }}"
```

**Ansible-lint**: [jinja[invalid]](https://ansible.readthedocs.io/projects/lint/rules/jinja/)

**Why**: `when` is already a Jinja context; {{ }} is redundant and causes errors.

### Don't Use Bare Variables in Loops

```yaml
# Good - Quoted in loop
- name: Install packages
  ansible.builtin.package:
    name: "{{ item }}"
    state: present
  loop: "{{ webserver_packages }}"

# Bad - Bare variable
- name: Install packages
  ansible.builtin.package:
    name: "{{ item }}"
  loop: {{ webserver_packages }}  # Syntax error!
```

**Ansible-lint**: [var-spacing](https://ansible.readthedocs.io/projects/lint/rules/var-spacing/)

### Avoid set_fact in Loops

```yaml
# Bad - set_fact in loop (performance issue)
- name: Build list
  ansible.builtin.set_fact:
    my_list: "{{ my_list | default([]) + [item] }}"
  loop: "{{ large_list }}"

# Good - Use map or other filters
- name: Build list
  ansible.builtin.set_fact:
    my_list: "{{ large_list | map(attribute='name') | list }}"

# Or use loop_control with register
- name: Process items
  ansible.builtin.command: process {{ item }}
  loop: "{{ items }}"
  register: results
```

**Ansible-lint**: [set_fact-no-loop](https://ansible.readthedocs.io/projects/lint/rules/no-loop-var-prefix/)

### Use Latest Ansible Practices

```yaml
# Good - Modern Ansible
loop: "{{ items }}"
loop_control:
  loop_var: item_name

# Bad - Deprecated
with_items: "{{ items }}"

# Good - Modern include
ansible.builtin.include_tasks: setup.yml

# Bad - Deprecated
include: setup.yml
```

**Ansible-lint**: [deprecated-module](https://ansible.readthedocs.io/projects/lint/rules/deprecated-module/)

---

## Task Naming Best Practices

### Start Task Names with Verbs

**Principle**: Task names should start with action verbs.

```yaml
# Good - Starts with verb
- name: Install Apache packages
- name: Ensure web server is started
- name: Configure firewall rules
- name: Verify application is responding
- name: Create backup directory

# Bad - Vague or passive
- name: Apache packages
- name: Web server
- name: Firewall
- name: Application check
```

**Ansible-lint**: [name[template]](https://ansible.readthedocs.io/projects/lint/rules/name/)

### Use Meaningful Task Names

```yaml
# Good - Describes what and why
- name: Install Apache to serve static content
- name: Ensure PostgreSQL is running for application database
- name: Configure firewall to allow HTTP traffic

# Acceptable - Clear what
- name: Install Apache web server
- name: Start PostgreSQL service
- name: Configure HTTP firewall rules

# Bad - Too vague
- name: Install packages
- name: Start service
- name: Configure firewall
```

### Prefix for Sub-task Files

```yaml
# roles/webserver/tasks/install.yml
- name: "webserver | Install Apache packages"
  ansible.builtin.package:
    name: "{{ webserver_packages }}"

- name: "webserver | Verify Apache binary exists"
  ansible.builtin.stat:
    path: /usr/sbin/httpd

# roles/webserver/tasks/configure.yml
- name: "webserver | Deploy configuration file"
  ansible.builtin.template:
    src: httpd.conf.j2
    dest: /etc/httpd/conf/httpd.conf
```

**Reference**: [Red Hat CoP - Prefix task names in sub-tasks](https://redhat-cop.github.io/automation-good-practices/#_prefix_task_names_in_sub_tasks_files_of_roles)

---

## File Organization

### Use include_tasks for Complex Roles

**Principle**: Break complex roles into logical task files.

```yaml
# roles/webserver/tasks/main.yml
---
- name: Include platform-specific variables
  ansible.builtin.include_vars: "{{ ansible_os_family }}.yml"

- name: Include installation tasks
  ansible.builtin.include_tasks: install.yml

- name: Include configuration tasks
  ansible.builtin.include_tasks: configure.yml

- name: Include service management tasks
  ansible.builtin.include_tasks: service.yml
```

**Why**: Improves readability, easier to maintain, logical organization.

### Keep Role Dependencies Minimal

**Principle**: Avoid deep role dependency chains.

```yaml
# roles/webserver/meta/main.yml

# Good - Minimal, necessary dependencies
dependencies:
  - role: common
    common_packages_extra:
      - mod_ssl

# Bad - Deep dependency chain
dependencies:
  - role: base
  - role: security
  - role: monitoring
  - role: logging
  # Too many dependencies!
```

**Ansible-lint**: [role-name](https://ansible.readthedocs.io/projects/lint/rules/role-name/)

---

## Testing and Validation

### Support Check Mode

**Principle**: Ensure roles work with `--check` flag.

```yaml
- name: Get current state
  ansible.builtin.command: get-state.sh
  register: current_state
  check_mode: false  # Always run
  changed_when: false

- name: Make changes based on state
  ansible.builtin.template:
    src: config.j2
    dest: /etc/app/config
  when: current_state.stdout != "configured"
```

**Reference**: [Red Hat CoP - Check Mode](https://redhat-cop.github.io/automation-good-practices/#_check_mode)

### Use register + assert for Validation

```yaml
# Good - Explicit validation
- name: Check web server response
  ansible.builtin.uri:
    url: "http://localhost:{{ webserver_port }}"
    status_code: 200
  register: web_response

- name: Verify response contains expected content
  ansible.builtin.assert:
    that:
      - web_response.status == 200
      - "'Welcome' in web_response.content"
    fail_msg: "Web server not responding correctly"
    success_msg: "Web server is healthy"
```

**Ansible-lint**: [risky-shell-pipe](https://ansible.readthedocs.io/projects/lint/rules/risky-shell-pipe/)

---

## References

### External Resources

- **[Red Hat CoP Automation Good Practices](https://redhat-cop.github.io/automation-good-practices/)** - Comprehensive guide from Red Hat Community of Practice
- **[Ansible-lint Rules](https://ansible.readthedocs.io/projects/lint/rules/)** - Complete list of ansible-lint rules
- **[Ansible Best Practices](https://docs.ansible.com/ansible/latest/tips_tricks/ansible_tips_tricks.html)** - Official Ansible documentation
- **[Ansible Style Guide](https://docs.ansible.com/ansible/latest/dev_guide/style_guide/)** - Official style guide

### Internal Documentation

- [Code Style Guide](./CODE-STYLE-GUIDE.md) - Platform-specific style guide
- [Naming Conventions](./NAMING-CONVENTIONS.md) - Naming standards
- [Constitution](../.specify/memory/constitution.md) - Platform principles
- [Testing Guide](./TESTING-GUIDE.md) - Testing standards

---

## Quick Reference Checklist

Before committing code, verify:

- [ ] All modules use FQCN
- [ ] All tasks have descriptive names
- [ ] Task names start with verbs
- [ ] Sub-task files have prefixed names
- [ ] Variables are prefixed with role name
- [ ] Using `template` instead of `copy` for configs
- [ ] Template files end in `.j2`
- [ ] No `{{ }}` in `when` conditions
- [ ] `changed_when` set for shell/command
- [ ] Multi-line format for complex tasks
- [ ] Type filters used for numeric operations
- [ ] Check mode supported
- [ ] No `ignore_errors` without justification
- [ ] Using specific modules over shell/command
- [ ] Idempotent operations
- [ ] Tests included

---

**Version**: 2.0  
**Last Updated**: 2025-10-30  
**Status**: ✅ Aligned with Red Hat CoP and ansible-lint rules  
**References**: Red Hat CoP, ansible-lint, Ansible official docs



