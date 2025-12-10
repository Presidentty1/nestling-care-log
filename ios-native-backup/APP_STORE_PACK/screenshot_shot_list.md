# Screenshot Shot List

## Required Screenshots

### iPhone 6.7" Display (iPhone 14 Pro Max, 15 Pro Max)

- **Home Screen**: Today dashboard with summary cards, quick actions, timeline
- **History Screen**: Date picker with timeline of events
- **Predictions Screen**: AI predictions with medical disclaimer
- **Settings Screen**: Settings list with all sections visible

### iPhone 6.5" Display (iPhone 11 Pro Max, XS Max)

- Same as 6.7" (can reuse with scaling)

### iPhone 5.5" Display (iPhone 8 Plus)

- Same as above (can reuse with scaling)

## Screenshot Scenarios

### Scenario 1: New User (Onboarding)

1. Welcome screen
2. Baby setup screen
3. Preferences screen

### Scenario 2: Active User (Demo Scenario)

1. Home with multiple events logged today
2. History with events across multiple days
3. Predictions with next feed/nap shown

### Scenario 3: Settings & Features

1. Settings root view
2. AI Data Sharing settings
3. Privacy & Data export options

## How to Capture

### Using XCUITest

Run screenshot tests in `ios/NestlingUITests/`:

- Tests automatically capture screenshots at key points
- Screenshots saved to test results directory

### Manual Capture

1. Open app in simulator
2. Load appropriate scenario (Settings → Debug → Load Scenario)
3. Navigate to target screen
4. Cmd+S to save screenshot
5. Crop to required dimensions

## Screenshot Requirements

- **Format**: PNG
- **Dimensions**: See Apple's current requirements
- **Content**: No personal information visible
- **Language**: English (primary), Spanish (if localized)
- **Theme**: Light mode (primary), Dark mode (optional)

## Screenshot Checklist

- [ ] Home screen (Light)
- [ ] Home screen (Dark)
- [ ] History screen (Light)
- [ ] Predictions screen (Light)
- [ ] Settings screen (Light)
- [ ] Onboarding flow (Light)
- [ ] Spanish screenshots (if localized)
