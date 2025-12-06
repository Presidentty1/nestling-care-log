# iOS Configuration Setup - REQUIRED

## Critical Issue Fixed: App Crash

✅ **Info.plist created** with all required privacy descriptions
✅ **SpeechRecognitionService updated** to use lazy initialization
✅ **Environment configuration template** created

---

## What Was Fixed

### 1. App Crash (NSSpeechRecognitionUsageDescription)

**Problem**: App crashed when accessing speech recognition because Info.plist was missing privacy descriptions.

**Solution**: Created `ios/Nuzzle/Nestling/Info.plist` with all required privacy keys:
- NSSpeechRecognitionUsageDescription
- NSMicrophoneUsageDescription  
- NSCameraUsageDescription
- NSPhotoLibraryUsageDescription
- NSUserNotificationsUsageDescription

**Action Required**: 
1. Open Xcode project: `ios/Nuzzle/Nestling.xcodeproj`
2. Drag `Info.plist` from Finder into the Nestling folder in Xcode
3. Make sure "Copy items if needed" is checked
4. Select "Nestling" target
5. In target settings, set "Info.plist File" to "Nestling/Info.plist"

### 2. Speech Recognition Safety

**Problem**: Speech recognition was initialized immediately, causing crash if permissions not configured.

**Solution**: Updated `SpeechRecognitionService.swift` to use lazy initialization:
- No longer requests permissions on init
- Permissions requested only when user actually tries to use voice input
- Async permission check prevents crashes

### 3. Supabase Configuration

**Problem**: Environment variables not set, causing "Supabase not configured" warnings.

**Solution**: Created `Environment.xcconfig` template.

**Action Required**:
1. Copy `Environment.xcconfig.template` (if exists) or use the new `Environment.xcconfig`
2. Fill in your actual Supabase credentials:
   ```
   SUPABASE_URL = https://your-project-id.supabase.co
   SUPABASE_ANON_KEY = your-actual-anon-key
   ```
3. In Xcode, select the project → Info tab → Configurations
4. Set Debug and Release configurations to use `Environment.xcconfig`

**OR** (Simpler for testing):
1. Open `Nestling/Services/Secrets.swift`
2. Replace the placeholder values directly:
   ```swift
   static let supabase URL = "https://your-project.supabase.co"
   static let supabaseAnonKey = "your-anon-key"
   ```

### 4. Firebase (Optional)

**Problem**: GoogleService-Info.plist not found.

**Solution**: Firebase is optional for MVP. If you want Firebase analytics:
1. Download `GoogleService-Info.plist` from Firebase Console
2. Drag it into the Nestling folder in Xcode
3. Ensure "Copy items if needed" is checked
4. Select "Nestling" target

**OR**: The app works fine without Firebase - it will use console-based analytics.

### 5. Sentry (Optional)

**Problem**: Using placeholder Sentry DSN.

**Solution**: Sentry is optional. If you want crash reporting:
1. Get DSN from Sentry.io
2. Add to `Environment.xcconfig`: `SENTRY_DSN = your-dsn`

**OR**: Update `Secrets.swift` directly with real DSN.

---

## Quick Start (Minimum Configuration)

### Option A: For Testing Without Backend (Guest Mode)

The app already works in guest mode! Just:
1. Add Info.plist to Xcode project (see Step 1 above)
2. Build and run

The app will:
- ✅ Run in guest mode (no auth required)
- ✅ Store data locally  
- ✅ Show all UI features
- ⚠️ Skip Supabase sync (data stays local)

### Option B: For Full Backend Integration

1. Add Info.plist to Xcode project
2. Configure Supabase credentials in `Secrets.swift`
3. Build and run

The app will:
- ✅ Support authentication
- ✅ Sync data to Supabase
- ✅ Enable multi-device sync

---

## Step-by-Step: Adding Info.plist to Xcode

This is **REQUIRED** to prevent crashes:

1. Open Xcode:
   ```bash
   open /Users/tyhorton/.cursor/worktrees/nestling-care-log/gnq/ios/Nuzzle/Nestling.xcodeproj
   ```

2. In Finder, navigate to:
   ```
   /Users/tyhorton/.cursor/worktrees/nestling-care-log/gnq/ios/Nuzzle/Nestling/
   ```

3. Drag `Info.plist` from Finder into the "Nestling" folder in Xcode's left sidebar

4. In the dialog that appears:
   - ✅ Check "Copy items if needed"
   - ✅ Check "Nestling" under "Add to targets"
   - Click "Finish"

5. Select the "Nestling" target in Xcode

6. Go to "Build Settings" tab

7. Search for "Info.plist"

8. Set "Info.plist File" to: `Nestling/Info.plist`

9. Clean Build Folder (⌘⇧K)

10. Build (⌘B)

11. Run (⌘R)

**The crash should be fixed!**

---

## Configuration Files Summary

### Created Files
- ✅ `ios/Nuzzle/Nestling/Info.plist` - Privacy descriptions (MUST add to Xcode)
- ✅ `ios/Nuzzle/Environment.xcconfig` - Environment variables template

### Modified Files
- ✅ `ios/Nuzzle/Nestling/Services/SpeechRecognitionService.swift` - Lazy initialization

### Existing Files (No changes needed)
- `ios/Nuzzle/Nestling/Services/Secrets.swift` - Already handles env vars
- `ios/Nuzzle/Nestling/Services/SupabaseClient.swift` - Already handles missing config
- `ios/Nuzzle/Nestling/Nestling.entitlements` - App capabilities
- `ios/Nuzzle/Nestling/PrivacyInfo.xcprivacy` - Privacy manifest

---

## Testing the Fix

### After adding Info.plist to Xcode:

1. Clean build folder (⌘⇧K)
2. Build (⌘B) - should succeed
3. Run (⌘R) - should launch without crash
4. Tap "First log card" - should open form without crash
5. Voice button will show in forms but only request permission when tapped

---

## Optional: Configure Supabase

If you want data sync (not required for testing UX):

### Quick Method (Hardcode for Testing)
Edit `Secrets.swift`:
```swift
static let supabaseURL = "https://dwcucxgtyagjeyuoxayr.supabase.co"  // Your actual URL
static let supabaseAnonKey = "eyJ..."  // Your actual anon key
```

### Proper Method (Environment Variables)
1. Edit `Environment.xcconfig` with real values
2. In Xcode → Project → Info → Configurations
3. Set Debug to use `Environment.xcconfig`
4. Set Release to use `Environment.xcconfig`

---

## Expected Behavior After Fix

### With Info.plist Added
- ✅ App launches without crash
- ✅ Can tap first log card
- ✅ Forms open correctly
- ✅ Voice button appears (requests permission when tapped)
- ✅ All UX features work

### Without Supabase Configured
- ✅ App runs in guest mode
- ✅ Data stored locally
- ⚠️ No multi-device sync

### With Supabase Configured
- ✅ Full authentication
- ✅ Data syncs across devices
- ✅ Multi-caregiver features

---

## Priority

1. **P0 (Must Do)**: Add Info.plist to Xcode - **REQUIRED to prevent crash**
2. **P1 (Should Do)**: Configure Supabase - needed for multi-device sync
3. **P2 (Nice to Have)**: Add Firebase - only needed for advanced analytics
4. **P3 (Optional)**: Configure Sentry - only needed for crash reporting

---

**The crash fix is ready! Just need to add Info.plist to the Xcode project.**

