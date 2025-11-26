# GitOps Loops Architecture

**Dual GitOps Loops: Platform + Application**

## Dual Loop Overview

```mermaid
graph TB
    GIT[Git Repository<br/>Source of Truth]

    subgraph "Platform Loop - ArgoCD"
        ARGO[ArgoCD<br/>Continuous Sync]
        CLUSTER[Cluster State<br/>Kubernetes Resources]
    end

    subgraph "Application Loop - Tekton"
        TEKTON[Tekton<br/>Event-Driven Pipelines]
        ARTIFACTS[Artifacts<br/>Collections, Images, Manifests]
    end

    GIT -->|1. Watch Config| ARGO
    ARGO -->|2. Detect Drift| ARGO
    ARGO -->|3. Sync to Desired State| CLUSTER
    CLUSTER -.->|4. Report Status| ARGO

    GIT -->|5. Trigger on Merge| TEKTON
    TEKTON -->|6. Build & Test| TEKTON
    TEKTON -->|7. Publish| ARTIFACTS
    ARTIFACTS -->|8. Update Manifest| GIT

    style ARGO fill:#ff6b6b
    style TEKTON fill:#4ecdc4
    style GIT fill:#95e1d3
```

---

## Platform Loop (ArgoCD)

**Purpose**: Declarative cluster configuration management

```mermaid
sequenceDiagram
    participant Git as Git Repository
    participant Argo as ArgoCD
    participant K8s as Kubernetes API
    participant AAP as AAP Operator

    Note over Git,AAP: Platform Loop - Continuous Sync

    Git->>Argo: 1. Poll for changes (every 3m)
    Argo->>Argo: 2. Detect configuration diff
    Argo->>K8s: 3. Apply manifests
    K8s->>K8s: 4. Create/Update resources
    K8s->>AAP: 5. Provision AAP instance
    AAP->>AAP: 6. Initialize AAP
    K8s-->>Argo: 7. Report resource status
    Argo->>Argo: 8. Update application health
    Argo-->>Git: 9. Mark synced (timestamp)

    Note over Git,AAP: Continuous reconciliation loop
```

### Platform Loop Characteristics

| Characteristic | Value |
|---------------|-------|
| **Pattern** | Pull-based, declarative |
| **Frequency** | Every 3 minutes (configurable) |
| **Scope** | Kubernetes resources only |
| **Automation** | Fully automated (auto-sync) |
| **Rollback** | Git revert + auto-sync |
| **Approval** | Via Git PR process |

### What the Platform Loop Manages

```mermaid
mindmap
  root((Platform Loop))
    Namespaces
      aap-dev
      aap-qa
      aap-prod
      platform
    AAP Instances
      AAP Dev
      AAP QA
      AAP Prod
    Operators
      AAP Operator
      PostgreSQL
      Redis
    RBAC
      Roles
      RoleBindings
      ServiceAccounts
    Network
      NetworkPolicies
      Routes
      Services
    Configuration
      ConfigMaps
      Secrets refs
      PVCs
```

---

## Application Loop (Tekton)

**Purpose**: Event-driven CI/CD for Ansible content

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant Git as Git Repository
    participant GH as GitHub Actions
    participant Tek as Tekton
    participant Reg as Registry/Galaxy
    participant Argo as ArgoCD

    Note over Dev,Argo: Application Loop - Event-Driven

    Dev->>Git: 1. Push code to branch
    Git->>GH: 2. Trigger tests
    GH->>GH: 3. Run sanity/units/lint
    GH-->>Dev: 4. Test results

    Dev->>Git: 5. Merge PR to main
    Git->>Tek: 6. Webhook trigger
    Tek->>Tek: 7. Clone repository
    Tek->>Tek: 8. Build collection
    Tek->>Tek: 9. Build EE image
    Tek->>Tek: 10. Run final tests
    Tek->>Reg: 11. Publish artifacts
    Tek->>Git: 12. Create release manifest

    Git->>Argo: 13. Detect manifest change
    Argo->>Argo: 14. Sync to cluster

    Note over Dev,Argo: Triggered by Git events
```

### Application Loop Characteristics

| Characteristic | Value |
|---------------|-------|
| **Pattern** | Event-driven, pipeline-based |
| **Frequency** | On Git events (push, tag, PR) |
| **Scope** | Build, test, publish artifacts |
| **Automation** | Automatic on merge to main |
| **Rollback** | Revert manifest + rollback job |
| **Approval** | Manual gates for prod promotion |

### What the Application Loop Manages

```mermaid
mindmap
  root((Application Loop))
    Building
      Collections
      Execution Environments
      Documentation
    Testing
      Unit Tests
      Integration Tests
      Sanity Checks
    Publishing
      Ansible Galaxy
      Quay.io Registry
      Artifact Storage
    Release Management
      Version Tagging
      Release Manifests
      Changelog Generation
    Promotion
      Dev Deploy
      QA Deploy
      Prod Deploy
