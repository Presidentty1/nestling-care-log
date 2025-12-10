# Adding New Swift Files to Xcode Project

## Problem

The new files we created today exist in the file system but are NOT added to the Xcode project, so they're not being compiled:

1. **InitialStateView.swift** - `ios/Sources/Features/Onboarding/InitialStateView.swift`
2. **GuidanceStripView.swift** - `ios/Sources/Features/Home/GuidanceStripView.swift`
3. **ExampleDataBanner.swift** - `ios/Sources/Features/Home/ExampleDataBanner.swift`

## Solution: Add Files in Xcode

### Method 1: Drag and Drop (Easiest)

1. Open Xcode with the project
2. In the Project Navigator (left sidebar), navigate to:
   - `Sources/Features/Onboarding/` folder
   - `Sources/Features/Home/` folder
3. Open Finder and navigate to:
   - `/Users/tyhorton/Coding Projects/nestling-care-log/ios/Sources/Features/Onboarding/`
   - `/Users/tyhorton/Coding Projects/nestling-care-log/ios/Sources/Features/Home/`
4. Drag the files from Finder into the corresponding folders in Xcode's Project Navigator
5. In the dialog that appears:
   - ✅ Check "Copy items if needed" (or leave unchecked if files are already in place)
   - ✅ Check "Add to targets: Nuzzle"
   - Click "Finish"

### Method 2: Add Files Menu

1. In Xcode, right-click on the `Sources/Features/Onboarding/` folder
2. Select "Add Files to Nuzzle..."
3. Navigate to `ios/Sources/Features/Onboarding/InitialStateView.swift`
4. Make sure:
   - "Copy items if needed" is UNCHECKED (files are already in the right place)
   - "Add to targets: Nuzzle" is CHECKED
5. Click "Add"
6. Repeat for `GuidanceStripView.swift` and `ExampleDataBanner.swift` in the `Home` folder

### After Adding Files

1. Clean Build Folder: `Cmd + Shift + K`
2. Build: `Cmd + B`
3. Verify the new features appear in the app

## Verification

After adding and building, you should see:

- ✅ Initial state question in onboarding (step 3 of 4)
- ✅ Three-segment guidance strip on home screen (Now / Next Nap / Next Feed)
- ✅ Example data banner when example timeline is shown
