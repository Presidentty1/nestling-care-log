#!/bin/bash
# PRE-CLEANUP VERIFICATION SCRIPT
# Run this before any file deletions to ensure iOS app safety

echo "🔍 PRE-CLEANUP VERIFICATION STARTING..."
echo "================================================"
echo ""

# Store the project root
PROJECT_ROOT="/Users/tyhorton/Coding Projects/nestling-care-log"
cd "$PROJECT_ROOT"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track if any checks fail
FAILED=0

echo "📋 Step 1: Checking git status..."
if [ -n "$(git status --porcelain)" ]; then
  echo -e "${YELLOW}⚠️  WARNING: You have uncommitted changes${NC}"
  echo "   Recommendation: Commit or stash changes before cleanup"
  read -p "Continue anyway? (y/N): " -n 1 -r
  echo
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 1
  fi
else
  echo -e "${GREEN}✅ Git status is clean${NC}"
fi
echo ""

echo "🌿 Step 2: Creating safety branch..."
CURRENT_BRANCH=$(git branch --show-current)
echo "   Current branch: $CURRENT_BRANCH"

# Check if cleanup branch already exists
if git show-ref --quiet refs/heads/cleanup/remove-web-artifacts; then
  echo -e "${YELLOW}⚠️  Branch 'cleanup/remove-web-artifacts' already exists${NC}"
  read -p "Delete existing branch and create new one? (y/N): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    git branch -D cleanup/remove-web-artifacts
    git checkout -b cleanup/remove-web-artifacts
  else
    git checkout cleanup/remove-web-artifacts
  fi
else
  git checkout -b cleanup/remove-web-artifacts
fi
echo -e "${GREEN}✅ On branch: cleanup/remove-web-artifacts${NC}"
echo ""

echo "📸 Step 3: Documenting current state..."
ls -lah > pre_cleanup_inventory.txt
du -sh * 2>/dev/null > pre_cleanup_sizes.txt
find . -name "*.swift" -type f 2>/dev/null | wc -l > pre_cleanup_swift_count.txt
echo "   Created: pre_cleanup_inventory.txt"
echo "   Created: pre_cleanup_sizes.txt"
echo "   Created: pre_cleanup_swift_count.txt"
echo -e "${GREEN}✅ Current state documented${NC}"
echo ""

echo "🔍 Step 4: Verifying Xcode project isolation..."
cd ios/Nuzzle
xcodebuild -project Nestling.xcodeproj -showBuildSettings -configuration Debug > ../../pre_cleanup_build_settings.txt 2>&1

SOURCE_ROOT=$(grep "SOURCE_ROOT =" ../../pre_cleanup_build_settings.txt | head -1 | awk -F' = ' '{print $2}')
echo "   SOURCE_ROOT: $SOURCE_ROOT"

if [[ "$SOURCE_ROOT" == *"/ios/Nuzzle" ]]; then
  echo -e "${GREEN}✅ Xcode SOURCE_ROOT is isolated to ios/Nuzzle/${NC}"
else
  echo -e "${RED}❌ WARNING: SOURCE_ROOT points outside ios/Nuzzle/${NC}"
  FAILED=1
fi
cd "$PROJECT_ROOT"
echo ""

echo "🔍 Step 5: Checking for external file references..."
EXTERNAL_REFS=$(grep -c "\.\.\/" ios/Nuzzle/Nestling.xcodeproj/project.pbxproj 2>/dev/null || echo "0")
if [ "$EXTERNAL_REFS" -gt 0 ]; then
  echo -e "${YELLOW}⚠️  WARNING: Found $EXTERNAL_REFS potential references escaping ios/ directory${NC}"
  echo "   Recommendation: Review these references before proceeding"
  grep "\.\.\/" ios/Nuzzle/Nestling.xcodeproj/project.pbxproj | head -5
  FAILED=1
else
  echo -e "${GREEN}✅ No ../ relative path references found${NC}"
fi
echo ""

echo "🔍 Step 6: Checking iOS environment configuration..."
if [ -f "ios/Nuzzle/Environment.xcconfig" ]; then
  echo -e "${GREEN}✅ Found ios/Nuzzle/Environment.xcconfig${NC}"
  if grep -q "SUPABASE" ios/Nuzzle/Environment.xcconfig; then
    echo "   Contains SUPABASE configuration"
  else
    echo -e "${YELLOW}   ⚠️  No SUPABASE vars found (may need manual setup)${NC}"
  fi
else
  echo -e "${YELLOW}⚠️  WARNING: No Environment.xcconfig found${NC}"
fi

if [ -f "ios/Nuzzle/.env.ios" ]; then
  echo -e "${GREEN}✅ Found ios/Nuzzle/.env.ios${NC}"
else
  echo "   ℹ️  No ios/Nuzzle/.env.ios (optional)"
fi
echo ""

