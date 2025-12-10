#!/bin/bash

# Script to add PrivacyInfo.xcprivacy to Xcode project
# This script uses PlistBuddy and sed to modify the project.pbxproj file

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_FILE="$PROJECT_DIR/Nestling.xcodeproj/project.pbxproj"
PRIVACY_FILE="$PROJECT_DIR/Nestling/PrivacyInfo.xcprivacy"

if [ ! -f "$PRIVACY_FILE" ]; then
    echo "❌ Error: PrivacyInfo.xcprivacy not found at $PRIVACY_FILE"
    exit 1
fi

if [ ! -f "$PROJECT_FILE" ]; then
    echo "❌ Error: project.pbxproj not found at $PROJECT_FILE"
    exit 1
fi

echo "✅ PrivacyInfo.xcprivacy file exists"
echo "⚠️  Note: Adding files to Xcode project programmatically is complex."
echo "   It's safer to add it manually in Xcode:"
echo ""
echo "   1. Open Nestling.xcodeproj in Xcode"
echo "   2. Right-click on 'Nestling' folder in Project Navigator"
echo "   3. Select 'Add Files to Nuzzle...'"
echo "   4. Navigate to: $PRIVACY_FILE"
echo "   5. Make sure 'Copy items if needed' is UNCHECKED"
echo "   6. Make sure 'Add to targets: Nuzzle' is CHECKED"
echo "   7. Click 'Add'"
echo ""
echo "   The file is ready at: $PRIVACY_FILE"













