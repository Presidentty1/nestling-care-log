# Xcode Project Setup Instructions

## Correct Xcode Project

**USE THIS PROJECT:**

```
ios/Nuzzle/Nestling.xcodeproj
```

**CLOSE THIS PROJECT (wrong location):**

```
/Users/tyhorton/Coding Projects/nestling-care-log/ios/Nuzzle/Nestling.xcodeproj
```

## Steps to Fix Build Errors

1. **Close both Xcode windows**

2. **Open ONLY the correct project:**
   - In Finder, navigate to: `ios/Nuzzle/`
   - Double-click `Nestling.xcodeproj` to open it

3. **Resolve Swift Package Dependencies:**
   - In Xcode, go to: **File** → **Packages** → **Reset Package Caches**
   - Then: **File** → **Packages** → **Resolve Package Versions**
   - Wait for the packages to download and resolve (this may take a few minutes)

4. **Clean Build Folder:**
   - Press: **Cmd + Shift + K** (or **Product** → **Clean Build Folder**)

5. **Build:**
   - Press: **Cmd + B** to build

## Packages That Should Resolve

The following packages are configured and should resolve:

- ✅ Sentry (sentry-cocoa)
- ✅ Supabase (supabase-swift)
- ✅ FirebaseAnalytics
- ✅ FirebaseCore

## If Issues Persist

If packages still don't resolve:

1. Close Xcode completely
2. Delete `~/Library/Developer/Xcode/DerivedData/Nestling-*` (already done)
3. Reopen the correct Xcode project
4. Let Xcode resolve packages automatically on first build
