# Versioning Strategy Rationale

**Why We Chose CalVer (YY.M.D-PATCH) Over SemVer**

---

## Quick Summary

| Aspect | Our Choice |
|--------|------------|
| **Format** | `YY.M.D-PATCH` (Calendar Versioning) |
| **Example** | `26.1.6-0` (January 6, 2026 - initial release) |
| **Alternative Considered** | SemVer (`MAJOR.MINOR.PATCH`) |
| **Decision** | CalVer for date-based clarity, operational simplicity, and collection compatibility |

---

## Why This Specific Format?

### Ansible Collection Compatibility

Ansible Galaxy requires **PEP 440 compatible versions**, which **do not allow leading zeros**:

```bash
# ❌ INVALID for collections (leading zeros)
26.01.06-0

# ✅ VALID for collections (no leading zeros)
26.1.6-0
```

To maintain **consistency across all components**, we use the same format everywhere:

| Component | Version | Notes |
|-----------|---------|-------|
| Git tags | `26.1.6-0` | Same format |
| Ansible Collections | `26.1.6-0` | PEP 440 compliant |
| Execution Environments | `26.1.6-0` | Same format |
| Release manifests | `26.1.6-0` | Same format |
| AAP Job Templates | `26.1.6-0` | Same format |

**Why not use leading zeros for everything except collections?**
- Consistency reduces cognitive load
- No format conversion needed in CI/CD pipelines
- Single source of truth for version format
- Simpler automation and tooling

### Sorting Consideration

Without leading zeros, string sorting doesn't equal chronological sorting:

```bash
# String sort (incorrect chronological order)
26.1.1-0
26.1.10-0   # ← Wrong position!
26.1.2-0

# Semantic version sort (correct order)
26.1.1-0
26.1.2-0
26.1.10-0   # ← Correct position
```

**Mitigation**: Use semantic version sorting in tooling (most package managers, container registries, and CI tools support this).

---

## Why CalVer Over SemVer?

### The Core Problem

In an enterprise Ansible automation platform, the question "What version is running in production?" often leads to follow-up questions:

- *"When was that deployed?"*
- *"How old is that release?"*
- *"What's different between prod and QA?"*

**SemVer** (e.g., `1.5.3`) tells you about API compatibility but nothing about *when* something was released.

**CalVer** (e.g., `26.1.6-0`) answers the "when" question instantly — you know exactly when the release was created just by reading the version.

---

## Pros of CalVer (YY.M.D-PATCH)

### ✅ **1. Instant Date Visibility**

The version number immediately tells you when something was released:

```
26.1.6-0   →  January 6, 2026 (initial release)
26.1.6-1   →  January 6, 2026 (first hotfix)
26.2.15-0  →  February 15, 2026
26.12.1-0  →  December 1, 2026
```

**With SemVer**, you'd need to cross-reference release notes:
```
1.5.3  →  When was this? Need to check docs/git log
```

**Impact**: Faster troubleshooting, easier auditing, simpler communication in incidents.

### ✅ **2. No Bikeshedding on Version Bumps**

SemVer requires decisions on every release:
- *"Is this a MAJOR, MINOR, or PATCH?"*
- *"Does this break the API?"*
- *"Are these features significant enough for a MINOR?"*

**CalVer eliminates this entirely**: The version is always today's date. No debate needed.

```bash
# Always the same decision process
# Get current date components without leading zeros
YEAR=$(date +%y)
MONTH=$(date +%-m)  # %-m removes leading zero
DAY=$(date +%-d)    # %-d removes leading zero
git tag -a "${YEAR}.${MONTH}.${DAY}-0" -m "Release description"
```

### ✅ **3. Natural Staleness Detection**

You can immediately see if a system is running outdated automation:

```
Prod:  26.1.6-0    ← 3 months old? Investigate!
QA:    26.4.10-0   ← Current
Dev:   26.4.12-0   ← Latest
```

With SemVer (`1.5.3` vs `1.5.7`), age isn't obvious without additional context.

### ✅ **4. Simplified Rollback Understanding**

When rolling back, the version tells you exactly how far back you're going:

```
Current:   26.4.10-0   (April 10)
Rollback:  26.4.5-0    (April 5)
```

You instantly know you're reverting to code from 5 days ago.

### ✅ **5. Consistent Across All Components**

The same version applies to:
- Git tags
- Ansible Collections
- Execution Environments
- AAP Job Templates
- Release manifests

```yaml
# Everything synchronized
Release: 26.1.6-0
  ├── AAP Config:   26.1.6-0
  ├── Collection:   26.1.6-0
  └── EE Image:     26.1.6-0
```

