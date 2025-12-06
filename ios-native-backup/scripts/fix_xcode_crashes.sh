#!/bin/bash

# Script to fix common Xcode crash issues
# Run this script if Xcode keeps crashing unexpectedly

set -e

echo "🔧 Fixing Xcode crash issues..."

# Get the project directory
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
XCODE_PROJECT="$PROJECT_DIR/Nestling/Nestling.xcodeproj"

echo "📁 Project directory: $PROJECT_DIR"

# 1. Clean derived data
echo "🧹 Cleaning derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
echo "✅ Derived data cleaned"

# 2. Clean module cache
echo "🧹 Cleaning module cache..."
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
echo "✅ Module cache cleaned"

# 3. Clean Xcode caches
echo "🧹 Cleaning Xcode caches..."
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
echo "✅ Xcode caches cleaned"

# 4. Clean project-specific build folders
echo "🧹 Cleaning project build folders..."
cd "$PROJECT_DIR/Nestling"
rm -rf build/
rm -rf .build/
find . -name "*.xcuserstate" -delete
find . -name "*.xcuserdatad" -type d -exec rm -rf {} + 2>/dev/null || true
echo "✅ Project build folders cleaned"

# 5. Verify project structure
echo "🔍 Verifying project structure..."
if [ ! -d "Nestling" ]; then
    echo "❌ ERROR: Nestling directory not found!"
    exit 1
fi

if [ ! -d "NestlingTests" ]; then
    echo "❌ ERROR: NestlingTests directory not found!"
    exit 1
fi

if [ ! -d "NestlingUITests" ]; then
    echo "❌ ERROR: NestlingUITests directory not found!"
    exit 1
fi

echo "✅ Project structure verified"

# 6. Fix file permissions
echo "🔧 Fixing file permissions..."
find "$PROJECT_DIR" -type f -name "*.swift" -exec chmod 644 {} \;
find "$PROJECT_DIR" -type d -exec chmod 755 {} \;
echo "✅ File permissions fixed"

# 7. Remove any corrupted workspace data
echo "🧹 Cleaning workspace data..."
if [ -d "$XCODE_PROJECT/project.xcworkspace/xcuserdata" ]; then
    rm -rf "$XCODE_PROJECT/project.xcworkspace/xcuserdata"
    echo "✅ Workspace user data cleaned"
fi

# 8. Verify project.pbxproj is valid
echo "🔍 Verifying project.pbxproj..."
if [ ! -f "$XCODE_PROJECT/project.pbxproj" ]; then
    echo "❌ ERROR: project.pbxproj not found!"
    exit 1
fi

# Check for common issues in project.pbxproj
if grep -q "PBXFileSystemSynchronizedRootGroup" "$XCODE_PROJECT/project.pbxproj"; then
    echo "⚠️  Using PBXFileSystemSynchronizedRootGroup (modern format)"
    echo "   This is fine, but if crashes persist, consider converting to traditional file references"
fi

echo "✅ project.pbxproj verified"

# 9. Reset Xcode preferences (optional - commented out by default)
# echo "⚠️  To reset Xcode preferences, run:"
# echo "   defaults delete com.apple.dt.Xcode"
# echo "   (This will reset all Xcode preferences)"

echo ""
echo "✅ All cleanup tasks completed!"
echo ""
echo "📝 Next steps:"
echo "   1. Quit Xcode completely (Cmd+Q)"
echo "   2. Wait a few seconds"
echo "   3. Reopen the project: open $XCODE_PROJECT"
echo "   4. If crashes persist, try:"
echo "      - Restart your Mac"
echo "      - Update Xcode to the latest version"
echo "      - Check Console.app for crash logs"
echo ""
