# Workspace Verification Guide

## Overview

This repository uses git worktrees, which means there are multiple working directories for the same repository. It's critical to ensure you're working in the correct workspace to avoid editing the wrong codebase.

## Correct Workspace

**Current Active Workspace:**
```
/Users/tyhorton/.cursor/worktrees/nestling-care-log/gnq
```

## Verification Steps

### 1. Check Current Directory

Run this command to verify your location:
```bash
pwd
```

You should see: `/Users/tyhorton/.cursor/worktrees/nestling-care-log/gnq`

### 2. Check Verification File

Verify the `.workspace-verification` file exists:
```bash
ls -la .workspace-verification
```

This file contains the correct workspace path and should always be present.

### 3. Run Verification Script

Use the automated verification script:
```bash
./scripts/verify-workspace.sh
```

This script checks:
- Current directory matches expected workspace
- Git remote URL is correct
- Verification file exists

### 4. Check Git Remote

Verify the git remote URL:
```bash
git remote get-url origin
```

Should return: `https://github.com/Presidentty1/nestling-care-log.git`

## Files That Should Never Contain Absolute Paths

The following files should **never** contain hardcoded absolute paths to worktrees:

- Documentation files (`.md` files)
- Configuration files (`*.config.ts`, `*.json`)
- Scripts (`scripts/*.sh`, `scripts/*.py`)
- Source code files

Instead, use:
- Relative paths (e.g., `ios/Nuzzle/` instead of `/Users/.../ios/Nuzzle/`)
- Environment variables
- Project root references

## Common Mistakes to Avoid

1. **Don't reference other worktrees**: Avoid paths like `/Users/.../worktrees/.../jet/` or `/Users/.../worktrees/.../vig/`
2. **Don't use absolute paths in docs**: Use relative paths or generic instructions
3. **Don't assume workspace location**: Always verify before making changes

## For AI Assistants

Before making any changes:

1. ✅ Check for `.workspace-verification` file
2. ✅ Verify current directory with `pwd`
3. ✅ Run `./scripts/verify-workspace.sh`
4. ✅ Check git remote URL
5. ✅ Use relative paths in all edits

## Troubleshooting

### Wrong Workspace Detected

If you're in the wrong workspace:
1. Navigate to the correct workspace: `cd /Users/tyhorton/.cursor/worktrees/nestling-care-log/gnq`
2. Verify with `./scripts/verify-workspace.sh`
3. Check git status: `git status`

### Verification File Missing

If `.workspace-verification` is missing:
1. This may indicate you're in the wrong location
2. Check the git worktree list: `git worktree list`
3. Navigate to the correct worktree

### Git Remote Mismatch

If the git remote doesn't match:
1. Check you're in the correct repository
2. Verify with: `git remote -v`
3. If incorrect, this may be a different repository

## Quick Reference

```bash
# Verify workspace
./scripts/verify-workspace.sh

# Check current location
pwd

# Verify git remote
git remote get-url origin

# List all worktrees
git worktree list
```

## Last Updated

2025-01-06

