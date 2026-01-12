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

**STRICT CONVENTIONS**: All AAP resources must follow these exact formats. Names are **lowercase only**, **no spaces** (use underscores), and **include the org short name** for uniqueness.

### AAP Organization Naming

**Organization objects** use full descriptive names, but **when used as prefixes** in other resource names, use abbreviated forms. This ensures uniqueness within each AAP instance and helps admins identify which organization owns each resource.

```bash
# Organization objects (full names):
engineering    # Full name in AAP
platform       # Full name in AAP
operations     # Full name in AAP

# Prefix abbreviations (for other resources):
eng_     # Engineering organization (abbreviated)
plat_    # Platform team organization (abbreviated)
ops_     # Operations organization (abbreviated)
sec_     # Security team organization (abbreviated)
dev_     # Development organization (abbreviated)

# Examples of common abbreviations:
admin_   # Administration
dba_     # Database administration
net_     # Network team
infra_   # Infrastructure
```

### AAP Variable File Organization

AAP resources are organized into two categories based on their coupling and reusability:

#### Shared Resource Files (one file per object type)

Resources that are reused across multiple JTs are defined in dedicated files named after the object type. This prevents duplicate definitions and makes shared resources easy to find and update.

```
group_vars/all/
  credentials.yml           # All credentials (shared across JTs)
  inventories.yml           # All inventories (shared across JTs)
  schedules.yml             # All schedules
  teams.yml                 # All teams
  organizations.yml         # All organizations
  labels.yml                # All labels

# Variable naming in shared files: controller_{resource_type}_all
controller_credentials_all:
  - name: "eng_machine_ansible_linux_prod"
    ...
  - name: "ops_machine_ansible_linux_prod"
    ...

controller_inventories_all:
  - name: "eng_webservers_prod"
    ...
  - name: "ops_databases_prod"
    ...
```

#### JT Bundle Files (EE + Project + JT together)

Execution Environments, Projects, and Job Templates are tightly coupled and versioned together. These are defined in JT-specific files to ensure they stay in sync.

```
group_vars/all/
  jt_eng_deploy_webapp.yml              # EE + Project + JT for eng webapp
  jt_ops_backup_database_daily.yml      # EE + Project + JT for ops db backup

# Variable naming: controller_{resource_type}_{org}_{jt_suffix}
# The suffix MUST include org abbreviation to guarantee uniqueness
controller_execution_environments_eng_deploy_webapp:
  - name: "eng_automation_ee_26.01.06-0"
    ...

controller_projects_eng_deploy_webapp:
  - name: "eng_webapp_deploy_playbooks"
    ...

controller_templates_eng_deploy_webapp:
  - name: "eng_deploy_webapp_prod"
    ...
```

#### Why This Structure?

| Resource Type | File Location | Reason |
|---------------|---------------|--------|
| Credentials | `credentials.yml` | Shared by many JTs, defined once |
| Inventories | `inventories.yml` | Shared by many JTs, defined once |
| Schedules | `schedules.yml` | References JTs, easier to manage together |
| EE + Project + JT | `jt_*.yml` | Tightly coupled, versioned together |

**Benefits:**
- Shared resources dedupe naturally (defined once)
- JT bundles version together (EE change = project change = JT change)
- Easy to find where a resource is defined
- Clear separation of concerns

### Organizations

```
# Format: {aap_org_full_name}
# All lowercase, underscores only

engineering
platform
operations
security
development

# Not:
Engineering Team
eng
eng_team
```

### Teams

```
# Format: {aap_org_abbrev}_{purpose}
# All lowercase, underscores only

eng_admins
plat_engineers
ops_oncall
sec_auditors
dev_developers

# Not:
Platform Team
Development Engineers
eng_team
platform-engineers
```

### Credentials

Credentials require identity information to ensure uniqueness. Multiple credentials may access the same target with different users/service accounts.

