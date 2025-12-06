#!/bin/bash
# Script to install CocoaPods and dependencies for iOS project

set -e

echo "🔧 Installing CocoaPods..."
if ! command -v pod &> /dev/null; then
    echo "CocoaPods not found. Installing..."
    if command -v brew &> /dev/null; then
        echo "Using Homebrew to install CocoaPods..."
        brew install cocoapods
    else
        echo "Using gem to install CocoaPods (requires sudo)..."
        sudo gem install cocoapods
    fi
else
    echo "✅ CocoaPods already installed"
fi

echo ""
echo "📦 Installing iOS dependencies..."
pod install

echo ""
echo "✅ Done! You can now open App.xcworkspace in Xcode"
