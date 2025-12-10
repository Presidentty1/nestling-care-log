# iOS MVP Test Plan

## Manual QA Checklist

Run these tests in the iOS Simulator after building the project in Xcode.

---

## Setup & First Launch

### Test 1: First Launch & Onboarding

1. **Delete app** from simulator (if installed)
2. **Launch app** (⌘R)
3. **Expected**: Onboarding flow appears
4. **Steps**:
   - Tap through Welcome screen
   - Enter baby name: "Test Baby"
   - Select date of birth (any date)
   - Select sex (optional)
   - Select feeding style (optional)
   - Choose units (ml or oz)
   - Choose time format (12h or 24h)
   - Toggle AI Data Sharing (try both on/off)
   - Skip or enable notifications
5. **Expected**: App navigates to Home screen with demo baby

### Test 2: Data Persistence

1. **Log a feed**: Quick action → Feed → Save
2. **Force quit app**: Swipe up in app switcher
3. **Relaunch app**
4. **Expected**: Feed event still appears in timeline

---

## Home Dashboard

### Test 3: Summary Cards

1. **Log multiple events**:
   - 2 feeds
   - 3 diapers
   - 1 sleep session
   - 1 tummy time
2. **Expected**: Summary cards show correct counts
   - Feeds: 2
   - Diapers: 3
   - Sleep: 1
   - Tummy Time: 1

### Test 4: Quick Actions

1. **Tap Feed quick action**
   - **Expected**: Feed logged immediately with defaults (120ml)
   - **Verify**: Appears in timeline
2. **Long-press Feed quick action**
   - **Expected**: Feed form opens
3. **Tap Sleep quick action** (when no active sleep)
   - **Expected**: Sleep starts, button shows "Stop"
4. **Tap Sleep quick action** (when active sleep)
   - **Expected**: Sleep stops, event saved

### Test 5: Timeline

1. **Scroll timeline**
   - **Expected**: Events appear in chronological order (newest first)
2. **Swipe right on event**
   - **Expected**: Edit and Delete buttons appear
3. **Tap Edit**
   - **Expected**: Form opens with prefilled values
4. **Tap Delete**
   - **Expected**: Confirmation dialog appears
   - **Tap Delete in dialog**
   - **Expected**: Event removed, undo toast appears
5. **Tap Undo in toast** (within 7 seconds)
   - **Expected**: Event restored

### Test 6: Search & Filters

1. **Pull down** on Home screen
   - **Expected**: Search bar appears
2. **Type "feed"**
   - **Expected**: Only feed events shown
3. **Tap "Feeds" filter chip**
   - **Expected**: Only feed events shown
4. **Clear search and filter**
   - **Expected**: All events shown

---

## Event Forms

### Test 7: Feed Form

1. **Open Feed form** (long-press Feed quick action)
2. **Fill form**:
   - Type: Bottle
   - Amount: 150
   - Unit: ml
   - Notes: "Test feed"
3. **Tap Save**
   - **Expected**: Success toast, form dismisses, event appears in timeline
4. **Edit event**: Tap event → Edit
   - **Expected**: Form opens with prefilled values
5. **Change amount to 180**
6. **Tap Save**
   - **Expected**: Event updated in timeline

### Test 8: Sleep Form - Timer Mode

1. **Open Sleep form**
2. **Verify**: Timer mode selected by default
3. **Tap Start Timer**
   - **Expected**: Timer starts counting, Stop button appears
4. **Wait 5 seconds**
5. **Tap Stop**
   - **Expected**: Duration calculated, Save button enabled
6. **Tap Save**
   - **Expected**: Sleep event saved with correct duration

### Test 9: Sleep Form - Manual Mode

1. **Open Sleep form**
2. **Switch to Manual mode**
3. **Set start time**: 2 hours ago
4. **Set end time**: 1 hour ago
5. **Tap Save**
   - **Expected**: Sleep event saved with 1-hour duration

### Test 10: Diaper Form

1. **Open Diaper form**
2. **Select**: Wet
3. **Add note**: "Changed"
4. **Tap Save**
   - **Expected**: Diaper event saved

### Test 11: Tummy Time Form - Timer

