#!/bin/bash
# Create a release tag with proper format and message
#
# Usage:
#   ./create-release-tag.sh              # Creates 25.01.05.0
#   ./create-release-tag.sh 1            # Creates 25.01.05.1 (hotfix)
#   ./create-release-tag.sh 2            # Creates 25.01.05.2 (hotfix)

set -e

PATCH=${1:-0}
MESSAGE=$2

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Validate PATCH
if ! [[ "$PATCH" =~ ^[0-9]+$ ]]; then
  echo -e "${RED}❌ Error: PATCH must be a number${NC}" >&2
  echo "" >&2
  echo "Usage: $0 [patch] [message]" >&2
  echo "" >&2
  echo "Examples:" >&2
  echo "  $0              # Create 25.01.05.0" >&2
  echo "  $0 1            # Create 25.01.05.1 (hotfix)" >&2
  echo '  $0 0 "Initial January release"' >&2
  exit 1
fi

# Generate version
VERSION=$(date +"%y.%m.%d").${PATCH}

# Check if tag already exists
if git rev-parse "$VERSION" >/dev/null 2>&1; then
  echo -e "${RED}❌ Error: Tag already exists: $VERSION${NC}" >&2
  echo "" >&2
  echo "Options:" >&2
  echo "  1. Increment PATCH: $0 $((PATCH + 1))" >&2
  echo "  2. Use different date (wait for tomorrow)" >&2
  echo "  3. Delete tag (not recommended): git tag -d $VERSION" >&2
  exit 1
fi

# Create tag message
if [ -z "$MESSAGE" ]; then
  if [ "$PATCH" -eq 0 ]; then
    TAG_MESSAGE="Release ${VERSION}"
  else
    TAG_MESSAGE="Hotfix ${PATCH} for ${VERSION%.*}.0"
  fi
else
  TAG_MESSAGE="${MESSAGE}"
fi

# Confirmation
echo -e "${YELLOW}Creating tag:${NC} ${VERSION}"
echo -e "${YELLOW}Patch:${NC}       ${PATCH}"
if [ "$PATCH" -gt 0 ]; then
  echo -e "${YELLOW}Type:${NC}        Hotfix"
fi
echo ""
echo "Message:"
echo "  ${TAG_MESSAGE}"
echo ""
read -p "Continue? (y/N): " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Cancelled"
  exit 0
fi

# Create and push tag
echo ""
echo "Creating tag..."
git tag -a "${VERSION}" -m "${TAG_MESSAGE}"

echo "Pushing tag to origin..."
git push origin "${VERSION}"

echo ""
echo -e "${GREEN}✅ Successfully created and pushed tag: ${VERSION}${NC}"
echo ""
echo "Next steps:"
echo "  - Tag will trigger deployment pipelines"
echo "  - Monitor pipeline execution"
echo "  - Update release manifest to track deployment status"
echo "  - Promote through: dev → qa → prod"
