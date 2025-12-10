#!/bin/bash

# Script to safely archive ios/Sources/ directory
# This moves Sources to Sources-archive/ with a timestamp

set -e  # Exit on error

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCES_DIR="$SCRIPT_DIR/Sources"
ARCHIVE_DIR="$SCRIPT_DIR/Sources-archive-$(date +%Y%m%d_%H%M%S)"

echo "📦 Archiving ios/Sources/ directory..."
echo ""

# Check if Sources directory exists
if [ ! -d "$SOURCES_DIR" ]; then
    echo "❌ Error: $SOURCES_DIR does not exist"
    exit 1
fi

# Check if archive directory already exists
if [ -d "$SCRIPT_DIR/Sources-archive" ]; then
    echo "⚠️  Warning: Sources-archive directory already exists"
    echo "   Using timestamped name: $(basename $ARCHIVE_DIR)"
else
    ARCHIVE_DIR="$SCRIPT_DIR/Sources-archive"
fi

# Create archive directory
echo "📁 Creating archive directory: $(basename $ARCHIVE_DIR)"
mkdir -p "$ARCHIVE_DIR"

# Move Sources to archive
echo "🔄 Moving Sources/ to archive..."
mv "$SOURCES_DIR" "$ARCHIVE_DIR/Sources"

# Count files archived
FILE_COUNT=$(find "$ARCHIVE_DIR/Sources" -type f | wc -l | tr -d ' ')
echo ""
echo "✅ Successfully archived $FILE_COUNT files"
echo "   Archive location: $ARCHIVE_DIR"
echo ""
echo "📝 Note: This archive is kept for reference."
echo "   The active iOS project uses: ios/Nuzzle/Nestling/"
echo ""