1. **Open Tummy Time form**
2. **Verify**: Timer mode selected
3. **Tap Start Timer**
4. **Wait 3 seconds**
5. **Tap Stop**
6. **Tap Save**
   - **Expected**: Tummy time saved with ~3 minute duration

### Test 12: Form Validation

1. **Open Feed form**
2. **Set amount to 5** (below minimum)
3. **Tap Save**
   - **Expected**: Error message, save disabled
4. **Set amount to 50**
5. **Tap Save**
   - **Expected**: Saves successfully

---

## History View

### Test 13: Date Navigation

1. **Navigate to History tab**
2. **Tap date picker**
3. **Select yesterday**
   - **Expected**: Timeline shows yesterday's events
4. **Select today**
   - **Expected**: Timeline shows today's events

### Test 14: History Timeline

1. **Log events on different days**:
   - Today: 2 feeds
   - Yesterday: 1 diaper
2. **Navigate to History**
3. **Select yesterday**
   - **Expected**: Shows 1 diaper event
4. **Select today**
   - **Expected**: Shows 2 feed events

### Test 15: Edit from History

1. **Navigate to History**
2. **Select a day with events**
3. **Tap event → Edit**
   - **Expected**: Form opens with prefilled values
4. **Make change and save**
   - **Expected**: Event updated, History refreshes

---

## Predictions

### Test 16: Predictions Gating

1. **Navigate to Labs tab**
2. **Tap Smart Predictions**
3. **If AI disabled**:
   - **Expected**: "Enable AI" message shown
4. **Navigate to Settings → AI Data Sharing**
5. **Enable AI Data Sharing**
6. **Return to Predictions**
   - **Expected**: Generate buttons enabled

### Test 17: Generate Predictions

1. **Ensure AI enabled** (Settings → AI Data Sharing)
2. **Navigate to Predictions**
3. **Tap "Generate Next Nap"**
   - **Expected**: Loading state, then prediction appears
4. **Verify**: Prediction shows time, confidence, explanation
5. **Tap "Recalculate"**
   - **Expected**: New prediction generated

---

## Settings

### Test 18: Units Toggle

1. **Navigate to Settings**
2. **Find Units setting**
3. **Toggle between ml and oz**
4. **Navigate to Feed form**
   - **Expected**: Unit picker shows selected unit
5. **Return to Settings**
   - **Expected**: Unit preference persisted

### Test 19: AI Data Sharing Toggle

1. **Navigate to Settings → AI Data Sharing**
2. **Toggle off**
   - **Expected**: Predictions view shows "Enable AI" message
3. **Toggle on**
   - **Expected**: Predictions view enables generate buttons

### Test 20: Notification Settings

1. **Navigate to Settings → Notification Settings**
2. **Toggle Feed Reminder on**
3. **Set hours to 3**
4. **Tap Request Permission** (if not granted)
   - **Expected**: System permission dialog appears
5. **Tap Test Notification**
   - **Expected**: Notification appears (if permission granted)

### Test 21: Privacy & Data - Export

1. **Navigate to Settings → Privacy & Data**
2. **Tap Export CSV**
   - **Expected**: CSV file generated, share sheet opens
3. **Save to Files**
   - **Expected**: File saved successfully
4. **Open file** (in Files app)
   - **Expected**: CSV contains event data

### Test 22: Privacy & Data - Delete All

1. **Navigate to Settings → Privacy & Data**
2. **Scroll to Delete All Data**
3. **Tap Delete All**
   - **Expected**: Confirmation dialog appears
4. **Type "DELETE"**
5. **Tap Confirm**
   - **Expected**: All data deleted, app reseeds mock data

### Test 23: Manage Babies

1. **Navigate to Settings → Manage Babies**
2. **Tap Add Baby**
3. **Fill form**:
   - Name: "Baby 2"
   - Date of birth: Any date
4. **Tap Save**
   - **Expected**: Baby added to list
5. **Return to Home**
   - **Expected**: Baby selector shows both babies
6. **Select "Baby 2"**
   - **Expected**: Timeline updates for new baby

---

## Edge Cases

### Test 24: No Events Today

1. **Delete all today's events**
2. **Navigate to Home**
   - **Expected**: Empty state message appears
   - **Expected**: Summary cards show zeros

