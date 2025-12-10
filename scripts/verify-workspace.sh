#!/bin/bash

# Workspace Verification Script
# Verifies that we're working in the correct workspace before making changes

EXPECTED_WORKSPACE="/Users/tyhorton/Coding Projects/nestling-care-log"
EXPECTED_REMOTE="https://github.com/Presidentty1/nestling-care-log.git"

CURRENT_DIR=$(pwd)
CURRENT_REMOTE=$(git remote get-url origin 2>/dev/null)

# Check workspace path
if [[ "$CURRENT_DIR" != "$EXPECTED_WORKSPACE"* ]]; then
    echo "❌ ERROR: Wrong workspace detected!"
    echo "   Current: $CURRENT_DIR"
    echo "   Expected: $EXPECTED_WORKSPACE"
    echo ""
    echo "Please navigate to the correct workspace before proceeding."
    exit 1
fi

# Check git remote
if [[ "$CURRENT_REMOTE" != "$EXPECTED_REMOTE" ]]; then
    echo "❌ ERROR: Wrong git remote detected!"
    echo "   Current: $CURRENT_REMOTE"
    echo "   Expected: $EXPECTED_REMOTE"
    exit 1
fi

# Check for verification file
if [[ ! -f ".workspace-verification" ]]; then
    echo "⚠️  WARNING: .workspace-verification file not found"
    echo "   This may indicate the workspace is not properly set up"
fi

echo "✓ Workspace verification passed"
echo "   Location: $CURRENT_DIR"
echo "   Remote: $CURRENT_REMOTE"
exit 0

