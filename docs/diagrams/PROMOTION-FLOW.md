# Promotion Flow Architecture

**Atomic Promotion with Release Manifests**

---

## 🔧 Tool Responsibilities (Constitutional Article II: Separation of Duties)

### ArgoCD (Platform Loop)

**Manages**: Kubernetes/OpenShift platform resources

**Responsibilities**:
- ✅ AAP Operator installation and versioning
- ✅ Tekton Operators
- ✅ Namespaces, RBAC, ServiceAccounts
- ✅ CRDs (Custom Resource Definitions)
- ✅ Platform-level configuration

**Repository**: `cluster-config`

**What ArgoCD DOES NOT Do**:
- ❌ AAP Configuration (Projects, Job Templates, Inventories)
- ❌ Application-level automation
- ❌ Promotion orchestration

---

### Tekton (Application Loop)

**Manages**: Application-level automation and AAP configuration

**Responsibilities**:
- ✅ Build Execution Environments
- ✅ Apply AAP Configuration (via `infra.aap_configuration`)
- ✅ Create Release Manifests
- ✅ Orchestrate promotions (Dev → QA → Prod)
- ✅ Run tests and validations

**Repository**: All automation repos (collections, EE, aap-config-as-code)

**How Tekton Applies AAP Config**:
```bash
# Tekton runs Ansible playbook with infra.aap_configuration collection
ansible-playbook aap-config-as-code/playbook.yml \
  -i inventory.yml \
  -l aap_dev \
  -e controller_hostname=$AAP_HOST \
  -e controller_oauthtoken=$AAP_TOKEN
```

---

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
        TAG_QA[Create Release Tag<br/>git tag 26.1.5-0]
        MANIFEST_QA[Create Manifest<br/>release-26.1.5-0.yaml]
        BUILD_EE_QA[Build EE<br/>ee:26.1.5-0]
        SYNC_QA[AAP QA Project<br/>Sync to 26.1.5-0]
        DEPLOY_QA[Deploy to AAP QA]
        TEST_QA[Full Test Suite]
        APPROVE_QA[QA Sign-off]
    end

    subgraph "Prod Promotion"
        CAB[Change Advisory Board]
        APPROVE_PROD[Production Approval]
        TAG_PROD[Same Tag Promoted<br/>26.1.5-0]
        BACKUP[Backup Rollback Point]
        MANIFEST_PROD[Update Manifest<br/>mark prod deployed]
        BUILD_EE_PROD[Same EE<br/>ee:26.1.5-0]
        SYNC_PROD[AAP Prod Project<br/>Sync to 26.1.5-0]
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

### Tag Naming Convention (CalVer)

| Format | Example | Description |
|--------|---------|-------------|
| `YY.M.D-PATCH` | `26.1.5-0` | January 5, 2025 - Initial release |
| `YY.M.D-PATCH` | `26.1.5-1` | January 5, 2025 - Hotfix |
| `YY.M.D-PATCH` | `26.1.6-0` | January 6, 2025 - New release |

### Atomic Promotion

- **Same tag** used across all environments (dev → qa → prod)
- **Release manifest** tracks which environments have the tag deployed
- **No environment prefixes** - one tag promotes through all stages
- **AAP Projects**: Configure to checkout specific CalVer tags

### Example Tag Creation

```bash
# Create release tag
git checkout main
git pull
git tag -a 26.1.5-0 -m "Release January 5, 2025

Features:
- Add monitoring role
- Update database backup

Rollback: 26.1.4-0"
git push origin 26.1.5-0

# Hotfix (same day)
git tag -a 26.1.5-1 -m "Hotfix: Critical security patch"
git push origin 26.1.5-1
```

**See**: [GIT-WORKFLOW.md](../GIT-WORKFLOW.md) for complete workflow

---

## Release Manifest Structure

### Manifest Evolution Across Environments

```mermaid
graph TB
    subgraph "Release Manifest"
        DEV_M["release-26.1.5-0.yaml"]
        DEV_TAG["git-tag: dev-abc123"]
        DEV_COL["collection-commit: abc1234..."]
        DEV_EE["ee-image: ee:dev-abc123"]
        DEV_AAP["aap-config: main"]
    end

    subgraph "QA Manifest"
        QA_M["environments.qa.deployed: true"]
        QA_TAG["git-tag: 26.1.5-0"]
        QA_COL["collection-commit: abc1234..."]
        QA_EE["ee-image: ee:26.1.5-0"]
        QA_AAP["aap-config-tag: 26.1.5-0"]
    end

    subgraph "Prod Manifest"
        PROD_M["environments.prod.deployed: true"]
        PROD_TAG["git-tag: 26.1.5-0"]
        PROD_COL["collection-commit: abc1234..."]
        PROD_EE["ee-image: ee:26.1.5-0"]
        PROD_AAP["aap-config-tag: 26.1.5-0"]
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
    participant AAP_D as AAP Dev

    Dev->>GH: Merge PR to main
    GH->>Tek: Trigger build pipeline

    Tek->>Tek: Build collection
    Tek->>Tek: Build EE image
    Tek->>Tek: Run tests
    Tek->>Reg: Publish artifacts
    Tek->>Tek: Create dev tag (dev-$SHA)

    Tek->>AAP_D: Apply AAP config<br/>(via infra.aap_configuration)
    AAP_D->>AAP_D: Sync Project to dev tag
    AAP_D->>Reg: Pull EE image
    AAP_D-->>Tek: Config applied
    Tek-->>Dev: Deployment complete

    Note over Dev,AAP_D: Tekton orchestrates, not ArgoCD
    Note over Tek,AAP_D: ArgoCD manages AAP operator only
```

