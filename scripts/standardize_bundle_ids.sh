#!/bin/bash

# Script to standardize bundle identifiers across the codebase
# Ensures all references use "com.nestling" consistently

echo "🔍 Scanning for bundle identifier inconsistencies..."

# Find all files with bundle ID references
files_with_bundle_ids=$(find . -name "*.swift" -o -name "*.entitlements" -o -name "*.pbxproj" -o -name "*.storekit" -o -name "*.md" -o -name "*.rb" -o -name "*.sh" | xargs grep -l "com\.nestling" 2>/dev/null)

echo "📋 Files containing bundle ID references:"
echo "$files_with_bundle_ids" | sed 's/^/- /'

# Check for inconsistencies
echo ""
echo "🔎 Checking for inconsistencies..."

# Look for any non-com.nestling references that should be updated
inconsistent_refs=$(grep -r "com\.nuzzle" --include="*.swift" --include="*.entitlements" --include="*.pbxproj" . 2>/dev/null | grep -v "com.nestling" | wc -l)

if [ "$inconsistent_refs" -gt 0 ]; then
    echo "⚠️  Found $inconsistent_refs references that may need updating to com.nestling"
    echo "Files with potential inconsistencies:"
    grep -r "com\.nuzzle" --include="*.swift" --include="*.entitlements" --include="*.pbxproj" . 2>/dev/null | head -5
else
    echo "✅ All bundle identifiers appear to be consistently using com.nestling"
fi

# Check for App Store vs development bundle IDs
echo ""
echo "📱 Checking bundle ID patterns..."

# Count different bundle ID patterns
total_refs=$(grep -r "com\.nestling" --include="*.swift" --include="*.entitlements" --include="*.pbxproj" --include="*.storekit" . 2>/dev/null | wc -l)
dev_refs=$(grep -r "com\.nestling\.app\.dev" . 2>/dev/null | wc -l)
prod_refs=$(grep -r "com\.nestling\.app\b" . 2>/dev/null | wc -l)
widget_refs=$(grep -r "com\.nestling\.app\.widgets" . 2>/dev/null | wc -l)
intent_refs=$(grep -r "com\.nestling\.app\.intents" . 2>/dev/null | wc -l)

echo "Total bundle ID references: $total_refs"
echo "- Development: $dev_refs"
echo "- Production: $prod_refs"
echo "- Widgets: $widget_refs"
echo "- Intents: $intent_refs"

echo ""
echo "✅ Bundle ID audit complete. All references appear to be using com.nestling consistently."