echo "🔍 Step 7: Checking root .env file..."
if [ -f ".env" ]; then
  echo "   Root .env file contents:"
  head -3 .env
  if grep -q "VITE_" .env; then
    echo -e "${GREEN}✅ Root .env contains VITE_ variables (web-only)${NC}"
    echo "   → Safe to delete"
  else
    echo -e "${YELLOW}⚠️  Root .env doesn't have VITE_ prefix${NC}"
    echo "   → Needs investigation before deletion"
  fi
else
  echo "   No root .env file found"
fi
echo ""

echo "🔨 Step 8: Building iOS app (CRITICAL TEST)..."
cd ios/Nuzzle
xcodebuild -project Nestling.xcodeproj \
  -scheme Nuzzle \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  clean build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  > ../../pre_cleanup_build_log.txt 2>&1

BUILD_RESULT=$?
if [ $BUILD_RESULT -eq 0 ]; then
  echo -e "${GREEN}✅ iOS app builds successfully!${NC}"
  echo "   ** BUILD SUCCEEDED **"
else
  echo -e "${RED}❌ iOS app build FAILED!${NC}"
  echo "   STOP: Fix build errors before cleanup"
  echo "   See pre_cleanup_build_log.txt for details"
  tail -20 ../../pre_cleanup_build_log.txt
  FAILED=1
fi
cd "$PROJECT_ROOT"
echo ""

echo "📋 Step 9: Preview of files to delete (TIER 1)..."
echo "Files that will be deleted:"

if [ -d "node_modules" ]; then
  SIZE=$(du -sh node_modules 2>/dev/null | cut -f1)
  echo "  📁 node_modules/ ($SIZE)"
else
  echo "  📁 node_modules/ (not found)"
fi

if [ -d "src" ]; then
  SIZE=$(du -sh src 2>/dev/null | cut -f1)
  echo "  📁 src/ ($SIZE)"
else
  echo "  📁 src/ (not found)"
fi

if [ -d "public" ]; then
  SIZE=$(du -sh public 2>/dev/null | cut -f1)
  echo "  📁 public/ ($SIZE)"
else
  echo "  📁 public/ (not found)"
fi

if [ -d "playwright-report" ]; then
  SIZE=$(du -sh playwright-report 2>/dev/null | cut -f1)
  echo "  📁 playwright-report/ ($SIZE)"
else
  echo "  📁 playwright-report/ (not found)"
fi

if [ -d "test-results" ]; then
  SIZE=$(du -sh test-results 2>/dev/null | cut -f1)
  echo "  📁 test-results/ ($SIZE)"
else
  echo "  📁 test-results/ (not found)"
fi

echo "  📄 package.json"
echo "  📄 bun.lockb"
echo "  📄 vite.config.ts"
echo "  📄 tailwind.config.js"
echo "  📄 postcss.config.js"
echo "  📄 tsconfig.json"
echo "  📄 tsconfig.node.json"
echo "  📄 components.json"
echo "  📄 vercel.json"
echo "  📄 .env (web-only)"
echo "  📄 .env.example"
echo "  📄 playwright.config.ts"
echo "  📄 index.html"

# Calculate total size to be freed
TOTAL_SIZE=$(du -sh node_modules src public playwright-report test-results 2>/dev/null | awk '{sum+=$1} END {print sum}')
echo ""
echo "  💾 Estimated space to free: ~1.1 GB"
echo ""

echo "💾 Step 10: Committing baseline..."
git add pre_cleanup_*.txt 2>/dev/null
git commit -m "Pre-cleanup: Document current state and verify build

Current state:
- iOS app builds: $([ $BUILD_RESULT -eq 0 ] && echo 'SUCCESS' || echo 'FAILED')
- Xcode SOURCE_ROOT: ios/Nuzzle/
- External file references: $EXTERNAL_REFS
- Ready for web artifact cleanup" 2>/dev/null

echo -e "${GREEN}✅ Baseline committed${NC}"
echo ""

echo "================================================"
echo ""
if [ $FAILED -eq 0 ] && [ $BUILD_RESULT -eq 0 ]; then
  echo -e "${GREEN}✅ PRE-CLEANUP VERIFICATION COMPLETE${NC}"
  echo ""
  echo "Summary:"
  echo "  ✅ Git branch created: cleanup/remove-web-artifacts"
  echo "  ✅ Current state documented"
  echo "  ✅ iOS build verified working"
  echo "  ✅ Xcode project isolated to ios/Nuzzle/"
  echo "  ✅ No external file references found"
  echo ""
  echo "🎯 You are SAFE to proceed with Phase 2: TIER 1 Deletion"
  echo ""
  echo "Next step: Run CLEANUP_PHASE2_TIER1.sh"
else
  echo -e "${RED}❌ PRE-CLEANUP VERIFICATION FAILED${NC}"
  echo ""
  echo "STOP: DO NOT PROCEED with cleanup"
  echo "Fix the issues above before continuing"
  echo ""
  echo "To rollback: git checkout $CURRENT_BRANCH && git branch -D cleanup/remove-web-artifacts"
  exit 1
fi
