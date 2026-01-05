#!/bin/bash
# Validate version string format: YY.MM.DD.PATCH
#
# Usage:
#   ./validate-version.sh 25.01.05.0    # ✅ Valid
#   ./validate-version.sh 25.1.5.0      # ❌ Invalid (missing leading zeros)
#   ./validate-version.sh 25.13.01.0    # ❌ Invalid (month > 12)

set -e

VERSION=$1

if [ -z "$VERSION" ]; then
  echo "❌ Error: Version required" >&2
  echo "Usage: $0 <version>" >&2
  echo "Format: YY.MM.DD.PATCH" >&2
  exit 1
fi

# Regex for YY.MM.DD.PATCH
# YY: 00-99
# MM: 01-12 (with leading zero)
# DD: 01-31 (with leading zero)
# PATCH: 0-N (any number)
REGEX='^[0-9]{2}\.(0[1-9]|1[0-2])\.(0[1-9]|[12][0-9]|3[01])\.[0-9]+$'

if [[ ! "$VERSION" =~ $REGEX ]]; then
  echo "❌ Invalid version format: $VERSION" >&2
  echo "" >&2
  echo "Expected format: YY.MM.DD.PATCH" >&2
  echo "  YY:    Two-digit year (00-99)" >&2
  echo "  MM:    Two-digit month (01-12)" >&2
  echo "  DD:    Two-digit day (01-31)" >&2
  echo "  PATCH: Patch number (0-N)" >&2
  echo "" >&2
  echo "Examples:" >&2
  echo "  ✅ 25.01.05.0" >&2
  echo "  ✅ 25.12.31.5" >&2
  echo "  ❌ 25.1.5.0   (missing leading zeros)" >&2
  echo "  ❌ 25.13.01.0 (invalid month)" >&2
  echo "  ❌ 25.01.32.0 (invalid day)" >&2
  exit 1
fi

echo "✅ Valid version: $VERSION"
exit 0

