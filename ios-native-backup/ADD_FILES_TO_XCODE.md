# Adding Source Files Back to Xcode Project

Follow these steps to add all your source files back to the regenerated Xcode project.

## Step 1: Add Main App Source Files

1. **In Xcode's Project Navigator** (left sidebar), right-click on the **"Nestling"** folder (the gray folder, not the blue project icon)

2. Select **"Add Files to 'Nestling'..."** from the context menu

3. In the file picker dialog:
   - Navigate to: `ios/Nestling/Nestling/`
   - **Select ALL folders** inside:
     - `App`
     - `Design`
     - `Domain`
     - `Features`
     - `Services`
     - `Utilities`
4. **Important settings at the bottom of the dialog:**
   - ✅ Check **"Create groups"** (not "Create folder references")
   - ✅ Check **"Add to targets: Nestling"**
   - ❌ Uncheck "Copy items if needed" (files are already in the right place)
   - ❌ Uncheck "Create groups" if you want to maintain folder structure

5. Click **"Add"**

## Step 2: Add Unit Test Files

1. Right-click on the **"NestlingTests"** folder in Project Navigator

2. Select **"Add Files to 'Nestling'..."**

3. Navigate to: `ios/Nestling/NestlingTests/`

4. Select all `.swift` files in that folder

5. **Settings:**
   - ✅ Check **"Create groups"**
   - ✅ Check **"Add to targets: NestlingTests"** (NOT Nestling!)
   - ❌ Uncheck "Copy items if needed"

6. Click **"Add"**

## Step 3: Add UI Test Files

1. Right-click on the **"NestlingUITests"** folder in Project Navigator

2. Select **"Add Files to 'Nestling'..."**

3. Navigate to: `ios/Nestling/NestlingUITests/`

4. Select all `.swift` files in that folder

5. **Settings:**
   - ✅ Check **"Create groups"**
   - ✅ Check **"Add to targets: NestlingUITests"** (NOT Nestling!)
   - ❌ Uncheck "Copy items if needed"

6. Click **"Add"**

## Step 4: Add Assets (if they exist)

1. Right-click on the **"Nestling"** folder in Project Navigator

2. Select **"Add Files to 'Nestling'..."**

3. Navigate to: `ios/Nestling/Nestling.xcodeproj/`

4. Select **"Assets.xcassets"** folder (if it exists)

5. **Settings:**
   - ✅ Check **"Create folder references"** (for assets)
   - ✅ Check **"Add to targets: Nestling"**

6. Click **"Add"**

## Step 5: Verify Files Are Added

1. **Check Project Navigator:**
   - Expand the "Nestling" folder - you should see all your source folders
   - Expand "NestlingTests" - you should see test files
   - Expand "NestlingUITests" - you should see UI test files

2. **Check Target Membership:**
   - Select a file from the "Nestling" folder
   - In the File Inspector (right sidebar), verify "Target Membership" shows ✅ Nestling
   - Select a test file, verify it shows ✅ NestlingTests
   - Select a UI test file, verify it shows ✅ NestlingUITests

## Step 6: Build the Project

1. **Select the Nestling scheme** from the scheme selector (top toolbar, next to the device selector)

2. **Select a simulator** (e.g., "iPhone 15 Pro" or any iOS 17+ simulator)

3. **Build the project:**
   - Press **⌘B** (Command + B)
   - Or go to **Product → Build**

4. **Fix any build errors:**
   - Check the Issue Navigator (⌘5) for any errors
   - Common issues:
     - Missing imports
     - Files not added to correct target
     - Missing dependencies

## Step 7: Run the App

1. **Run the app:**
   - Press **⌘R** (Command + R)
   - Or go to **Product → Run**

2. The app should launch in the simulator!

## Quick Checklist

- [ ] All source folders added to Nestling target
- [ ] Test files added to NestlingTests target
- [ ] UI test files added to NestlingUITests target
- [ ] Assets.xcassets added (if exists)
- [ ] Project builds without errors (⌘B)
- [ ] App runs in simulator (⌘R)

## Troubleshooting

### Files not showing in Project Navigator

- Make sure you selected "Create groups" not "Create folder references"
- Try closing and reopening Xcode

### Build errors about missing files

- Verify files are added to the correct target
- Check File Inspector → Target Membership

### "No such module" errors

- Clean build folder: Product → Clean Build Folder (⇧⌘K)
- Build again: ⌘B

### Files in wrong location

- Drag files to correct folder in Project Navigator
- Xcode will ask if you want to move them - say yes

## Alternative: Add Files via Drag & Drop

You can also drag files directly from Finder:

1. Open Finder and navigate to `ios/Nestling/Nestling/`
2. Select the folders you want to add
3. Drag them into Xcode's Project Navigator onto the "Nestling" folder
4. In the dialog that appears:
   - Select "Create groups"
   - Check "Add to targets: Nestling"
   - Click "Finish"

This method is faster if you're adding many files at once!
