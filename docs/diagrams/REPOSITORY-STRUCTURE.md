# Repository Structure Diagrams

**Git Repository Organization and Relationships**

## Repository Overview

```mermaid
graph TB
    subgraph "Platform Repositories"
        CC[cluster-config<br/>📦 Kubernetes/ArgoCD/Tekton]
        AAP[aap-config-as-code<br/>⚙️ AAP Configuration]
    end

    subgraph "Application Repositories"
        COL[automation-collection<br/>📚 Ansible Content]
        EE[automation-ee<br/>🐳 Execution Environments]
    end

    subgraph "Release Repository"
        REL[automation-release-manifest<br/>📋 Version Tracking]
    end

    CC -->|Deploys| AAP
    COL -->|Builds| REL
    EE -->|Builds| REL
    AAP -->|Uses| REL

    style CC fill:#ffadad
    style AAP fill:#ffd6a5
    style COL fill:#fdffb6
    style EE fill:#caffbf
    style REL fill:#9bf6ff
```

---

## cluster-config Repository

**Purpose**: OpenShift cluster configuration (Platform Loop)

```mermaid
graph TB
    ROOT[cluster-config/]

    ROOT --> ARGO[argocd/<br/>ArgoCD Applications]
    ROOT --> TEKTON[tekton/<br/>Pipeline Definitions]
    ROOT --> NAMESPACES[namespaces/<br/>Namespace Resources]
    ROOT --> OPERATORS[operators/<br/>Operator Configs]
    ROOT --> RBAC[rbac/<br/>RBAC Resources]
    ROOT --> NETWORK[network/<br/>Network Policies]
    ROOT --> GITHUB[.github/<br/>CI/CD Workflows]
    ROOT --> DOCS[docs/<br/>Documentation]

    ARGO --> ARGO_APPS[applications/<br/>App Definitions]
    ARGO --> ARGO_PROJ[projects/<br/>ArgoCD Projects]

    TEKTON --> TEK_PIPES[pipelines/<br/>Pipeline Resources]
    TEKTON --> TEK_TASKS[tasks/<br/>Task Definitions]
    TEKTON --> TEK_TRIG[triggers/<br/>Event Listeners]

    NAMESPACES --> NS_DEV[dev/<br/>Dev Resources]
    NAMESPACES --> NS_QA[qa/<br/>QA Resources]
    NAMESPACES --> NS_PROD[prod/<br/>Prod Resources]

    style ROOT fill:#ff6b6b
    style ARGO fill:#4ecdc4
    style TEKTON fill:#ffe66d
```

### Directory Structure

```
cluster-config/
├── argocd/
│   ├── applications/
│   │   ├── aap-dev.yaml              # AAP Dev instance
│   │   ├── aap-qa.yaml               # AAP QA instance
│   │   ├── aap-prod.yaml             # AAP Prod instance
│   │   └── tekton-pipelines.yaml    # Tekton pipeline app
│   ├── projects/
│   │   ├── platform.yaml             # Platform project
│   │   └── automation.yaml           # Automation project
│   └── appsets/
│       └── environment-appset.yaml   # Environment app set
│
├── tekton/
│   ├── pipelines/
│   │   ├── build-collection.yaml    # Collection build
│   │   ├── build-ee.yaml            # EE image build
│   │   ├── promote-qa.yaml          # QA promotion
│   │   └── promote-prod.yaml        # Prod promotion
│   ├── tasks/
│   │   ├── ansible-test.yaml        # Ansible testing
│   │   ├── build-image.yaml         # Image building
│   │   └── create-manifest.yaml     # Manifest creation
│   └── triggers/
│       ├── github-webhook.yaml      # GitHub integration
│       └── eventlisteners.yaml      # Event listeners
│
├── namespaces/
│   ├── platform/
│   │   └── namespace.yaml
│   ├── aap-dev/
│   │   ├── namespace.yaml
│   │   ├── limitrange.yaml
│   │   └── resourcequota.yaml
│   ├── aap-qa/
│   │   └── ...
│   └── aap-prod/
│       └── ...
│
├── operators/
│   ├── aap-operator.yaml            # AAP Operator
│   ├── postgresql-operator.yaml    # PostgreSQL
│   └── vault-operator.yaml          # Vault
│
├── rbac/
│   ├── platform-admin-role.yaml
│   ├── developer-role.yaml
│   └── automation-sa.yaml
│
├── network/
│   ├── networkpolicies/
│   │   ├── deny-all-default.yaml
│   │   ├── allow-aap-postgres.yaml
│   │   └── allow-external-api.yaml
│   └── routes/
│       ├── aap-dev-route.yaml
│       └── ...
│
├── .github/workflows/
│   ├── pre-commit.yml
│   ├── validate-kubernetes.yml
│   └── pr-validation.yml
│
├── .pre-commit-config.yaml
├── .yamllint
└── README.md
```

