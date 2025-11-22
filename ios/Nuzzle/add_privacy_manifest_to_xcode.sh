#!/bin/bash

# Script to help add PrivacyInfo.xcprivacy to Xcode project
# This is a helper script - the actual addition must be done manually in Xcode

set -e

PRIVACY_MANIFEST="Nestling/PrivacyInfo.xcprivacy"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_PATH="${PROJECT_DIR}/${PRIVACY_MANIFEST}"

echo "🔍 Checking Privacy Manifest..."
echo ""

if [ ! -f "$MANIFEST_PATH" ]; then
    echo "❌ Error: Privacy Manifest not found at: $MANIFEST_PATH"
    exit 1
fi

echo "✅ Privacy Manifest found at: $MANIFEST_PATH"
echo ""
echo "📋 To add this file to your Xcode project:"
echo ""
echo "1. Open Nestling.xcodeproj in Xcode"
echo "2. Right-click on the 'Nestling' folder in Project Navigator"
echo "3. Select 'Add Files to \"Nuzzle\"...'"
echo "4. Navigate to: $MANIFEST_PATH"
echo "5. Make sure 'Copy items if needed' is UNCHECKED (file is already in place)"
echo "6. Make sure 'Add to targets: Nuzzle' is CHECKED"
echo "7. Click 'Add'"
echo ""
echo "🔍 Verifying file contents..."
echo ""

if grep -q "NSPrivacyAccessedAPITypes" "$MANIFEST_PATH"; then
    echo "✅ Privacy Manifest contains required API declarations"
else
    echo "⚠️  Warning: Privacy Manifest may be missing required declarations"
fi

if grep -q "NSPrivacyCollectedDataTypes" "$MANIFEST_PATH"; then
    echo "✅ Privacy Manifest contains data collection declarations"
else
    echo "⚠️  Warning: Privacy Manifest may be missing data collection declarations"
fi

echo ""
echo "✨ After adding to Xcode, verify:"
echo "   - File appears in Project Navigator"
echo "   - Target Membership shows 'Nuzzle' checked"
echo "   - File Inspector shows correct file type"
echo ""