```
# Format: {org}_{type}_{identity}_{target}
# All lowercase, underscores only
# Identity = username, service account, or key identifier

eng_machine_ansible_linux_prod          # ansible user -> prod linux servers
eng_machine_svc_deploy_linux_prod       # svc_deploy user -> prod linux servers
plat_scm_git_github_main                # git user -> github main org
plat_scm_svc_cicd_github_main           # svc_cicd user -> github main org
ops_cloud_svc_backup_aws_prod           # svc_backup role -> AWS prod account
ops_registry_svc_builder_quay_io        # svc_builder -> quay.io registry
sec_vault_app_secrets_hashicorp_main    # app_secrets policy -> HashiCorp Vault
plat_k8s_sa_admin_ocp_prod              # sa_admin service account -> OCP prod

# Type abbreviations (keep short for readability):
# machine_   - SSH/Machine credentials
# scm_       - Source control (git)
# cloud_     - Cloud provider (AWS, Azure, GCP)
# registry_  - Container registry
# vault_     - Secret management
# k8s_       - Kubernetes/OpenShift API
# token_     - API tokens
# password_  - Username/password combos

# Identity patterns:
# {username}     - Human user (ansible, admin)
# svc_{name}     - Service account (svc_deploy, svc_cicd)
# sa_{name}      - Kubernetes service account (sa_admin)
# app_{name}     - Application identity (app_secrets)

# Target patterns:
# {platform}_{env}    - linux_prod, aws_prod, ocp_dev
# {service}_{scope}   - github_main, quay_io, hashicorp_main

# Not:
Linux Servers                    # No spaces
GitHub - Main                    # No spaces or special chars
eng_machine_linux_servers        # Missing identity (which user?)
linux-servers                    # Wrong separator
```

### Projects

Projects typically map 1:1 to git repositories. Include the repository purpose and scope to ensure uniqueness.

```
# Format: {org}_{domain}_{purpose}_{type}
# All lowercase, underscores only
# Domain = application/system area this project manages

eng_webapp_deploy_playbooks             # Webapp deployment playbooks
eng_webapp_config_playbooks             # Webapp configuration playbooks
plat_infra_core_config                  # Core infrastructure config
plat_infra_network_config               # Network infrastructure config
ops_database_backup_playbooks           # Database backup automation
ops_database_restore_playbooks          # Database restore automation
sec_compliance_scan_playbooks           # Compliance scanning
sec_vulnerability_remediate_playbooks   # Vulnerability remediation
dev_testing_molecule_framework          # Molecule testing framework

# Domain prefixes (what system/app area):
# webapp_        - Web application
# infra_         - Infrastructure
# database_      - Database systems
# network_       - Network equipment
# container_     - Container/Kubernetes
# monitoring_    - Monitoring systems
# security_      - Security tooling

# Purpose (what action/function):
# deploy_        - Deployment automation
# config_        - Configuration management
# backup_        - Backup operations
# restore_       - Restore operations
# scan_          - Scanning/auditing
# remediate_     - Fix/remediation
# patch_         - Patching

# Type suffixes:
# _playbooks     - Ansible playbooks repository
# _config        - Configuration repository
# _framework     - Testing/development framework
# _collection    - Ansible collection

# Not:
Infrastructure Playbooks           # No spaces
eng_automation_playbooks           # Too generic (which automation?)
App Deploy                         # No spaces
eng-playbooks                      # Wrong separator
```

### Inventories

Inventories should clearly identify the target hosts and their scope/environment to prevent ambiguity at scale.

```
# Format: {org}_{target}_{scope}
# All lowercase, underscores only
# Scope = functional grouping, region, or organizational separation

eng_webservers_app                     # Application web servers
eng_webservers_api                     # API web servers
plat_databases_primary                 # Primary database servers
plat_databases_replica                 # Replica database servers
ops_appservers_tier1                   # Tier 1 application servers
ops_appservers_tier2                   # Tier 2 application servers
sec_network_firewalls_perimeter        # Perimeter firewalls
sec_network_switches_core              # Core network switches
dev_containers_ocp_cluster             # OCP cluster containers

# Target (what hosts):
# webservers_        - Web application servers
# databases_         - Database servers
# appservers_        - Application servers
# containers_        - Container platforms
# network_           - Network equipment (prefix for sub-types)
# linux_             - Linux systems
# windows_           - Windows systems

# Scope suffixes (for functional separation):
# _app / _api / _web                  - Application components
# _primary / _replica / _backup       - Database roles
# _tier1 / _tier2 / _tier3            - Service tiers
# _perimeter / _core / _edge          - Network zones
# _cluster / _node / _master          - Infrastructure roles

# Not:
Production                         # No context
Dev Servers                        # No spaces
eng_webservers                     # Missing scope (which environment?)
prod                               # Too generic
eng-prod-servers                   # Wrong separator
```

### Job Templates

Job templates need enough context to be unique across 100+ templates. Include what is being done, to what, and the scope.