```

---

## Loop Interactions

```mermaid
stateDiagram-v2
    [*] --> CodeChange: Developer commits

    state "Platform Loop" as PlatLoop {
        [*] --> DetectConfig
        DetectConfig --> SyncCluster
        SyncCluster --> ValidateHealth
        ValidateHealth --> [*]
    }

    state "Application Loop" as AppLoop {
        [*] --> TriggerBuild
        TriggerBuild --> BuildArtifacts
        BuildArtifacts --> PublishArtifacts
        PublishArtifacts --> CreateManifest
        CreateManifest --> [*]
    }

    CodeChange --> PlatLoop: If cluster-config changed
    CodeChange --> AppLoop: If collection/EE changed

    AppLoop --> PlatLoop: Manifest created
    PlatLoop --> [*]: Deployed

    note right of PlatLoop
        Continuous sync
        Every 3 minutes
        Pull-based
    end note

    note right of AppLoop
        Event-driven
        On merge/tag
        Push-based
    end note
```

---

## Promotion Flow Through Loops

### Development Environment

```mermaid
graph LR
    subgraph "Developer Workflow"
        DEV[Code Change]
        PR[Pull Request]
        MERGE[Merge to Main]
    end

    subgraph "Application Loop"
        BUILD[Build Pipeline]
        MANIFEST[Create Manifest<br/>Version: dev-$SHA]
    end

    subgraph "Platform Loop"
        SYNC[ArgoCD Sync]
        DEPLOY[Deploy to AAP Dev]
    end

    DEV --> PR
    PR -->|Tests Pass| MERGE
    MERGE -->|Trigger| BUILD
    BUILD --> MANIFEST
    MANIFEST -->|Git Commit| SYNC
    SYNC --> DEPLOY

    style MERGE fill:#4ecdc4
    style MANIFEST fill:#ffe66d
    style DEPLOY fill:#95e1d3
```

### QA Environment

```mermaid
graph LR
    subgraph "Manual Trigger"
        PROMOTE[Promotion Request<br/>dev → qa]
    end

    subgraph "Application Loop"
        PIPELINE[Promotion Pipeline]
        MANIFEST_QA[Update Manifest<br/>Version: qa-$VERSION]
    end

    subgraph "Platform Loop"
        SYNC_QA[ArgoCD Sync]
        DEPLOY_QA[Deploy to AAP QA]
        TEST[Run Smoke Tests]
    end

    PROMOTE -->|Trigger| PIPELINE
    PIPELINE --> MANIFEST_QA
    MANIFEST_QA -->|Git Commit| SYNC_QA
    SYNC_QA --> DEPLOY_QA
    DEPLOY_QA --> TEST

    style PROMOTE fill:#ffd93d
    style MANIFEST_QA fill:#ffe66d
    style TEST fill:#95e1d3
```

### Production Environment

```mermaid
graph LR
    subgraph "Approval Process"
        REQUEST[Promotion Request<br/>qa → prod]
        APPROVE[Manual Approval<br/>Change Advisory Board]
    end

    subgraph "Application Loop"
        PIPELINE_PROD[Promotion Pipeline]
        MANIFEST_PROD[Update Manifest<br/>Version: prod-$VERSION]
        BACKUP[Backup Rollback Point]
    end

    subgraph "Platform Loop"
        SYNC_PROD[ArgoCD Sync]
        DEPLOY_PROD[Deploy to AAP Prod]
        VERIFY[Verify Health]
    end

    REQUEST --> APPROVE
    APPROVE -->|Approved| PIPELINE_PROD
    PIPELINE_PROD --> BACKUP
    BACKUP --> MANIFEST_PROD
    MANIFEST_PROD -->|Git Commit| SYNC_PROD
    SYNC_PROD --> DEPLOY_PROD
    DEPLOY_PROD --> VERIFY

    style APPROVE fill:#ff6b6b
    style BACKUP fill:#ffd93d
    style VERIFY fill:#95e1d3
```

---

## Repository Mapping to Loops

```mermaid
graph TB
    subgraph "Git Repositories"
        CC[cluster-config]
        AAP[aap-config-as-code]
        COL[automation-collection]
        EE[automation-ee]
        REL[automation-release-manifest]
    end

    subgraph "Platform Loop"
        ARGO[ArgoCD]
    end

    subgraph "Application Loop"
        TEK[Tekton]
    end

    CC -->|Manages| ARGO
    ARGO -.->|Deploys Tekton| TEK

    AAP -->|Config| TEK
    COL -->|Build| TEK
    EE -->|Build| TEK

    TEK -->|Updates| REL
    REL -->|Versions| ARGO

    style CC fill:#ff6b6b
    style ARGO fill:#ff6b6b
    style TEK fill:#4ecdc4
    style REL fill:#95e1d3
