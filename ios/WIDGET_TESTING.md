# Widget Testing Guide

This guide explains how to test widgets on physical iOS devices and simulators.

## Prerequisites

- Xcode 15+
- iOS 17+ device (for lock screen widgets and Dynamic Island)
- Valid Apple Developer account (for device testing)
- App Groups configured (see setup below)

## App Groups Setup

Widgets require App Groups to share data between the app and widget extension.

### Step 1: Configure App Groups in Xcode

1. Select the **Nestling** app target
2. Go to **Signing & Capabilities**
3. Click **+ Capability**
4. Add **App Groups**
5. Create group: `group.com.nestling.app`
6. Repeat for **NestlingWidgets** target (same group ID)

### Step 2: Update DataStore to Use App Groups

The `JSONBackedDataStore` should save data to the App Groups container:

```swift
private var appGroupURL: URL? {
    FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.nestling.app")
}

private var dataFileURL: URL {
    appGroupURL?.appendingPathComponent(AppConstants.dataStoreFileName)
        ?? documentsURL.appendingPathComponent(AppConstants.dataStoreFileName)
}
```

## Testing on Simulator

### Basic Widget Testing

1. **Build and Run**:

   ```bash
   xcodebuild -scheme Nestling -destination 'platform=iOS Simulator,name=iPhone 15' build
   ```

2. **Add Widget to Home Screen**:
   - Long-press home screen
   - Tap "+" button
   - Search for "Nestling"
   - Select widget size
   - Tap "Add Widget"

3. **Verify Widget Displays Data**:
   - Widget should show current baby's data
   - Next feed/nap times should be accurate
   - Summary should match app data

### Testing Widget Updates

1. **Log an Event** in the app
2. **Reload Widget Timeline**:

   ```swift
   WidgetCenter.shared.reloadAllTimelines()
   ```

   Or use Developer Settings → "Reload All Widgets"

3. **Verify Widget Updates**:
   - Widget should reflect new event
   - Summary counts should update

## Testing on Physical Device

### Lock Screen Widgets

1. **Build and Install** on device
2. **Add Lock Screen Widget**:
   - Long-press lock screen
   - Tap "Customize"
   - Tap lock screen area
   - Tap "+" to add widget
   - Select Nestling widget

3. **Test Widget Actions**:
   - Tap widget button (if interactive)
   - Verify action executes in app
   - Check widget updates after action

### Dynamic Island (iPhone 14 Pro+)

1. **Start Sleep Timer** in app
2. **Verify Dynamic Island**:
   - Should show compact view
   - Tap to expand
   - Should show stop button
   - Tap stop to end sleep

3. **Test Fallback**:
   - On devices without Dynamic Island
   - Should show Live Activity instead

## Widget Test Helper

Use `WidgetTestHelper` for programmatic testing:

```swift
// Reload all widgets
WidgetTestHelper.reloadAllWidgets()

// Generate test data
let testData = WidgetTestHelper.generateTestData()

// Test data persistence
WidgetTestHelper.testDataPersistence(data: testData)

// Verify App Groups
let verified = WidgetTestHelper.verifyAppGroups()
```

## Common Issues

### Widget Shows "No Data"

**Cause**: App Groups not configured or data not shared

**Fix**:

1. Verify App Groups capability added to both targets
2. Check group ID matches: `group.com.nestling.app`
3. Verify DataStore saves to App Groups container
4. Reload widget timeline

### Widget Doesn't Update

**Cause**: Timeline not reloaded after data change

**Fix**:

1. Call `WidgetCenter.shared.reloadAllTimelines()` after data changes
2. Check widget refresh policy (`.atEnd` vs `.after`)
3. Verify widget entry provider fetches latest data

### Interactive Widget Actions Don't Work

**Cause**: App Intents not configured or not handling actions

**Fix**:

1. Verify App Intents target added to project
2. Check intent handlers registered
3. Test intent in Shortcuts app first
4. Verify App Groups shared between app and intents

## Testing Checklist

### Home Screen Widgets

- [ ] Widget displays correct data
- [ ] Widget updates when data changes
- [ ] Widget handles empty states
- [ ] Widget handles errors gracefully
- [ ] Widget matches app design
- [ ] Widget supports dark mode

### Lock Screen Widgets

- [ ] Circular widget displays correctly
- [ ] Inline widget displays correctly
- [ ] Widget updates in background
- [ ] Widget actions work (if interactive)

### Dynamic Island / Live Activity

- [ ] Compact view displays
- [ ] Expanded view displays
- [ ] Stop button works
- [ ] Updates in real-time
- [ ] Fallback UI works on older devices

### Performance

- [ ] Widget loads quickly (< 1 second)
- [ ] No memory leaks
- [ ] Efficient data fetching
- [ ] Background updates work

## Automated Testing

### Unit Tests

```swift
func testWidgetDataGeneration() {
    let testData = WidgetTestHelper.generateTestData()
    XCTAssertNotNil(testData["baby"])
    XCTAssertNotNil(testData["events_today"])
}

func testAppGroupsVerification() {
    let verified = WidgetTestHelper.verifyAppGroups()
    XCTAssertTrue(verified, "App Groups must be configured")
}
```

### UI Tests

```swift
func testWidgetDisplays() {
    let app = XCUIApplication()
    app.launch()

    // Add widget (manual step)
    // Verify widget content
    // This requires manual interaction or screenshot comparison
}
```

## Debugging

### Enable Widget Debugging

1. In Xcode, go to **Product → Scheme → Edit Scheme**
2. Select **Run** → **Arguments**
3. Add environment variable: `WIDGET_DEBUG=1`

### View Widget Logs

Widget logs appear in Xcode console when:

- Widget is added to home screen
- Widget timeline reloads
- Widget entry provider runs

### Test Widget Entry Provider

```swift
// In widget entry provider
let entry = try await getTimelineEntry(for: context)
print("[Widget] Entry: \(entry)")
```

## Resources

- [WidgetKit Documentation](https://developer.apple.com/documentation/widgetkit)
- [App Intents Documentation](https://developer.apple.com/documentation/appintents)
- [Live Activities Documentation](https://developer.apple.com/documentation/activitykit)
- [App Groups Documentation](https://developer.apple.com/documentation/xcode/configuring-app-groups)