---

## aap-config-as-code Repository

**Purpose**: AAP configuration as code

```mermaid
graph TB
    ROOT[aap-config-as-code/]

    ROOT --> ENV[environments/<br/>Environment Configs]
    ROOT --> SHARED[shared/<br/>Shared Resources]
    ROOT --> PLAYBOOKS[playbooks/<br/>Configuration Playbooks]
    ROOT --> INVENTORY[inventory/<br/>AAP Inventories]
    ROOT --> GITHUB[.github/<br/>CI/CD Workflows]
    ROOT --> SCRIPTS[scripts/<br/>Helper Scripts]

    ENV --> ENV_DEV[dev/<br/>Dev Configuration]
    ENV --> ENV_QA[qa/<br/>QA Configuration]
    ENV --> ENV_PROD[prod/<br/>Prod Configuration]

    SHARED --> SH_CRED[credentials/<br/>Credential Types]
    SHARED --> SH_TEAMS[teams/<br/>Team Definitions]
    SHARED --> SH_NOTIF[notifications/<br/>Notifications]

    style ROOT fill:#ffd6a5
    style ENV fill:#4ecdc4
    style SHARED fill:#ffe66d
```

### Directory Structure

```
aap-config-as-code/
├── environments/
│   ├── dev/
│   │   ├── organizations.yml
│   │   ├── projects.yml
│   │   ├── inventories.yml
│   │   ├── job-templates.yml
│   │   ├── workflow-templates.yml
│   │   └── credentials.yml
│   ├── qa/
│   │   └── ...
│   └── prod/
│       └── ...
│
├── shared/
│   ├── credential-types/
│   │   ├── vault-credential-type.yml
│   │   └── cloud-credential-type.yml
│   ├── teams/
│   │   ├── platform-team.yml
│   │   ├── developers-team.yml
│   │   └── operations-team.yml
│   ├── notifications/
│   │   ├── slack-notification.yml
│   │   └── email-notification.yml
│   └── execution-environments/
│       └── ee-list.yml
│
├── playbooks/
│   ├── configure-aap.yml           # Main playbook
│   ├── configure-organizations.yml
│   ├── configure-projects.yml
│   ├── configure-inventories.yml
│   ├── configure-job-templates.yml
│   └── configure-workflows.yml
│
├── inventory/
│   ├── dev/
│   │   └── hosts.yml
│   ├── qa/
│   │   └── hosts.yml
│   └── prod/
│       └── hosts.yml
│
├── scripts/
│   ├── validate-aap-config.py      # Config validator
│   ├── backup-aap.sh              # Backup script
│   └── diff-configs.sh            # Config diff tool
│
├── .github/workflows/
│   ├── ansible-lint.yml
│   ├── deploy-dev.yml
│   └── pr-validation.yml
│
├── .pre-commit-config.yaml
├── .ansible-lint
└── README.md
```

---

## automation-collection Repository

**Purpose**: Custom Ansible collection (Application Loop)

