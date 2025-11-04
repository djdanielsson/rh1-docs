# Naming Conventions - Cloud-Native Ansible Lifecycle Platform

Comprehensive naming standards for all resources, files, variables, and components in the platform.

## Table of Contents

- [Overview](#overview)
- [General Principles](#general-principles)
- [Repository Naming](#repository-naming)
- [File Naming](#file-naming)
- [Ansible Naming](#ansible-naming)
- [Kubernetes Naming](#kubernetes-naming)
- [AAP Resource Naming](#aap-resource-naming)
- [Git Naming](#git-naming)

---

## Overview

Consistent naming conventions ensure:
- **Readability**: Easy to understand purpose
- **Searchability**: Quick to find resources
- **Maintainability**: Clear ownership and structure
- **Scalability**: Patterns that grow with the platform

---

## General Principles

### 1. Be Descriptive

```
# Good
webserver_port
database_connection_string
aap_dev_credentials

# Bad
port
conn_str
creds
```

### 2. Be Consistent

Use the same pattern throughout:
- File extensions: `.yml` (not `.yaml` mixed with `.yml`)
- Separators: Use one consistently (underscore or hyphen)
- Case: Stick to one convention per context

### 3. Be Concise

Balance between descriptive and brief:

```
# Good
web_server_config
db_backup_schedule

# Too verbose
web_server_configuration_file_settings
database_backup_scheduled_job_template

# Too brief
ws_cfg
db_bkp
```

### 4. Use Standard Abbreviations

Common abbreviations that are acceptable:
- `aap` - Ansible Automation Platform
- `ee` - Execution Environment
- `cac` - Configuration as Code
- `qa` - Quality Assurance
- `prod` - Production
- `dev` - Development
- `config` - Configuration
- `auth` - Authentication
- `k8s` - Kubernetes (when appropriate)

---

## Repository Naming

### Format

```
{purpose}-{type}
```

### Examples

```
# Platform repositories
cluster-config               # Platform GitOps
aap-config-as-code          # AAP Configuration
automation-collection-example # Ansible Collection
automation-ee-example        # Execution Environment
automation-release-manifest  # Release Management

# Additional repositories
{org}-ansible-collection     # Custom collection
{project}-playbooks          # Playbook repository
{app}-deployment            # Application deployment
```

### Rules

- Use **lowercase** with **hyphens**
- Start with purpose, end with type
- Keep under 50 characters
- No special characters except hyphens

---

## File Naming

### YAML Files

#### Ansible Playbooks

```
# Format: {verb}-{noun}.yml
deploy-webapp.yml
configure-webserver.yml
backup-database.yml
patch-systems.yml

# Not:
webapp.yml
webserver.yml
database.yml
```

#### Group Variables

```
# Format: {category}.yml
group_vars/
  all/
    organizations.yml
    teams.yml
    labels.yml
  aap_dev/
    credentials.yml
    projects.yml
    job_templates.yml
    inventories.yml
```

#### Kubernetes Resources

```
# Format: {resource-type}-{name}.yaml
namespace-aap-dev.yaml
deployment-aap-controller.yaml
service-aap-api.yaml
ingress-aap-web.yaml

# ArgoCD Applications
argocd/applications/
  aap-instances-app.yaml
  tekton-pipelines-app.yaml
  namespaces-app.yaml
```

### Python Files

```
# Modules: {action}_{resource}.py
manage_service.py
configure_firewall.py
deploy_application.py

# Filters: {category}_filters.py
text_filters.py
network_filters.py
date_filters.py

# Tests: test_{what}.py
test_basic.py
test_integration.py
test_sample_module.py
```

### Templates

```
# Format: {filename}.{extension}.j2
index.html.j2
httpd.conf.j2
postgresql.conf.j2
application.properties.j2
```

### Shell Scripts

```
# Format: {verb}-{noun}.sh
run-tests.sh
setup-environment.sh
create-manifest.sh
validate-manifest.sh
```

---

## Ansible Naming

### Roles

#### Role Names

```
# Format: lowercase, underscores
webserver
database
monitoring
load_balancer
application_server

# Not:
WebServer
web-server
WebServerRole
```

#### Role Directories

```
roles/
  webserver/
    tasks/
      main.yml          # Main entry point
      install.yml       # Specific task file
      configure.yml
    defaults/
      main.yml          # Default variables
    vars/
      main.yml          # Role variables
    handlers/
      main.yml          # Handlers
    templates/
      config.j2         # Templates
    files/
      script.sh         # Static files
    meta/
      main.yml          # Role metadata
```

### Variables

#### Variable Naming

```
# Format: {role}_{category}_{name}
webserver_port
webserver_document_root
webserver_ssl_enabled

database_name
database_user
database_backup_schedule

# Boolean variables - use positive names
webserver_enabled              # Good
database_ssl_verify            # Good

# Not:
webserver_disabled             # Avoid negatives
database_ssl_no_verify         # Avoid negatives
```

#### Variable Prefixes

Always prefix role variables with role name:

```yaml
# In webserver role
webserver_packages:
  - httpd
webserver_service: httpd
webserver_port: 80

# Not (conflicts possible):
packages:
  - httpd
service: httpd
port: 80
```

#### Environment Variables

```
# Format: SCREAMING_SNAKE_CASE
DB_PASSWORD
API_TOKEN
VAULT_ADDR
CONTROLLER_HOST
```

### Tasks

#### Task Names

```yaml
# Format: {Action} {target} [{detail}]

# Good - Start with verb, be specific
- name: Install Apache packages
- name: Configure web server firewall rules
- name: Ensure PostgreSQL is started and enabled
- name: Deploy application configuration file

# Bad - Not descriptive enough
- name: Install packages
- name: Configure
- name: Start service
```

#### Task File Names

```
tasks/
  main.yml              # Main task list
  install.yml           # Installation tasks
  configure.yml         # Configuration tasks  
  validate.yml          # Validation tasks
  cleanup.yml           # Cleanup tasks
```

### Handlers

```yaml
# Format: {action} {target}
handlers:
  - name: restart apache
  - name: reload nginx
  - name: restart postgresql
  - name: reload systemd

# Not:
  - name: apache
  - name: restart
```

### Tags

```yaml
# Use descriptive, hierarchical tags
tags:
  - install
  - configure
  - security
  - firewall
  - validate

# Hierarchical:
  - web
  - web:install
  - web:configure
```

---

## Kubernetes Naming

### Namespace Naming

```
# Format: {purpose}-{environment}
aap-dev
aap-qa
aap-prod
dev-tools
monitoring

# Not:
development
production
tools
```

### Resource Naming

#### Format

```
{app}-{component}-{environment}
```

#### Examples

```yaml
# Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aap-controller-dev
  namespace: aap-dev

# Service
apiVersion: v1
kind: Service
metadata:
  name: aap-api-dev
  namespace: aap-dev

# ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: aap-config-dev
  namespace: aap-dev
```

### Labels

```yaml
# Standard labels
metadata:
  labels:
    app: aap-controller
    component: api
    environment: dev
    version: "2.5"
    managed-by: argocd
```

### ArgoCD Applications

```
# Format: {component}-app
aap-instances-app
namespaces-app
operators-app
tekton-pipelines-app
rbac-app
```

---

## AAP Resource Naming

### Organizations

```
# Format: {Department/Team Name}
Engineering
Operations
Platform Team
Security Team

# Not abbreviations:
Eng
Ops
```

### Teams

```
# Format: {Team Name}
Platform Team
Application Team
DevOps Team
Database Team
```

### Credentials

```
# Format: {Type} - {Purpose/Target}
Linux Servers
Windows Servers
GitHub - Main
GitLab - Internal
AWS - Production
Quay.io
HashiCorp Vault

# Not:
ssh-key
git-creds
aws
```

### Projects

```
# Format: {Purpose/Name}
Infrastructure Playbooks
Application Deployment
AAP Configuration
Security Compliance
Database Management

# Not:
infra
app-deploy
config
```

### Inventories

```
# Format: {Environment}
Production
Staging  
Development
Test

# Or with purpose:
Production - US East
Development - Local
```

### Job Templates

```
# Format: {Action} {Target} [{Environment}]
Deploy Web Application
Configure Web Servers
Backup Database
Patch Systems - Production
Security Scan - All Hosts

# Not:
deploy-app
config
backup
```

### Workflow Templates

```
# Format: {Descriptive Name}
Full Application Deployment
Complete Infrastructure Setup
Disaster Recovery Procedure
Security Compliance Check

# Not:
app-workflow
infra-wf
```

### Execution Environments

```
# Format: {Purpose} EE
Production EE
Development EE
Minimal EE
Security Scanning EE
Network Automation EE

# Not:
prod-ee
dev-ee
ee-minimal
```

### Schedules

```
# Format: {Frequency} {Task}
Nightly Database Backup
Weekly System Patching
Monthly Security Scan
Hourly Health Check

# Not:
backup-schedule
patch-sched
```

---

## Git Naming

### Branch Names

**Main Branch**:
```
main  # or master (single source of truth)
```

**Feature/Fix Branches**:
```
# Format: {type}/{description}

# Feature branches (short-lived)
feature/add-webserver-role
feature/implement-workflow-template
feat/configure-monitoring

# Bug fixes
fix/correct-inventory-validation
fix/update-firewall-rules
bugfix/ee-build-failure

# Hotfixes (emergency production fixes)
hotfix/security-patch
hotfix/critical-bug
release/v1.1.0-rc1

# Not:
new-feature
bug-fix
my-branch
```

### Commit Messages

```
# Format: {type}: {description}

# Good
feat: add webserver role with molecule tests
fix: correct database connection timeout
docs: update installation guide
chore: update dependencies
test: add integration tests for filters
refactor: simplify credential management

# Not:
added stuff
fixes
update
wip
```

### Commit Types

```
feat:     New feature
fix:      Bug fix
docs:     Documentation only
style:    Code style (formatting)
refactor: Code refactoring
test:     Adding tests
chore:    Maintenance tasks
ci:       CI/CD changes
perf:     Performance improvement
```

### Git Tags

**Environment-Specific Tags** (for promotion):

| Environment | Format | Example | Usage |
|-------------|--------|---------|-------|
| **Development** | `dev-<short-sha>` | `dev-abc123` | Automatic on merge |
| **QA** | `qa-v<major>.<minor>.<patch>` | `qa-v1.1.0` | Manual, semantic version |
| **Production** | `prod-v<major>.<minor>.<patch>` | `prod-v1.0.0` | Manual, with approval |

**Semantic Version Tags**:
```bash
# Format: v{major}.{minor}.{patch}[-{prerelease}]

v1.0.0        # Major release
v1.1.0        # Minor release (new features)
v1.1.1        # Patch release (bug fixes)
v2.0.0-rc1    # Release candidate
v2.0.0-beta   # Beta release

# Environment-specific examples:
dev-a1b2c3d    # Dev deployment (auto-generated)
qa-v1.2.0      # QA release
prod-v1.1.0    # Production release

# Not:
version-1.0    # Missing standard prefix
release-1.0    # Wrong prefix
1.0.0          # No 'v' prefix
latest         # Too generic, not immutable
```

**Tag Message Guidelines**:
```bash
# Good - Detailed tag message
git tag -a qa-v1.2.0 -m "Release 1.2.0 for QA testing

Features:
- Add webserver role with HA support
- Add database backup automation
- Update monitoring configuration

Testing:
- All molecule tests pass
- Integration tests successful
- Security scan clean

QA Ticket: QA-1234"

# Production tag with approval info
git tag -a prod-v1.1.0 -m "Production Release 1.1.0

Approved by: CAB
Change Ticket: CHG0001234
Approval Date: 2025-01-04

Rollback Plan: Revert to prod-v1.0.0"
```

**Tag Immutability Rules**:
- ✅ Dev tags: May be deleted after promotion (ephemeral)
- ❌ QA/Prod tags: **NEVER** delete or move
- ❌ **NEVER** force-push tags: `git push --force origin <tag>`
- ❌ **NEVER** reuse tag names on different commits

**See**: [BRANCHING-STRATEGY.md](./BRANCHING-STRATEGY.md) for complete workflow

---

## Examples by Context

### Complete Role Example

```
roles/webserver/
  defaults/main.yml:
    webserver_packages: []
    webserver_port: 80
    webserver_ssl_enabled: false
    
  tasks/main.yml:
    - name: Install web server packages
    - name: Configure web server
    - name: Ensure web server is started
    
  handlers/main.yml:
    - name: restart webserver
    - name: reload webserver
    
  templates/
    httpd.conf.j2
    index.html.j2
```

### Complete AAP Configuration

```yaml
controller_organizations:
  - name: "Engineering"

controller_teams:
  - name: "Platform Team"
    organization: "Engineering"

controller_credentials:
  - name: "Linux Servers"
    credential_type: "Machine"

controller_projects:
  - name: "Infrastructure Playbooks"
    scm_url: "https://github.com/org/infra-playbooks.git"

controller_templates:
  - name: "Deploy Web Application"
    project: "Application Deployment"
    playbook: "deploy-webapp.yml"
```

### Complete Kubernetes Resource

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: aap-controller-dev
  namespace: aap-dev
  labels:
    app: aap-controller
    component: api
    environment: dev
spec:
  selector:
    matchLabels:
      app: aap-controller
      component: api
```

---

## Validation Checklist

Use this checklist to validate naming:

- [ ] Name is descriptive and clear
- [ ] Follows the appropriate format for its type
- [ ] Uses correct case (lowercase, snake_case, etc.)
- [ ] Uses appropriate separators (hyphens, underscores)
- [ ] Includes necessary prefixes (role name for variables)
- [ ] Avoids abbreviations unless standard
- [ ] Follows environment suffixes where needed
- [ ] Matches existing patterns in codebase
- [ ] No special characters except allowed ones
- [ ] Length is reasonable (not too long/short)

---

## Anti-Patterns to Avoid

### 1. Inconsistent Separators

```
# Bad - mixing separators
web-server_config
database_backup-schedule

# Good - consistent
web_server_config
database_backup_schedule
```

### 2. Unclear Abbreviations

```
# Bad
cfg
db_bkp
sys_adm

# Good
config
database_backup
system_admin
```

### 3. Missing Context

```
# Bad
config.yml
template.j2
script.sh

# Good  
webserver-config.yml
httpd-template.j2
backup-database.sh
```

### 4. Negative Boolean Names

```
# Bad
disabled: false
no_ssl: false
skip_backup: false

# Good
enabled: true
ssl_enabled: true
perform_backup: true
```

---

## Tools and Automation

### Validation Scripts

```bash
# Check YAML file naming
find . -name "*.yaml" -o -name "*.yml" | while read file; do
  if [[ ! "$file" =~ ^[a-z0-9-]+\.(yaml|yml)$ ]]; then
    echo "Invalid filename: $file"
  fi
done

# Check variable naming in defaults
grep -r "^[A-Z]" roles/*/defaults/main.yml && \
  echo "Found uppercase variables (should be lowercase)"
```

### Pre-commit Hooks

See `.pre-commit-config.yaml` for automated naming validation.

---

## References

- [Ansible Best Practices](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html)
- [Kubernetes Naming Conventions](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/)
- [Semantic Versioning](https://semver.org/)
- [Conventional Commits](https://www.conventionalcommits.org/)

---

**Version**: 1.0  
**Last Updated**: 2025-10-30  
**Status**: ✅ Approved and enforced



