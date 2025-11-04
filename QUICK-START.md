# Quick Start - Cloud-Native Ansible Lifecycle Platform

**Get started in 5 minutes!** Everything you need to begin using the platform.

---

## ⚡ Super Quick Start

```bash
# 1. Install tools
pip install pre-commit ansible-lint yamllint pytest

# 2. Setup pre-commit hooks
./setup-precommit-all.sh

# 3. Run smoke test
ansible-playbook tests/test-playbooks/smoke-test.yml

# 4. Start developing!
cd automation-collection-example/
```

**Done!** You're ready to develop. ✅

---

## 📚 Essential Reading (15 minutes)

Read these in order:

1. **[README.md](./README.md)** (5 min) - Platform overview
2. **[Ansible Best Practices](./docs/ANSIBLE-BEST-PRACTICES.md)** (10 min) - Essential practices
3. **[Examples Summary](./docs/EXAMPLES-SUMMARY.md)** (5 min) - See what's available

---

## 🛠️ First Development Task (30 minutes)

### Option 1: Test an Example Role

```bash
cd automation-collection-example/roles/webserver

# Run Molecule test
molecule test

# Expected: All tests pass ✅
```

### Option 2: Create a New Role

```bash
cd automation-collection-example/

# Activate virtual environment
source ~/workspace/ansible/bin/activate

# Create new role
ansible-creator add resource role myapp .

# Develop the role
cd roles/myapp
vi tasks/main.yml

# Test it
molecule test
```

### Option 3: Run the Test Suite

```bash
# Run all tests
./tests/run-tests.sh

# Expected: Platform validation complete ✅
```

---

## 📖 Documentation Cheat Sheet

### Most Important Docs

| Document | When to Read | Time |
|----------|-------------|------|
| [Ansible Best Practices](./docs/ANSIBLE-BEST-PRACTICES.md) | Before writing any code | 20 min |
| [Pre-commit Setup](./docs/PRE-COMMIT-SETUP.md) | First day setup | 10 min |
| [Testing Guide](./docs/TESTING-GUIDE.md) | Before writing tests | 15 min |
| [Examples Summary](./docs/EXAMPLES-SUMMARY.md) | When looking for patterns | 10 min |
| [CI/CD Guide](./docs/CICD-GUIDE.md) | Setting up GitHub repos | 20 min |

### Quick References

| Document | Purpose | Time |
|----------|---------|------|
| [Pre-commit Reference](./docs/PRE-COMMIT-REFERENCE.md) | Command lookup | <5 min |
| [Naming Conventions](./docs/NAMING-CONVENTIONS.md) | Naming lookup | <5 min |
| [Documentation Index](./docs/INDEX.md) | Find anything | <2 min |

### Governance (Read Once)

| Document | Purpose | Time |
|----------|---------|------|
| [Constitution](./.specify/memory/constitution.md) | The 5 articles | 10 min |
| [Specification](./.specify/memory/specification.md) | Requirements | 15 min |

---

## 🎯 Common Tasks

### Before Every Commit

```bash
# Run pre-commit checks
pre-commit run --all-files

# If all pass, commit
git add .
git commit -m "feat: descriptive message"
```

### Before Creating a PR

```bash
# 1. Run full tests
./tests/run-tests.sh

# 2. Check for secrets
detect-secrets scan

# 3. Lint code
ansible-lint --profile production

# 4. Create PR
git push origin feature/my-feature
gh pr create --title "feat: my feature"
```

### When Writing a New Role

```bash
# 1. Create with ansible-creator
source ~/workspace/ansible/bin/activate
ansible-creator add resource role myrole .

# 2. Follow the template
# - Add tasks (prefix with role name)
# - Add defaults (prefix variables)
# - Add handlers
# - Add templates (end with .j2)
# - Add argument_specs.yml
# - Add README.md

# 3. Test with Molecule
cd roles/myrole
molecule test

# 4. Check with ansible-lint
ansible-lint .
```

### When Writing a Module

```bash
# Follow structure in plugins/modules/manage_service.py
# Include:
# - DOCUMENTATION
# - EXAMPLES  
# - RETURN
# - Type hints
# - Error handling

# Test
pytest tests/unit/test_mymodule.py
```

---

## 🔍 Finding Information Fast

### "How do I...?"

| Question | Answer | Document |
|----------|--------|----------|
| ...install pre-commit? | `pip install pre-commit` | PRE-COMMIT-SETUP.md |
| ...run tests? | `./tests/run-tests.sh` | TESTING-GUIDE.md |
| ...name variables? | `rolename_var_name` | NAMING-CONVENTIONS.md |
| ...write a task? | Start with verb, use FQCN | ANSIBLE-BEST-PRACTICES.md |
| ...create a role? | `ansible-creator add resource role name .` | EXAMPLES-SUMMARY.md |
| ...find an example? | Check examples/ or roles/ | EXAMPLES-SUMMARY.md |

