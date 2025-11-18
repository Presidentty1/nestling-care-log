#!/bin/bash

# Verify Xcode Project Setup
# Run this after creating the Xcode project to verify everything is configured correctly

set -e

echo "🔍 Verifying Xcode Project Setup"
echo "=================================="
echo ""

# Check if we're in the ios directory
if [ ! -d "Sources" ]; then
    echo "❌ Error: Must run from ios/ directory"
    exit 1
fi

# Check if project exists
if [ ! -d "Nestling.xcodeproj" ]; then
    echo "❌ Error: Nestling.xcodeproj not found"
    echo "   Please create the Xcode project first (see QUICK_START.md)"
    exit 1
fi

echo "✅ Xcode project found"
echo ""

# Try to build (if xcodebuild is available)
if command -v xcodebuild &> /dev/null; then
    echo "🔨 Attempting to build project..."
    echo ""
    
    # Check if we can list schemes
    SCHEMES=$(xcodebuild -list -project Nestling.xcodeproj 2>/dev/null | grep -A 10 "Schemes:" | tail -n +2 | grep -v "^$" | head -n 1)
    
    if [ -z "$SCHEMES" ]; then
        echo "⚠️  Warning: Could not detect schemes. Project may not be fully configured."
        echo "   Make sure all source files are added to the Nestling target."
    else
        echo "✅ Found scheme: $SCHEMES"
        echo ""
        echo "📋 Manual Verification Checklist:"
        echo ""
        echo "Please verify in Xcode:"
        echo "  [ ] All files in Sources/ are added to Nestling target"
        echo "  [ ] Nestling/Assets.xcassets is added to Nestling target"
        echo "  [ ] Nestling/Info.plist is set as Info.plist file"
        echo "  [ ] Nestling/Entitlements.entitlements is linked"
        echo "  [ ] Core Data model (Nestling.xcdatamodeld) is added to Nestling target"
        echo "  [ ] Test files are added to NestlingTests target (NOT Nestling)"
        echo "  [ ] Deployment Target is set to iOS 17.0"
        echo "  [ ] Swift Language Version is 5.9"
        echo "  [ ] Bundle Identifier is com.nestling.app"
        echo ""
        echo "Then try building:"
        echo "  ⌘B (Product → Build)"
        echo ""
        echo "If build succeeds, try running:"
        echo "  ⌘R (Product → Run)"
    fi
else
    echo "⚠️  xcodebuild not found. Skipping build verification."
    echo ""
    echo "📋 Manual Verification Checklist:"
    echo ""
    echo "Please verify in Xcode:"
    echo "  [ ] All files in Sources/ are added to Nestling target"
    echo "  [ ] Build succeeds (⌘B)"
    echo "  [ ] App runs in simulator (⌘R)"
fi

echo ""
echo "✨ Verification complete!"
echo ""
echo "📚 Next Steps:"
echo "   - See TEST_PLAN.md for manual QA steps"
echo "   - See MVP_CHECKLIST.md for feature verification"