```mermaid
graph TB
    ROOT[automation-collection/]

    ROOT --> PLUGINS[plugins/<br/>Collection Plugins]
    ROOT --> ROLES[roles/<br/>Ansible Roles]
    ROOT --> PLAYBOOKS[playbooks/<br/>Example Playbooks]
    ROOT --> TESTS[tests/<br/>Test Suite]
    ROOT --> DOCS[docs/<br/>Documentation]
    ROOT --> GITHUB[.github/<br/>CI/CD Workflows]

    PLUGINS --> MOD[modules/<br/>Custom Modules]
    PLUGINS --> FILT[filter/<br/>Filter Plugins]
    PLUGINS --> LOOK[lookup/<br/>Lookup Plugins]

    ROLES --> ROLE_WEB[webserver/<br/>Web Server Role]
    ROLES --> ROLE_DB[database/<br/>Database Role]
    ROLES --> ROLE_MON[monitoring/<br/>Monitoring Role]

    TESTS --> TEST_UNIT[unit/<br/>Unit Tests]
    TESTS --> TEST_INT[integration/<br/>Integration Tests]
    TESTS --> TEST_MOL[molecule/<br/>Molecule Scenarios]

    style ROOT fill:#fdffb6
    style PLUGINS fill:#4ecdc4
    style ROLES fill:#ffe66d
    style TESTS fill:#95e1d3
```

### Directory Structure

```
automation-collection/
├── plugins/
│   ├── modules/
│   │   ├── sample_module.py
│   │   ├── manage_service.py
│   │   └── config_manager.py
│   ├── filter/
│   │   ├── text_filters.py
│   │   └── data_filters.py
│   ├── lookup/
│   │   ├── vault_secrets.py
│   │   └── config_lookup.py
│   └── module_utils/
│       └── common.py
│
├── roles/
│   ├── webserver/
│   │   ├── tasks/
│   │   │   └── main.yml
│   │   ├── handlers/
│   │   │   └── main.yml
│   │   ├── templates/
│   │   │   ├── httpd.conf.j2
│   │   │   └── index.html.j2
│   │   ├── defaults/
│   │   │   └── main.yml
│   │   ├── vars/
│   │   │   ├── RedHat.yml
│   │   │   └── Debian.yml
│   │   ├── meta/
│   │   │   ├── main.yml
│   │   │   └── argument_specs.yml
│   │   ├── molecule/
│   │   │   ├── default/
│   │   │   ├── centos/
│   │   │   └── ubuntu/
│   │   └── README.md
│   ├── database/
│   │   └── ...
│   └── monitoring/
│       └── ...
│
├── playbooks/
│   ├── deploy-webserver.yml
│   ├── deploy-database.yml
│   └── full-stack-deploy.yml
│
├── tests/
│   ├── unit/
│   │   ├── test_modules.py
│   │   └── test_filters.py
│   ├── integration/
│   │   ├── test_integration.py
│   │   └── targets/
│   │       └── sample_module/
│   └── molecule/
│       └── shared-scenarios/
│
├── docs/
│   ├── modules/
│   │   └── sample_module.md
│   ├── roles/
│   │   └── webserver.md
│   └── guides/
│       └── getting-started.md
│
├── .github/workflows/
│   ├── test-sanity-units.yml
│   ├── integration-tests.yml
│   └── molecule-test.yml
│
├── galaxy.yml                      # Collection metadata
├── .pre-commit-config.yaml
├── .ansible-lint
└── README.md
```

---

## automation-ee Repository

**Purpose**: Execution environment definitions

```mermaid
graph TB
    ROOT[automation-ee/]

    ROOT --> BASE[base/<br/>Base EE Definition]
    ROOT --> CUSTOM[custom/<br/>Custom EE Variants]
    ROOT --> SCRIPTS[scripts/<br/>Build Scripts]
    ROOT --> TESTS[tests/<br/>Test Scripts]
    ROOT --> GITHUB[.github/<br/>CI/CD Workflows]

    CUSTOM --> NET[network-ee/<br/>Network Automation]
    CUSTOM --> CLOUD[cloud-ee/<br/>Cloud Automation]
    CUSTOM --> SEC[security-ee/<br/>Security Automation]

    style ROOT fill:#caffbf
    style BASE fill:#4ecdc4
    style CUSTOM fill:#ffe66d
```

### Directory Structure

