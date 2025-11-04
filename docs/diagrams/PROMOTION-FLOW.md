# Promotion Flow Architecture

**Atomic Promotion with Release Manifests**

## Promotion Overview

```mermaid
graph LR
    DEV[Development<br/>aap-dev]
    QA[QA<br/>aap-qa]
    PROD[Production<br/>aap-prod]

    DEV -->|Validate| QA
    QA -->|Approve| PROD

    style DEV fill:#4ecdc4
    style QA fill:#ffd93d
    style PROD fill:#95e1d3
```

---

## Complete Promotion Pipeline with Git Tags

```mermaid
graph TB
    subgraph "Development Phase"
        CODE[Code Changes<br/>Feature Branch]
        TEST1[GitHub Actions<br/>Tests & Linting]
        MERGE[Merge to Main]
        TAG_DEV[Create Dev Tag<br/>dev-abc123]
    end

    subgraph "Build Phase"
        BUILD_COL[Build Collection]
        BUILD_EE[Build EE Image<br/>ee:dev-abc123]
        TEST_BUILD[Post-Build Tests]
    end

    subgraph "Release Phase"
        MANIFEST_DEV[Create Release Manifest<br/>dev-abc123.yaml]
        PUBLISH[Publish to Registries]
    end

    subgraph "Dev Environment"
        SYNC_DEV[AAP Dev Project<br/>Sync to main/dev tag]
        DEPLOY_DEV[Deploy to AAP Dev]
        SMOKE_DEV[Smoke Tests]
        VALIDATE_DEV[Validation Tests]
    end

    subgraph "QA Promotion"
        TAG_QA[Create QA Tag<br/>git tag qa-v1.1.0]
        MANIFEST_QA[Create Manifest<br/>qa-v1.1.0.yaml]
        BUILD_EE_QA[Build EE<br/>ee:qa-v1.1.0]
        SYNC_QA[AAP QA Project<br/>Sync to qa-v1.1.0]
        DEPLOY_QA[Deploy to AAP QA]
        TEST_QA[Full Test Suite]
        APPROVE_QA[QA Sign-off]
    end

    subgraph "Prod Promotion"
        CAB[Change Advisory Board]
        APPROVE_PROD[Production Approval]
        TAG_PROD[Create Prod Tag<br/>git tag prod-v1.0.0]
        BACKUP[Backup Rollback Point]
        MANIFEST_PROD[Create Manifest<br/>prod-v1.0.0.yaml]
        BUILD_EE_PROD[Build EE<br/>ee:prod-v1.0.0]
        SYNC_PROD[AAP Prod Project<br/>Sync to prod-v1.0.0]
        DEPLOY_PROD[Deploy to AAP Prod]
        VERIFY_PROD[Production Verification]
    end

    CODE --> TEST1
    TEST1 -->|Pass| MERGE
    MERGE --> TAG_DEV
    TAG_DEV --> BUILD_COL
    TAG_DEV --> BUILD_EE
    BUILD_COL --> TEST_BUILD
    BUILD_EE --> TEST_BUILD
    TEST_BUILD -->|Pass| MANIFEST_DEV
    MANIFEST_DEV --> PUBLISH
    PUBLISH --> SYNC_DEV
    SYNC_DEV --> DEPLOY_DEV
    DEPLOY_DEV --> SMOKE_DEV
    SMOKE_DEV --> VALIDATE_DEV
    VALIDATE_DEV -->|Pass| TAG_QA

    TAG_QA --> MANIFEST_QA
    TAG_QA --> BUILD_EE_QA
    MANIFEST_QA --> SYNC_QA
    BUILD_EE_QA --> SYNC_QA
    SYNC_QA --> DEPLOY_QA
    DEPLOY_QA --> TEST_QA
    TEST_QA -->|Pass| APPROVE_QA

    APPROVE_QA --> CAB
    CAB --> APPROVE_PROD
    APPROVE_PROD --> TAG_PROD
    TAG_PROD --> BACKUP
    BACKUP --> MANIFEST_PROD
    TAG_PROD --> BUILD_EE_PROD
    MANIFEST_PROD --> SYNC_PROD
    BUILD_EE_PROD --> SYNC_PROD
    SYNC_PROD --> DEPLOY_PROD
    DEPLOY_PROD --> VERIFY_PROD

    style MERGE fill:#4ecdc4
    style TAG_DEV fill:#4ecdc4
    style TAG_QA fill:#ffd93d
    style TAG_PROD fill:#ff6b6b
    style DEPLOY_PROD fill:#95e1d3
```