### Test 25: Multiple Babies

1. **Add second baby** (Settings → Manage Babies)
2. **Log events for Baby 1**
3. **Switch to Baby 2** (baby selector)
   - **Expected**: Timeline shows Baby 2's events (empty if none)
4. **Log event for Baby 2**
   - **Expected**: Event appears in Baby 2's timeline
5. **Switch back to Baby 1**
   - **Expected**: Baby 1's events still present

### Test 26: App Kill During Active Sleep

1. **Start sleep timer**
2. **Force quit app** (swipe up in app switcher)
3. **Relaunch app**
   - **Expected**: Active sleep state restored
   - **Expected**: Timer continues from where it left off

### Test 27: Form Double-Submission Prevention

1. **Open Feed form**
2. **Fill form**
3. **Tap Save rapidly 3 times**
   - **Expected**: Only one event created
   - **Expected**: Save button disabled while saving

### Test 28: Undo Window Expiry

1. **Delete an event**
2. **Wait 8 seconds** (past undo window)
3. **Expected**: Undo toast disappears
4. **Event cannot be undone**

---

## Accessibility

### Test 29: VoiceOver

1. **Enable VoiceOver** (Settings → Accessibility → VoiceOver)
2. **Navigate Home screen**
3. **Swipe through elements**
   - **Expected**: All buttons and labels read correctly
4. **Double-tap Feed quick action**
   - **Expected**: Feed logged
5. **Navigate to Feed form**
   - **Expected**: Form fields accessible
   - **Expected**: Labels and hints read correctly

### Test 30: Dynamic Type

1. **Settings → Accessibility → Display & Text Size → Larger Text**
2. **Set to largest size**
3. **Navigate Home screen**
   - **Expected**: Text scales without clipping
   - **Expected**: Layout remains usable

### Test 31: Dark Mode

1. **Settings → Display & Brightness → Dark**
2. **Navigate app**
   - **Expected**: All screens render correctly
   - **Expected**: Contrast is acceptable
   - **Expected**: Colors are readable

---

## Performance

### Test 32: Launch Time

1. **Force quit app**
2. **Launch app** (⌘R)
3. **Measure time** to Home screen visible
   - **Target**: < 400ms
   - **Expected**: App feels snappy

### Test 33: Timeline Scrolling

1. **Log 50+ events** (use quick actions)
2. **Navigate to Home**
3. **Scroll timeline rapidly**
   - **Expected**: Smooth scrolling (60 FPS)
   - **Expected**: No lag or stuttering

---

## Known Issues

See `ios/KNOWN_ISSUES.md` for current limitations and edge cases.

---

## Test Results Template

```
Test Date: __________
Tester: __________
Device/Simulator: __________
iOS Version: __________

[ ] Test 1: First Launch & Onboarding
[ ] Test 2: Data Persistence
[ ] Test 3: Summary Cards
[ ] Test 4: Quick Actions
[ ] Test 5: Timeline
[ ] Test 6: Search & Filters
[ ] Test 7: Feed Form
[ ] Test 8: Sleep Form - Timer
[ ] Test 9: Sleep Form - Manual
[ ] Test 10: Diaper Form
[ ] Test 11: Tummy Time Form
[ ] Test 12: Form Validation
[ ] Test 13: Date Navigation
[ ] Test 14: History Timeline
[ ] Test 15: Edit from History
[ ] Test 16: Predictions Gating
[ ] Test 17: Generate Predictions
[ ] Test 18: Units Toggle
[ ] Test 19: AI Data Sharing Toggle
[ ] Test 20: Notification Settings
[ ] Test 21: Privacy & Data - Export
[ ] Test 22: Privacy & Data - Delete All
[ ] Test 23: Manage Babies
[ ] Test 24: No Events Today
[ ] Test 25: Multiple Babies
[ ] Test 26: App Kill During Active Sleep
[ ] Test 27: Form Double-Submission Prevention
[ ] Test 28: Undo Window Expiry
[ ] Test 29: VoiceOver
[ ] Test 30: Dynamic Type
[ ] Test 31: Dark Mode
[ ] Test 32: Launch Time
[ ] Test 33: Timeline Scrolling

Issues Found:
-

Notes:
-
```
