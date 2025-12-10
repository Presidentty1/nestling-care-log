# Xcode Project Setup Instructions

## Creating the Xcode Project

Since Xcode project files (`.xcodeproj`) are complex binary/XML files that are best created through Xcode's GUI, follow these steps:

### Step 1: Create New Project in Xcode

1. Open Xcode
2. File → New → Project
3. Select **iOS** → **App**
4. Click **Next**
5. Configure:
   - **Product Name**: `Nestling`
   - **Team**: Select your team (or "None" for now)
   - **Organization Identifier**: `com.nestling`
   - **Bundle Identifier**: `com.nestling.app`
   - **Interface**: SwiftUI
   - **Language**: Swift
   - **Storage**: None (we'll use Core Data separately)
   - **Include Tests**: ✅ Yes
6. Click **Next**
7. Navigate to `ios/` directory
8. **IMPORTANT**: Uncheck "Create Git repository" (repo already exists)
9. Click **Create**

### Step 2: Delete Auto-Generated Files

Xcode creates some files we already have:

1. **Delete**: `NestlingApp.swift` (we have `Sources/App/NestlingApp.swift`)
2. **Delete**: `ContentView.swift` (if created, we have our own)
3. **Delete**: `Assets.xcassets` folder (we have `Nestling/Assets.xcassets`)
4. **Keep**: `NestlingTests` folder (we'll add our tests here)

### Step 3: Add Existing Source Files

1. In Xcode, **right-click** on the `Nestling` folder in Project Navigator
2. Select **Add Files to "Nestling"...**
3. Navigate to `ios/Sources/`
4. **Select ALL folders**:
   - `App/`
   - `Design/`
   - `Domain/` (includes Core Data model)
   - `Features/`
   - `Services/`
   - `Utilities/`
5. **Options**:
   - ✅ **Copy items if needed**: ❌ **Unchecked** (files already in place)
   - ✅ **Create groups**: ✅ **Selected**
   - ✅ **Add to targets**: Nestling ✅
6. Click **Add**

**Important**: The `Domain/Models/CoreData/Nestling.xcdatamodeld` file must be added to the target. Xcode should recognize it automatically, but verify it's included.

### Step 4: Add Asset Catalogs

1. **Right-click** `Nestling` folder
2. **Add Files**: `ios/Nestling/Assets.xcassets`
3. **Options**: Same as above (don't copy, create groups, add to Nestling target)

### Step 5: Configure Main App Target

1. Select **Nestling** target in Project Navigator
2. **General** tab:
   - **Display Name**: Nestling
   - **Bundle Identifier**: `com.nestling.app`
   - **Version**: 1.0
   - **Build**: 1
   - **Deployment Target**: iOS 17.0
   - **Supported Destinations**: iPhone, iPad
3. **Signing & Capabilities** tab:
   - Select your team
   - Add capability: **App Groups** → `group.com.nestling.Nestling`
   - Add capability: **Push Notifications** (for future)
4. **Info** tab:
   - Replace `Info.plist` with the one from `ios/Nestling/Info.plist`
   - Or manually add URL scheme: `nestling://`
   - Add usage descriptions (microphone, notifications, Face ID)

### Step 6: Add Tests

1. **Right-click** `NestlingTests` folder
2. **Add Files**: `ios/Tests/`
3. **Select all test files**:
   - `DataStoreTests.swift`
   - `DateUtilsTests.swift`
   - `EventValidatorTests.swift`
   - `NotificationSchedulerTests.swift`
   - `PerformanceTests.swift`
   - `ResilienceTests.swift`
4. **Options**:
   - ✅ **Copy items if needed**: ❌ Unchecked
   - ✅ **Create groups**: ✅ Selected
   - ✅ **Add to targets**: NestlingTests ✅ (NOT Nestling)
5. **Click** Add

**Note**: Test files should use `@testable import Nestling` to access internal types.

### Step 7: Create Widgets Extension Target (Optional)

1. File → New → Target
2. Select **Widget Extension**
3. Configure:
   - **Product Name**: `NestlingWidgets`
   - **Bundle Identifier**: `com.nestling.app.widgets`
   - **Include Configuration Intent**: ❌ No
4. Click **Finish**
5. Delete the auto-generated `NestlingWidgets.swift` (we'll create our own)
6. Add `ios/NestlingWidgets/` source files to this target

### Step 8: Create App Intents Extension Target (Optional)

1. File → New → Target
2. Select **App Intents Extension**
3. Configure:
   - **Product Name**: `NestlingIntents`
   - **Bundle Identifier**: `com.nestling.app.intents`
4. Click **Finish**
5. Delete auto-generated files (we'll create our own)
6. Add `ios/NestlingIntents/` source files to this target

### Step 9: Add UI Tests (Optional)

1. **Right-click** `NestlingUITests` folder
2. **Add Files**: `ios/NestlingUITests/`
3. **Select all UI test files**
4. **Options**: Add to NestlingUITests target only

### Step 10: Update Build Settings

For **Nestling** target:
- **Swift Language Version**: Swift 5.9
- **iOS Deployment Target**: 17.0
- **Swift Compiler - Language**: Swift
- **Enable Modules**: Yes

For **NestlingWidgets** target:
- **Swift Language Version**: Swift 5.9
- **iOS Deployment Target**: 17.0
- **App Groups**: `group.com.nestling.Nestling`

For **NestlingIntents** target:
- **Swift Language Version**: Swift 5.9
- **iOS Deployment Target**: 17.0
- **App Groups**: `group.com.nestling.Nestling`

### Step 11: Add Entitlements

1. For **Nestling** target:
   - Add `ios/Nestling/Entitlements.entitlements` file
   - In target settings → **Signing & Capabilities** → ensure entitlements file is set
   - **Add Capability**: App Groups → `group.com.nestling.Nestling` (for widgets/extensions)

### Step 12: Configure Info.plist

1. **Select** Nestling target
2. **Info** tab:
   - **URL Types**: Add `nestling` scheme
   - **Privacy - Microphone Usage Description**: "Record baby's cry for analysis"
   - **Privacy - Face ID Usage Description**: "Secure your baby's data"
   - **Privacy - User Notifications**: Not needed (handled in code)

### Step 13: Verify Compilation

1. **Product → Clean Build Folder** (⇧⌘K)
2. **Product → Build** (⌘B)
3. **Fix any import errors**:
   - Ensure all files are added to Nestling target
   - Check File Inspector → Target Membership
4. **Common issues**:
   - Missing imports: Usually means file not in target
   - Core Data errors: Model file must be added to target
   - Test errors: Ensure `@testable import Nestling` is used

### Step 14: Set Up Schemes

1. Product → Scheme → Manage Schemes
2. Ensure schemes exist for:
   - Nestling (Run)
   - NestlingTests (Test)
   - NestlingUITests (Test)
   - NestlingWidgets (Run)
   - NestlingIntents (Run)

## Project Structure After Setup

```
Nestling.xcodeproj/
├── Nestling/                    (Main App Target)
│   ├── Info.plist
│   ├── Entitlements.entitlements
│   └── Sources/                 (All source files)
│
├── NestlingWidgets/             (Widget Extension Target)
│   ├── Info.plist
│   └── Sources/
│
├── NestlingIntents/             (App Intents Target)
│   ├── Info.plist
│   └── Sources/
│
├── NestlingTests/               (Unit Tests Target)
│   └── Tests/
│
└── NestlingUITests/             (UI Tests Target)
    └── UITests/
```

## Troubleshooting

### Import Errors
- Ensure all source files are added to correct targets
- Check that `@testable import Nestling` is used in test files

### Missing Files
- Verify file paths in Project Navigator match actual file locations
- Use "Show in Finder" to verify file exists

### Build Errors
- Clean build folder (⇧⌘K)
- Delete DerivedData: `~/Library/Developer/Xcode/DerivedData`
- Restart Xcode

## Quick Verification

After setup, verify:

1. **Build succeeds** (⌘B)
2. **Run in simulator** (⌘R)
3. **Onboarding appears** on first launch
4. **Home screen loads** with demo data
5. **Quick actions work** (tap Feed, Sleep, etc.)
6. **Timeline shows events**

## Next Steps

After project setup is complete:
1. ✅ Verify all targets build successfully
2. ✅ Run unit tests (⌘U)
3. ✅ Test core flows (see `TEST_PLAN.md`)
4. ✅ Verify data persistence (close/reopen app)

## Troubleshooting

### "Cannot find type 'X' in scope"
- **Solution**: File not added to target
- **Fix**: Select file → File Inspector → Target Membership → Nestling ✅

### Core Data model not found
- **Solution**: Ensure `Nestling.xcdatamodeld` is added to Nestling target
- **Fix**: Select model file → File Inspector → Target Membership → Nestling ✅
- **Note**: App will fall back to JSON storage if Core Data unavailable

### Test compilation errors
- **Solution**: Ensure test target links to Nestling
- **Fix**: NestlingTests target → Build Phases → Link Binary With Libraries → Add Nestling framework
- **Alternative**: Use `@testable import Nestling` in test files

### Missing App Groups
- **Solution**: Widgets/extensions require App Groups
- **Fix**: Target → Signing & Capabilities → + Capability → App Groups → `group.com.nestling.Nestling`
- **Note**: Optional for MVP, required for widgets

