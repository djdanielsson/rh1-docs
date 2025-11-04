# Platform Architecture

**Cloud-Native Ansible Lifecycle Platform - High-Level Architecture**

## Overall Platform Architecture

```mermaid
graph TB
    subgraph "Developer Workstation"
        DEV[Developer]
        IDE[VS Code/Cursor<br/>Dev Container]
        GIT[Git Client]
    end

    subgraph "GitHub"
        REPO[Git Repositories]
        ACTIONS[GitHub Actions<br/>Testing & Linting]
        ARTIFACTS[Artifacts & Reports]
    end

    subgraph "OpenShift Cluster"
        subgraph "Platform Loop - GitOps"
            ARGOCD[ArgoCD<br/>Continuous Deployment]
            K8S_APPS[Kubernetes Resources<br/>AAP, Operators, RBAC]
        end

        subgraph "Application Loop - CI/CD"
            TEKTON[Tekton Pipelines<br/>Build & Release]
            REGISTRY[Container Registry<br/>Quay.io]
            GALAXY[Collection Store<br/>Ansible Galaxy/Hub]
        end

        subgraph "Automation Platform"
            AAP_DEV[AAP Dev]
            AAP_QA[AAP QA]
            AAP_PROD[AAP Prod]
            EE[Execution Environments]
        end
    end

    subgraph "Release Artifacts"
        MANIFEST[Release Manifests<br/>Atomic Versions]
        COLLECTION[Ansible Collections]
        IMAGES[Container Images]
    end

    %% Developer Flow
    DEV -->|Code| IDE
    IDE -->|Test Locally| IDE
    IDE -->|Commit| GIT
    GIT -->|Push| REPO

    %% GitHub Actions Flow
    REPO -->|Trigger| ACTIONS
    ACTIONS -->|Test & Lint| ACTIONS
    ACTIONS -->|Report| ARTIFACTS

    %% Platform Loop (GitOps)
    REPO -->|Sync| ARGOCD
    ARGOCD -->|Deploy| K8S_APPS
    K8S_APPS -->|Provision| AAP_DEV
    K8S_APPS -->|Provision| AAP_QA
    K8S_APPS -->|Provision| AAP_PROD

    %% Application Loop (CI/CD)
    REPO -->|Merge to Main| TEKTON
    TEKTON -->|Build Collections| COLLECTION
    TEKTON -->|Build EEs| IMAGES
    TEKTON -->|Create| MANIFEST
    COLLECTION -->|Store| GALAXY
    IMAGES -->|Store| REGISTRY
    MANIFEST -->|Track Versions| MANIFEST

    %% Deployment
    MANIFEST -->|Promote Dev| AAP_DEV
    MANIFEST -->|Promote QA| AAP_QA
    MANIFEST -->|Promote Prod| AAP_PROD
    GALAXY -->|Pull Collections| AAP_DEV
    GALAXY -->|Pull Collections| AAP_QA
    GALAXY -->|Pull Collections| AAP_PROD
    REGISTRY -->|Pull EEs| EE
    EE -->|Run Jobs| AAP_DEV
    EE -->|Run Jobs| AAP_QA
    EE -->|Run Jobs| AAP_PROD

    style DEV fill:#e1f5ff
    style ARGOCD fill:#ff6b6b
    style TEKTON fill:#4ecdc4
    style AAP_PROD fill:#ffe66d
    style MANIFEST fill:#95e1d3
```

---

## Component Responsibilities

### 🔵 Developer Workstation
- **Purpose**: Local development and testing
- **Tools**: VS Code/Cursor with Dev Containers
- **Activities**: 
  - Write Ansible content (roles, playbooks, modules)
  - Test locally with Molecule
  - Commit and push to Git

### 🟢 GitHub
- **Purpose**: Source control and quality gates
- **Components**:
  - **Git Repositories**: Source of truth for all code
  - **GitHub Actions**: Automated testing and linting (NOT building/releasing)
  - **Artifacts**: Test reports, coverage, SBOM

### 🔴 ArgoCD (Platform Loop)
- **Purpose**: GitOps-based cluster configuration
- **Scope**: 
  - Kubernetes resources
  - AAP instance deployments
  - Operators and CRDs
  - RBAC and network policies
- **Pattern**: Declarative, pull-based synchronization

### 🟡 Tekton (Application Loop)
- **Purpose**: CI/CD for Ansible content
- **Scope**:
  - Build Ansible collections
  - Build execution environments
  - Create release manifests
  - Publish to registries
  - Coordinate promotions
- **Pattern**: Event-driven, pipeline-based

### 🟠 AAP Instances
- **Purpose**: Run automation workloads
- **Environments**:
  - **Dev**: Development and feature testing
  - **QA**: Integration and validation testing  
  - **Prod**: Production automation execution
- **Configuration**: Managed as code via aap-config-as-code repo

---

## Data Flow

