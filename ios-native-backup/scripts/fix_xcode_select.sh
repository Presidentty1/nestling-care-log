#!/bin/bash

# Fix xcode-select to point to Xcode instead of Command Line Tools

echo "🔧 Fixing xcode-select path..."

# Find Xcode installation
XCODE_PATH=$(ls -d /Applications/Xcode*.app 2>/dev/null | head -1)

if [ -z "$XCODE_PATH" ]; then
    echo "❌ ERROR: Xcode not found in /Applications/"
    echo "   Please install Xcode from the App Store"
    exit 1
fi

echo "   Found Xcode at: $XCODE_PATH"

# Set xcode-select path
echo "   Setting xcode-select to point to Xcode..."
sudo xcode-select --switch "$XCODE_PATH/Contents/Developer"

if [ $? -eq 0 ]; then
    echo "✅ xcode-select fixed!"
    echo ""
    echo "   Verifying..."
    xcodebuild -version
    echo ""
    echo "✅ Xcode is now properly configured"
else
    echo "❌ Failed to set xcode-select path"
    echo "   You may need to run this script with sudo"
    exit 1
fi

