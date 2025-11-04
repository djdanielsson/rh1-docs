# Standards & Conventions Summary

Comprehensive overview of all standards, conventions, and best practices for the Cloud-Native Ansible Lifecycle Platform.

## 📚 Documentation Created

### 1. **Naming Conventions** (`NAMING-CONVENTIONS.md`)

Complete naming standards for:
- **Repositories**: `{purpose}-{type}` (e.g., `cluster-config`)
- **Files**: Context-specific formats (playbooks: `{verb}-{noun}.yml`)
- **Variables**: `{role}_{category}_{name}` (e.g., `webserver_port`)
- **Kubernetes Resources**: `{app}-{component}-{environment}`
- **AAP Resources**: Descriptive names (e.g., "Deploy Web Application")
- **Git Branches**: `{type}/{description}` (e.g., `feature/add-role`)
- **Git Commits**: `{type}: {description}` (e.g., `feat: add webserver`)
- **Tags**: `v{major}.{minor}.{patch}` (e.g., `v1.0.0`)

**Key Principles**:
- Be descriptive
- Be consistent  
- Be concise
- Use standard abbreviations

### 2. **Code Style Guide** (`CODE-STYLE-GUIDE.md`)

Comprehensive style standards for:

#### YAML Style
- 2-space indentation
- Document start with `---`
- Consistent list and dictionary formatting
- Line length <160 characters
- Comments above blocks

#### Ansible Style
- Always use FQCN (Fully Qualified Collection Names)
- Descriptive task names starting with verbs
- One parameter per line for readability
- Clear conditionals and loops
- Prefixed role variables
- Hierarchical tags

#### Python Style
- PEP 8 compliance
- Black formatting (100 char line length)
- isort for import organization
- Complete docstrings
- Type hints
- Proper module structure (DOCUMENTATION, EXAMPLES, RETURN)

#### Shell Script Style
- Shebang with `set -e -u -o pipefail`
- Clear function definitions
- Quoted variables
- Modern conditionals `[[ ]]`

#### Jinja2 Templates
- Whitespace control
- Clear comments
- Appropriate filter usage

---

## 🔀 Git Workflow (Included in Standards)

### Branching Strategy

```
main (protected)
  ├── feature/add-webserver-role
  ├── fix/correct-validation
  ├── release/v1.0.0
  └── hotfix/security-patch
```

**Branch Types**:
- `main`: Production-ready code
- `feature/*`: New features
- `fix/*`: Bug fixes
- `hotfix/*`: Critical production fixes
- `release/*`: Release preparation

### Commit Message Format

```
{type}: {description}

{body}

{footer}
```

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation
- `style`: Formatting
- `refactor`: Code restructuring
- `test`: Tests
- `chore`: Maintenance
- `ci`: CI/CD changes

**Example**:
```
feat: add webserver role with molecule tests

- Implements Apache HTTP Server configuration
- Includes firewall management
- Adds comprehensive Molecule tests
- Documents all variables

Closes #123
```

### Pull Request Process

1. Create feature branch
2. Make changes
3. Run tests locally
4. Push and create PR
5. Automated checks run
6. Code review
7. Approval required
8. Squash and merge

---

## 📦 Versioning Standards (Semantic Versioning)

### Format

```
v{MAJOR}.{MINOR}.{PATCH}[-{PRERELEASE}][+{BUILD}]
```

### Examples

```
v1.0.0          # Initial release
v1.1.0          # New feature
v1.1.1          # Bug fix
v2.0.0          # Breaking change
v1.2.0-rc1      # Release candidate
v1.2.0-beta     # Beta release
```

### Increment Rules

- **MAJOR**: Breaking changes (incompatible API changes)
- **MINOR**: New features (backward compatible)
- **PATCH**: Bug fixes (backward compatible)

### Version Locations

Update version in:
- `galaxy.yml` (collections)
- `CHANGELOG.rst` (collections)
- Release manifests
- Git tags
- Documentation

---

## ✅ Code Review Checklist

### Constitutional Compliance

- [ ] **Article I**: All config in Git, no manual changes
- [ ] **Article II**: Proper tool separation (ArgoCD vs Tekton)
- [ ] **Article III**: Version locking (no `:latest` in prod)
- [ ] **Article IV**: Tests included and passing
- [ ] **Article V**: No secrets in code

### Code Quality

- [ ] Follows naming conventions
- [ ] Follows code style guide
- [ ] Includes documentation
- [ ] Includes tests
- [ ] Tests pass locally and in CI
- [ ] No linter errors
- [ ] Idempotent operations

### Functionality

- [ ] Code works as expected
- [ ] Edge cases handled
- [ ] Error handling implemented
- [ ] Logging appropriate
- [ ] Performance acceptable

### Documentation

- [ ] README updated if needed
- [ ] Inline comments for complex logic
- [ ] CHANGELOG updated (if applicable)
- [ ] Examples provided

### Security

- [ ] No hardcoded secrets
- [ ] No sensitive data in logs
- [ ] Input validation
- [ ] Secure defaults
- [ ] Dependencies up to date

### Git

- [ ] Commit messages follow convention
- [ ] Commits are logical units
- [ ] Branch name follows convention
- [ ] PR description is clear

---

## 📖 Documentation Standards

### Required Documentation

Every component must have:

1. **README.md**
   - Purpose
   - Requirements
   - Installation
   - Usage examples
   - Variables/Options
   - License

2. **Inline Documentation**
   - Module DOCUMENTATION strings
   - Function docstrings
   - Complex logic comments

3. **CHANGELOG**
   - All changes documented
   - Semantic versioning followed
   - Categories: Added, Changed, Fixed, Removed

