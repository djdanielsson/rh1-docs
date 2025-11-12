# Ansible Automation Platform Code Lifecycle - Workflow Diagrams

## Git Workflow - Trunk-Based Development with Tags

```mermaid
gitGraph
    commit id: "Initial commit"
    commit id: "Setup project structure"
    
    branch feature/webserver-role
    checkout feature/webserver-role
    commit id: "Create webserver role"
    commit id: "Add tasks"
    commit id: "Add molecule tests"
    commit id: "Fix ansible-lint issues"
    
    checkout main
    merge feature/webserver-role tag: "Merge PR #123"
    
    branch feature/database-role
    checkout feature/database-role
    commit id: "Create database role"
    commit id: "Add handlers"
    
    checkout main
    branch feature/monitoring
    checkout feature/monitoring
    commit id: "Add monitoring tasks"
    commit id: "Update requirements.yml"
    
    checkout main
    merge feature/database-role tag: "Merge PR #124"
    commit id: "Update EE definition"
    commit id: "Dev testing passed" tag: "qa-v1.1.0"
    
    checkout feature/monitoring
    commit id: "Fix molecule tests"
    
    checkout main
    merge feature/monitoring tag: "Merge PR #125"
    commit id: "QA testing passed" tag: "prod-v1.0.0"
    
    commit id: "Hotfix: update vars"
    commit id: "Tested in dev" tag: "qa-v1.1.1"
    commit id: "QA verified" tag: "prod-v1.0.1"
```

### Git Workflow Explanation

**Trunk-Based Development Strategy:**
- **main branch**: Single source of truth, always deployable
- **Feature branches**: Short-lived, merge back to main frequently
- **Git tags**: Immutable markers for environment promotion
  - `qa-vX.Y.Z`: Tags for QA environment deployment
  - `prod-vX.Y.Z`: Tags for Production environment deployment

**Workflow Steps:**
1. Create feature branch from main
2. Develop playbooks/roles/collections
3. Run local tests (ansible-lint, molecule)
4. Create Pull Request
5. CI/CD runs automated tests
6. Code review and approval
7. Merge to main
8. Test in Dev environment (tracks main branch)
9. Create QA tag when Dev tests pass
10. Deploy to QA using tag
11. Create Prod tag when QA tests pass
12. Deploy to Prod using tag

**Key Benefits:**
- Simplified Git management (no long-lived environment branches)
- Immutable releases via tags
- Clear promotion path: Dev (main) → QA (tag) → Prod (tag)
- Easy rollback (deploy previous tag)

---

## Code Development and Testing Flow

```mermaid
flowchart TD
    Start([New Feature/Fix]) --> Clone[Clone Repository]
    Clone --> Branch[Create Feature Branch<br/>feature/my-feature]
    
    Branch --> DevLoop{Development<br/>Cycle}
    
    DevLoop --> Code[Write Ansible Code<br/>Playbooks/Roles/Collections]
    Code --> Structure[Follow Standards<br/>- defaults/main.yml<br/>- vars/main.yml<br/>- Variable prefixes<br/>- FQCNs]
    
    Structure --> LocalTest[Local Testing]
    LocalTest --> Lint[ansible-lint]
    Lint --> Molecule[Molecule Tests<br/>molecule converge<br/>molecule verify]
    Molecule --> Idempotent[Idempotence Check]
    
    Idempotent --> LocalPass{Tests Pass?}
    LocalPass -->|No| DevLoop
    LocalPass -->|Yes| Commit[Git Commit<br/>Clear message]
    
    Commit --> Push[Push Feature Branch]
    Push --> PR[Create Pull Request]
    
    PR --> CI[CI/CD Pipeline Triggered]
    CI --> CI_Lint[ansible-lint]
    CI --> CI_Molecule[molecule test]
    CI --> CI_Other[Other checks]
    
    CI_Other --> CIPass{CI Pass?}
    CIPass -->|No| DevLoop
    CIPass -->|Yes| Review[Code Review]
    
    Review --> ReviewPass{Approved?}
    ReviewPass -->|No| DevLoop
    ReviewPass -->|Yes| Merge[Merge to main]
    
    Merge --> MainBranch[(main Branch)]
    MainBranch --> DevDeploy[Dev Environment<br/>Auto-syncs main]
    
    DevDeploy --> DevTest{Integration<br/>Tests Pass?}
    DevTest -->|No| Hotfix[Create Hotfix Branch]
    Hotfix --> DevLoop
    
    DevTest -->|Yes| QATag[Create QA Tag<br/>qa-vX.Y.Z]
    QATag --> QAReady([Ready for QA Deployment])
    
    style Code fill:#fff4e1
    style LocalTest fill:#ffe1f5
    style CI fill:#ffe1f5
    style MainBranch fill:#e1f5ff
    style QATag fill:#90EE90
    style QAReady fill:#90EE90
```