---

## Git Tag-Based Promotion Strategy

### Tag Naming Convention

| Environment | Tag Format | Example | Created When |
|-------------|------------|---------|--------------|
| **Development** | `dev-<short-sha>` | `dev-abc123` | Automatic on merge to main |
| **QA** | `qa-v<major>.<minor>.<patch>` | `qa-v1.1.0` | Manual, when ready for QA |
| **Production** | `prod-v<major>.<minor>.<patch>` | `prod-v1.0.0` | Manual, after CAB approval |

### Tag Immutability

- **Dev tags**: May be ephemeral, deleted after promotion
- **QA/Prod tags**: **IMMUTABLE** - never deleted or moved
- **Semantic Versioning**: QA and Prod follow [SemVer](https://semver.org/)
- **AAP Projects**: Configure to checkout specific tags (not branch names)

### Example Tag Creation

```bash
# Development (automatic)
git checkout main
git pull
git tag dev-$(git rev-parse --short HEAD)
git push origin dev-$(git rev-parse --short HEAD)

# QA (manual)
git tag -a qa-v1.1.0 -m "Release 1.1.0 for QA testing"
git push origin qa-v1.1.0

# Production (manual, after approval)
git tag -a prod-v1.0.0 -m "Production Release 1.0.0
Approved by: CAB
Change: CHG0001234"
git push origin prod-v1.0.0
```

**See**: [BRANCHING-STRATEGY.md](../BRANCHING-STRATEGY.md) for complete workflow

---

## Release Manifest Structure

### Manifest Evolution Across Environments

```mermaid
graph TB
    subgraph "Dev Manifest"
        DEV_M["release-dev-abc123.yaml"]
        DEV_TAG["git-tag: dev-abc123"]
        DEV_COL["collection-commit: abc1234..."]
        DEV_EE["ee-image: ee:dev-abc123"]
        DEV_AAP["aap-config: main"]
    end

    subgraph "QA Manifest"
        QA_M["release-qa-v1.1.0.yaml"]
        QA_TAG["git-tag: qa-v1.1.0"]
        QA_COL["collection-commit: abc1234..."]
        QA_EE["ee-image: ee:qa-v1.1.0"]
        QA_AAP["aap-config-tag: qa-v1.1.0"]
    end

    subgraph "Prod Manifest"
        PROD_M["release-prod-v1.0.0.yaml"]
        PROD_TAG["git-tag: prod-v1.0.0"]
        PROD_COL["collection-commit: abc1234..."]
        PROD_EE["ee-image: ee:prod-v1.0.0"]
        PROD_AAP["aap-config-tag: prod-v1.0.0"]
        PROD_APPROVED["approved: true<br/>approved-by: CAB<br/>approved-at: 2025-01-04T15:30:00Z"]
    end

    DEV_M --> QA_M
    QA_M --> PROD_M

    style DEV_M fill:#e3f2fd
    style QA_M fill:#fff3e0
    style PROD_M fill:#e8f5e9
```

---

## Detailed Promotion Sequence

### 1. Development Deployment

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant GH as GitHub
    participant Tek as Tekton
    participant Reg as Registry
    participant Argo as ArgoCD
    participant AAP_D as AAP Dev

    Dev->>GH: Merge PR to main
    GH->>Tek: Trigger build pipeline
    
    Tek->>Tek: Build collection
    Tek->>Tek: Build EE image
    Tek->>Tek: Run tests
    Tek->>Reg: Publish artifacts
    Tek->>GH: Create manifest (dev-$SHA)
    
    GH->>Argo: Detect manifest change
    Argo->>AAP_D: Deploy configuration
    AAP_D->>AAP_D: Pull artifacts from registry
    AAP_D-->>Argo: Report health
    Argo-->>Dev: Deployment complete

    Note over Dev,AAP_D: Automatic on merge
```

### 2. QA Promotion

```mermaid
sequenceDiagram
    participant QA_Lead as QA Lead
    participant GH as GitHub
    participant Tek as Tekton
    participant Argo as ArgoCD
    participant AAP_Q as AAP QA

    QA_Lead->>GH: Request promotion (dev → qa)
    GH->>Tek: Trigger promotion pipeline
    
    Tek->>Tek: Validate dev manifest
    Tek->>Tek: Create QA manifest
    Tek->>GH: Commit QA manifest
    
    GH->>Argo: Detect manifest change
    Argo->>AAP_Q: Deploy configuration
    AAP_Q->>AAP_Q: Pull artifacts
    AAP_Q->>AAP_Q: Run smoke tests
    AAP_Q-->>Argo: Report health
    Argo-->>QA_Lead: Deployment complete
    
    QA_Lead->>AAP_Q: Execute test suite
    AAP_Q-->>QA_Lead: Test results
    QA_Lead->>GH: Sign-off (approve PR)

    Note over QA_Lead,AAP_Q: Manual trigger + validation
```

### 3. Production Promotion

```mermaid
sequenceDiagram
    participant CAB as Change Advisory Board
    participant GH as GitHub
    participant Tek as Tekton
    participant Argo as ArgoCD
    participant AAP_P as AAP Prod
    participant Backup as Backup Service

    CAB->>GH: Approve promotion (qa → prod)
    GH->>Tek: Trigger production pipeline
    
    Tek->>Tek: Validate QA manifest
    Tek->>Backup: Create backup/snapshot
    Backup-->>Tek: Backup ID
    Tek->>Tek: Create prod manifest
    Tek->>GH: Commit prod manifest
    
    GH->>Argo: Detect manifest change
    Argo->>AAP_P: Deploy configuration (blue-green)
    AAP_P->>AAP_P: Pull artifacts
    AAP_P->>AAP_P: Health checks
    AAP_P-->>Argo: Green environment healthy
    Argo->>AAP_P: Switch traffic to green
    AAP_P-->>Argo: Deployment complete
    Argo-->>CAB: Production deployed

    Note over CAB,AAP_P: Approval + backup + verification
```

---

## Rollback Scenarios

### Development Rollback

```mermaid
graph LR
    ISSUE[Issue Detected]
    REVERT[Git Revert Commit]
    REBUILD[Rebuild Triggered]
    DEPLOY[Auto-Deploy]

    ISSUE --> REVERT
    REVERT --> REBUILD
    REBUILD --> DEPLOY

    style ISSUE fill:#ff6b6b
    style REVERT fill:#ffd93d
    style DEPLOY fill:#95e1d3
```

### QA/Production Rollback

```mermaid
sequenceDiagram
    participant Ops as Operations
    participant GH as GitHub
    participant Tek as Tekton
    participant Argo as ArgoCD
    participant AAP as AAP Instance

    Ops->>GH: Trigger rollback pipeline
    GH->>Tek: Start rollback job
    
    Tek->>Tek: Identify previous manifest
    Tek->>GH: Revert to previous manifest
    
    GH->>Argo: Detect change
    Argo->>AAP: Deploy previous version
    AAP->>AAP: Pull previous artifacts
    AAP-->>Argo: Rollback complete
    Argo-->>Ops: Previous version restored

    Note over Ops,AAP: Fast rollback via manifest revert
```

---

## Promotion Gates

```mermaid
graph TB
    subgraph "Dev → QA Gates"
        G1[Smoke Tests Pass]
        G2[No Critical Bugs]
        G3[Dev Environment Stable]
        G4[QA Lead Approval]
    end

    subgraph "QA → Prod Gates"
        G5[Full Test Suite Pass]
        G6[Integration Tests Pass]
        G7[Security Scan Pass]
        G8[Performance Tests Pass]
        G9[QA Sign-off]
        G10[CAB Approval]
        G11[Backup Complete]
    end

    START[Deployment Complete] --> G1
    G1 --> G2
    G2 --> G3
    G3 --> G4
    G4 --> PROMOTE_QA[Promote to QA]

    PROMOTE_QA --> G5
    G5 --> G6
    G6 --> G7
    G7 --> G8
    G8 --> G9
    G9 --> G10
    G10 --> G11
    G11 --> PROMOTE_PROD[Promote to Prod]

    style G4 fill:#ffd93d
    style G10 fill:#ff6b6b
    style G11 fill:#95e1d3
```

---

## Version Progression

```mermaid
timeline
    title Release Version Progression
    
    section Development
        Commit abc123 : Feature developed
                      : Tests pass
                      : Merge to main
        
        Dev Deploy : release-dev-20250104-abc123
                   : collection: 1.0.0-dev+abc123
                   : ee-image: latest-dev

    section QA
        QA Promotion : release-qa-20250104-001
                     : collection: 1.0.0
                     : ee-image: 1.0.0
                     : Immutable versions
        
        QA Testing : Integration tests
                   : Security scans
                   : QA sign-off

    section Production
        Prod Promotion : release-prod-20250104-001
                       : collection: 1.0.0
                       : ee-image: 1.0.0
                       : CAB approval
        
        Prod Deploy : Blue-green deployment
                    : Health verification
                    : Traffic switch
```

---

## Atomic Promotion Benefits

```mermaid
mindmap
  root((Atomic<br/>Promotion))
    Consistency
      Same versions everywhere
      No version mismatch
      Coordinated updates
    Traceability
      Git history
      Audit trail
      Approval records
    Safety
      Easy rollback
      Atomic operations
      No partial deploys
    Speed
      Fast promotion
      Automated process
      Parallel updates
    Compliance
      Change control
      Approval workflow
      Audit requirements
```

---

## Promotion Timeline

### Fast-Track Promotion (Emergency Fix)

```mermaid
gantt
    title Emergency Hotfix Promotion
    dateFormat HH:mm
    axisFormat %H:%M

    section Dev
    Code & Test     :00:00, 1h
    Build & Deploy  :01:00, 15m
    Validation      :01:15, 15m

    section QA
    Deploy to QA    :01:30, 10m
    Critical Tests  :01:40, 20m

    section Prod
    Emergency CAB   :02:00, 15m
    Prod Deploy     :02:15, 15m
    Verification    :02:30, 30m
```

### Standard Promotion (Feature Release)

```mermaid
gantt
    title Standard Feature Release
    dateFormat YYYY-MM-DD
    axisFormat %m/%d

    section Dev
    Development     :2025-01-01, 5d
    Dev Testing     :2025-01-06, 2d

    section QA
    QA Deploy       :2025-01-08, 1d
    QA Testing      :2025-01-09, 3d

    section Prod
    CAB Review      :2025-01-13, 1d
    Prod Deploy     :2025-01-14, 1d
    Monitoring      :2025-01-15, 2d
```

---

## Manifest Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Created: Tekton build
    Created --> DevDeployed: ArgoCD sync
    DevDeployed --> DevValidated: Tests pass
    DevValidated --> QAPromoted: Manual trigger
    QAPromoted --> QADeployed: ArgoCD sync
    QADeployed --> QAValidated: Tests pass
    QAValidated --> CABReview: Submit for approval
    CABReview --> ProdPromoted: Approved
    CABReview --> QAValidated: Rejected
    ProdPromoted --> ProdDeployed: ArgoCD sync
    ProdDeployed --> ProdActive: Verification pass
    ProdActive --> [*]: Superseded by new release

    note right of Created
        Manifest includes:
        - Collection version
        - EE image digest
        - AAP config commit
        - Build metadata
    end note

    note right of CABReview
        Required for production:
        - QA sign-off
        - Security scan
        - CAB approval
        - Backup complete
    end note
```

---

## Multi-Repository Coordination

```mermaid
graph TB
    subgraph "Repository Changes"
        COL[Collection Changes<br/>v1.2.0]
        EE[EE Changes<br/>Added packages]
        AAP[AAP Config Changes<br/>New job templates]
    end

    subgraph "Build Process"
        BUILD_COL[Build Collection<br/>1.2.0]
        BUILD_EE[Build EE<br/>1.2.0]
        COMBINE[Coordinate Builds]
    end

    subgraph "Release Manifest"
        MANIFEST["release-dev-20250104-xyz789.yaml<br/>─────────────────────────<br/>collection: 1.2.0<br/>ee-image: 1.2.0@sha256:abc...<br/>aap-config: commit-xyz789"]
    end

    subgraph "Atomic Deployment"
        DEPLOY_ALL[Deploy All Components<br/>Together]
    end

    COL --> BUILD_COL
    EE --> BUILD_EE
    AAP --> COMBINE
    BUILD_COL --> COMBINE
    BUILD_EE --> COMBINE
    COMBINE --> MANIFEST
    MANIFEST --> DEPLOY_ALL

    style COMBINE fill:#4ecdc4
    style MANIFEST fill:#ffe66d
    style DEPLOY_ALL fill:#95e1d3
```

---

## Approval Workflow

```mermaid
graph TB
    subgraph "QA Approval"
        QA_TEST[QA Tests Complete]
        QA_LEAD[QA Lead Reviews]
        QA_APPROVE[QA Sign-off]
    end

    subgraph "Production Approval"
        PROD_REQUEST[Production Request]
        SEC_REVIEW[Security Review]
        OPS_REVIEW[Operations Review]
        CAB_MEET[CAB Meeting]
        CAB_VOTE[CAB Vote]
        CAB_APPROVE[CAB Approval]
    end

    QA_TEST --> QA_LEAD
    QA_LEAD --> QA_APPROVE
    QA_APPROVE --> PROD_REQUEST

    PROD_REQUEST --> SEC_REVIEW
    PROD_REQUEST --> OPS_REVIEW
    SEC_REVIEW --> CAB_MEET
    OPS_REVIEW --> CAB_MEET
    CAB_MEET --> CAB_VOTE
    CAB_VOTE -->|Approved| CAB_APPROVE
    CAB_VOTE -->|Rejected| PROD_REQUEST

    style QA_APPROVE fill:#ffd93d
    style CAB_APPROVE fill:#95e1d3
```

---

## Blue-Green Deployment (Production)

```mermaid
sequenceDiagram
    participant LB as Load Balancer
    participant Blue as Blue Environment<br/>(Current Production)
    participant Green as Green Environment<br/>(New Version)
    participant Monitor as Monitoring

    Note over Blue,Green: Current: Blue serving traffic

    Green->>Green: Deploy new version
    Green->>Green: Run health checks
    Green-->>Monitor: Health: OK
    
    Monitor->>LB: Begin traffic shift
    LB->>Green: 10% traffic
    Monitor->>Monitor: Monitor metrics
    LB->>Green: 50% traffic
    Monitor->>Monitor: Monitor metrics
    LB->>Green: 100% traffic
    
    Note over Blue,Green: New: Green serving traffic
    
    Blue->>Blue: Keep running (rollback ready)
    Monitor->>Monitor: Monitor for 24h
    
    alt Deployment Successful
        Blue->>Blue: Shut down old version
    else Issue Detected
        LB->>Blue: Rollback traffic to Blue
        Green->>Green: Investigate issue
    end
```

---

## Summary

### Promotion Principles

1. **Atomic**: All components promoted together
2. **Versioned**: Every promotion tracked in Git
3. **Gated**: Automated and manual approvals
4. **Traceable**: Full audit trail
5. **Reversible**: Fast rollback capability

### Key Characteristics

| Environment | Trigger | Approval | Speed | Risk |
|-------------|---------|----------|-------|------|
| **Dev** | Automatic | None | Fast (minutes) | Low |
| **QA** | Manual | QA Lead | Medium (hours) | Medium |
| **Prod** | Manual | CAB | Slow (days) | High |

### Constitutional Alignment

- ✅ **Article I**: All promotions via Git
- ✅ **Article II**: Approvals enforced by process
- ✅ **Article III**: Atomic promotion via manifests
- ✅ **Article IV**: Quality gates at each stage
- ✅ **Article V**: No secrets in manifests

---

**Result**: Safe, predictable, auditable promotion workflow

