# Supabase Swift SDK Setup for Nestling iOS App

## Step 1: Add Supabase Swift SDK to Xcode

1. **Open Xcode project**: Open `ios/Nestling.xcodeproj`
2. **File → Add Package Dependencies**
3. **Enter URL**: `https://github.com/supabase/supabase-swift`
4. **Select version**: Latest release (recommended: `~> 2.0.0`)
5. **Add to target**: Nestling ✅

## Step 2: Verify Installation

After adding the package, verify it's correctly installed:
- Check `ios/Nestling.xcodeproj/project.pbxproj` contains Supabase references
- Build the project to ensure no compilation errors
- Check that `Supabase` import works in Swift files

## Step 3: Environment Variables

Ensure these environment variables are set in your build configuration:

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
```

### Setting Environment Variables in Xcode:

1. **Project Settings → Info → Custom iOS Target Properties**
2. **Add Rows**:
   - `SUPABASE_URL`: `https://your-project.supabase.co`
   - `SUPABASE_ANON_KEY`: `your-anon-key-here`

## Step 4: Update Implementation

After SDK installation, update these files with the implementations in this directory:
- `SupabaseClient.swift` - Real Supabase client implementation
- `AIAssistantService.swift` - Session token extraction
- `NestlingApp.swift` - Client initialization

## Step 5: Test Authentication

1. Run the app on device/simulator
2. Test AI Assistant feature
3. Verify authentication works (no 403 errors)
4. Check console logs for any SDK errors

## Troubleshooting

### Common Issues:

**"Missing package product 'Supabase'"**
- Rebuild the project completely (Product → Clean Build Folder)
- Restart Xcode
- Re-add the package dependency

**"Cannot find 'Supabase' in scope"**
- Ensure the package is added to the correct target (Nestling)
- Check that import statements are correct

**Authentication failing**
- Verify environment variables are set correctly
- Check Supabase project settings
- Ensure RLS policies allow authenticated access

### Verification Commands:

```bash
# Check if package is installed
cd ios && find . -name "*.pbxproj" -exec grep -l "Supabase" {} \;

# Verify environment variables
echo $SUPABASE_URL $SUPABASE_ANON_KEY
```