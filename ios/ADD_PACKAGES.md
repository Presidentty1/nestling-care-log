# Adding Swift Package Dependencies to Xcode

The iOS project needs the following Swift Package dependencies. Since the automated scripts aren't working with the current xcodeproj gem version, please add them manually in Xcode:

## Required Packages

1. **Firebase iOS SDK**
   - URL: `https://github.com/firebase/firebase-ios-sdk.git`
   - Version: `11.0.0` or later
   - Products needed:
     - `FirebaseCore`
     - `FirebaseAnalytics`

2. **Supabase Swift**
   - URL: `https://github.com/supabase/supabase-swift.git`
   - Version: `2.0.0` or later
   - Products needed:
     - `Supabase`

3. **Sentry Cocoa**
   - URL: `https://github.com/getsentry/sentry-cocoa.git`
   - Version: `8.0.0` or later
   - Products needed:
     - `Sentry`

## Steps to Add in Xcode

1. Open `ios/Nuzzle/Nuzzle.xcodeproj` in Xcode
2. Select the **Nuzzle** project in the navigator (top item)
3. Select the **Nuzzle** target
4. Go to the **Package Dependencies** tab
5. Click the **+** button to add a package
6. For each package:
   - Paste the URL
   - Choose "Up to Next Major Version" and enter the version number
   - Click "Add Package"
   - Select the products listed above
   - Click "Add Package"
7. Xcode will automatically resolve and download the packages
8. Build the project (⌘B)

## Fix Import Error

The `HomeView.swift` file had an incorrect import that has been fixed. The `FeatureGate` struct is in the same module and doesn't need a special import.