```
automation-ee/
├── base/
│   ├── execution-environment.yml    # Base EE definition
│   ├── requirements.yml            # Ansible deps
│   ├── requirements.txt            # Python deps
│   ├── bindep.txt                  # System deps
│   └── README.md
│
├── custom/
│   ├── network-ee/
│   │   ├── execution-environment.yml
│   │   ├── requirements.yml        # cisco.ios, etc.
│   │   └── requirements.txt
│   ├── cloud-ee/
│   │   ├── execution-environment.yml
│   │   ├── requirements.yml        # amazon.aws, etc.
│   │   └── requirements.txt        # boto3, etc.
│   └── security-ee/
│       ├── execution-environment.yml
│       └── requirements.yml
│
├── scripts/
│   ├── build-ee.sh                 # Build script
│   ├── test-ee.sh                  # Test script
│   ├── generate-sbom.sh            # SBOM generation
│   └── scan-vulnerabilities.sh     # Security scan
│
├── tests/
│   ├── test-basic-ee.yml           # Basic tests
│   ├── test-module-imports.yml     # Import tests
│   └── fixtures/
│       └── test-playbook.yml
│
├── .github/workflows/
│   ├── validate-ee.yml
│   ├── build-ee.yml
│   └── sbom-generation.yml
│
├── .pre-commit-config.yaml
└── README.md
```

---

## automation-release-manifest Repository

**Purpose**: Atomic version tracking

```mermaid
graph TB
    ROOT[automation-release-manifest/]

    ROOT --> RELEASES[releases/<br/>Release Manifests]
    ROOT --> SCHEMAS[schemas/<br/>JSON Schemas]
    ROOT --> SCRIPTS[scripts/<br/>Validation Scripts]
    ROOT --> GITHUB[.github/<br/>CI/CD Workflows]

    RELEASES --> DEV[dev/<br/>Dev Releases]
    RELEASES --> QA[qa/<br/>QA Releases]
    RELEASES --> PROD[prod/<br/>Prod Releases]

    style ROOT fill:#9bf6ff
    style RELEASES fill:#4ecdc4
    style SCHEMAS fill:#ffe66d
```

### Directory Structure

```
automation-release-manifest/
├── releases/
│   ├── dev/
│   │   ├── release-dev-20250104-abc123.yaml
│   │   ├── release-dev-20250103-xyz789.yaml
│   │   └── ...
│   ├── qa/
│   │   ├── release-qa-20250104-001.yaml
│   │   ├── release-qa-20250103-001.yaml
│   │   └── ...
│   └── prod/
│       ├── release-prod-20250104-001.yaml
│       ├── release-prod-20250101-001.yaml
│       └── ...
│
├── schemas/
│   ├── release-manifest-schema.json  # JSON Schema
│   └── examples/
│       ├── minimal-manifest.yaml
│       └── complete-manifest.yaml
│
├── scripts/
│   ├── create-manifest.py          # Manifest creator
│   ├── validate-manifest-schema.py # Schema validator
│   ├── promote-manifest.py         # Promotion tool
│   └── rollback-manifest.py        # Rollback tool
│
├── .github/workflows/
│   ├── validate-manifest.yml
│   └── auto-label.yml
│
├── .pre-commit-config.yaml
└── README.md
```

---

## Repository Relationships

### Build Flow

```mermaid
graph LR
    subgraph "Source"
        COL[automation-collection<br/>Ansible Content]
        EE[automation-ee<br/>EE Definitions]
        AAP[aap-config-as-code<br/>AAP Config]
    end

    subgraph "Build System"
        TEK[Tekton Pipelines<br/>from cluster-config]
    end

    subgraph "Artifacts"
        GALAXY[Ansible Galaxy<br/>Collections]
        QUAY[Quay.io<br/>Container Images]
    end

    subgraph "Tracking"
        REL[automation-release-manifest<br/>Version Manifests]
    end

    COL -->|Build| TEK
    EE -->|Build| TEK
    AAP -->|Validate| TEK

    TEK -->|Publish| GALAXY
    TEK -->|Publish| QUAY
    TEK -->|Create| REL

    style TEK fill:#4ecdc4
    style REL fill:#9bf6ff
```

### Deployment Flow

```mermaid
graph TB
    subgraph "Configuration"
        CC[cluster-config<br/>Kubernetes Resources]
        AAP_CONFIG[aap-config-as-code<br/>AAP Configuration]
    end

    subgraph "GitOps"
        ARGO[ArgoCD<br/>Continuous Sync]
    end

    subgraph "Cluster"
        K8S[Kubernetes<br/>Resources]
        AAP_INST[AAP<br/>Instances]
    end

    subgraph "Version Control"
        REL[automation-release-manifest<br/>Versions]
    end

    CC -->|Sync| ARGO
    AAP_CONFIG -->|Sync| ARGO
    REL -->|Track| ARGO

    ARGO -->|Apply| K8S
    ARGO -->|Configure| AAP_INST

    style ARGO fill:#ff6b6b
    style K8S fill:#95e1d3
```

