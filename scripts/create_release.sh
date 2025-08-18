#!/bin/bash

# StayClose Release Creation Script
# Usage: ./scripts/create_release.sh

set -e

echo "🚀 StayClose Release Creator"
echo "================================"

# Get current version from pubspec.yaml
CURRENT_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //')
echo "Current version in pubspec.yaml: $CURRENT_VERSION"

# Prompt for release details
echo ""
read -p "Enter release version (e.g., v0.2.3+7): " VERSION
read -p "Enter release title (e.g., Enhanced Notifications): " TITLE
read -p "Enter release type (major/minor/patch/hotfix): " RELEASE_TYPE

# Set emoji based on release type
case $RELEASE_TYPE in
  "major")
    EMOJI="🚀"
    TYPE_NAME="Major Release"
    ;;
  "minor")
    EMOJI="✨"
    TYPE_NAME="Minor Release"
    ;;
  "patch")
    EMOJI="🔧"
    TYPE_NAME="Patch Release"
    ;;
  "hotfix")
    EMOJI="🔧"
    TYPE_NAME="Hotfix"
    ;;
  *)
    EMOJI="📱"
    TYPE_NAME="Release"
    ;;
esac

echo ""
echo "Release Preview:"
echo "Version: $VERSION"
echo "Title: StayClose $VERSION - $TITLE"
echo "Type: $EMOJI $TYPE_NAME"
echo ""

read -p "Continue with release creation? (y/N): " CONFIRM

if [[ $CONFIRM != [yY] ]]; then
  echo "Release cancelled."
  exit 0
fi

# Get commit range
LAST_TAG=$(git tag --sort=-version:refname | head -n1)
if [ -z "$LAST_TAG" ]; then
  COMMIT_RANGE="Initial release"
else
  COMMIT_RANGE="$LAST_TAG → $(git rev-parse --short HEAD)"
fi

# Create release
echo ""
echo "Creating GitHub release..."

gh release create "$VERSION" \
  --title "StayClose $VERSION - $TITLE" \
  --notes "$(cat <<EOF
## $EMOJI $TYPE_NAME: $TITLE

[Add description of what this release accomplishes]

### Changes Made
- [List key changes]
- [Add more items as needed]

### Testing
- ✅ [Test performed]
- ✅ [Another test]

### Deployment
**Target**: Google Play Console  
**Priority**: Normal  
**Commits**: $COMMIT_RANGE

---
🤖 Generated with [Claude Code](https://claude.ai/code)
EOF
)"

echo ""
echo "✅ Release created successfully!"
echo "🔗 View at: https://github.com/brett-buskirk/stayclose/releases/tag/$VERSION"
echo ""
echo "Next steps:"
echo "1. Edit release notes on GitHub to add specific details"
echo "2. Deploy to Google Play Console"
echo "3. Update CLAUDE.md if needed"