```
# Format: {org}_{action}_{target}_{scope}
# All lowercase, underscores only
# Scope = frequency, functional variant, or operational context

eng_deploy_webapp_canary                # Canary deployment variant
plat_configure_webservers_ssl           # Configure SSL on web servers
ops_backup_database_full_daily          # Daily full database backup
ops_backup_database_incr_hourly         # Hourly incremental backup
ops_restore_database_primary            # Restore primary database
sec_scan_compliance_cis_weekly          # Weekly CIS compliance scan
sec_scan_vulnerability_critical         # Critical vulnerability scan
dev_validate_deployment_smoke           # Smoke test validation
dev_validate_deployment_integration     # Integration test validation
plat_patch_systems_security_monthly     # Monthly security patching
plat_monitor_services_health            # Health monitoring for services

# Action prefixes:
# deploy_      - Deploy applications/services
# configure_   - Configure systems/services
# backup_      - Create backups
# restore_     - Restore from backups
# patch_       - Apply patches/updates
# scan_        - Run security/compliance scans
# monitor_     - Monitoring/health checks
# cleanup_     - Cleanup operations
# restart_     - Service restarts
# validate_    - Validation checks
# provision_   - Provision new resources
# decommission_ - Remove/decommission resources

# Scope suffixes (pick what makes it unique):
# Frequency:   _daily / _hourly / _weekly / _monthly
# Variant:     _full / _incr / _canary / _blue / _green
# Role:        _primary / _replica / _master / _worker
# Type:        _cis / _stig / _pci (compliance frameworks)
#              _smoke / _integration / _e2e (test types)
# Function:    _health / _performance / _security

# Not:
Deploy Web Application             # No spaces
deploy-app                         # Wrong separator
eng_deploy_webapp                  # Missing scope (to where? how often?)
webapp-deploy                      # Wrong format
```

### Workflow Templates

```
# Format: {aap_org_abbrev}_{workflow}_{scope}_{purpose}
# All lowercase, underscores only

eng_workflow_full_deployment
plat_workflow_infrastructure_setup
ops_workflow_disaster_recovery
sec_workflow_compliance_audit

# Workflow prefixes:
# workflow_  - Workflow template

# Scope suffixes:
# _full      - Complete end-to-end workflow
# _infrastructure - Infrastructure-focused
# _application - Application-focused
# _security  - Security-focused

# Purpose suffixes:
# _deployment - Deployment workflows
# _setup      - Setup/initialization
# _recovery   - Recovery procedures
# _audit      - Audit/compliance workflows
# _maintenance - Maintenance workflows

# Not:
Full Application Deployment
full-deployment
eng-full-deploy-workflow
```

### Execution Environments

```
# Format: {aap_org_abbrev}_{purpose}_ee_{YY.MM.DD-PATCH}
# All lowercase, underscores only

eng_automation_ee_26.01.06-0
plat_minimal_ee_26.01.06-0
ops_security_scan_ee_26.01.06-0
sec_network_automation_ee_26.01.06-0
dev_database_admin_ee_26.01.06-0

# Purpose prefixes:
# automation_     - General automation tasks
# minimal_        - Minimal dependencies
# security_scan_  - Security scanning tools
# network_automation_ - Network automation
# database_admin_ - Database administration
# monitoring_     - Monitoring tools
# development_    - Development/testing tools

# Tag format: YY.MM.DD-PATCH (Calendar Versioning)
# YY - Two-digit year (26 = 2026)
# MM - Two-digit month (01 = January)
# DD - Two-digit day (06 = 6th)
# PATCH - Hotfix number (0 = initial, 1+ = hotfixes)

# Always include _ee_ in the middle

# Not:
Production EE
prod-ee
eng-ee
ee-automation
eng_automation_ee_dev
```

### Schedules

Schedules should reference their job template clearly and include timing context. The schedule name should make it obvious which JT it triggers.

