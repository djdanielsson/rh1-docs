# Architecture Diagrams

Visual documentation of the Cloud-Native Ansible Lifecycle Platform using Mermaid.js.

---

## Diagram Index

| Diagram | Description |
|---------|-------------|
| [Platform Architecture](./PLATFORM-ARCHITECTURE.md) | ⭐ Overall system design, components, security layers |
| [GitOps Loops](./GITOPS-LOOPS.md) | ⭐ Dual GitOps loops (ArgoCD + Tekton) |
| [Promotion Flow](./PROMOTION-FLOW.md) | ⭐ Dev → QA → Prod pipeline, release manifests |
| [Repository Structure](./REPOSITORY-STRUCTURE.md) | Git repository organization and relationships |

---

## Viewing Diagrams

- **GitHub**: Automatically rendered
- **VS Code**: Install "Markdown Preview Mermaid Support" extension
- **Live Editor**: https://mermaid.live

---

## Quick Reference

### By Role

| Role | Start With |
|------|------------|
| **New Developer** | [Repository Structure](./REPOSITORY-STRUCTURE.md) → [GitOps Loops](./GITOPS-LOOPS.md) |
| **Platform Engineer** | [Platform Architecture](./PLATFORM-ARCHITECTURE.md) → [GitOps Loops](./GITOPS-LOOPS.md) |
| **Release Manager** | [Promotion Flow](./PROMOTION-FLOW.md) → [GitOps Loops](./GITOPS-LOOPS.md) |

### Common Questions

| Question | Diagram |
|----------|---------|
| How does GitOps work? | [GitOps Loops](./GITOPS-LOOPS.md) |
| How do releases get to production? | [Promotion Flow](./PROMOTION-FLOW.md) |
| What's the security model? | [Platform Architecture](./PLATFORM-ARCHITECTURE.md#security-layers) |
| Where does my code go? | [Repository Structure](./REPOSITORY-STRUCTURE.md) |

---

## Related Documentation

- [Getting Started](../GETTING-STARTED.md)
- [Git Workflow](../GIT-WORKFLOW.md)
- [CI/CD Guide](../CICD-GUIDE.md)
