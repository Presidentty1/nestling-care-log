# Manual Testing Protocol - Pre-Launch

## Test Environment Setup
- [ ] iOS Simulator (iPhone 15 Pro)
- [ ] Physical iPhone device (if available)
- [ ] Chrome desktop
- [ ] Safari desktop
- [ ] Clear all data before testing

## Critical Path 1: First-Time User Experience
**Goal:** New user can onboard and log first event in <2 minutes

1. [ ] Open app (fresh install simulation)
2. [ ] Complete onboarding form
3. [ ] Verify lands on Home
4. [ ] Tap "Feed" button
5. [ ] Select "Bottle"
6. [ ] Enter "120" ml
7. [ ] Tap "Save Log"
8. [ ] Verify event appears in timeline
9. [ ] Verify "Since last feed" chip updates

**Expected time:** < 2 minutes
**Pass criteria:** Zero confusion, smooth flow

## Critical Path 2: Timer-Based Logging
**Goal:** Sleep timer works correctly, including backgrounding

1. [ ] Tap "Sleep" button
2. [ ] Tap "Start" timer
3. [ ] Verify timer displays elapsed time
4. [ ] Background app (home button)
5. [ ] Wait 30 seconds
6. [ ] Return to app
7. [ ] Verify timer still running
8. [ ] Tap "Stop"
9. [ ] Verify duration calculated correctly
10. [ ] Tap "Save Log"
11. [ ] Verify event in timeline

**Expected duration shown:** ~30 seconds
**Pass criteria:** Timer survives backgrounding

## Critical Path 3: Offline → Online Sync
**Goal:** Events logged offline sync when connection restored

1. [ ] Enable airplane mode
2. [ ] Verify offline indicator (if present)
3. [ ] Log feed event (4 oz bottle)
4. [ ] Log diaper event (wet)
5. [ ] Log sleep event (45 min manual)
6. [ ] Verify all 3 appear in timeline
7. [ ] Disable airplane mode
8. [ ] Wait 10 seconds
9. [ ] Check for "Synced" indicator
10. [ ] Open Lovable Cloud dashboard
11. [ ] Verify all 3 events in database

**Expected sync time:** < 10 seconds after connection
**Pass criteria:** All events sync successfully

## Critical Path 4: Multi-Caregiver Sync
**Goal:** Events logged on Device A appear on Device B

**Setup:** Need 2 devices with same account

1. Device A: [ ] Log feed event
2. Device B: [ ] Wait 10 seconds
3. Device B: [ ] Pull to refresh (if needed)
4. Device B: [ ] Verify event appears

**Expected sync time:** < 10 seconds
**Pass criteria:** Real-time sync works

## Critical Path 5: Data Export
**Goal:** User can export all data to CSV

1. [ ] Navigate to Settings
2. [ ] Tap "Export Data"
3. [ ] Select CSV format
4. [ ] Download file
5. [ ] Open in Excel/Google Sheets
6. [ ] Verify all events present
7. [ ] Verify columns: date, time, type, amount, notes

**Pass criteria:** CSV opens correctly, data complete

## Critical Path 6: Delete Account
**Goal:** User can delete all data and account

1. [ ] Navigate to Settings → Privacy & Data
2. [ ] Tap "Delete All Data"
3. [ ] Read warning
4. [ ] Confirm deletion
5. [ ] Verify redirected to auth screen
6. [ ] Try to log back in
7. [ ] Verify data is gone

**Pass criteria:** Complete data deletion, no orphaned records

## Accessibility Testing

### Large Text Support (iOS)
1. [ ] Settings → Accessibility → Larger Text → Max
2. [ ] Open app
3. [ ] Navigate all screens
4. [ ] Verify no text truncation
5. [ ] Verify buttons remain tappable (>44pt)

### VoiceOver Testing (iOS)
1. [ ] Enable VoiceOver (triple-click home)
2. [ ] Navigate Home screen
3. [ ] Verify all buttons announced clearly
4. [ ] Open Feed form
5. [ ] Verify all inputs labeled
6. [ ] Submit form
7. [ ] Verify success toast announced

### Keyboard Navigation (Desktop)
1. [ ] Tab through all buttons on Home
2. [ ] Verify focus indicators visible
3. [ ] Open Feed form
4. [ ] Tab through inputs
5. [ ] Press Enter to submit
6. [ ] Press Escape to close
7. [ ] Verify no keyboard traps

## Performance Testing

### Load Time (Cold Start)
1. [ ] Clear cache
2. [ ] Force quit app
3. [ ] Start timer
4. [ ] Open app
5. [ ] Stop timer when interactive

**Target:** < 2 seconds on iPhone 12
**Measured:** _____ seconds

### Scroll Performance (Large Dataset)
**Setup:** Need 100+ events

1. [ ] Navigate to History
2. [ ] Scroll through timeline
3. [ ] Check for jank/stuttering
4. [ ] Monitor frame rate (60fps)

**Pass criteria:** Smooth 60fps scrolling

### Memory Usage
1. [ ] Open app
2. [ ] Log 50 events
3. [ ] Navigate all screens
4. [ ] Check Xcode Instruments → Memory
5. [ ] Verify no leaks
6. [ ] Verify < 150MB usage

**Target:** < 150MB on iPhone 12

## Dark Mode Testing

1. [ ] Enable dark mode (system)
2. [ ] Navigate all screens
3. [ ] Verify contrast (text readable)
4. [ ] Verify no white flashes
5. [ ] Toggle dark mode on/off
6. [ ] Verify app responds immediately

## Error Handling Testing

### Network Errors
1. [ ] Enable airplane mode
2. [ ] Try to use AI features
3. [ ] Verify friendly error message
4. [ ] Verify "Works offline" message

### Form Validation
1. [ ] Open Feed form
2. [ ] Leave all fields empty
3. [ ] Tap Save
4. [ ] Verify validation errors shown
5. [ ] Fill required fields
6. [ ] Verify errors clear

### Edge Function Failures
1. [ ] Navigate to AI Assistant
2. [ ] Ask question
3. [ ] If function fails, verify error message
4. [ ] Verify retry option available

## Sign-Off Checklist

**Critical Paths:**
- [ ] All 6 critical paths pass
- [ ] Zero blocking bugs found
- [ ] All features work as expected

**Accessibility:**
- [ ] Large Text support verified
- [ ] VoiceOver navigation works
- [ ] Keyboard navigation complete

**Performance:**
- [ ] Load time < 2 seconds
- [ ] Scrolling smooth (60fps)
- [ ] Memory usage reasonable

**Polish:**
- [ ] Dark mode looks great
- [ ] Error messages helpful
- [ ] Loading states consistent
- [ ] Empty states friendly

**Final Approval:**
- [ ] Tested by: ___________
- [ ] Date: ___________
- [ ] Ready for App Store: YES / NO