### Documentation Format

#### Module Documentation

```python
DOCUMENTATION = r'''
---
module: module_name
short_description: One-line description
description:
    - Longer description
    - Multiple paragraphs OK
options:
    name:
        description: Parameter description
        required: true
        type: str
author:
    - Platform Team
'''
```

#### Role Documentation

```markdown
# Role Name

Brief description.

## Requirements

- Requirement 1
- Requirement 2

## Role Variables

```yaml
role_var_name: default_value  # Description
```

## Dependencies

None or list dependencies.

## Example Playbook

```yaml
- hosts: servers
  roles:
    - role: role_name
      role_var: value
```

## License

MIT
```

#### Playbook Documentation

```yaml
---
# Playbook: deploy-webapp.yml
# Purpose: Deploy web application to servers
# Requirements:
#   - Inventory with 'webservers' group
#   - Variables: app_version, app_environment
# Usage:
#   ansible-playbook deploy-webapp.yml -e app_version=1.2.3

- name: Deploy web application
  hosts: webservers
  # ... rest of playbook
```

---

## 🎯 Best Practices

### General

1. **Follow the Constitution**: All five articles, always
2. **Test Everything**: Unit, integration, end-to-end
3. **Document Everything**: Code, decisions, processes
4. **Review Everything**: All code goes through PR review
5. **Automate Everything**: No manual steps

### Ansible-Specific

1. **Use FQCN**: Always use fully qualified collection names
2. **Prefix Variables**: Namespace all role variables
3. **Be Idempotent**: Safe to run multiple times
4. **Use Check Mode**: Support `--check` flag
5. **Tag Appropriately**: Enable selective execution
6. **Handle Errors**: Use blocks, rescue, always
7. **Verify State**: Check before and after changes

### Python-Specific

1. **Type Hints**: Use for function signatures
2. **Docstrings**: Document all public functions
3. **Error Handling**: Catch specific exceptions
4. **Testing**: 80%+ code coverage target
5. **Linting**: Pass black, flake8, pylint

### Git-Specific

1. **Small Commits**: Logical, atomic changes
2. **Good Messages**: Clear, descriptive commits
3. **Clean History**: Squash before merge
4. **Protected Branches**: main requires approval
5. **Sign Commits**: Use GPG signing (recommended)

---

## 🔧 Tooling

### Linters & Formatters

- **ansible-lint**: Ansible best practices (production profile)
- **yamllint**: YAML formatting
- **black**: Python formatting
- **isort**: Python import sorting
- **flake8**: Python style checking
- **pylint**: Python code analysis
- **shellcheck**: Shell script analysis
- **markdownlint**: Markdown formatting

### Pre-commit Hooks

All repositories include `.pre-commit-config.yaml` with:
- YAML linting
- Ansible linting
- Python linting
- Secret detection
- File checks
- Constitutional compliance

### CI/CD

All repositories include GitHub Actions:
- Pre-commit checks
- Linting
- Testing (unit, integration, Molecule)
- Security scanning
- Build validation

---

## 📊 Compliance Matrix

| Standard | Enforced By | Automated |
|----------|-------------|-----------|
| Naming Conventions | Code Review | Partially |
| Code Style | Pre-commit + CI | ✅ Yes |
| Git Workflow | Branch Protection | ✅ Yes |
| Versioning | Release Process | Partially |
| Code Review | GitHub Settings | ✅ Yes |
| Documentation | CI + Review | Partially |
| Testing | CI | ✅ Yes |
| Security | Pre-commit + CI | ✅ Yes |

---

## 🚀 Quick Reference

### Before Committing

```bash
# 1. Format code
black --line-length=100 .
isort --profile black .

# 2. Run linters
ansible-lint --profile production
yamllint .
flake8 .

# 3. Run tests
pytest tests/
molecule test

# 4. Run pre-commit
pre-commit run --all-files

# 5. Commit
git add .
git commit -m "feat: descriptive message"
```

### Creating a PR

```bash
# 1. Create feature branch
git checkout -b feature/my-feature

# 2. Make changes and test
# ... your work ...

# 3. Push
git push origin feature/my-feature

# 4. Create PR
gh pr create --title "feat: my feature" \
             --body "Description of changes"
```

### Before Merging

- [ ] All CI checks pass
- [ ] Code review approved
- [ ] Documentation updated
- [ ] CHANGELOG updated (if needed)
- [ ] No merge conflicts
- [ ] Constitutional compliance verified

---

## 📚 Related Documentation

- [Naming Conventions](./NAMING-CONVENTIONS.md)
- [Code Style Guide](./CODE-STYLE-GUIDE.md)
- [Pre-commit Setup](./PRE-COMMIT-SETUP.md)
- [CI/CD Guide](./CICD-GUIDE.md)
- [Testing Guide](./TESTING-GUIDE.md)
- [Constitution](../.specify/memory/constitution.md)
- [Specification](../.specify/memory/specification.md)

---

## ✅ Summary

The platform enforces high standards through:

1. **Clear Documentation**: All standards documented
2. **Automated Enforcement**: Pre-commit + CI/CD
3. **Code Review**: Human verification
4. **Constitutional Compliance**: Five articles enforced
5. **Best Practices**: Industry standards followed

All code contributions must:
- Follow naming conventions
- Match code style guide
- Pass all automated checks
- Include tests and documentation
- Be reviewed and approved

---

**Version**: 1.0  
**Last Updated**: 2025-10-30  
**Status**: ✅ Complete and Enforced  
**Compliance**: Mandatory for all contributors