### Code → Test → Build → Deploy

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant GH as GitHub
    participant GHA as GitHub Actions
    participant Tek as Tekton
    participant Argo as ArgoCD
    participant AAP as AAP Instance

    Dev->>GH: Push code
    GH->>GHA: Trigger tests
    GHA->>GHA: Run sanity/units/lint
    GHA-->>Dev: Test results
    
    Dev->>GH: Create PR
    GHA->>GHA: Full test suite
    GHA-->>GH: Quality gates pass
    
    Dev->>GH: Merge to main
    GH->>Tek: Trigger build pipeline
    Tek->>Tek: Build collection
    Tek->>Tek: Build EE
    Tek->>Tek: Create release manifest
    Tek->>GH: Store manifest in Git
    
    GH->>Argo: Detect manifest change
    Argo->>AAP: Apply configuration
    AAP->>AAP: Run automation
```

---

## Repository Architecture

```mermaid
graph LR
    subgraph "Git Repositories"
        CC[cluster-config<br/>Kubernetes/ArgoCD/Tekton]
        AAP[aap-config-as-code<br/>AAP Configuration]
        COL[automation-collection<br/>Ansible Content]
        EE[automation-ee<br/>Execution Environments]
        REL[automation-release-manifest<br/>Version Tracking]
    end

    subgraph "Deployed Resources"
        K8S[Kubernetes<br/>Resources]
        AAPI[AAP<br/>Instances]
        GALA[Galaxy/<br/>Automation Hub]
        QUAY[Quay.io<br/>Registry]
    end

    CC -->|ArgoCD| K8S
    AAP -->|AAP Controller| AAPI
    COL -->|Tekton Build| GALA
    EE -->|Tekton Build| QUAY
    REL -->|Track All| REL

    K8S -.->|Provisions| AAPI
    AAPI -.->|Pulls from| GALA
    AAPI -.->|Pulls from| QUAY

    style CC fill:#ffadad
    style AAP fill:#ffd6a5
    style COL fill:#fdffb6
    style EE fill:#caffbf
    style REL fill:#9bf6ff
```

---

## Technology Stack

```mermaid
mindmap
  root((Platform))
    GitOps
      ArgoCD
      Tekton
      Git
    Kubernetes
      OpenShift
      Operators
      CRDs
    Ansible
      AAP Controller
      Collections
      Execution Environments
    Testing
      GitHub Actions
      Molecule
      ansible-test
    Security
      Grype
      Syft
      Dependabot
      Pre-commit
    Developer Tools
      VS Code
      Dev Containers
      OpenShift Dev Spaces
```

---

## Network Architecture

```mermaid
graph TB
    subgraph "External"
        INTERNET[Internet]
        GITHUB[GitHub.com]
        QUAY[Quay.io]
        GALAXY[Ansible Galaxy]
    end

    subgraph "OpenShift Cluster"
        subgraph "Ingress"
            ROUTE[Routes/Ingress]
        end

        subgraph "Platform Namespace"
            ARGOCD_SVC[ArgoCD Server]
            TEKTON_SVC[Tekton Dashboard]
        end

        subgraph "AAP Namespaces"
            AAP_DEV_SVC[AAP Dev UI]
            AAP_QA_SVC[AAP QA UI]
            AAP_PROD_SVC[AAP Prod UI]
        end

        subgraph "Internal Services"
            POSTGRES[PostgreSQL]
            REDIS[Redis]
        end
    end

    subgraph "Target Infrastructure"
        SERVERS[Managed Servers]
        CLOUD[Cloud Resources]
        NETWORK[Network Devices]
    end

    INTERNET -->|HTTPS| ROUTE
    ROUTE -->|Route| ARGOCD_SVC
    ROUTE -->|Route| TEKTON_SVC
    ROUTE -->|Route| AAP_DEV_SVC
    ROUTE -->|Route| AAP_QA_SVC
    ROUTE -->|Route| AAP_PROD_SVC

    ARGOCD_SVC -.->|Pull| GITHUB
    TEKTON_SVC -.->|Pull| GITHUB
    TEKTON_SVC -.->|Push| QUAY
    TEKTON_SVC -.->|Push| GALAXY

    AAP_DEV_SVC -->|DB| POSTGRES
    AAP_QA_SVC -->|DB| POSTGRES
    AAP_PROD_SVC -->|DB| POSTGRES
    AAP_DEV_SVC -->|Cache| REDIS
    AAP_QA_SVC -->|Cache| REDIS
    AAP_PROD_SVC -->|Cache| REDIS

    AAP_DEV_SVC -.->|SSH/WinRM| SERVERS
    AAP_QA_SVC -.->|SSH/WinRM| SERVERS
    AAP_PROD_SVC -.->|SSH/WinRM| SERVERS
    AAP_PROD_SVC -.->|API| CLOUD
    AAP_PROD_SVC -.->|SSH/API| NETWORK

    style ROUTE fill:#ff6b6b
    style ARGOCD_SVC fill:#4ecdc4
    style AAP_PROD_SVC fill:#ffe66d