### Development Flow Key Points

**Local Development:**
- Feature branches for all changes
- Local testing before pushing
- ansible-lint for code quality
- Molecule for role/collection testing

**CI/CD Integration:**
- Automated testing on every PR
- Blocks merge if tests fail
- Enforces code quality standards

**Code Standards:**
- Idempotent playbooks
- Named tasks for debugging
- Proper variable precedence (defaults vs vars)
- FQCN for all modules
- Comprehensive README files

---

## Complete AAP Deployment Pipeline

```mermaid
flowchart TD
    Start([Start: Automation Need]) --> Phase1[Phase 1: Plan & Structure]
    
    Phase1 --> P1_1[Define Goal]
    Phase1 --> P1_2[Setup Inventories<br/>Dev/QA/Prod]
    Phase1 --> P1_3[Setup Dev Environment<br/>IDE, ADT, VSCode]
    Phase1 --> P1_4[Adopt Project Structure<br/>Alternative Directory Layout]
    Phase1 --> P1_5[Standardize Role Creation<br/>ansible-creator]
    Phase1 --> P1_6[Utilize Collections<br/>requirements.yml]
    
    P1_6 --> Phase2[Phase 2: Develop & Version]
    
    Phase2 --> P2_1[Write High-Quality Code<br/>Idempotent, Named Tasks]
    Phase2 --> P2_2[Manage Secrets<br/>AAP Credentials]
    Phase2 --> P2_3[Version Control in Git<br/>main branch]
    
    P2_3 --> FeatureBranch[Create Feature Branch]
    FeatureBranch --> P2_4[Code Development]
    P2_4 --> LocalLint[Local: ansible-lint]
    
    LocalLint --> Phase3[Phase 3: Test]
    
    Phase3 --> P3_1[Molecule Testing<br/>Local/Container]
    P3_1 --> P3_2[molecule converge]
    P3_2 --> P3_3[molecule verify]
    P3_3 --> P3_4[Idempotence Check]
    
    P3_4 --> PR[Create Pull Request]
    PR --> CI[CI/CD Pipeline]
    CI --> CI_Lint[Run ansible-lint]
    CI --> CI_Molecule[Run molecule test]
    
    CI_Molecule --> CodeReview[Code Review]
    CodeReview --> MergeMain[Merge to main]
    
    MergeMain --> MainBranch[(Git main Branch)]
    
    MainBranch --> DevSync[Dev AAP Project<br/>Syncs main branch]
    DevSync --> DevTest{Test in Dev?}
    DevTest -->|Pass| CreateQATag[Create Git Tag<br/>qa-v1.1.0]
    DevTest -->|Fail| FeatureBranch
    
    CreateQATag --> BuildEE[Build Execution Environment<br/>ansible-builder]
    BuildEE --> TagEE[Tag EE Image<br/>my-registry/my-ee:qa-v1.1.0]
    TagEE --> PushEE[Push to Container Registry<br/>Automation Hub/Quay]
    
    PushEE --> UpdateCaC[Update CaC Definitions<br/>infra.aap_configuration]
    UpdateCaC --> CaCGit[(CaC Git Repository)]
    
    CaCGit --> Phase4QA[Phase 4: Deploy to QA]
    
    Phase4QA --> WF_QA[QA Workflow Job Template]
    WF_QA --> QA1[Sync QA Project<br/>Tag: qa-v1.1.0]
    QA1 --> QA2[Pull EE Image<br/>qa-v1.1.0]
    QA2 --> QA3[Run Job Template<br/>QA Inventory]
    QA3 --> QA4{QA Tests Pass?}
    
    QA4 -->|Fail| QA_Rollback[Rollback JT]
    QA_Rollback --> FeatureBranch
    
    QA4 -->|Pass| QA_Approval[Approval Node<br/>QA Sign-off]
    
    QA_Approval -->|Approved| CreateProdTag[Create Git Tag<br/>prod-v1.0.0]
    QA_Approval -->|Rejected| FeatureBranch
    
    CreateProdTag --> BuildProdEE[Build/Tag Prod EE<br/>prod-v1.0.0]
    BuildProdEE --> PushProdEE[Push to Registry]
    
    PushProdEE --> UpdateProdCaC[Update Prod CaC]
    UpdateProdCaC --> Phase4Prod[Phase 4: Deploy to Prod]
    
    Phase4Prod --> WF_Prod[Prod Workflow Job Template]
    WF_Prod --> Prod1[Sync Prod Project<br/>Tag: prod-v1.0.0]
    Prod1 --> Prod2[Pull EE Image<br/>prod-v1.0.0]
    Prod2 --> Prod3[Run Job Template<br/>Prod Inventory]
    Prod3 --> Prod4{Prod Deploy Success?}
    
    Prod4 -->|Fail| Prod_Rollback[Rollback JT<br/>Previous Tag]
    Prod_Rollback --> Incident[Incident Review]
    
    Prod4 -->|Success| Prod_Approval[Approval Node<br/>Prod Sign-off]
    Prod_Approval --> Complete([Deployment Complete])
    
    Phase5[Phase 5: Manage AAP - CaC] -.->|Configures| Phase4QA
    Phase5 -.->|Configures| Phase4Prod
    Phase5 --> CaC1[AAP Configuration as Code<br/>Projects, JTs, WFJTs, EEs]
    CaC1 --> CaC2[GitOps Workflow<br/>PR/MR for Changes]
    CaC2 --> CaC3[CI/CD Auto-applies<br/>to AAP Instances]
    
    style Phase1 fill:#e1f5ff
    style Phase2 fill:#fff4e1
    style Phase3 fill:#ffe1f5
    style Phase4QA fill:#e1ffe1
    style Phase4Prod fill:#e1ffe1
    style Phase5 fill:#f5e1ff
    style Complete fill:#90EE90
    style QA_Rollback fill:#ffcccc
    style Prod_Rollback fill:#ffcccc
```

