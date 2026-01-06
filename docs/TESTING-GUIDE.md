# Testing Guide

Testing strategies and tools for the platform.

---

## Testing Pyramid

```
      /\  E2E Tests (Few, Slow)
     /──\
    / In \  Integration Tests
   /──────\
  /  Unit  \  Unit Tests (Many, Fast)
 /──────────\
/  Syntax    \  Linting (Fastest)
```

---

## Test Types

| Type | Tool | When | Duration |
|------|------|------|----------|
| Syntax | yamllint, ansible --syntax-check | Every commit | <1 sec |
| Linting | ansible-lint, flake8 | Every commit | <30 sec |
| Unit | pytest | Every commit | <1 min |
| Molecule | molecule | PR creation | 5-10 min |
| Integration | pytest, playbooks | PR merge | <15 min |

---

## Quick Commands

```bash
# Run all tests
./tests/run-tests.sh

# Specific test types
ansible-playbook tests/test-playbooks/smoke-test.yml
pre-commit run --all-files
pytest tests/unit/ -v
molecule test
```

---

## Syntax & Linting

```bash
# YAML
yamllint -c .yamllint .

# Ansible
ansible-playbook --syntax-check playbook.yml
ansible-lint --profile production

# Python
black --check --line-length=100 plugins/
flake8 plugins/
```

---

## Unit Tests

```bash
cd automation-collection-example/
pytest tests/unit/ -v
pytest tests/unit/ --cov=plugins --cov-report=html
```

### Example Test

```python
import pytest
from plugins.filter.sample_filter import FilterModule

def test_sample_filter_basic():
    fm = FilterModule()
    filters = fm.filters()
    result = filters['sample_filter']("test")
    assert result == "TEST"
```

---

## Molecule Tests

```bash
cd roles/webserver/

# Full test
molecule test

# Step by step
molecule create     # Create container
molecule converge   # Run role
molecule verify     # Verify
molecule destroy    # Clean up

# Specific scenario
molecule test -s centos
```

### Test Sequence

1. dependency → 2. destroy → 3. create → 4. prepare → 5. converge → 6. idempotence → 7. verify → 8. destroy

### Example Verify

```yaml
# molecule/default/verify.yml
- name: Verify
  hosts: all
  tasks:
    - name: Check service is running
      ansible.builtin.service:
        name: httpd
        state: started
      check_mode: true
      register: result
      failed_when: result.changed
```

---

## Integration Tests

```bash
# Python
pytest tests/integration/ -v

# Ansible
ansible-playbook tests/integration/test-full-workflow.yml
```

### Example Integration Test

```yaml
# tests/integration/targets/sample_module/tasks/main.yml
- name: Test module
  myorg.collection.sample_module:
    name: "test"
  register: result

- name: Verify success
  ansible.builtin.assert:
    that:
      - result is success
      - result is changed
```

---

## Security Tests

```bash
# Secret detection
detect-secrets scan

# Python security
bandit -r plugins/

# Container scanning
trivy image quay.io/myorg/custom-ee:latest
```

---

## Mock Data

Use fixtures for testing without infrastructure:

```yaml
# tests/fixtures/mock-aap-inventory.yml
all:
  children:
    aap_dev:
      hosts:
        aap-dev-mock:
          ansible_host: localhost
          controller_host: "http://localhost:8080"
```

```bash
ansible-playbook playbook.yml -i tests/fixtures/mock-aap-inventory.yml --check
```

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Molecule: Docker connection | `docker ps` / set `MOLECULE_DRIVER=podman` |
| Pre-commit slow | `SKIP=ansible-lint,molecule git commit` |
| pytest not finding tests | Create `pytest.ini` with `testpaths = tests` |
| ansible-lint too many errors | `ansible-lint --generate-ignore` |

### Debug Commands

```bash
pytest -vv --tb=long
ansible-playbook -vvv playbook.yml
molecule --debug test
```

---

## Best Practices

1. **Test naming**: `test_module_returns_correct_value()`
2. **Arrange-Act-Assert**: Clear test structure
3. **Independence**: Tests don't depend on each other
4. **Use fixtures**: Reusable test data
5. **Fast feedback**: Run quick tests locally first

---

## References

- [pytest Documentation](https://docs.pytest.org/)
- [Molecule Documentation](https://molecule.readthedocs.io/)
- [Ansible Test Guide](https://docs.ansible.com/ansible/latest/dev_guide/testing.html)
