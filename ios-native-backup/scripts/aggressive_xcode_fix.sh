#!/bin/bash

# Aggressive Xcode crash fix - addresses all known crash causes
# Use this if standard fixes don't work

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
XCODE_PROJECT="$PROJECT_DIR/Nestling/Nestling.xcodeproj"

echo "🔧 Aggressive Xcode Crash Fix"
echo "=============================="
echo ""

# Step 1: Kill Xcode completely
echo "1️⃣  Killing Xcode processes..."
killall Xcode 2>/dev/null || true
killall com.apple.dt.Xcode 2>/dev/null || true
sleep 2
echo "✅ Xcode processes killed"

# Step 2: Clean all Xcode caches
echo ""
echo "2️⃣  Cleaning Xcode caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/*
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
rm -rf ~/Library/Caches/com.apple.dt.Xcode/*
rm -rf ~/Library/Developer/Xcode/Archives/*
rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport/*
echo "✅ Caches cleaned"

# Step 3: Remove user-specific project data
echo ""
echo "3️⃣  Removing user-specific project data..."
cd "$PROJECT_DIR/Nestling"
rm -rf "$XCODE_PROJECT/xcuserdata"
rm -rf "$XCODE_PROJECT/project.xcworkspace/xcuserdata"
find . -name "*.xcuserstate" -delete
find . -name "*.xcuserdatad" -type d -exec rm -rf {} + 2>/dev/null || true
echo "✅ User data removed"

# Step 4: Clean project build folders
echo ""
echo "4️⃣  Cleaning project build folders..."
rm -rf build/
rm -rf .build/
rm -rf "$XCODE_PROJECT/project.xcworkspace/xcshareddata/swiftpm"
echo "✅ Build folders cleaned"

# Step 5: Verify source directories exist
echo ""
echo "5️⃣  Verifying source directories..."
MISSING_DIRS=0

if [ ! -d "Nestling" ]; then
    echo "❌ ERROR: Nestling directory missing!"
    MISSING_DIRS=1
fi

if [ ! -d "NestlingTests" ]; then
    echo "❌ ERROR: NestlingTests directory missing!"
    MISSING_DIRS=1
fi

if [ ! -d "NestlingUITests" ]; then
    echo "❌ ERROR: NestlingUITests directory missing!"
    MISSING_DIRS=1
fi

if [ $MISSING_DIRS -eq 0 ]; then
    echo "✅ All source directories exist"
else
    echo "❌ Missing directories found - project structure is broken"
    exit 1
fi

# Step 6: Fix file permissions
echo ""
echo "6️⃣  Fixing file permissions..."
find "$PROJECT_DIR/Nestling" -type f -name "*.swift" -exec chmod 644 {} \;
find "$PROJECT_DIR/Nestling" -type d -exec chmod 755 {} \;
chmod 644 "$XCODE_PROJECT/project.pbxproj" 2>/dev/null || true
echo "✅ Permissions fixed"

# Step 7: Check for problematic file references
echo ""
echo "7️⃣  Checking for problematic files..."
PROBLEMATIC_FILES=0

# Check for files with special characters that might cause issues
find "$PROJECT_DIR/Nestling/Nestling" -type f -name "*[^a-zA-Z0-9._-]*" | while read file; do
    echo "⚠️  Warning: File with special characters: $file"
    PROBLEMATIC_FILES=1
done

# Check for very long file paths (can cause issues)
find "$PROJECT_DIR/Nestling" -type f | while read file; do
    if [ ${#file} -gt 200 ]; then
        echo "⚠️  Warning: Very long file path: $file"
        PROBLEMATIC_FILES=1
    fi
done

if [ $PROBLEMATIC_FILES -eq 0 ]; then
    echo "✅ No problematic files found"
fi

# Step 8: Reset Xcode preferences (optional)
echo ""
echo "8️⃣  Xcode Preferences"
echo "   To reset Xcode preferences (removes all custom settings):"
echo "   defaults delete com.apple.dt.Xcode"
echo "   (Not running automatically - run manually if needed)"

# Step 9: Verify project file integrity
echo ""
echo "9️⃣  Verifying project file..."
if python3 "$PROJECT_DIR/scripts/rebuild_project_pbxproj.py" 2>&1 | grep -q "✅ Project file structure is valid"; then
    echo "✅ Project file is valid"
else
    echo "❌ Project file has issues - may need manual repair"
fi

# Step 10: Create fresh workspace if needed
echo ""
echo "🔟 Ensuring workspace is properly configured..."
WORKSPACE_FILE="$XCODE_PROJECT/project.xcworkspace/contents.xcworkspacedata"
if [ ! -f "$WORKSPACE_FILE" ]; then
    echo "   Creating workspace file..."
    mkdir -p "$XCODE_PROJECT/project.xcworkspace"
    cat > "$WORKSPACE_FILE" << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
   <FileRef
      location = "self:">
   </FileRef>
</Workspace>
EOF
    echo "✅ Workspace file created"
else
    echo "✅ Workspace file exists"
fi

echo ""
echo "=============================="
echo "✅ Aggressive fix complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Wait 10 seconds for all processes to finish"
echo "   2. Restart your Mac (recommended for best results)"
echo "   3. After restart, open: open $XCODE_PROJECT"
echo ""
echo "   If crashes persist after restart:"
echo "   - Check Console.app for crash logs"
echo "   - Verify Xcode version: xcodebuild -version"
echo "   - Try opening a simple new Xcode project to test if Xcode itself works"
echo "   - Consider updating Xcode to the latest version"
echo ""