### 2. QA Promotion

```mermaid
sequenceDiagram
    participant QA_Lead as QA Lead
    participant GH as GitHub
    participant Tek as Tekton
    participant AAP_Q as AAP QA

    QA_Lead->>GH: Create release tag (26.1.5-0)
    GH->>Tek: Tag trigger → promotion pipeline

    Tek->>Tek: Build EE (ee:26.1.5-0)
    Tek->>Tek: Create QA manifest
    Tek->>GH: Commit QA manifest

    Tek->>AAP_Q: Apply AAP config<br/>(via infra.aap_configuration)
    AAP_Q->>AAP_Q: Sync Project to 26.1.5-0
    AAP_Q->>AAP_Q: Pull EE ee:26.1.5-0
    AAP_Q->>AAP_Q: Run smoke tests
    AAP_Q-->>Tek: Config applied
    Tek-->>QA_Lead: QA deployment complete

    QA_Lead->>AAP_Q: Execute full test suite
    AAP_Q-->>QA_Lead: Test results
    QA_Lead->>GH: Sign-off (approve for prod)

    Note over Tek,AAP_Q: Tekton applies AAP config
    Note over GH: ArgoCD manages AAP operator/platform only
```

### 3. Production Promotion

```mermaid
sequenceDiagram
    participant CAB as Change Advisory Board
    participant GH as GitHub
    participant Tek as Tekton
    participant AAP_P as AAP Prod
    participant Backup as Backup Service

    CAB->>GH: Approve prod deployment (26.1.5-0)
    GH->>Tek: Tag trigger → prod pipeline

    Tek->>Tek: Validate QA manifest
    Tek->>Tek: Use same EE (ee:26.1.5-0)
    Tek->>Backup: Create backup/snapshot
    Backup-->>Tek: Backup ID
    Tek->>Tek: Create prod manifest
    Tek->>GH: Commit prod manifest

    Tek->>AAP_P: Apply AAP config<br/>(via infra.aap_configuration)
    AAP_P->>AAP_P: Sync Project to 26.1.5-0
    AAP_P->>AAP_P: Pull EE ee:26.1.5-0
    AAP_P->>AAP_P: Health checks
    AAP_P-->>Tek: Config applied
    Tek-->>CAB: Production deployed

    Note over Tek,AAP_P: Tekton orchestrates deployment
    Note over GH: ArgoCD manages AAP operator only
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
    participant AAP as AAP Instance

    Ops->>GH: Trigger rollback pipeline
    GH->>Tek: Start rollback job

    Tek->>Tek: Identify previous manifest
    Tek->>AAP: Apply previous AAP config<br/>(via infra.aap_configuration)
    AAP->>AAP: Sync Project to previous tag
    AAP->>AAP: Pull previous EE image
    AAP-->>Tek: Rollback complete
    Tek-->>Ops: Previous version restored

    Note over Tek,AAP: Tekton applies previous config
    Note over GH: ArgoCD not involved in AAP config
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
        G7B[Content Signatures Verified]
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
    G7 --> G7B
    G7B --> G8
    G8 --> G9
    G9 --> G10
    G10 --> G11
    G11 --> PROMOTE_PROD[Promote to Prod]

    style G7B fill:#ffd93d
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
    Created --> DevDeployed: Tekton applies config
    DevDeployed --> DevValidated: Tests pass
    DevValidated --> QAPromoted: Git tag created
    QAPromoted --> QADeployed: Tekton applies config
    QADeployed --> QAValidated: Tests pass
    QAValidated --> CABReview: Submit for approval
    CABReview --> ProdPromoted: Approved
    CABReview --> QAValidated: Rejected
    ProdPromoted --> ProdDeployed: Tekton applies config
    ProdDeployed --> ProdActive: Verification pass
    ProdActive --> [*]: Superseded by new release

    note right of Created
        Manifest includes:
        - Collection version
        - EE image digest
        - AAP config commit
        - Build metadata
    end note

    note right of DevDeployed
        Tekton orchestrates:
        - Apply AAP config (CaC)
        - Sync AAP Projects
        - Update Job Templates

        ArgoCD manages:
        - AAP operator
        - Platform resources
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
        COL[Collection Changes<br/>26.1.5-0]
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
