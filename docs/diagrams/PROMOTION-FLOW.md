# Promotion Flow Architecture

**Atomic Promotion with Release Manifests**

---

## Tool Responsibilities

| Tool | Manages | Repository |
|------|---------|------------|
| **ArgoCD** (Platform Loop) | Kubernetes resources, AAP Operator, Tekton, RBAC | `cluster-config` |
| **Tekton** (Application Loop) | Build EEs, Apply AAP Config, Create Manifests, Promote | All automation repos |

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

## Complete Promotion Pipeline

```mermaid
graph TB
    subgraph "Development"
        CODE[Code Changes] --> TEST[Tests & Linting]
        TEST -->|Pass| MERGE[Merge to Main]
        MERGE --> BUILD[Build Collection + EE]
        BUILD --> MANIFEST_DEV[Create Manifest]
    end

    subgraph "Dev Environment"
        MANIFEST_DEV --> DEPLOY_DEV[Deploy to AAP Dev]
        DEPLOY_DEV --> VALIDATE_DEV[Validation]
        VALIDATE_DEV -->|Pass| TAG_QA[Create Release Tag<br/>25.01.05.0]
    end

    subgraph "QA Promotion"
        TAG_QA --> DEPLOY_QA[Deploy to AAP QA]
        DEPLOY_QA --> TEST_QA[Full Test Suite]
        TEST_QA -->|Pass| APPROVE_QA[QA Sign-off]
    end

    subgraph "Prod Promotion"
        APPROVE_QA --> CAB[CAB Approval]
        CAB --> BACKUP[Backup]
        BACKUP --> DEPLOY_PROD[Deploy to AAP Prod]
        DEPLOY_PROD --> VERIFY[Verification]
    end

    style MERGE fill:#4ecdc4
    style TAG_QA fill:#ffd93d
    style CAB fill:#ff6b6b
    style VERIFY fill:#95e1d3
```

---

## Version Format (CalVer)

| Format | Example | Description |
|--------|---------|-------------|
| `YY.MM.DD.PATCH` | `25.01.05.0` | January 5, 2025 - Initial |
| `YY.MM.DD.PATCH` | `25.01.05.1` | January 5, 2025 - Hotfix |

**Key**: Same tag promotes through all environments (dev → qa → prod)

---

## Detailed Sequences

### Development Deployment

```mermaid
sequenceDiagram
    participant Dev as Developer
    participant GH as GitHub
    participant Tek as Tekton
    participant AAP_D as AAP Dev

    Dev->>GH: Merge PR to main
    GH->>Tek: Trigger build pipeline
    Tek->>Tek: Build collection + EE
    Tek->>AAP_D: Apply AAP config<br/>(infra.aap_configuration)
    AAP_D-->>Dev: Deployment complete
```

### QA Promotion

```mermaid
sequenceDiagram
    participant Lead as QA Lead
    participant GH as GitHub
    participant Tek as Tekton
    participant AAP_Q as AAP QA

    Lead->>GH: Create release tag (25.01.05.0)
    GH->>Tek: Tag trigger → promotion
    Tek->>AAP_Q: Apply AAP config
    AAP_Q->>AAP_Q: Run smoke tests
    AAP_Q-->>Lead: Ready for testing
    Lead->>GH: Sign-off for prod
```

### Production Promotion

```mermaid
sequenceDiagram
    participant CAB as Change Advisory Board
    participant Tek as Tekton
    participant AAP_P as AAP Prod
    participant Backup as Backup Service

    CAB->>Tek: Approve deployment
    Tek->>Backup: Create backup
    Tek->>AAP_P: Apply AAP config
    AAP_P->>AAP_P: Health checks
    AAP_P-->>CAB: Deployed
```

---

## Rollback

### Quick Rollback

```bash
# Using Tekton pipeline
tkn pipeline start rollback \
  -p TARGET_VERSION=25.01.04.0 \
  -p ENVIRONMENT=prod

# Or Git revert (for platform changes)
cd cluster-config
git revert HEAD && git push
```

---

## Promotion Gates

| Gate | Dev → QA | QA → Prod |
|------|----------|-----------|
| Tests Pass | ✅ | ✅ |
| Security Scan | - | ✅ |
| Sign-off | Dev Lead | QA Lead |
| CAB Approval | - | ✅ |
| Backup | - | ✅ |

---

## Release Manifest Lifecycle

```mermaid
stateDiagram-v2
    [*] --> Created: Tekton build
    Created --> DevDeployed: Apply config
    DevDeployed --> DevValidated: Tests pass
    DevValidated --> QAPromoted: Git tag created
    QAPromoted --> QADeployed: Apply config
    QADeployed --> QAValidated: Tests pass
    QAValidated --> CABReview: Submit
    CABReview --> ProdDeployed: Approved
    CABReview --> QAValidated: Rejected
    ProdDeployed --> [*]: Complete
```

---

## Constitutional Alignment

- ✅ **Article I**: All promotions via Git
- ✅ **Article II**: Approvals enforced
- ✅ **Article III**: Atomic promotion via manifests
- ✅ **Article IV**: Quality gates at each stage
- ✅ **Article V**: No secrets in manifests
