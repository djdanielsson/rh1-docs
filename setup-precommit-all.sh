#!/bin/bash
# Setup pre-commit hooks in all repositories
# Cloud-Native Ansible Lifecycle Platform

set -e

echo "======================================================================"
echo "Pre-commit Hooks Setup for All Repositories"
echo "======================================================================"
echo ""

# Check if pre-commit is installed
if ! command -v pre-commit &> /dev/null; then
    echo "❌ pre-commit not found!"
    echo ""
    echo "Install with:"
    echo "  pip install pre-commit"
    echo ""
    exit 1
fi

echo "✅ pre-commit found: $(pre-commit --version)"
echo ""

# List of repositories
repos=(
  "cluster-config"
  "aap-config-as-code"
  "automation-collection-example"
  "automation-ee-example"
  "automation-release-manifest"
)

success_count=0
skip_count=0
fail_count=0

# Install pre-commit in each repository
for repo in "${repos[@]}"; do
  echo "----------------------------------------------------------------------"
  echo "Repository: $repo"
  echo "----------------------------------------------------------------------"

  if [ ! -d "$repo" ]; then
    echo "⚠️  Directory not found, skipping"
    echo ""
    skip_count=$((skip_count + 1))
    continue
  fi

  cd "$repo"

  # Check if .pre-commit-config.yaml exists
  if [ ! -f ".pre-commit-config.yaml" ]; then
    echo "⚠️  .pre-commit-config.yaml not found, skipping"
    cd ..
    skip_count=$((skip_count + 1))
    continue
  fi

  # Install hooks
  echo "Installing pre-commit hooks..."
  if pre-commit install; then
    echo "✅ Pre-commit hooks installed"
    success_count=$((success_count + 1))
  else
    echo "❌ Failed to install pre-commit hooks"
    fail_count=$((fail_count + 1))
  fi

  # Optional: Install commit-msg and pre-push hooks
  # pre-commit install --hook-type commit-msg
  # pre-commit install --hook-type pre-push

  cd ..
  echo ""
done

echo "======================================================================"
echo "Summary"
echo "======================================================================"
echo "✅ Successful: $success_count"
echo "⚠️  Skipped:    $skip_count"
echo "❌ Failed:     $fail_count"
echo ""

if [ $fail_count -gt 0 ]; then
    echo "Some repositories failed to set up. Please check the output above."
    exit 1
fi

echo "======================================================================"
echo "Next Steps"
echo "======================================================================"
echo ""
echo "1. Verify installation:"
echo "   cd <repo> && pre-commit --version"
echo ""
echo "2. Run initial check (recommended):"
echo "   cd <repo> && pre-commit run --all-files"
echo ""
echo "3. Read the documentation:"
echo "   cat docs/PRE-COMMIT-SETUP.md"
echo ""
echo "======================================================================"
echo "Pre-commit hooks are now installed!"
echo "They will run automatically on every 'git commit'."
echo "======================================================================"



