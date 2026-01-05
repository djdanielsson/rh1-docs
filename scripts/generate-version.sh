#!/bin/bash
# Generate version string in YY.MM.DD.PATCH format
#
# Usage:
#   ./generate-version.sh           # Output: 25.01.05.0
#   ./generate-version.sh 1         # Output: 25.01.05.1
#   ./generate-version.sh 2         # Output: 25.01.05.2

set -e

PATCH=${1:-0}

# Validate PATCH is a number
if ! [[ "$PATCH" =~ ^[0-9]+$ ]]; then
  echo "❌ Error: PATCH must be a number" >&2
  echo "Usage: $0 [patch_number]" >&2
  exit 1
fi

# Generate YY.MM.DD
VERSION=$(date +"%y.%m.%d")

# Append PATCH
FULL_VERSION="${VERSION}.${PATCH}"

echo "${FULL_VERSION}"

