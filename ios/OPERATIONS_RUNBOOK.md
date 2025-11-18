# Operations Runbook

## Data Reset Procedures

### Reset JSON Storage
1. Delete app from device/simulator
2. Reinstall app
3. JSON storage will be recreated on first launch

### Reset Core Data
1. Delete app from device/simulator
2. Reinstall app
3. Core Data store will be recreated

### Reset Onboarding
1. Open app
2. Navigate to Settings → Debug → Reset Onboarding
3. App will show onboarding on next launch

### Clear All Data
1. Open app
2. Navigate to Settings → Privacy & Data → Delete All Data
3. Type "DELETE" to confirm
4. All data will be cleared and reseeded with defaults

## Data Migration

### JSON → Core Data
1. Open app
2. Navigate to Settings → Privacy & Data → Data Migration (Debug only)
3. Tap "Import from JSON"
4. Wait for migration to complete
5. Verify data appears in app

### Core Data → JSON Export
1. Open app
2. Navigate to Settings → Privacy & Data → Export & Delete Data
3. Tap "Export JSON"
4. Share or save the JSON file

## Debugging

### View Logs
- Use Console.app or Xcode console
- Filter by subsystem: `com.nestling.app`
- Categories: DataStore, Predictions, UI, Performance

### Performance Profiling
- Use Instruments → Time Profiler
- Look for signposts in Instruments → Signposts
- Check for main thread blocking

### Widget Debugging
- Add widget to home screen
- Check timeline provider logs
- Verify App Groups shared storage

### Notification Debugging
- Check notification permission status in Settings
- Use "Send Test Notification" in Notification Settings
- Verify quiet hours logic

## Common Issues

### App Won't Launch
- Check Core Data migration errors
- Verify App Groups entitlement
- Check Info.plist configuration

### Widgets Not Updating
- Verify App Groups shared storage
- Check timeline reload policy
- Ensure widget extension is running

### Notifications Not Working
- Verify notification permission granted
- Check quiet hours settings
- Ensure notification scheduler is running

### Data Not Persisting
- Check Core Data store location
- Verify App Groups container
- Check file permissions

## Feature Flags

- `USE_CORE_DATA`: Use Core Data instead of JSON (default: true)
- `ENABLE_CRY_INSIGHTS`: Enable Cry Insights feature (default: true)
- `ENABLE_WIDGETS`: Enable Widgets extension (default: true)
- `ENABLE_LIVE_ACTIVITIES`: Enable Live Activities (default: true)
- `ENABLE_APP_INTENTS`: Enable App Intents (default: true)

## Backup & Restore

### Create Backup
1. Navigate to Settings → Privacy & Data
2. Tap "Create Backup"
3. Share or save the ZIP file

### Restore Backup
1. Navigate to Settings → Privacy & Data
2. Tap "Restore Backup"
3. Select backup file (ZIP or JSON)
4. Wait for restore to complete

## Testing

### Run Unit Tests
```bash
xcodebuild test -scheme Nestling -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Run UI Tests
```bash
xcodebuild test -scheme NestlingUITests -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Manual QA Checklist
See `TEST_PLAN.md` for detailed manual testing steps.


