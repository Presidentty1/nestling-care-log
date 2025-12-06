# QUICK FIX: Add New Files to Xcode Project

## The Problem
The new Swift files we created today exist in the file system but are NOT in the Xcode project, so they're not being compiled. That's why you don't see the changes.

## The Solution (2 minutes)

### Step 1: Open Xcode
Make sure the project is open in Xcode.

### Step 2: Add InitialStateView.swift
1. In Xcode's Project Navigator (left sidebar), find `Sources/Features/Onboarding/`
2. Right-click on the `Onboarding` folder
3. Select **"Add Files to Nuzzle..."**
4. Navigate to: `ios/Sources/Features/Onboarding/InitialStateView.swift`
5. In the dialog:
   - ✅ **UNCHECK** "Copy items if needed" (file is already in the right place)
   - ✅ **CHECK** "Add to targets: Nuzzle"
6. Click **"Add"**

### Step 3: Add GuidanceStripView.swift and ExampleDataBanner.swift
1. In Xcode's Project Navigator, find `Sources/Features/Home/`
2. Right-click on the `Home` folder
3. Select **"Add Files to Nuzzle..."**
4. Navigate to: `ios/Sources/Features/Home/`
5. **Select BOTH files** (Cmd+Click):
   - `GuidanceStripView.swift`
   - `ExampleDataBanner.swift`
6. In the dialog:
   - ✅ **UNCHECK** "Copy items if needed"
   - ✅ **CHECK** "Add to targets: Nuzzle"
7. Click **"Add"**

### Step 4: Clean and Build
1. Press `Cmd + Shift + K` (Clean Build Folder)
2. Press `Cmd + B` (Build)

### Step 5: Verify
After building, you should now see:
- ✅ Initial state question in onboarding (step 3 of 4)
- ✅ Three-segment guidance strip on home screen
- ✅ Example data banner when example timeline is shown

## Alternative: Drag and Drop
You can also drag the files from Finder directly into the correct folders in Xcode's Project Navigator. Make sure "Add to targets: Nuzzle" is checked in the dialog.
