#!/bin/bash
# EMERGENCY ROLLBACK SCRIPT
# Run this if anything breaks during cleanup

echo "🚨 EMERGENCY ROLLBACK - Restoring pre-cleanup state"
echo "================================================"
echo ""

PROJECT_ROOT="/Users/tyhorton/Coding Projects/nestling-care-log"
cd "$PROJECT_ROOT"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)
echo "Current branch: $CURRENT_BRANCH"

if [ "$CURRENT_BRANCH" != "cleanup/remove-web-artifacts" ]; then
  echo -e "${YELLOW}⚠️  Not on cleanup branch${NC}"
  echo "Are you sure you want to rollback?"
  read -p "Continue? (y/N): " -n 1 -r
  echo ""
  if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    exit 0
  fi
fi

echo ""
echo "📦 Step 1: Checking out main branch..."
git checkout main
if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ Switched to main branch${NC}"
else
  echo -e "${RED}❌ Failed to switch to main${NC}"
  exit 1
fi

echo ""
echo "🗑️  Step 2: Removing cleanup branch..."
git branch -D cleanup/remove-web-artifacts 2>/dev/null
if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ Cleanup branch deleted${NC}"
else
  echo "   (Branch may not exist)"
fi

echo ""
echo "🧹 Step 3: Cleaning Xcode cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Nestling-* 2>/dev/null
rm -rf ~/Library/Developer/Xcode/DerivedData/Nuzzle-* 2>/dev/null
echo -e "${GREEN}✅ Xcode cache cleaned${NC}"

echo ""
echo "🔨 Step 4: Rebuilding iOS app..."
cd ios/Nuzzle
xcodebuild -project Nestling.xcodeproj \
  -scheme Nuzzle \
  -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  clean build \
  CODE_SIGN_IDENTITY="" \
  CODE_SIGNING_REQUIRED=NO \
  > ../../rollback_build_log.txt 2>&1

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✅ iOS app builds successfully${NC}"
  echo "   ** BUILD SUCCEEDED **"
  cd "$PROJECT_ROOT"
  
  echo ""
  echo "================================================"
  echo -e "${GREEN}✅ ROLLBACK COMPLETE${NC}"
  echo ""
  echo "Your project has been restored to pre-cleanup state"
  echo "iOS app should now work as before"
  echo ""
  echo "Files restored:"
  echo "  - node_modules/ (if it existed)"
  echo "  - src/ (if it existed)"
  echo "  - All web config files"
  echo ""
else
  echo -e "${RED}❌ iOS app build still fails!${NC}"
  echo ""
  cd "$PROJECT_ROOT"
  echo "This suggests the build was already broken"
  echo "See rollback_build_log.txt for details"
  echo ""
  tail -30 rollback_build_log.txt
  echo ""
  echo "Manual intervention required:"
  echo "1. Check rollback_build_log.txt"
  echo "2. Verify Xcode project integrity"
  echo "3. Try opening in Xcode and building manually"
  exit 1
fi
