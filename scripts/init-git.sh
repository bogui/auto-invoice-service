#!/bin/bash

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Initializing Git repository...${NC}"

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: Git is not installed${NC}"
    exit 1
fi

# Check if we're in a git repository
if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo -e "${RED}Error: Already in a git repository${NC}"
    exit 1
fi

# Initialize git repository
git init

# Create initial branches
git checkout -b main
git checkout -b develop

# Set up git configuration
git config --local core.autocrlf input
git config --local core.fileMode true
git config --local core.ignorecase false
git config --local core.whitespace trailing-space,space-before-tab,indent-with-non-tab,cr-at-eol

# Set up git hooks
mkdir -p .git/hooks
cp scripts/validate-commit-msg.sh .git/hooks/commit-msg
chmod +x .git/hooks/commit-msg

# Create initial commit
git add .
git commit -m "chore: initial commit"

# Create initial tag
git tag -a v0.1.0 -m "Initial release"

echo -e "${GREEN}Git repository initialized successfully!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Add your remote repository:"
echo "   git remote add origin <your-repo-url>"
echo "2. Push the branches:"
echo "   git push -u origin main"
echo "   git push -u origin develop"
echo "3. Push the initial tag:"
echo "   git push origin v0.1.0"
echo "4. Set up branch protection rules in your repository settings:"
echo "   - Require pull request reviews"
echo "   - Require status checks to pass"
echo "   - Require linear history"
echo "   - Include administrators" 