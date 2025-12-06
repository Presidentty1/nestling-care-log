# New Features Testing Guide

Quick guide for testing the newly implemented UX improvements and premium features.

## How to Test: Onboarding Improvements

### Setup
1. Delete app and reinstall (or clear all data)
2. Launch app

### Test Flow
1. **Sign up/Sign in**
   - Should go directly to onboarding

2. **Step 1: Baby Setup**
   - ✅ See "Step 1 of 3" (not 4)
   - ✅ Only see: Name + Date of Birth fields
   - ✅ No "Sex" field (moved to Settings)
   - ✅ Enter baby name and DOB
   - ✅ Tap "Continue"

3. **Step 2: Goal Selection**
   - ✅ See 5 goal options
   - ✅ Select one (e.g., "Better naps")
   - ✅ Or tap "Skip for now"
   - ✅ Tap "Continue"

4. **Step 3: Initial State**
   - ✅ Choose "Asleep" or "Awake"
   - ✅ Or tap "Skip for now"
   - ✅ Tap "Continue"

5. **Completion**
   - ✅ Should navigate to Home screen
   - ⏱️ **Measure time:** Should complete in <60 seconds

### Analytics to Verify
- Check for `onboarding_completed` event with `time_to_complete_seconds`
- Check for `onboarding_goal_selected` event

---

## How to Test: First Tasks Checklist

### Setup
1. Complete onboarding (above)
2. Land on Home screen for first time

### Test Flow
1. **See Checklist**
   - ✅ Should see "Get Started" card
   - ✅ Shows "0 of 3 completed"
   - ✅ Three tasks listed:
     - ⬜ Log your first feed
     - ⬜ Log your first sleep
     - ⬜ Explore AI predictions (👑 crown icon)

2. **Complete Task 1**
   - ✅ Tap "Log your first feed"
   - ✅ Opens feed form
   - ✅ Log a feed event
   - ✅ Return to Home
   - ✅ Checklist now shows "1 of 3 completed"
   - ✅ Progress bar updates

3. **Complete Task 2**
   - ✅ Tap "Log your first sleep"
   - ✅ Log a sleep event
   - ✅ Checklist shows "2 of 3 completed"

4. **Complete Task 3**
   - ✅ Tap "Explore AI predictions"
   - ✅ Should navigate to Predictions view (or show Premium prompt)
   - ✅ Checklist shows "3 of 3 completed"
   - ✅ See celebration message: "You're all set!"

5. **Dismiss Checklist**
   - ✅ Tap X button
   - ✅ Checklist disappears
   - ✅ Should not reappear on next app launch

### Analytics to Verify
- `first_tasks_dismissed` event with completion count

---

## How to Test: Celebration Animation

### Setup
1. Fresh user who has never logged an event
2. Log first event (any type)

### Test Flow
1. **Log First Event**
   - ✅ Open any event form (feed/sleep/diaper)
   - ✅ Submit event
   - ✅ Return to Home screen

2. **See Celebration**
   - ✅ Modal appears with confetti animation
   - ✅ Shows event type icon (feed/sleep/diaper)
   - ✅ Shows "🎉 Great job!" message
   - ✅ Shows encouragement text
   - ✅ Haptic feedback fires

3. **Dismiss**
   - ✅ Tap "Continue" button
   - ✅ Modal disappears
   - ✅ Should not appear again (even after logging more events)

---

## How to Test: Home Tutorial Overlay

### Setup
1. Complete onboarding
2. First visit to Home screen (with empty timeline)

### Test Flow
1. **Tutorial Appears**
   - ✅ See dimmed background overlay
   - ✅ See tutorial card with step 1: "Quick Actions"
   - ✅ Shows progress dots (3 dots, first one filled)

2. **Navigate Steps**
   - ✅ Tap "Next" → See step 2: "Your Timeline"
   - ✅ Tap "Next" → See step 3: "AI Predictions" (Premium teaser)
   - ✅ Tap "Get Started" → Tutorial dismisses

3. **Skip Option**
   - ✅ Tap "Skip Tutorial" at any step
   - ✅ Tutorial dismisses immediately

4. **Persistence**
   - ✅ Close app and reopen
   - ✅ Tutorial should NOT appear again

### Analytics to Verify
- `home_tutorial_completed` event
- `home_tutorial_skipped` event (if skipped)

---

## How to Test: Monthly Calendar View

### Setup
1. Have some events logged (across multiple days)
2. Navigate to History tab

### Test Flow
1. **See Calendar**
   - ✅ See full month grid (current month)
   - ✅ See month/year header (e.g., "December 2025")
   - ✅ See weekday labels (Sun, Mon, Tue...)
   - ✅ See "Today" button in top right

2. **Event Indicators**
   - ✅ Days with events show colored dots
   - ✅ Blue dot = Feed events
   - ✅ Purple dot = Sleep events
   - ✅ Green dot = Diaper events
   - ✅ Multiple dots if multiple event types

3. **Navigation**
   - ✅ Tap left arrow → Go to previous month
   - ✅ Tap right arrow → Go to next month (disabled if future)
   - ✅ Tap "Today" → Jump to current date
   - ✅ Tap any date → Load that day's timeline below

