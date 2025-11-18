#!/bin/bash

# Xcode Project Setup Helper Script
# This script helps automate some aspects of Xcode project setup

set -e

echo "🚀 Nestling iOS Project Setup Helper"
echo "======================================"
echo ""

# Check if we're in the ios directory
if [ ! -d "Sources" ]; then
    echo "❌ Error: Must run from ios/ directory"
    echo "   Usage: cd ios && bash scripts/setup_xcode_project.sh"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo "❌ Error: Xcode not found. Please install Xcode from the App Store."
    exit 1
fi

echo "✅ Xcode found: $(xcodebuild -version | head -n 1)"
echo ""

# Check if project already exists
if [ -d "Nestling.xcodeproj" ]; then
    echo "⚠️  Warning: Nestling.xcodeproj already exists"
    read -p "   Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "📋 Setup Checklist:"
echo ""
echo "This script will help you verify your setup. You still need to:"
echo "  1. Create the Xcode project manually (File → New → Project)"
echo "  2. Add source files to targets"
echo "  3. Configure code signing"
echo ""
read -p "Press Enter to continue..."
echo ""

# Verify source structure
echo "🔍 Verifying source structure..."
MISSING_FILES=0

check_dir() {
    if [ ! -d "$1" ]; then
        echo "  ❌ Missing: $1"
        MISSING_FILES=$((MISSING_FILES + 1))
    else
        echo "  ✅ Found: $1"
    fi
}

check_dir "Sources/App"
check_dir "Sources/Domain"
check_dir "Sources/Features"
check_dir "Sources/Design"
check_dir "Sources/Services"
check_dir "Sources/Utilities"
check_dir "Tests"
check_dir "Nestling"

if [ $MISSING_FILES -gt 0 ]; then
    echo ""
    echo "❌ Some required directories are missing!"
    exit 1
fi

echo ""
echo "✅ All source directories found"
echo ""

# Check for Core Data model
if [ -f "Sources/Domain/Models/CoreData/Nestling.xcdatamodeld/Nestling.xcdatamodel/contents" ]; then
    echo "✅ Core Data model found"
else
    echo "⚠️  Core Data model not found (optional)"
fi

# Check for asset catalogs
if [ -d "Nestling/Assets.xcassets" ]; then
    echo "✅ Asset catalogs found"
else
    echo "⚠️  Asset catalogs not found"
fi

# Check for Info.plist
if [ -f "Nestling/Info.plist" ]; then
    echo "✅ Info.plist found"
else
    echo "⚠️  Info.plist not found"
fi

# Check for Entitlements
if [ -f "Nestling/Entitlements.entitlements" ]; then
    echo "✅ Entitlements file found"
    # Verify App Groups are configured
    if grep -q "group.com.nestling.app" "Nestling/Entitlements.entitlements"; then
        echo "✅ App Groups configured in entitlements"
    else
        echo "⚠️  App Groups not found in entitlements"
    fi
else
    echo "⚠️  Entitlements file not found"
fi

echo ""
echo "📝 Next Steps:"
echo ""
echo "1. Open Xcode"
echo "2. File → New → Project"
echo "3. Select: iOS → App"
echo "4. Configure:"
echo "   - Product Name: Nestling"
echo "   - Organization Identifier: com.nestling"
echo "   - Bundle Identifier: com.nestling.app"
echo "   - Interface: SwiftUI"
echo "   - Language: Swift"
echo "   - Storage: None"
echo "   - Include Tests: Yes"
echo "5. Save to: $(pwd)"
echo "6. Follow QUICK_START.md for adding files"
echo ""
echo "📚 Documentation:"
echo "   - Quick Start: QUICK_START.md"
echo "   - Detailed Setup: XCODE_SETUP.md"
echo "   - Architecture: IOS_ARCHITECTURE.md"
echo ""
echo "✨ Setup helper complete!"


