#!/bin/bash
# PHASE 2: TIER 1 DELETION - Zero Risk Files
# Only run this AFTER pre-cleanup verification passes

echo "🗑️  PHASE 2: TIER 1 DELETION STARTING..."
echo "================================================"
echo ""

PROJECT_ROOT="/Users/tyhorton/Coding Projects/nestling-care-log"
cd "$PROJECT_ROOT"

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Verify we're on the right branch
CURRENT_BRANCH=$(git branch --show-current)
if [ "$CURRENT_BRANCH" != "cleanup/remove-web-artifacts" ]; then
  echo -e "${RED}❌ ERROR: Not on cleanup/remove-web-artifacts branch${NC}"
  echo "   Current branch: $CURRENT_BRANCH"
  echo "   Run pre-cleanup verification first"
  exit 1
fi

echo "✅ On correct branch: $CURRENT_BRANCH"
echo ""

echo "⚠️  About to delete the following (TIER 1 - Zero Risk):"
echo "   📁 node_modules/ (946 MB)"
echo "   📁 src/ (72 KB)"
echo "   📁 public/ (36 KB)"
echo "   📁 playwright-report/ (2.1 MB)"
echo "   📁 test-results/ (124 KB)"
echo "   📄 Web config files (package.json, vite.config.ts, etc.)"
echo "   📄 .env and .env.example (web-only)"
echo ""
read -p "Continue with deletion? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted by user"
  exit 0
fi

echo ""
echo "🗑️  Deleting TIER 1 files..."

# Delete directories
echo "Deleting node_modules/..."
rm -rf node_modules/

echo "Deleting src/..."
rm -rf src/

echo "Deleting public/..."
rm -rf public/

echo "Deleting playwright-report/..."
rm -rf playwright-report/

echo "Deleting test-results/..."
rm -rf test-results/

# Delete web config files
echo "Deleting web config files..."
rm -f package.json
rm -f bun.lockb
rm -f vite.config.ts
rm -f tailwind.config.js
rm -f postcss.config.js
rm -f tsconfig.json
rm -f tsconfig.node.json
rm -f components.json
rm -f vercel.json
rm -f playwright.config.ts
rm -f index.html

# Delete root .env files (web-only, iOS uses ios/Nuzzle/.env.ios)
echo "Deleting root .env files (web-only)..."
rm -f .env
rm -f .env.example

echo -e "${GREEN}✅ TIER 1 files deleted${NC}"
echo ""

# Show space freed
echo "💾 Checking space freed..."
du -sh .
echo ""

# Commit changes
echo "💾 Committing TIER 1 deletions..."
git add -A
git commit -m "Cleanup TIER 1: Remove web-only artifacts

Deleted:
- node_modules/ (946 MB) - npm dependencies
- src/ (72 KB) - React source code
- public/ (36 KB) - Web assets
- playwright-report/ (2.1 MB) - Test artifacts
- test-results/ (124 KB) - Test results
- Web config files (60 KB)
- .env and .env.example (web-only variables)

Total space freed: ~1.1 GB

iOS dependencies preserved:
- ios/ directory (intact)
- supabase/ directory (intact)
- ios/Nuzzle/.env.ios (intact)
- ios/Nuzzle/Environment.xcconfig (intact)"

echo -e "${GREEN}✅ Changes committed${NC}"
echo ""

# CRITICAL: Verify iOS build still works
echo "🔨 CRITICAL VERIFICATION: Building iOS app..."
echo ""

# Clean Xcode derived data first
echo "Cleaning Xcode derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Nestling-* 2>/dev/null
rm -rf ~/Library/Developer/Xcode/DerivedData/Nuzzle-* 2>/dev/null

# Build
cd ios/Nuzzle
xcodebuild -project Nestling.xcodeproj \
  -scheme Nuzzle \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  clean build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  > ../../post_tier1_build_log.txt 2>&1

BUILD_RESULT=$?
cd "$PROJECT_ROOT"

if [ $BUILD_RESULT -eq 0 ]; then
  echo -e "${GREEN}✅ iOS app still builds successfully!${NC}"
  echo "   ** BUILD SUCCEEDED **"
  echo ""
  echo "================================================"
  echo -e "${GREEN}✅ PHASE 2 COMPLETE${NC}"
  echo ""
  echo "Summary:"
  echo "  ✅ Deleted ~1.1 GB of web artifacts"
  echo "  ✅ iOS build still works"
  echo "  ✅ Changes committed to git"
  echo ""
  echo "🎯 Safe to proceed with Phase 3 (optional)"
  echo "   Or merge to main if satisfied"
  echo ""
  echo "Next step (optional): CLEANUP_PHASE3_TIER2.sh"
  echo "Or merge now: git checkout main && git merge cleanup/remove-web-artifacts"
else
  echo -e "${RED}❌ iOS app build FAILED after deletion!${NC}"
  echo ""
  echo "CRITICAL: Web file deletion broke the build"
  echo "See post_tier1_build_log.txt for details"
  echo ""
  tail -30 post_tier1_build_log.txt
  echo ""
  echo "🚨 ROLLING BACK IMMEDIATELY..."
  git reset --hard HEAD~1
  echo ""
  echo "✅ Rollback complete - files restored"
  echo ""
  echo "Next steps:"
  echo "1. Review post_tier1_build_log.txt to see what broke"
  echo "2. Report issue (this shouldn't happen based on verification)"
  echo "3. Do NOT proceed with further cleanup"
  exit 1
fi
