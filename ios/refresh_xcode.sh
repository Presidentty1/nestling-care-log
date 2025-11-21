#!/bin/bash
# Script to refresh Xcode project and resolve package dependencies

echo "🔄 Refreshing Xcode project for Nestling..."
cd "$(dirname "$0")/Nestling"

echo "1. Cleaning caches..."
rm -rf ~/Library/Developer/Xcode/DerivedData/Nestling-* 2>/dev/null
rm -rf ~/Library/Caches/org.swift.swiftpm 2>/dev/null
rm -rf .swiftpm 2>/dev/null
rm -rf .build 2>/dev/null

echo "2. Resolving packages..."
xcodebuild -resolvePackageDependencies -project Nestling.xcodeproj -clonedSourcePackagesDirPath .swiftpm

echo "3. Touching project file..."
touch Nestling.xcodeproj/project.pbxproj

echo ""
echo "✅ Done! Now:"
echo "   1. Close Xcode completely (⌘Q)"
echo "   2. Reopen the project"
echo "   3. Wait for package resolution (progress bar in Xcode)"
echo "   4. Build (⌘B)"