### ✅ **6. Works Well With Trunk-Based Development**

CalVer pairs naturally with trunk-based development:
- No long-lived release branches
- No version negotiation
- Single source of truth (`main`) + immutable tags

### ✅ **7. Human-Friendly Communication**

In meetings and incidents:
- *"We deployed the January 6th release"* → `26.1.6-0`
- *"Roll back to last week's release"* → Immediately find `26.1.3-0`

### ✅ **8. Immutability by Design**

A CalVer tag represents a specific point in time. You can't move `26.1.6-0` to a different commit because that would change "what January 6th means."

```bash
# ❌ Never do this (violates immutability)
git tag -d 26.1.6-0
git tag 26.1.6-0 <different-commit>
```

### ✅ **9. Audit Trail Clarity**

For compliance and auditing:
- *"What was running on March 15?"* → Check if `26.3.15-X` or earlier tag was deployed
- Easy to correlate versions with deployment dates

### ✅ **10. Collection Compatibility**

No format conversion needed — the same version string works everywhere:

```yaml
# galaxy.yml
version: 26.1.6-0  # ✅ Valid PEP 440

# git tag
git tag 26.1.6-0   # ✅ Same format

# container image
quay.io/myorg/ee:26.1.6-0  # ✅ Same format
```

---

## Cons of CalVer (YY.M.D-PATCH)

### ⚠️ **1. No Built-in API Compatibility Signal**

SemVer's MAJOR version tells you about breaking changes. CalVer doesn't:

```
SemVer: 2.0.0 → MAJOR bump = breaking changes expected
CalVer: 26.1.6-0 → No indication of breaking changes
```

**Mitigation**: Document breaking changes prominently in tag messages and CHANGELOG:

```bash
git tag -a 26.2.1-0 -m "⚠️ BREAKING CHANGES
- Removed deprecated inventory format
- Changed role variable names
See CHANGELOG.md for migration guide"
```

### ⚠️ **2. String Sorting Doesn't Equal Chronological Sorting**

Without leading zeros, simple string sorting produces incorrect order:

```
# String sort (wrong)
26.1.1-0, 26.1.10-0, 26.1.2-0

# Semantic sort (correct)
26.1.1-0, 26.1.2-0, 26.1.10-0
```

**Mitigation**: Use semantic version sorting in tooling. Most modern tools support this:
- Container registries (Quay, Harbor)
- Package managers (pip, ansible-galaxy)
- CI/CD systems (GitHub Actions, Tekton)

### ⚠️ **3. Multiple Releases Per Day Require PATCH**

If you release multiple times in a day, you increment PATCH:

```
26.1.6-0   # Morning release
26.1.6-1   # Afternoon hotfix
26.1.6-2   # Evening fix
```

This works fine but can feel awkward if `-0` isn't always the "final" release of the day.

### ⚠️ **4. Year 2100 Edge Case**

Two-digit years (`YY`) won't distinguish 2026 from 2126. This is unlikely to matter for most organizations.

**Mitigation**: Could switch to 4-digit years (`YYYY.M.D-PATCH`) if longevity is a concern.

### ⚠️ **5. Less Familiar to Some Teams**

SemVer is more widely known. CalVer may require onboarding:

```
Developer: "Is 26.1.6-0 compatible with 26.1.5-0?"
Answer: "Check the changelog — version numbers don't tell you"
```

**Mitigation**: Clear documentation and consistent CHANGELOG practices.

### ⚠️ **6. Doesn't Work Well for Libraries with API Contracts**

For public libraries or APIs where consumers need to understand compatibility, SemVer is often better.

**Our Case**: This is an *internal automation platform*, not a public library. We control all consumers.

### ⚠️ **7. Tag Pollution on High-Velocity Days**

Very active days could generate many tags:

```
26.1.6-0
26.1.6-1
26.1.6-2
26.1.6-3
26.1.6-4
```

**Mitigation**: This hasn't been a practical issue. Consolidate changes into fewer releases when possible.

---

## Why CalVer Works for This Platform

| Platform Characteristic | Why CalVer Fits |
|------------------------|-----------------|
| **Internal automation platform** | No external API contract to communicate |
| **Ops-focused** | "When was this deployed?" matters more than "Is this backward compatible?" |
| **Trunk-based development** | Single branch + tags = no version negotiation |
| **All components synchronized** | Same version everywhere simplifies tracking |
| **Rollback is common** | Date-based versions make rollback decisions clearer |
| **Compliance/auditing** | Easy to correlate versions with calendar dates |
| **Ansible collections** | PEP 440 compliance requires no leading zeros |