```

---

## Security Layers

```mermaid
graph TB
    subgraph "Layer 1: Source Control"
        PRE[Pre-commit Hooks<br/>Secret Detection]
        GHA[GitHub Actions<br/>Quality Gates]
        BRANCH[Branch Protection<br/>Required Reviews]
    end

    subgraph "Layer 2: Build Time"
        SBOM[SBOM Generation<br/>Component Tracking]
        VULN[Vulnerability Scanning<br/>Grype/Trivy]
        SIGN[Image Signing<br/>Cosign]
    end

    subgraph "Layer 3: Deploy Time"
        POLICY[OPA Policies<br/>Admission Control]
        RBAC[RBAC<br/>Least Privilege]
        NETPOL[Network Policies<br/>Segmentation]
    end

    subgraph "Layer 4: Runtime"
        VAULT[Vault Integration<br/>Secret Management]
        AUDIT[Audit Logging<br/>Compliance]
        MONITOR[Security Monitoring<br/>Alerts]
    end

    PRE --> GHA
    GHA --> BRANCH
    BRANCH --> SBOM
    SBOM --> VULN
    VULN --> SIGN
    SIGN --> POLICY
    POLICY --> RBAC
    RBAC --> NETPOL
    NETPOL --> VAULT
    VAULT --> AUDIT
    AUDIT --> MONITOR

    style PRE fill:#95e1d3
    style SIGN fill:#ffd93d
    style VAULT fill:#6bcf7f
    style MONITOR fill:#ff6b9d
```

---

## Constitutional Alignment

```mermaid
graph LR
    subgraph "Article I: GitOps First"
        A1[All config in Git<br/>ArgoCD/Tekton<br/>Declarative]
    end

    subgraph "Article II: Separation of Duties"
        A2[RBAC enforced<br/>Team structure<br/>Approvals required]
    end

    subgraph "Article III: Atomic Promotion"
        A3[Release manifests<br/>Coordinated versions<br/>Rollback support]
    end

    subgraph "Article IV: Production-Grade Quality"
        A4[Automated testing<br/>Matrix testing<br/>Quality gates]
    end

    subgraph "Article V: Zero-Trust Security"
        A5[No hardcoded secrets<br/>SBOM tracking<br/>Vulnerability scanning]
    end

    A1 -->|Enables| A3
    A2 -->|Enforces| A4
    A3 -->|Supports| A4
    A4 -->|Validates| A5
    A5 -->|Protects| A1

    style A1 fill:#e3f2fd
    style A2 fill:#f3e5f5
    style A3 fill:#e8f5e9
    style A4 fill:#fff3e0
    style A5 fill:#fce4ec
```

---

## Deployment Topology

```mermaid
graph TB
    subgraph "Single Cluster Deployment"
        subgraph "Namespace: platform"
            ARGO[ArgoCD]
            TEK[Tekton]
            OPS[Operators]
        end

        subgraph "Namespace: aap-dev"
            AAP_D[AAP Dev<br/>Controller + DB]
            EE_D[Execution Environments]
        end

        subgraph "Namespace: aap-qa"
            AAP_Q[AAP QA<br/>Controller + DB]
            EE_Q[Execution Environments]
        end

        subgraph "Namespace: aap-prod"
            AAP_P[AAP Prod<br/>Controller + DB<br/>HA: 3 replicas]
            EE_P[Execution Environments]
        end

        subgraph "Namespace: shared-services"
            PG[PostgreSQL Operator]
            REDIS[Redis Operator]
            VAULT[Vault]
        end
    end

    ARGO -->|Manages| AAP_D
    ARGO -->|Manages| AAP_Q
    ARGO -->|Manages| AAP_P
    TEK -->|Builds for| EE_D
    TEK -->|Builds for| EE_Q
    TEK -->|Builds for| EE_P

    AAP_D -.->|Uses| PG
    AAP_Q -.->|Uses| PG
    AAP_P -.->|Uses| PG
    AAP_D -.->|Uses| VAULT
    AAP_Q -.->|Uses| VAULT
    AAP_P -.->|Uses| VAULT

    style ARGO fill:#ff6b6b
    style TEK fill:#4ecdc4
    style AAP_P fill:#ffe66d
    style VAULT fill:#95e1d3
```

---

## Summary

### Key Architectural Principles

1. **GitOps-Driven**: Everything managed through Git
2. **Dual Loop**: Platform (ArgoCD) + Application (Tekton)
3. **Separation of Concerns**: Clear boundaries between components
4. **Cloud-Native**: Kubernetes-native, container-based
5. **Security First**: Multiple layers of security controls

### Component Interactions

- **Developers** → Push code to **GitHub**
- **GitHub Actions** → Test and validate (quality gates)
- **ArgoCD** → Deploy platform configuration (cluster-config)
- **Tekton** → Build and release Ansible content
- **AAP** → Execute automation workloads

### Data Flow Patterns

- **Configuration**: Git → ArgoCD → Kubernetes → AAP
- **Content**: Git → Tekton → Registry/Galaxy → AAP
- **Promotion**: Manifest → Dev → QA → Prod (atomic)

---

**Constitutional Alignment**: ✅ All 5 articles implemented and enforced through architecture