---

## Access Patterns

### Developer Daily Workflow

```mermaid
graph TB
    START[Start Work]

    START --> COL[Clone automation-collection]
    COL --> DEV[Develop Role/Module]
    DEV --> TEST[Run Local Tests]
    TEST --> COMMIT[Commit & Push]
    COMMIT --> PR[Create PR]
    PR --> REVIEW[Code Review]
    REVIEW --> MERGE[Merge to Main]
    MERGE --> AUTO[Tekton Auto-Build]
    AUTO --> DEPLOY[Auto-Deploy to Dev]

    style COL fill:#fdffb6
    style TEST fill:#95e1d3
    style DEPLOY fill:#4ecdc4
```

### Platform Engineer Daily Workflow

```mermaid
graph TB
    START[Start Work]

    START --> CC[Clone cluster-config]
    CC --> MODIFY[Modify K8s Resources]
    MODIFY --> VALIDATE[Validate Locally]
    VALIDATE --> COMMIT[Commit & Push]
    COMMIT --> PR[Create PR]
    PR --> REVIEW[Code Review]
    REVIEW --> MERGE[Merge to Main]
    MERGE --> SYNC[ArgoCD Auto-Sync]
    SYNC --> APPLY[Applied to Cluster]

    style CC fill:#ffadad
    style VALIDATE fill:#95e1d3
    style SYNC fill:#ff6b6b
```

### Release Manager Daily Workflow

```mermaid
graph TB
    START[Review Releases]

    START --> CHECK[Check Dev Manifests]
    CHECK --> VALIDATE[Validate QA Readiness]
    VALIDATE --> PROMOTE[Trigger QA Promotion]
    PROMOTE --> TEST[Monitor QA Tests]
    TEST --> APPROVE[QA Sign-off]
    APPROVE --> CAB[Submit to CAB]
    CAB --> PROD_PROMOTE[Promote to Prod]
    PROD_PROMOTE --> VERIFY[Verify Production]

    style CHECK fill:#9bf6ff
    style APPROVE fill:#ffd93d
    style PROD_PROMOTE fill:#95e1d3
```

---

## Repository Statistics

```mermaid
pie title Repository Distribution by Purpose
    "Platform Configuration (cluster-config)" : 25
    "AAP Configuration (aap-config-as-code)" : 20
    "Ansible Content (automation-collection)" : 30
    "Execution Environments (automation-ee)" : 15
    "Release Tracking (automation-release-manifest)" : 10
```

---

## Branching Strategy

### Main Branch Flow

```mermaid
gitGraph
    commit id: "Initial"
    branch feature/add-role
    checkout feature/add-role
    commit id: "Add webserver role"
    commit id: "Add tests"
    checkout main
    merge feature/add-role tag: "dev-abc123"
    commit id: "Build triggered" type: HIGHLIGHT
    branch release/qa
    checkout release/qa
    commit id: "QA manifest" tag: "qa-001"
    checkout main
    merge release/qa
    branch release/prod
    checkout release/prod
    commit id: "Prod manifest" tag: "prod-001"
    checkout main
    merge release/prod
```

---

## Summary

### Repository Purposes

| Repository | Type | Purpose | Managed By |
|------------|------|---------|------------|
| **cluster-config** | Platform | Kubernetes/GitOps config | Platform Team |
| **aap-config-as-code** | Platform | AAP configuration | Automation Team |
| **automation-collection** | Application | Ansible content | Developers |
| **automation-ee** | Application | Container images | Developers |
| **automation-release-manifest** | Tracking | Version coordination | Release Mgmt |

### Key Characteristics

- ✅ **Separation of Concerns**: Each repo has clear purpose
- ✅ **Independent Development**: Teams work in parallel
- ✅ **Coordinated Releases**: Manifests unite all components
- ✅ **Full Traceability**: Git history tracks everything
- ✅ **Constitutional Compliance**: All 5 articles enforced

---

**Result**: Clean, maintainable, scalable repository structure

