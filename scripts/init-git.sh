#!/bin/bash

# Exit on error
set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Initializing Git repository...${NC}"

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

echo -e "${GREEN}Git repository initialized successfully!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Add your remote repository:"
echo "   git remote add origin <your-repo-url>"
echo "2. Push the branches:"
echo "   git push -u origin main"
echo "   git push -u origin develop"
echo "3. Set up branch protection rules in your repository settings" 