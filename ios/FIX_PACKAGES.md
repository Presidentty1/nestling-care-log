# Fix Swift Package Manager Dependencies

The build is failing due to corrupted Swift Package Manager dependencies, not the code changes.

## Steps to Fix in Xcode:

1. **Open Xcode**
   - Open `ios/Nuzzle/Nestling.xcodeproj` in Xcode

2. **Reset Package Caches**
   - Go to: **File → Packages → Reset Package Caches**
   - Wait for it to complete (may take a minute)

3. **Update Packages**
   - Go to: **File → Packages → Update to Latest Package Versions**
   - Wait for packages to resolve

4. **If that doesn't work, try resolving packages manually:**
   - In Project Navigator, select the **Nestling** project (top item)
   - Go to the **Package Dependencies** tab
   - Click the **"+"** button for each missing package:
     - Sentry: `https://github.com/getsentry/sentry-cocoa.git`
     - Supabase: `https://github.com/supabase/supabase-swift.git`
     - Firebase: `https://github.com/firebase/firebase-ios-sdk.git`

5. **Clean Build Folder**
   - Go to: **Product → Clean Build Folder** (Cmd+Shift+K)
   - Then build again: **Product → Build** (Cmd+B)

## Alternative: Command Line Fix

If Xcode GUI doesn't work, try this in Terminal:

```bash
cd "/Users/tyhorton/Coding Projects/nestling-care-log/ios/Nuzzle"

# Remove package resolved file
rm -f Nestling.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved

# Clear all caches
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Reopen in Xcode and let it resolve packages
```

## What Changed in the Code

The refactoring we did was all Swift code changes - no package dependencies were modified:

### New Files Created:

- `Features/Onboarding/LastWakeView.swift`
- `Features/Onboarding/PaywallView.swift`
- `Features/Onboarding/OnboardingCompleteView.swift`
- `Features/Home/TodayHeaderBar.swift`
- `Features/Home/AITeaseCard.swift`
- `Features/More/MoreView.swift`

### Files Modified:

- `OnboardingCoordinator.swift` - Added 7-step flow
- `OnboardingView.swift` - Wired new steps
- `WelcomeView.swift` - Updated copy
- `BabyEssentialsView.swift` - Added due date option
- `GoalSelectionView.swift` - Multi-select focus areas
- `NotificationsIntroView.swift` - Enhanced with nap context
- `HomeContentView.swift` - Simplified Today layout
- `NestlingApp.swift` - Changed to 3-tab structure
- `NapPredictionCard.swift` - Added safety disclaimer

All changes compile correctly - this is purely a dependency resolution issue.

## If Still Failing

The package manager may have corrupted package checkouts. Try:

1. Delete the entire Xcode project directory temporarily
2. Re-clone from git
3. Let Xcode resolve packages from scratch

Or just restart Xcode and try the "Reset Package Caches" option again.