4. **Selected Date**
   - ✅ Selected date highlighted with border
   - ✅ Today has special indicator
   - ✅ Timeline below shows events for selected date

---

## How to Test: Calendar Heatmap (Premium)

### Setup
1. **Free User Test:**
   - Use app without Premium subscription
2. **Premium User Test:**
   - Use app with active Premium subscription

### Test Flow (Free User)
1. **See Toggle**
   - ✅ See "Dots" and "Heatmap" toggle buttons
   - ✅ "Heatmap" has crown icon (👑)
   - ✅ "Dots" is selected by default

2. **Attempt Upgrade**
   - ✅ Tap "Heatmap" button
   - ✅ See upgrade sheet appear
   - ✅ Shows: "Calendar Heatmap" feature description
   - ✅ Shows benefits list
   - ✅ Shows "Upgrade to Premium" button
   - ✅ Tap upgrade → Navigate to subscription screen

### Test Flow (Premium User)
1. **Toggle Views**
   - ✅ Tap "Heatmap" button
   - ✅ Calendar switches to heatmap view
   - ✅ See intensity gradient legend ("Less → More")
   - ✅ Days with more events show darker colors
   - ✅ Can still tap dates to see timeline

2. **Switch Back**
   - ✅ Tap "Dots" button
   - ✅ Calendar switches back to dot view

---

## How to Test: PDF Doctor Reports

### Setup
1. Have some events logged
2. Navigate to Settings → Privacy & Data → Export Data

### Test Flow
1. **Select PDF Format**
   - ✅ See format picker: CSV, PDF, JSON
   - ✅ Select "PDF"
   - ✅ See description: "Professional report for pediatrician visits"

2. **Choose Date Range**
   - ✅ Select range (Last Week, Last Month, etc.)

3. **Export**
   - ✅ Tap "Export Data"
   - ✅ See progress indicator
   - ✅ PDF generates
   - ✅ System share sheet appears
   - ✅ Can save to Files, AirDrop, email, etc.

4. **Verify PDF Content**
   - ✅ Open generated PDF
   - ✅ See: Baby name, DOB, age
   - ✅ See: Activity summary (feeds, sleep, diapers)
   - ✅ See: Feeding details (totals, averages)
   - ✅ See: Space for doctor notes
   - ✅ Professional formatting

### Premium Gating (Optional)
- If PDF is Premium-only, free users should see upgrade prompt

---

## Performance Benchmarks

### Expected Performance
- **Onboarding completion:** <60 seconds
- **Calendar load time:** <500ms (month view)
- **PDF generation:** <2 seconds
- **Tutorial animation:** Smooth 60fps

### How to Measure
1. Use Xcode Instruments (Time Profiler)
2. Test on oldest supported device (iPhone 8)
3. Test with large datasets (1000+ events)

---

## Rollback Plan

If any feature causes issues:

1. **Onboarding Issues:**
   - Revert `BabySetupView.swift` to include Sex field
   - Change totalSteps back to 4

2. **Calendar Issues:**
   - Comment out `MonthlyCalendarView` in `HistoryView.swift`
   - Restore old `DatePickerView` component

3. **Tutorial Issues:**
   - Remove `.overlay` from `HomeView.swift`
   - Set `hasSeenHomeTutorial = true` for all users

---

## Known Limitations

### Intentional Scope Limitations
1. **No landing page improvements:** iOS apps don't have landing pages (App Store is the landing page)
2. **Calendar heatmap:** Simple intensity calculation, not advanced ML patterns
3. **Tutorial:** Basic spotlight, not animated masks
4. **Celebration:** Shows once per user, not per event type

### Technical Limitations
1. **Calendar queries:** Not cached (will optimize if performance issues)
2. **PDF generation:** Synchronous on main thread (acceptable for small datasets)
3. **Photo attachments:** Not implemented yet (requires Supabase storage)

---

## Success Criteria Recap

### 30-Day Targets
- [ ] Onboarding completion: 80%
- [ ] First log within 5 min: 60%
- [ ] Day 1 retention: 65%
- [ ] Calendar usage: 60% of users
- [ ] Premium awareness: 80% see upgrade prompt
- [ ] Trial sign-up: 15-18%
- [ ] Paid conversion: 12-15%
- [ ] **MRR: $900-1,200** (3-4x growth)

### Quality Targets
- [ ] Crash-free rate: 99.5%
- [ ] Calendar load: <500ms
- [ ] PDF generation: <2s
- [ ] App Store rating: 4.7+ stars

---

## Contact & Feedback

For questions or issues with these implementations:
- See: `UX_IMPROVEMENTS_SUMMARY.md` for detailed changes
- See: `PRODUCT_REVIEW_IMPLEMENTATION_MAP.md` for plan mapping
- See: Individual Swift files for code documentation

---

*Last Updated: December 6, 2025*
*Implementation Phase: Phase 1-3 Complete*
*Next Phase: Premium Features Sprint (Photos, Growth, Notifications)*