```
# Format: {org}_{freq}_{jt_action}_{jt_target}_{variant}
# All lowercase, underscores only
# Should mirror the JT name with frequency prepended

ops_daily_backup_database_full          # Daily trigger for ops_backup_database_full_daily JT
ops_hourly_backup_database_incr         # Hourly trigger for ops_backup_database_incr_hourly JT
eng_nightly_deploy_webapp_canary        # Nightly canary deployment
plat_weekly_patch_linux_systems         # Weekly patching for linux systems
sec_weekly_scan_compliance_cis          # Weekly CIS compliance scan
sec_monthly_scan_vulnerability_full     # Monthly full vuln scan
dev_hourly_validate_deployment_smoke    # Hourly smoke tests

# Frequency (after org, before JT reference):
# hourly_   - Every hour
# daily_    - Every day
# nightly_  - Once per night (specific time)
# weekly_   - Every week
# monthly_  - Every month
# quarterly_ - Every quarter

# The rest should mirror the Job Template name:
# {action}_{target}_{scope/variant}

# Relationship to JT names:
# Schedule: ops_daily_backup_database_full
# JT:       ops_backup_database_full_daily
#           ^^^-matches-^^^^^^^^^^^^^^^^

# Not:
Nightly Database Backup            # No spaces
backup-schedule                    # Wrong separator, too generic
ops_daily_backup                   # Missing target details
ops_backup_database                # Same as JT name (ambiguous)
daily_backup                       # Missing org
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
release/25.01.05-0

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

**CalVer Format** (YY.MM.DD-PATCH):

This platform uses **Calendar Versioning** with a single tag promoted across all environments.

| Component | Description | Example |
|-----------|-------------|---------|
| **YY** | Two-digit year | `26` (2026) |
| **MM** | Two-digit month | `01` (January) |
| **DD** | Two-digit day | `06` (6th) |
| **PATCH** | Hotfix number | `0` (first), `1` (hotfix) |

**Tag Examples**:
```bash
# Format: YY.MM.DD-PATCH
26.01.06-0    # January 6, 2026 - Initial release
26.01.06-1    # January 6, 2026 - Hotfix
26.01.07-0    # January 7, 2026 - New release
26.02.15-0    # February 15, 2026

# Same tag promotes through all environments:
# dev → qa → prod (tracked via release manifest)

# Not:
1.0.0         # Wrong format (SemVer)
v26.01.06-0   # Wrong format (version prefix)
latest        # Not immutable
26.1.6.0      # Missing leading zeros
```

**Tag Message Guidelines**:
```bash
# Good - Detailed tag message
git tag -a 25.01.05-0 -m "Release January 5, 2025

Features:
- Add webserver role with HA support
- Add database backup automation
- Update monitoring configuration

Testing:
- All molecule tests pass
- Integration tests successful
- Security scan clean

Rollback: Revert to 25.01.04-0"
```

**Tag Immutability Rules**:
- ✅ Same tag used across dev → qa → prod
- ❌ **NEVER** delete or move tags
- ❌ **NEVER** force-push tags: `git push --force origin <tag>`
- ❌ **NEVER** reuse tag names on different commits
- ✅ For hotfixes, increment PATCH: `25.01.05-1`

**See**: [GIT-WORKFLOW.md](./GIT-WORKFLOW.md) for complete workflow

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

### Complete AAP Configuration (File Structure)

```
group_vars/all/
├── organizations.yml          # controller_organizations_all
├── teams.yml                  # controller_teams_all
├── credentials.yml            # controller_credentials_all (shared)
├── inventories.yml            # controller_inventories_all (shared)
├── schedules.yml              # controller_schedules_all (shared)
├── jt_eng_deploy_webapp.yml   # EE + Project + JT bundle
└── jt_ops_backup_db_daily.yml # EE + Project + JT bundle
```

**Shared resource file (credentials.yml):**
```yaml
controller_credentials_all:
  - name: "eng_machine_ansible_linux"             # {org}_{type}_{identity}_{target}
    credential_type: "Machine"
    organization: "engineering"
  - name: "eng_scm_git_github"
    credential_type: "Source Control"
    organization: "engineering"
```

**JT bundle file (jt_eng_deploy_webapp.yml):**
```yaml
# EE + Project + JT versioned together
controller_execution_environments_eng_deploy_webapp:
  - name: "eng_automation_ee_26.01.06-0"
    image: "quay.io/company/eng-ee@sha256:26.01.06-0"
    credential: "eng_registry_svc_builder_quay_io"

controller_projects_eng_deploy_webapp:
  - name: "eng_webapp_deploy_playbooks"
    scm_url: "https://github.com/company/eng-webapp-deploy-playbooks.git"
    credential: "eng_scm_git_github_main"
    organization: "engineering"

controller_templates_eng_deploy_webapp:
  - name: "eng_deploy_webapp_canary"
    project: "eng_webapp_deploy_playbooks"
    inventory: "eng_webservers_app"               # Defined in inventories.yml
    playbook: "deploy-webapp.yml"
    execution_environment: "eng_automation_ee_26.01.06-0"
    credentials:
      - "eng_machine_ansible_linux"               # Defined in credentials.yml
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