---

## When to Use SemVer Instead

CalVer isn't right for everything. Consider **SemVer** if:

| Scenario | Use SemVer |
|----------|------------|
| **Public library** | Consumers need API compatibility signals |
| **Long support windows** | `1.x` supported while `2.x` is current |
| **Feature-based releases** | Releases tied to features, not calendar |
| **Infrequent releases** | Monthly/quarterly releases make dates less meaningful |

---

## Version Format Deep Dive

### Format Breakdown

```
YY.M.D-PATCH
│  │ │ │
│  │ │ └── Hotfix number (0 = initial, 1+ = hotfixes)
│  │ └──── Day (1-31, no leading zero)
│  └────── Month (1-12, no leading zero)
└───────── Two-digit year (26 = 2026)
```

### Examples

| Version | Meaning |
|---------|---------|
| `26.1.6-0` | January 6, 2026 - Initial release |
| `26.1.6-1` | January 6, 2026 - First hotfix |
| `26.1.7-0` | January 7, 2026 - New release |
| `26.2.15-0` | February 15, 2026 - New release |
| `26.12.1-0` | December 1, 2026 - New release |
| `26.12.31-0` | December 31, 2026 - New release |

### Validation Regex

```regex
^[0-9]{2}\.(1[0-2]|[1-9])\.(3[01]|[12][0-9]|[1-9])-[0-9]+$
```

**Breakdown**:
- `[0-9]{2}` - Two-digit year
- `\.` - Literal dot
- `(1[0-2]|[1-9])` - Month 1-12 (no leading zero)
- `\.` - Literal dot
- `(3[01]|[12][0-9]|[1-9])` - Day 1-31 (no leading zero)
- `-` - Literal hyphen
- `[0-9]+` - Patch number (0 or more)

---

## Comparison Table: CalVer vs SemVer

| Aspect | CalVer (Our Choice) | SemVer |
|--------|---------------------|--------|
| **Format** | `YY.M.D-PATCH` | `MAJOR.MINOR.PATCH` |
| **Example** | `26.1.6-0` | `2.5.3` |
| **Date visibility** | ✅ Instant | ❌ Requires lookup |
| **API compatibility signal** | ❌ None | ✅ MAJOR bump = breaking |
| **Version decision** | ✅ Automatic (today's date) | ⚠️ Requires judgment |
| **Staleness detection** | ✅ Obvious from version | ❌ Not obvious |
| **String sorting** | ⚠️ Use semantic sort | ✅ Natural |
| **Familiarity** | ⚠️ Less common | ✅ Industry standard |
| **Multi-release days** | ⚠️ Increment PATCH | ✅ Natural |
| **Rollback clarity** | ✅ Excellent | ⚠️ Good |
| **Collection compatible** | ✅ PEP 440 valid | ✅ PEP 440 valid |

---

## Decision Record

### Decision

Use **CalVer (YY.M.D-PATCH)** for all versioning in this platform.

### Context

- Internal enterprise automation platform
- Trunk-based development workflow
- Ops-focused with frequent releases
- Need for quick "when was this released?" answers
- All components (collections, EEs, config) versioned together
- Ansible collections require PEP 440 compatible versions (no leading zeros)

### Consequences

**Positive:**
- Simplified versioning decisions
- Instant date visibility
- Clear rollback understanding
- Easy auditing and compliance
- Consistent format across all components
- No version format conversion needed

**Negative:**
- No API compatibility signal (mitigated by changelog)
- Less familiar to some team members (mitigated by documentation)
- Multiple same-day releases use PATCH (acceptable)
- Requires semantic sorting instead of string sorting (most tools support this)

### Status

**Accepted** - Effective January 2025

---

## Related Documentation

- [GIT-WORKFLOW.md](./GIT-WORKFLOW.md) - Branching and tagging workflow
- [EE-VERSIONING-STRATEGY.md](./EE-VERSIONING-STRATEGY.md) - Execution Environment versioning
- [NAMING-CONVENTIONS.md](./NAMING-CONVENTIONS.md) - Full naming standards
- [CICD-GUIDE.md](./CICD-GUIDE.md) - CI/CD pipeline integration

---

## External References

- **CalVer Specification**: https://calver.org/
- **SemVer Specification**: https://semver.org/
- **PEP 440 (Python Versioning)**: https://peps.python.org/pep-0440/
- **Ubuntu's CalVer**: https://ubuntu.com/about/release-cycle (uses `YY.MM`)
- **Comparison Article**: https://sedimental.org/designing_a_version.html