## Key Components

### Phase 1: Plan & Structure (Blue)
- Define automation goals
- Setup development environment
- Configure AAP inventories for Dev/QA/Prod
- Establish project structure and role standards
- Define collections and dependencies

### Phase 2: Develop & Version (Orange)
- Feature branch development
- Code quality standards (idempotency, naming)
- Local linting with ansible-lint
- Version control with Git (trunk-based development)
- Pull Request workflow

### Phase 3: Test (Pink)
- Molecule testing framework
- Local container-based testing
- CI/CD pipeline integration
- Code review process
- Automated quality gates

### Phase 4: Deploy & Orchestrate (Green)
- **Dev Environment**: Syncs main branch for continuous testing
- **QA Environment**: 
  - Uses tagged releases (qa-vX.Y.Z)
  - Synchronized EE images
  - Approval gates
  - Automated rollback on failure
- **Prod Environment**:
  - Uses production tags (prod-vX.Y.Z)
  - Version-locked EE images
  - Multiple approval gates
  - Rollback capabilities

### Phase 5: Manage AAP - Configuration as Code (Purple)
- AAP configuration managed in Git
- GitOps workflow for infrastructure changes
- Automated application of configurations
- Environment-specific variables

## Key Synchronization Points

1. **Git Tags**: Immutable release markers (qa-v1.1.0, prod-v1.0.0)
2. **EE Images**: Version-tagged to match Git tags
3. **AAP Projects**: Point to specific Git tags per environment
4. **CaC Definitions**: Ensure correct configuration per environment

## Workflow Features

- **Continuous Testing**: Dev environment continuously syncs main branch
- **Progressive Promotion**: Dev → QA → Prod with gates
- **Approval Nodes**: Human checkpoints before QA and Prod
- **Rollback Capability**: Automated rollback on failures
- **Version Control**: Everything tracked in Git (code, configs, EEs)
- **Immutable Releases**: Tags create fixed points in time


