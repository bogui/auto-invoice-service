#!/bin/bash

# Conventional commit types
TYPES="feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert"

# Get the commit message
COMMIT_MSG=$(cat "$1")

# Check if the commit message matches the conventional commit format
if ! echo "$COMMIT_MSG" | grep -qE "^($TYPES)(\([a-z-]+\))?: .+$"; then
    echo "Error: Commit message does not follow conventional commit format"
    echo "Format: <type>(<scope>): <description>"
    echo "Types: $TYPES"
    echo "Example: feat(auth): add login functionality"
    exit 1
fi

# Check if the description is too long (max 72 characters)
DESCRIPTION=$(echo "$COMMIT_MSG" | cut -d':' -f2- | sed 's/^[[:space:]]*//')
if [ ${#DESCRIPTION} -gt 72 ]; then
    echo "Error: Commit description is too long (max 72 characters)"
    exit 1
fi

# Check if the commit message ends with a period
if [[ "$DESCRIPTION" =~ \.$ ]]; then
    echo "Warning: Commit message ends with a period"
fi

exit 0 