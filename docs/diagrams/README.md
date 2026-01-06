# Architecture Diagrams

**Visual documentation of the Cloud-Native Ansible Lifecycle Platform**

## 📖 Diagram Index

This directory contains comprehensive architecture diagrams using Mermaid.js, which render beautifully on GitHub and in most modern documentation viewers.

### Core Architecture

1. **[Platform Architecture](./PLATFORM-ARCHITECTURE.md)** ⭐
   - Overall system architecture
   - Component responsibilities
   - Technology stack
   - Network architecture
   - Security layers
   - Constitutional alignment

2. **[GitOps Loops](./GITOPS-LOOPS.md)** ⭐
   - Dual GitOps loops (Platform + Application)
   - ArgoCD continuous sync
   - Tekton event-driven pipelines
   - Loop interactions and reconciliation
   - Failure handling

3. **[Promotion Flow](./PROMOTION-FLOW.md)** ⭐
   - Development to production pipeline
   - Release manifest lifecycle
   - Approval workflows
   - Rollback scenarios
   - Blue-green deployment

4. **[Repository Structure](./REPOSITORY-STRUCTURE.md)** ⭐
   - Repository organization
   - Directory structures
   - Repository relationships
   - Access patterns
   - Branching strategy

---

## 🚀 Quick Start

### Viewing Diagrams

All diagrams are in Markdown format with embedded Mermaid.js syntax:

- **GitHub**: Automatically rendered
- **VS Code**: Install "Markdown Preview Mermaid Support" extension
- **IntelliJ/PyCharm**: Built-in Mermaid support
- **Browser**: Use Mermaid Live Editor (https://mermaid.live)

### Using Diagrams in Presentations

1. **Export as PNG/SVG**:
   ```bash
   # Using mmdc (mermaid-cli)
   npm install -g @mermaid-js/mermaid-cli
   mmdc -i PLATFORM-ARCHITECTURE.md -o platform-arch.png
   ```

2. **Embed in Documentation**:
   - Copy the Mermaid code block
   - Paste into your markdown document
   - Will render automatically on GitHub

3. **Interactive Editing**:
   - Visit https://mermaid.live
   - Paste diagram code
   - Edit and download

---

## 📊 Diagram Overview

### Platform Architecture

**What it shows**: Complete platform overview with all components and their interactions.

**Key diagrams**:
- Overall Platform Architecture (high-level system view)
- Component Responsibilities (what each part does)
- Data Flow (code → test → build → deploy)
- Repository Architecture (Git repo relationships)
- Network Architecture (ingress, routes, services)
- Security Layers (4-layer security model)
- Constitutional Alignment (how principles are enforced)
- Technology Stack (all technologies used)

**Best for**:
- Executive presentations
- Onboarding new team members
- Understanding the big picture
- Architecture reviews

---

### GitOps Loops

**What it shows**: How the dual GitOps loops (ArgoCD + Tekton) work together.

**Key diagrams**:
- Dual Loop Overview (Platform + Application loops)
- Platform Loop (ArgoCD continuous sync)
- Application Loop (Tekton event-driven)
- Loop Interactions (how they coordinate)
- Repository Mapping (which repos use which loop)
- Reconciliation (how loops maintain state)
- Failure Handling (error scenarios)
- Comparison Matrix (Platform vs Application)

**Best for**:
- Understanding GitOps implementation
- Troubleshooting deployment issues
- Explaining continuous deployment
- Platform operations training

---

### Promotion Flow

**What it shows**: How code moves from development through QA to production.

**Key diagrams**:
- Complete Promotion Pipeline (end-to-end flow)
- Release Manifest Structure (version tracking)
- Development Deployment (automatic)
- QA Promotion (manual trigger)
- Production Promotion (approval + backup)
- Rollback Scenarios (dev, qa, prod)
- Promotion Gates (quality checkpoints)
- Version Progression (timeline view)
- Atomic Promotion Benefits (why it matters)
- Blue-Green Deployment (production strategy)

**Best for**:
- Release management
- Change advisory board presentations
- Understanding promotion process
- Incident response procedures

---

### Repository Structure

**What it shows**: Organization of Git repositories and their relationships.

**Key diagrams**:
- Repository Overview (all 5 repos)
- cluster-config Structure (platform configuration)
- aap-config-as-code Structure (AAP config)
- automation-collection Structure (Ansible content)
- automation-ee Structure (execution environments)
- automation-release-manifest Structure (version tracking)
- Repository Relationships (build & deployment flows)
- Access Patterns (daily workflows)
- Branching Strategy (Git flow)

**Best for**:
- Developer onboarding
- Understanding repository organization
- Finding files and configurations
- Planning new features

---

## 🎯 Diagram Use Cases

### For Developers

**Start with**:
1. [Repository Structure](./REPOSITORY-STRUCTURE.md) - Understand where code lives
2. [GitOps Loops](./GITOPS-LOOPS.md) - How your code gets deployed
3. [Promotion Flow](./PROMOTION-FLOW.md) - How releases work

**Focus on**:
- Repository directory structures
- Application Loop (Tekton)
- Development deployment
- Daily workflows

---

### For Platform Engineers

**Start with**:
1. [Platform Architecture](./PLATFORM-ARCHITECTURE.md) - Overall system design
2. [GitOps Loops](./GITOPS-LOOPS.md) - Platform Loop (ArgoCD)
3. [Repository Structure](./REPOSITORY-STRUCTURE.md) - cluster-config organization

**Focus on**:
- Platform Loop reconciliation
- Kubernetes resources
- Network architecture
- Security layers

---

### For Release Managers

**Start with**:
1. [Promotion Flow](./PROMOTION-FLOW.md) - End-to-end release process
2. [GitOps Loops](./GITOPS-LOOPS.md) - How promotions trigger deployments
3. [Repository Structure](./REPOSITORY-STRUCTURE.md) - Release manifest repo

**Focus on**:
- Promotion gates
- Approval workflows
- Rollback scenarios
- Manifest lifecycle

---

### For Leadership/Stakeholders

**Start with**:
1. [Platform Architecture](./PLATFORM-ARCHITECTURE.md) - Big picture
2. [Promotion Flow](./PROMOTION-FLOW.md) - How we do releases safely
3. [Platform Architecture > Constitutional Alignment](./PLATFORM-ARCHITECTURE.md#constitutional-alignment) - How principles are enforced

**Focus on**:
- Overall architecture
- Security layers
- Constitutional compliance
- Benefits of atomic promotion

---

## 🔍 Finding Specific Information

### "How do I..."

| Question | Diagram | Section |
|----------|---------|---------|
| ...understand the overall platform? | Platform Architecture | Overall Platform Architecture |
| ...find out how GitOps works here? | GitOps Loops | Dual Loop Overview |
| ...see how code gets to production? | Promotion Flow | Complete Promotion Pipeline |
| ...know where to put my code? | Repository Structure | automation-collection |
| ...understand the security model? | Platform Architecture | Security Layers |
| ...see how approvals work? | Promotion Flow | Approval Workflow |
| ...understand rollback procedures? | Promotion Flow | Rollback Scenarios |
| ...find network configuration? | Platform Architecture | Network Architecture |
| ...see the technology stack? | Platform Architecture | Technology Stack |
| ...understand Git workflow? | Repository Structure | Branching Strategy |

### "Where is..."

| Looking for | Diagram | Section |
|------------|---------|---------|
| ArgoCD configuration | Repository Structure | cluster-config/argocd/ |
| Tekton pipelines | Repository Structure | cluster-config/tekton/ |
| AAP configuration | Repository Structure | aap-config-as-code/ |
| Ansible roles | Repository Structure | automation-collection/roles/ |
| EE definitions | Repository Structure | automation-ee/ |
| Release manifests | Repository Structure | automation-release-manifest/ |
| CI/CD workflows | Repository Structure | .github/workflows/ |

---

## 📚 Diagram Conventions

### Color Coding

Throughout the diagrams, we use consistent colors to represent different concepts:

- 🔴 **Red (#ff6b6b)**: ArgoCD / Platform Loop
- 🔵 **Blue (#4ecdc4)**: Tekton / Application Loop / Testing
- 🟡 **Yellow (#ffe66d)**: Configuration / Manifests
- 🟢 **Green (#95e1d3)**: Deployments / Success States
- 🟠 **Orange (#ffd93d)**: Approvals / Gates

### Node Shapes

- **Rectangles**: Services, applications, processes
- **Rounded rectangles**: Data stores, repositories
- **Diamonds**: Decision points
- **Circles**: Start/end points
- **Parallelograms**: Data/documents

### Line Styles

- **Solid arrows (→)**: Direct actions, synchronous flow
- **Dashed arrows (-.->)**: Indirect relationships, async communication
- **Bold lines**: Primary/critical paths
- **Thin lines**: Secondary/supporting paths

---

## 🛠️ Editing Diagrams

### Prerequisites

```bash
# Install Mermaid CLI (optional, for local rendering)
npm install -g @mermaid-js/mermaid-cli

# Or use VS Code extension
code --install-extension bierner.markdown-mermaid
```

### Best Practices

1. **Keep diagrams focused**: One concept per diagram
2. **Use subgraphs**: Group related components
3. **Add notes**: Explain complex interactions
4. **Consistent naming**: Use same names across diagrams
5. **Test rendering**: Verify on GitHub before committing

### Testing Changes

```bash
# Validate Mermaid syntax
mmdc -i docs/diagrams/PLATFORM-ARCHITECTURE.md -o /tmp/test.png

# Or use online editor
# Visit: https://mermaid.live
```

---

## 📈 Diagram Statistics

| Diagram | Total Diagrams | Lines of Code | Key Concepts |
|---------|----------------|---------------|--------------|
| Platform Architecture | 8 | ~450 | Components, Flow, Security |
| GitOps Loops | 10 | ~520 | Loops, Reconciliation |
| Promotion Flow | 12 | ~680 | Promotion, Rollback, Gates |
| Repository Structure | 9 | ~580 | Repos, Structure, Workflows |
| **Total** | **39** | **~2,230** | **Full Platform** |

---

## 🔗 Related Documentation

### Getting Started
- [Getting Started Guide](../GETTING-STARTED.md) - Quick start
- [Development Guide](../DEVELOPMENT.md) - Development workflow

### Architecture
- [Constitution](../../.specify/memory/constitution.md) - Core principles
- [Specification](../../.specify/memory/specification.md) - Detailed requirements

### Operations
- [CI/CD Guide](../CICD-GUIDE.md) - Automation workflows
- [Testing Guide](../TESTING-GUIDE.md) - Testing strategies

### Standards
- [Naming Conventions](../NAMING-CONVENTIONS.md) - Naming standards
- [Code Style Guide](../CODE-STYLE-GUIDE.md) - Coding standards
- [Ansible Best Practices](../ANSIBLE-BEST-PRACTICES.md) - Ansible standards

---

## 💡 Tips for Using Diagrams

### During Meetings

1. **Screen share**: Open diagrams directly from GitHub
2. **Walk through flows**: Use sequence diagrams for step-by-step
3. **Zoom in**: Focus on specific subgraphs
4. **Link to details**: Reference other docs for depth

### In Documentation

1. **Link diagrams**: Reference specific sections
2. **Embed snippets**: Copy relevant Mermaid blocks
3. **Keep current**: Update diagrams with code changes
4. **Version control**: Diagrams live in Git like code

### For Training

1. **Start high-level**: Platform Architecture overview
2. **Drill down**: Move to specific flows
3. **Hands-on**: Have trainees walk through workflows
4. **Reference**: Use diagrams as ongoing reference

---

## 📝 Contributing

### Adding New Diagrams

1. **Create file**: `docs/diagrams/YOUR-DIAGRAM.md`
2. **Follow structure**: Use existing diagrams as templates
3. **Add to index**: Update this README
4. **Test rendering**: Verify on GitHub
5. **Get review**: PR with diagram changes

### Updating Existing Diagrams

1. **Identify changes**: What needs updating?
2. **Edit Mermaid code**: Maintain consistent style
3. **Test locally**: Use mmdc or online editor
4. **Update references**: Check if other docs reference this
5. **Submit PR**: Include screenshot in PR description

---

## 🎓 Learning Resources

### Mermaid.js Documentation
- **Official Docs**: https://mermaid.js.org/
- **Live Editor**: https://mermaid.live
- **Syntax Guide**: https://mermaid.js.org/intro/

### Diagram Types Used
- **Flowchart**: System architecture, flows
- **Sequence**: Interaction sequences
- **State**: Lifecycle, state machines
- **Gantt**: Timelines, schedules
- **Pie**: Statistics, distributions
- **Mindmap**: Concepts, categories
- **Timeline**: Version progression
- **Git Graph**: Branch strategies

---

## ✅ Validation

All diagrams are validated for:

- ✅ **Mermaid syntax**: Valid syntax, renders correctly
- ✅ **Constitutional compliance**: Aligns with 5 articles
- ✅ **Consistency**: Matches actual implementation
- ✅ **Completeness**: Covers all major components
- ✅ **Clarity**: Easy to understand
- ✅ **Maintenance**: Kept up-to-date with changes

---

## 🚀 Quick Links

| Quick Access | Link |
|--------------|------|
| 🏗️ Platform Overview | [Platform Architecture](./PLATFORM-ARCHITECTURE.md) |
| 🔄 GitOps Explanation | [GitOps Loops](./GITOPS-LOOPS.md) |
| 📦 Release Process | [Promotion Flow](./PROMOTION-FLOW.md) |
| 📁 Code Organization | [Repository Structure](./REPOSITORY-STRUCTURE.md) |
| 📚 Full Documentation | [Documentation Index](../INDEX.md) |
| 🏠 Project Home | [Main README](../../README.md) |