```

---

## Loop Reconciliation

### Platform Loop Reconciliation

```mermaid
sequenceDiagram
    participant Git
    participant Argo as ArgoCD
    participant K8s as Kubernetes

    loop Every 3 Minutes
        Argo->>Git: Fetch latest commit
        Argo->>Argo: Compare Git SHA

        alt Configuration Changed
            Argo->>K8s: Calculate diff
            Argo->>K8s: Apply changes
            K8s-->>Argo: Report status
            Argo->>Argo: Update sync status
        else No Changes
            Argo->>Argo: Status: Synced
        end
    end

    Note over Git,K8s: Continuous reconciliation ensures<br/>cluster matches Git state
```

### Application Loop Reconciliation

```mermaid
sequenceDiagram
    participant Git
    participant Tekton
    participant Registry
    participant Manifest as Release Manifest

    Git->>Tekton: Push to main branch
    Tekton->>Tekton: Start pipeline run
    Tekton->>Tekton: Build artifacts
    Tekton->>Registry: Publish
    Registry-->>Tekton: Confirm published
    Tekton->>Manifest: Create/update manifest
    Manifest->>Git: Commit manifest
    Git-->>Tekton: Pipeline complete

    Note over Git,Manifest: Event-driven pipeline<br/>triggered by Git events
```

---

## Failure Handling

### Platform Loop Failures

```mermaid
stateDiagram-v2
    [*] --> Syncing
    Syncing --> Healthy: Sync successful
    Syncing --> Degraded: Partial sync
    Syncing --> Failed: Sync failed

    Healthy --> [*]

    Degraded --> Retry: Auto-retry
    Retry --> Syncing
    Retry --> Alert: Max retries

    Failed --> Alert: Immediate
    Alert --> Manual: Investigation
    Manual --> Syncing: Fix applied
```

### Application Loop Failures

```mermaid
stateDiagram-v2
    [*] --> Running
    Running --> Success: Build successful
    Running --> Failed: Build failed

    Success --> Published: Artifacts published
    Published --> [*]

    Failed --> Alert: Notify team
    Alert --> Investigate: Review logs
    Investigate --> FixCode: Fix and re-run
    FixCode --> [*]
```

---

## Comparison: Platform vs Application Loop

| Aspect | Platform Loop (ArgoCD) | Application Loop (Tekton) |
|--------|------------------------|---------------------------|
| **Trigger** | Time-based poll (3min) | Event-based (webhook) |
| **Pattern** | Pull | Push |
| **Scope** | Cluster configuration | Ansible content |
| **Automation** | Fully automatic | Semi-automatic (approvals) |
| **Rollback** | Git revert | Manifest rollback |
| **Speed** | Slow (minutes) | Fast (seconds) |
| **Idempotent** | Yes | Yes |
| **Validation** | Kubernetes API | Tests + builds |

---

## Integration Points

```mermaid
graph TB
    subgraph "Integration Flow"
        CODE[Code Change]
        TEST[GitHub Actions<br/>Quality Gates]
        MERGE[Merge to Main]

        BUILD[Tekton Build<br/>Application Loop]
        MANIFEST[Release Manifest]

        SYNC[ArgoCD Sync<br/>Platform Loop]
        DEPLOY[Deployment]
    end

    CODE --> TEST
    TEST -->|Pass| MERGE
    MERGE -->|Trigger| BUILD
    BUILD -->|Create| MANIFEST
    MANIFEST -->|Detect| SYNC
    SYNC -->|Apply| DEPLOY

    style TEST fill:#4ecdc4
    style BUILD fill:#4ecdc4
    style SYNC fill:#ff6b6b
    style DEPLOY fill:#95e1d3
```

---

## Summary

### Key Differences

**Platform Loop (ArgoCD)**:
- ✅ Manages **what** runs (infrastructure)
- ✅ Continuous reconciliation
- ✅ Cluster-scoped
- ✅ Declarative sync

**Application Loop (Tekton)**:
- ✅ Manages **how** things are built (applications)
- ✅ Event-driven execution
- ✅ Build-scoped
- ✅ Imperative pipelines

### Why Both?

1. **Separation of Concerns**: Infrastructure vs application
2. **Different Patterns**: Continuous sync vs event-driven
3. **Different Speeds**: Minutes vs seconds
4. **Different Scope**: Cluster-wide vs artifact-specific
5. **Constitutional Alignment**: Article I (GitOps First) requires both

### Together They Provide

- **Complete GitOps**: Everything from Git
- **Fast Feedback**: Quick builds, gradual rollout
- **Safety**: Declarative infra, tested apps
- **Traceability**: All changes tracked in Git
- **Atomic Promotion**: Coordinated via manifests

---

**Constitutional Compliance**: ✅ Article I (GitOps First) implemented through dual loops

