#!/bin/bash

# Diagnostic script to identify Xcode crash causes

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
XCODE_PROJECT="$PROJECT_DIR/Nestling/Nestling.xcodeproj"

echo "🔍 Xcode Crash Diagnostics"
echo "=========================="
echo ""

# Check Xcode version
echo "1️⃣  Xcode Version:"
if command -v xcodebuild &> /dev/null; then
    xcodebuild -version 2>&1 || echo "   ⚠️  Cannot determine Xcode version"
else
    echo "   ⚠️  xcodebuild not found - Xcode may not be properly installed"
fi
echo ""

# Check macOS version
echo "2️⃣  macOS Version:"
sw_vers
echo ""

# Check project file format
echo "3️⃣  Project File Format:"
if grep -q "objectVersion = 77" "$XCODE_PROJECT/project.pbxproj"; then
    echo "   ✅ Using objectVersion 77 (Xcode 15+)"
    echo "   ✅ Using PBXFileSystemSynchronizedRootGroup (modern format)"
    echo ""
    echo "   ⚠️  NOTE: Some Xcode versions have bugs with PBXFileSystemSynchronizedRootGroup"
    echo "   If crashes persist, consider converting to traditional file references"
else
    echo "   Using traditional project format"
fi
echo ""

# Check for crash logs
echo "4️⃣  Recent Crash Logs:"
CRASH_LOGS=$(find ~/Library/Logs/DiagnosticReports -name "Xcode_*.crash" -mtime -1 2>/dev/null | head -3)
if [ -z "$CRASH_LOGS" ]; then
    echo "   ℹ️  No recent crash logs found in DiagnosticReports"
    echo "   Check Console.app for real-time crash information"
else
    echo "   Found recent crash logs:"
    echo "$CRASH_LOGS" | while read log; do
        echo "   - $log"
        echo "     $(stat -f "%Sm" "$log" 2>/dev/null || echo "unknown date")"
    done
fi
echo ""

# Check project file size
echo "5️⃣  Project File Analysis:"
PROJECT_FILE="$XCODE_PROJECT/project.pbxproj"
FILE_SIZE=$(wc -l < "$PROJECT_FILE")
echo "   Project file: $FILE_SIZE lines"
echo "   File size: $(du -h "$PROJECT_FILE" | cut -f1)"

# Count objects
PBX_COUNT=$(grep -c "isa = PBX" "$PROJECT_FILE" || echo "0")
echo "   PBX objects: $PBX_COUNT"

# Check for common issues
echo ""
echo "6️⃣  Common Issues Check:"
ISSUES=0

# Check for missing directories referenced in project
if grep -q "path = Nestling" "$PROJECT_FILE"; then
    if [ ! -d "$PROJECT_DIR/Nestling/Nestling" ]; then
        echo "   ❌ Referenced directory 'Nestling' does not exist"
        ISSUES=1
    fi
fi

if grep -q "path = NestlingTests" "$PROJECT_FILE"; then
    if [ ! -d "$PROJECT_DIR/Nestling/NestlingTests" ]; then
        echo "   ❌ Referenced directory 'NestlingTests' does not exist"
        ISSUES=1
    fi
fi

if grep -q "path = NestlingUITests" "$PROJECT_FILE"; then
    if [ ! -d "$PROJECT_DIR/Nestling/NestlingUITests" ]; then
        echo "   ❌ Referenced directory 'NestlingUITests' does not exist"
        ISSUES=1
    fi
fi

if [ $ISSUES -eq 0 ]; then
    echo "   ✅ No obvious structural issues found"
fi
echo ""

# Check disk space
echo "7️⃣  System Resources:"
DISK_SPACE=$(df -h "$PROJECT_DIR" | tail -1 | awk '{print $4}')
echo "   Available disk space: $DISK_SPACE"

MEMORY=$(vm_stat | grep "Pages free" | awk '{print $3}' | sed 's/\.//')
if [ ! -z "$MEMORY" ]; then
    MEMORY_GB=$((MEMORY * 4096 / 1024 / 1024 / 1024))
    echo "   Free memory: ~${MEMORY_GB}GB"
fi
echo ""

# Recommendations
echo "8️⃣  Recommendations:"
echo ""
echo "   If Xcode crashes immediately on opening:"
echo "   1. Run: bash scripts/aggressive_xcode_fix.sh"
echo "   2. Restart your Mac"
echo "   3. Try opening a simple new Xcode project first"
echo "   4. If that works, try opening this project"
echo ""
echo "   If Xcode crashes when building:"
echo "   1. Check for syntax errors in Swift files"
echo "   2. Verify all source files are valid UTF-8"
echo "   3. Try building from command line: xcodebuild -project Nestling.xcodeproj -scheme Nestling"
echo ""
echo "   If Xcode crashes when browsing files:"
echo "   1. May be issue with PBXFileSystemSynchronizedRootGroup"
echo "   2. Consider converting to traditional file references"
echo "   3. Check Console.app for specific error messages"
echo ""
echo "   To view crash logs in Console.app:"
echo "   1. Open Console.app"
echo "   2. Search for 'Xcode' and 'crash'"
echo "   3. Look for error messages or stack traces"
echo ""

