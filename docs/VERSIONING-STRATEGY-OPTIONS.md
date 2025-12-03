# Versioning Strategy Options

**Document Purpose**: Facilitate decision-making on versioning scheme for the Ansible Automation Platform lifecycle

**Status**: 🟡 Draft - Pending Decision  
**Created**: 2025-12-03  
**Decision Required By**: [TBD]

---

## Table of Contents

- [Current State](#current-state)
- [Versioning Options Overview](#versioning-options-overview)
- [Detailed Comparison](#detailed-comparison)
- [Hybrid Approaches](#hybrid-approaches)
- [Recommended Options](#recommended-options)
- [Implementation Impact](#implementation-impact)
- [Decision Framework](#decision-framework)
- [Next Steps](#next-steps)

---

## Current State

### What We Currently Use

| Component | Current Format | Example |
|-----------|---------------|---------|
| **Git Tags - Dev** | `dev-<commit-sha>` | `dev-abc1234` |
| **Git Tags - QA** | `qa-v<semver>` | `qa-v1.1.0` |
| **Git Tags - Prod** | `prod-v<semver>` | `prod-v1.0.0` |
| **Release Manifests** | `<semver>` | `1.0.0` |
| **Collection (galaxy.yml)** | SemVer | `1.0.0` |
| **EE Images** | Tag matches code | `ee:qa-v1.1.0` |

### Current Documentation

- **BRANCHING-STRATEGY.md**: Defines trunk-based dev with SemVer tags
- **EE-VERSIONING-STRATEGY.md**: Synchronizes EE tags with code tags
- **Release manifests**: Lock versions atomically across components

---

## Versioning Options Overview

### Option 1: SemVer (Semantic Versioning) 🟢 CURRENT

```
MAJOR.MINOR.PATCH
```

**Format**: `v1.2.3`

**Examples:**
- `v1.0.0` - Initial release
- `v1.1.0` - Add new feature
- `v1.1.1` - Bug fix
- `v2.0.0` - Breaking change

**Meaning:**
- **MAJOR** - Breaking changes
- **MINOR** - New features (backward compatible)
- **PATCH** - Bug fixes

**Pros:**
- ✅ Clear compatibility signaling
- ✅ Industry standard for libraries/APIs
- ✅ Well understood by developers
- ✅ Supported by all tooling
- ✅ Already implemented in our codebase

**Cons:**
- ❌ No indication of release date
- ❌ Doesn't reflect regular release cadence
- ❌ Version numbers can grow large
- ❌ Subjective (is it major or minor?)

**Best For:**
- Libraries and collections consumed by others
- APIs with compatibility contracts
- Projects with unpredictable release schedules

**Used By:** npm packages, Python packages, Ansible collections, Kubernetes

---

### Option 2: CalVer (Calendar Versioning)

```
YYYY.MM.DD or YYYY.MM or YY.MM
```

**Format Options:**

| Format | Example | Use Case |
|--------|---------|----------|
| `YYYY.MM.DD` | `2025.12.03` | Daily releases |
| `YYYY.MM` | `2025.12` | Monthly releases |
| `YY.MM` | `25.12` | Short format |
| `YYYY.WW` | `2025.49` | Week-based |

**Pros:**
- ✅ Instant visibility on release age
- ✅ Aligns with scheduled release cycles
- ✅ Simple to understand for ops teams
- ✅ No debate about version bumps
- ✅ Great for platform/infrastructure releases

**Cons:**
- ❌ No compatibility signaling
- ❌ Harder to convey breaking changes
- ❌ Unusual for libraries
- ❌ Time-zone considerations for daily releases

**Best For:**
- Platform releases with regular schedules
- Infrastructure/ops-focused projects
- Application deployments
- When "how old is this?" matters

**Used By:** Ubuntu (24.04), pip, Black, PyCharm, IntelliJ IDEA

---

### Option 3: Hybrid CalVer + SemVer

Multiple hybrid combinations possible:

#### 3a. CalVer.MICRO

```
YYYY.MM.MICRO
```

**Examples:**
- `2025.12.0` - December 2025 release
- `2025.12.1` - Hotfix 1
- `2025.12.2` - Hotfix 2
- `2026.01.0` - January 2026 release

**Pros:**
- ✅ Date-based + hotfix support
- ✅ Clear release timeframe
- ✅ Simple incremental patches

**Cons:**
- ❌ No breaking change signal
- ❌ Monthly releases only (or builds up fast)

**Used By:** Black (Python formatter), many PyCharm plugins

---

#### 3b. CalVer.MINOR.PATCH

```
YYYY.MINOR.PATCH
```

**Examples:**
- `2025.0.0` - First 2025 release
- `2025.1.0` - Second feature release
- `2025.1.1` - Patch
- `2026.0.0` - First 2026 release

**Pros:**
- ✅ Year visibility + traditional versioning
- ✅ Supports multiple releases per year
- ✅ Has patch capability

**Cons:**
- ❌ MINOR loses semantic meaning
- ❌ No month visibility

**Used By:** pip (24.0, 24.1, 24.2)

---

#### 3c. MAJOR.CalVer

```
MAJOR.YYYY.MM
```

**Examples:**
- `1.2025.12` - Version 1.x, December 2025
- `1.2026.01` - Version 1.x, January 2026
- `2.2026.06` - Version 2.x (breaking), June 2026

**Pros:**
- ✅ Preserves major version for breaking changes
- ✅ Date visibility
- ✅ Best of both worlds

**Cons:**
- ❌ Longer version strings
- ❌ Less common format

---

#### 3d. Environment + CalVer.MICRO

```
ENV-YYYY.MM.MICRO
```

**Examples:**
- `dev-2025.12.03` - Dev snapshot Dec 3
- `qa-2025.12.0` - QA release December
- `qa-2025.12.1` - QA hotfix
- `prod-2025.12.0` - Prod release December

**Pros:**
- ✅ Environment explicitly tagged
- ✅ Date-based
- ✅ Hotfix support
- ✅ Matches current environment pattern

**Cons:**
- ❌ Environment prefix not standard versioning
- ❌ Redundant if stored in metadata

---

## Detailed Comparison

### Scenario Analysis

| Scenario | SemVer | CalVer | Hybrid (CalVer.MICRO) |
|----------|--------|--------|----------------------|
| **Regular monthly releases** | `v1.0.0`, `v1.1.0`, `v1.2.0` | `2025.12`, `2026.01`, `2026.02` | `2025.12.0`, `2026.01.0`, `2026.02.0` |
| **Hotfix needed** | `v1.1.1` | `2026.01.1`? (awkward) | `2026.01.1` ✅ |
| **Breaking change** | `v2.0.0` ✅ | `2026.06` (not clear) | `2.2026.06.0` (with major) |
| **Know release age** | Not visible | `2025.12` ✅ | `2025.12.0` ✅ |
| **Multiple releases same day** | `v1.1.0`, `v1.1.1` | Hard | `2025.12.0`, `2025.12.1` |

---

## Hybrid Approaches

### Multi-Component Strategy

**Use different versioning for different components based on their nature:**

| Component | Recommended Versioning | Rationale |
|-----------|----------------------|-----------|
| **Ansible Collections** | SemVer (`1.2.0`) | Consumed as libraries, need compatibility signals |
| **AAP Configuration** | CalVer or Hybrid (`2025.12.0`) | Configuration changes over time, ops-focused |
| **Execution Environments** | Match collection or CalVer | Tied to runtime dependencies |
| **Release Manifests** | CalVer (`2025.12.0`) | Represents deployment date |
| **Git Tags** | Environment + version | Maintains current pattern |

### Example Multi-Component Implementation

```yaml
# Release Manifest: release-2025.12.0.yaml
version: "2025.12.0"                    # CalVer for platform release
created: "2025-12-03T10:00:00Z"

components:
  aap_configuration:
    repository: "github.com/org/aap-config"
    tag: "prod-2025.12.0"              # Environment + CalVer
    commit: "abc123..."

  collections:
    namespace: "myorg"
    name: "custom_collection"
    version: "1.2.0"                    # SemVer for library semantics
    tag: "v1.2.0"
    commit: "def456..."

  execution_environment:
    image: "quay.io/myorg/ee:2025.12.0" # CalVer matching release
    digest: "sha256:..."
```

---

## Recommended Options

### 🥇 Recommendation 1: Hybrid Multi-Component (BEST FLEXIBILITY)

**Strategy**: Different versioning schemes per component type

```
Collections (libraries):    v1.2.0              (SemVer)
AAP Config (platform):      prod-2025.12.0      (Env + CalVer.MICRO)
EE Images:                  2025.12.0           (CalVer.MICRO)
Release Manifests:          2025.12.0           (CalVer.MICRO)
```

**Pros:**
- ✅ Each component uses appropriate versioning
- ✅ Collections signal compatibility (SemVer)
- ✅ Platform shows release date (CalVer)
- ✅ Hotfix support via MICRO
- ✅ Minimal breaking changes to current setup

**Cons:**
- ❌ Mixed versioning to manage
- ❌ Requires clear documentation

**Implementation Effort**: Medium

---

### 🥈 Recommendation 2: Pure Hybrid CalVer.MICRO (SIMPLICITY)

**Strategy**: Single hybrid scheme across all components

```
All components:  YYYY.MM.MICRO
Git tags:        env-YYYY.MM.MICRO

dev-2025.12.03
qa-2025.12.0
prod-2025.12.0
```

**Pros:**
- ✅ Single consistent approach
- ✅ Date visibility
- ✅ Hotfix support
- ✅ Simpler to explain

**Cons:**
- ❌ No breaking change signal
- ❌ Changes collection versioning pattern

**Implementation Effort**: Medium-High

---

### 🥉 Recommendation 3: Keep SemVer, Add CalVer Metadata (MINIMAL CHANGE)

**Strategy**: Keep current SemVer, add CalVer as metadata

```yaml
# Release manifest
version: "1.2.0"              # SemVer (current)
metadata:
  calver: "2025.12"          # Added: Calendar version
  release_date: "2025-12-03"
```

**Pros:**
- ✅ No breaking changes
- ✅ Keeps SemVer benefits
- ✅ Adds date tracking
- ✅ Easy to implement

**Cons:**
- ❌ Primary version still lacks date info
- ❌ Doesn't solve the core ask

**Implementation Effort**: Low

---

## Implementation Impact

### Changes Required by Option

#### Option 1: Multi-Component Hybrid

**Files to Update:**
- ✏️ `docs/BRANCHING-STRATEGY.md` - Update tag format table
- ✏️ `docs/EE-VERSIONING-STRATEGY.md` - Update EE tag examples
- ✏️ `automation-release-manifest/schemas/release-manifest-schema.json` - Update version patterns
- ✏️ `automation-release-manifest/templates/release-template.yaml` - Update examples
- ✏️ `automation-collection-example/galaxy.yml` - Keep SemVer (no change)
- ✏️ CI/CD pipelines - Update tag validation regex

**Git Tag Changes:**
```bash
# OLD
git tag qa-v1.1.0
git tag prod-v1.0.0

# NEW
git tag qa-2025.12.0
git tag prod-2025.12.0

# Collections stay the same
git tag v1.2.0  # In collection repo
```

**Breaking Changes:**
- Git tag format changes
- Existing automation may need regex updates
- Documentation references

---

#### Option 2: Pure CalVer

**Files to Update:**
- Same as Option 1, plus:
- ✏️ `automation-collection-example/galaxy.yml` - Change to CalVer

**Git Tag Changes:**
```bash
# Everything moves to CalVer
git tag 2025.12.0  # Collection
git tag qa-2025.12.0  # QA
git tag prod-2025.12.0  # Prod
```

**Breaking Changes:**
- More extensive changes
- Collection versioning paradigm shift
- May confuse collection consumers

---

#### Option 3: Add Metadata Only

**Files to Update:**
- ✏️ `automation-release-manifest/schemas/release-manifest-schema.json` - Add metadata fields
- ✏️ Scripts to populate CalVer metadata

**Git Tag Changes:**
- None

**Breaking Changes:**
- None

---

## Decision Framework

### Questions to Answer

#### 1. Release Cadence
- ❓ Do we have a regular release schedule? (monthly, quarterly)
- ❓ Are releases time-driven or feature-driven?

**If time-driven → CalVer makes more sense**  
**If feature-driven → SemVer makes more sense**

---

#### 2. Breaking Changes
- ❓ How often do we have breaking changes?
- ❓ Do consumers need to know about compatibility?

**If frequent breaking changes → Keep SemVer or MAJOR.CalVer**  
**If rare breaking changes → CalVer acceptable**

---

#### 3. Audience
- ❓ Who consumes our versions? (internal ops vs external users)
- ❓ Are collections published to Galaxy for external use?

**If external library consumers → SemVer for collections**  
**If internal ops only → CalVer more practical**

---

#### 4. Tooling
- ❓ Do we have tooling that depends on current version format?
- ❓ How much effort to update CI/CD pipelines?

**If heavy tooling dependencies → Minimize changes**  
**If flexible automation → More freedom to change**

---

#### 5. Team Preference
- ❓ What does the team find easier to work with?
- ❓ What aligns with organizational standards?

---

### Decision Matrix

| Criteria | Weight | SemVer (Current) | Multi-Component Hybrid | Pure CalVer |
|----------|--------|------------------|----------------------|-------------|
| **Compatibility signaling** | High | ⭐⭐⭐ | ⭐⭐⭐ | ⭐ |
| **Release date visibility** | Medium | ⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| **Ease of use (ops)** | High | ⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ |
| **Industry standard** | Medium | ⭐⭐⭐ | ⭐⭐ | ⭐⭐ |
| **Implementation effort** | Medium | ⭐⭐⭐ (no change) | ⭐⭐ | ⭐ |
| **Hotfix support** | High | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ |
| **Breaking change signal** | High | ⭐⭐⭐ | ⭐⭐⭐ | ⭐ |

---

## Examples from Real Projects

### Organizations Using SemVer
- **Ansible Collections**: All official collections use SemVer
- **Kubernetes**: API versioning (v1, v2)
- **npm ecosystem**: Package versioning

### Organizations Using CalVer
- **Ubuntu**: 24.04, 24.10 (YY.MM)
- **pip**: 24.0, 24.1, 24.2 (YY.MINOR)
- **Black**: 24.10.0 (YY.MM.MICRO)

### Organizations Using Hybrid
- **PyCharm**: 2024.3.1 (YYYY.MINOR.PATCH)
- **IntelliJ IDEA**: 2024.2 (YYYY.MINOR)
- Many enterprise platforms

---

## Next Steps

### Decision Process

1. **📋 Review this document** with the team
2. **💬 Discuss trade-offs** in team meeting
3. **🗳️ Vote/decide** on preferred approach
4. **📝 Document decision** in this file
5. **🔨 Create implementation plan**
6. **🚀 Execute migration** (if changing from current)

### Decision Template

```markdown
## DECISION RECORD

**Date**: [YYYY-MM-DD]
**Decision Made By**: [Team/Individual]
**Decision**: [Chosen Option]

**Rationale**:
- [Reason 1]
- [Reason 2]
- [Reason 3]

**Action Items**:
- [ ] Task 1
- [ ] Task 2
- [ ] Task 3

**Timeline**: [Start Date] to [Completion Date]
```

---

## Appendix: Conversion Examples

### Example: Current Month Migration

If migrating to CalVer today (December 2025):

```bash
# Current tags
qa-v1.1.0
prod-v1.0.0

# Would become
qa-2025.12.0
prod-2025.12.0

# Next month
qa-2026.01.0
prod-2026.01.0

# Hotfix
prod-2025.12.1
```

### Example: Git Tag Commands

```bash
# SemVer (current)
git tag -a qa-v1.2.0 -m "Release 1.2.0 for QA"

# CalVer.MICRO
git tag -a qa-2025.12.0 -m "December 2025 QA Release"

# Hybrid with environment
git tag -a prod-2025.12.0 -m "Production Release December 2025
Features:
- Monitoring role
- Database backup

Approved: CHG0001234"
```

---

## References

- **SemVer Spec**: https://semver.org/
- **CalVer Spec**: https://calver.org/
- **Current Branching Strategy**: [BRANCHING-STRATEGY.md](./BRANCHING-STRATEGY.md)
- **Current EE Versioning**: [EE-VERSIONING-STRATEGY.md](./EE-VERSIONING-STRATEGY.md)
- **Release Manifests**: [../automation-release-manifest/README.md](../automation-release-manifest/README.md)

---

**Status**: 🟡 Awaiting Decision  
**Last Updated**: 2025-12-03  
**Next Review**: [TBD]

