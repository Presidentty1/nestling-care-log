#!/bin/bash

# Script to clean up backup directories in ios/
# This removes old backup directories that are no longer needed

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🧹 Cleaning up backup directories in ios/..."
echo ""

# List of backup directories to remove
BACKUP_DIRS=(
    "backup_20251118_215121"
    "ios-native-backup"
)

# Also check for .backup files in project directories
BACKUP_FILES=(
    "Nuzzle/Nestling.xcodeproj/project.pbxproj.backup_pre_phase1"
    "Nuzzle/Nestling.xcodeproj/project.pbxproj.backup_trialbanner"
    "Nuzzle/Nestling.xcodeproj.backup"
    "Nuzzle/Nestling.xcodeproj.backup.20251118_214456"
)

REMOVED_COUNT=0
TOTAL_SIZE=0

# Remove backup directories
for dir in "${BACKUP_DIRS[@]}"; do
    FULL_PATH="$SCRIPT_DIR/$dir"
    if [ -d "$FULL_PATH" ]; then
        SIZE=$(du -sh "$FULL_PATH" 2>/dev/null | cut -f1)
        echo "📁 Removing directory: $dir ($SIZE)"
        rm -rf "$FULL_PATH"
        REMOVED_COUNT=$((REMOVED_COUNT + 1))
    else
        echo "⏭️  Skipping (not found): $dir"
    fi
done

# Remove backup files
for file in "${BACKUP_FILES[@]}"; do
    FULL_PATH="$SCRIPT_DIR/$file"
    if [ -e "$FULL_PATH" ]; then
        if [ -d "$FULL_PATH" ]; then
            SIZE=$(du -sh "$FULL_PATH" 2>/dev/null | cut -f1)
            echo "📁 Removing directory: $file ($SIZE)"
            rm -rf "$FULL_PATH"
        else
            SIZE=$(du -h "$FULL_PATH" 2>/dev/null | cut -f1)
            echo "📄 Removing file: $file ($SIZE)"
            rm -f "$FULL_PATH"
        fi
        REMOVED_COUNT=$((REMOVED_COUNT + 1))
    else
        echo "⏭️  Skipping (not found): $file"
    fi
done

echo ""
if [ $REMOVED_COUNT -gt 0 ]; then
    echo "✅ Cleanup complete! Removed $REMOVED_COUNT backup items"
else
    echo "ℹ️  No backup items found to remove"
fi
echo ""
echo "📝 Note: Sources-archive/ is kept for reference and is not removed."
echo ""