### "What should I read about...?"

| Topic | Document |
|-------|----------|
| Ansible coding | ANSIBLE-BEST-PRACTICES.md |
| Naming things | NAMING-CONVENTIONS.md |
| Code style | CODE-STYLE-GUIDE.md |
| Testing | TESTING-GUIDE.md |
| CI/CD | CICD-GUIDE.md |
| Pre-commit | PRE-COMMIT-SETUP.md |
| Examples | EXAMPLES-SUMMARY.md |
| Everything | INDEX.md |

---

## ⚡ Quick Commands

### Pre-commit

```bash
pre-commit run --all-files          # Run all hooks
pre-commit run ansible-lint         # Run specific hook
pre-commit autoupdate               # Update hooks
```

### Testing

```bash
./tests/run-tests.sh                # Run everything
ansible-playbook tests/test-playbooks/smoke-test.yml  # Smoke test
cd roles/myrole && molecule test    # Test role
pytest tests/unit/ -v               # Unit tests
```

### Linting

```bash
ansible-lint --profile production   # Ansible
yamllint .                          # YAML
black --check .                     # Python format
flake8 .                            # Python style
```

### Building

```bash
# Build collection
cd automation-collection-example
ansible-galaxy collection build

# Build EE
cd automation-ee-example
ansible-builder build -t myee:test
```

---

## 🎓 Learning Path

### Day 1: Setup and Familiarize

- [ ] Read README.md
- [ ] Install tools (pre-commit, ansible-lint, etc.)
- [ ] Run `./setup-precommit-all.sh`
- [ ] Run smoke test
- [ ] Browse example roles

### Day 2: Deep Dive

- [ ] Read Ansible Best Practices
- [ ] Read Constitution (5 articles)
- [ ] Study webserver role example
- [ ] Run Molecule test
- [ ] Review CI/CD workflows

### Day 3: Start Developing

- [ ] Create a new role
- [ ] Write tasks following standards
- [ ] Add Molecule tests
- [ ] Run pre-commit
- [ ] Create a PR

---

## 💡 Pro Tips

1. **Bookmark `docs/INDEX.md`** - Fast navigation to any doc
2. **Run pre-commit before committing** - Catch issues early
3. **Study the examples** - webserver role is production-ready
4. **Use the templates** - AAP config templates in templates/
5. **Check the checklists** - Code review checklist in STANDARDS-SUMMARY.md
6. **Run tests locally** - Don't wait for CI
7. **Read the Zen of Ansible** - In ANSIBLE-BEST-PRACTICES.md
8. **Follow Red Hat CoP** - Link in all docs

---

## 🆘 Getting Help

### Common Issues

| Problem | Solution | Doc |
|---------|----------|-----|
| Pre-commit fails | Check PRE-COMMIT-REFERENCE.md | Troubleshooting section |
| Ansible-lint errors | Check ANSIBLE-BEST-PRACTICES.md | Common patterns |
| Test failures | Check TESTING-GUIDE.md | Troubleshooting section |
| Don't know how to name something | Check NAMING-CONVENTIONS.md | Examples section |

### Where to Look

1. **First**: Check the relevant guide (INDEX.md helps find it)
2. **Second**: Check examples (EXAMPLES-SUMMARY.md)
3. **Third**: Check external references (Red Hat CoP, ansible-lint docs)
4. **Last**: Ask the team or file an issue

---

## ✅ Verification Checklist

After setup, verify:

- [ ] Pre-commit hooks installed (`pre-commit --version`)
- [ ] Tools installed (ansible-lint, yamllint, pytest)
- [ ] Smoke test passes
- [ ] Can run Molecule tests
- [ ] Can build collection
- [ ] Documentation accessible
- [ ] Examples work

---

## 🌟 You're Ready!

You now have:

✅ **Complete platform** ready for development  
✅ **Comprehensive documentation** (17,000 lines)  
✅ **Automated quality** (85 hooks + 25 workflows)  
✅ **Rich examples** (4 roles, 2 modules, 4 filters)  
✅ **Testing infrastructure** (multi-level)  
✅ **Best practices** (Red Hat CoP aligned)  
✅ **Security** (4-layer scanning)  
✅ **Standards** (comprehensive guides)  

**Next**: Start developing! 🚀

---

**Last Updated**: 2025-10-30  
**Status**: ✅ Ready to Use  
**Questions?**: Check [Documentation Index](./docs/INDEX.md)



