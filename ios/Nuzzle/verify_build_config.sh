#!/bin/bash

# Script to verify build configuration is ready for App Store submission

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_FILE="$PROJECT_DIR/Nestling.xcodeproj/project.pbxproj"

echo "🔍 Verifying Build Configuration..."
echo ""

# Check version numbers
echo "📋 Version & Build Numbers:"
VERSION=$(grep -A 1 "MARKETING_VERSION" "$PROJECT_FILE" | grep -v "MARKETING_VERSION" | head -1 | sed 's/.*= //' | tr -d ';' | xargs)
BUILD=$(grep -A 1 "CURRENT_PROJECT_VERSION" "$PROJECT_FILE" | grep -v "CURRENT_PROJECT_VERSION" | head -1 | sed 's/.*= //' | tr -d ';' | xargs)

if [ -z "$VERSION" ] || [ "$VERSION" = "" ]; then
    echo "   ⚠️  Version not found"
else
    echo "   ✅ Version: $VERSION"
fi

if [ -z "$BUILD" ] || [ "$BUILD" = "" ]; then
    echo "   ⚠️  Build number not found"
else
    echo "   ✅ Build: $BUILD"
fi

echo ""

# Check privacy descriptions
echo "📋 Privacy Usage Descriptions:"
if grep -q "Nuzzle needs microphone access" "$PROJECT_FILE"; then
    echo "   ✅ NSMicrophoneUsageDescription: Updated to Nuzzle"
else
    echo "   ❌ NSMicrophoneUsageDescription: Still contains Nestling"
fi

if grep -q "Nuzzle needs camera access" "$PROJECT_FILE"; then
    echo "   ✅ NSCameraUsageDescription: Updated to Nuzzle"
else
    echo "   ❌ NSCameraUsageDescription: Still contains Nestling"
fi

if grep -q "Nuzzle needs photo library access" "$PROJECT_FILE"; then
    echo "   ✅ NSPhotoLibraryUsageDescription: Updated to Nuzzle"
else
    echo "   ❌ NSPhotoLibraryUsageDescription: Still contains Nestling"
fi

echo ""

# Check Privacy Manifest
echo "📋 Privacy Manifest:"
if [ -f "$PROJECT_DIR/Nestling/PrivacyInfo.xcprivacy" ]; then
    echo "   ✅ PrivacyInfo.xcprivacy file exists"
    if grep -q "PrivacyInfo.xcprivacy" "$PROJECT_FILE"; then
        echo "   ✅ PrivacyInfo.xcprivacy is in Xcode project"
    else
        echo "   ⚠️  PrivacyInfo.xcprivacy exists but not in Xcode project"
        echo "      Run: ./add_privacy_manifest.sh for instructions"
    fi
else
    echo "   ❌ PrivacyInfo.xcprivacy file not found"
fi

echo ""

# Check bundle identifier
echo "📋 Bundle Identifier:"
BUNDLE_ID=$(grep "PRODUCT_BUNDLE_IDENTIFIER" "$PROJECT_FILE" | head -1 | sed 's/.*= //' | tr -d ';' | xargs)
if [ -n "$BUNDLE_ID" ]; then
    echo "   ✅ Bundle ID: $BUNDLE_ID"
    if [[ "$BUNDLE_ID" == *"nestling"* ]]; then
        echo "      ℹ️  Note: Bundle ID preserved for App Store continuity (as planned)"
    fi
fi

echo ""

# Check for remaining "Nestling" references in user-facing code
echo "📋 Remaining 'Nestling' References:"
NESTLING_COUNT=$(grep -r "Nestling" "$PROJECT_DIR/Nestling" --include="*.swift" 2>/dev/null | grep -v "TODO" | grep -v "//" | wc -l | xargs)
if [ "$NESTLING_COUNT" -eq 0 ]; then
    echo "   ✅ No 'Nestling' references found in Swift code (excluding TODOs)"
else
    echo "   ⚠️  Found $NESTLING_COUNT references (may be in comments/TODOs)"
    echo "      Run: grep -r 'Nestling' Nestling/ --include='*.swift' | grep -v TODO"
fi

echo ""
echo "✅ Verification complete!"
















