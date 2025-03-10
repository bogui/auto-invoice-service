#!/bin/bash

# Version control script for auto-invoice-service
# Usage: ./version.sh [major|minor|patch]

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Check if version type is provided
if [ -z "$1" ]; then
    echo -e "${RED}Error: Version type not provided${NC}"
    echo "Usage: ./version.sh [major|minor|patch]"
    exit 1
fi

# Check if we're on develop branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "develop" ]; then
    echo -e "${RED}Error: Version bumping must be done from develop branch${NC}"
    echo "Current branch: $CURRENT_BRANCH"
    exit 1
fi

# Check if working directory is clean
if [ -n "$(git status --porcelain)" ]; then
    echo -e "${RED}Error: Working directory is not clean${NC}"
    echo "Please commit or stash your changes before bumping version"
    exit 1
fi

# Get current version from CHANGELOG.md
if [ ! -f "CHANGELOG.md" ]; then
    echo -e "${RED}Error: CHANGELOG.md not found${NC}"
    exit 1
fi

CURRENT_VERSION=$(grep -oP '## \[\K[0-9]+\.[0-9]+\.[0-9]+(?=\])' CHANGELOG.md | head -n1)
if [ -z "$CURRENT_VERSION" ]; then
    echo -e "${RED}Error: Could not find current version in CHANGELOG.md${NC}"
    exit 1
fi

# Split version into components
IFS='.' read -r -a version_parts <<< "$CURRENT_VERSION"
MAJOR="${version_parts[0]}"
MINOR="${version_parts[1]}"
PATCH="${version_parts[2]}"

# Increment version based on argument
case "$1" in
    "major")
        MAJOR=$((MAJOR + 1))
        MINOR=0
        PATCH=0
        ;;
    "minor")
        MINOR=$((MINOR + 1))
        PATCH=0
        ;;
    "patch")
        PATCH=$((PATCH + 1))
        ;;
    *)
        echo -e "${RED}Error: Invalid version type${NC}"
        echo "Use major, minor, or patch"
        exit 1
        ;;
esac

# Create new version string
NEW_VERSION="$MAJOR.$MINOR.$PATCH"

# Check if version already exists
if grep -q "## \[$NEW_VERSION\]" CHANGELOG.md; then
    echo -e "${RED}Error: Version $NEW_VERSION already exists in CHANGELOG.md${NC}"
    exit 1
fi

# Update CHANGELOG.md
echo -e "${YELLOW}Updating CHANGELOG.md...${NC}"
sed -i "s/## \[Unreleased\]/## \[Unreleased\]\n\n## \[$NEW_VERSION\] - $(date +%Y-%m-%d)/" CHANGELOG.md

# Create git tag
echo -e "${YELLOW}Creating git tag...${NC}"
git add CHANGELOG.md
git commit -m "chore: bump version to $NEW_VERSION"
git tag -a "v$NEW_VERSION" -m "Release version $NEW_VERSION"

echo -e "${GREEN}Version bumped to $NEW_VERSION${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Push changes:"
echo "   git push origin develop"
echo "2. Push tags:"
echo "   git push origin v$NEW_VERSION"
echo "3. Create pull request to main branch" 