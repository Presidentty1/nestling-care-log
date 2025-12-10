# 🧪 MVP Testing Guide

This guide outlines how to manually test all MVP features before launch.

## Pre-Test Setup

1. Clear browser cache and local storage
2. Test in both light and dark mode
3. Test with various screen sizes (mobile, tablet, desktop)
4. Use iOS Safari for primary testing (target platform)

## Phase 5: Manual Testing Protocol

### 1. Authentication Flow

- [ ] Sign up with email
- [ ] Verify email confirmation (auto-confirm enabled)
- [ ] Sign in with existing account
- [ ] Sign out
- [ ] Password reset (if implemented)

### 2. Onboarding

- [ ] Complete onboarding with valid baby data
- [ ] Verify timezone auto-detection works
- [ ] Try submitting with empty name (should show validation)
- [ ] Try future date of birth (should show error)
- [ ] Successfully create baby profile

### 3. Core Logging (≤2 taps)

**Feed:**

- [ ] Quick log bottle feed with amount
- [ ] Start/stop breast feed timer
- [ ] Switch breast sides correctly
- [ ] Log pump session
- [ ] Verify all feeds appear in timeline

**Sleep:**

- [ ] Start sleep timer
- [ ] Stop sleep timer
- [ ] Verify duration calculated correctly
- [ ] Manually add past sleep session
- [ ] Check sleep shows in timeline with duration

**Diaper:**

- [ ] One-tap wet diaper
- [ ] One-tap dirty diaper
- [ ] One-tap both
- [ ] Add optional note
- [ ] Verify all appear in timeline

### 4. Timeline & History

- [ ] View today's events on home
- [ ] Edit an event
- [ ] Delete an event
- [ ] Swipe to delete works
- [ ] Navigate to history page
- [ ] Filter by date
- [ ] View past days
- [ ] Verify empty states show for days with no logs

### 5. AI Features

**Nap Predictor:**

- [ ] View nap prediction on home
- [ ] Verify prediction updates after logging sleep
- [ ] Check prediction reason makes sense
- [ ] Test feedback buttons (accurate/not accurate)

**Cry Analysis:**

- [ ] Navigate to Cry Insights
- [ ] Grant microphone permission
- [ ] Record 10-15 seconds of audio
- [ ] Verify analysis result displays
- [ ] Check interpretation is reasonable
- [ ] Verify works offline (shows friendly error)

**AI Assistant:**

- [ ] Open AI Assistant
- [ ] Ask a question about baby care
- [ ] Verify response is helpful
- [ ] Check medical disclaimer is visible
- [ ] Try quick questions
- [ ] Verify conversation history persists

### 6. Offline Mode

- [ ] Enable airplane mode
- [ ] Log feed event
- [ ] Log sleep event
- [ ] Log diaper event
- [ ] Verify "offline" indicator shows
- [ ] Disable airplane mode
- [ ] Wait for sync
- [ ] Verify all offline events synced to backend
- [ ] Check sync indicator shows "Synced just now"

### 7. Multi-Caregiver (if applicable)

- [ ] Invite second caregiver
- [ ] Accept invite on second device/account
- [ ] Log event on device 1
- [ ] Verify event appears on device 2 within 10s
- [ ] Test simultaneous editing (conflict resolution)

### 8. Data Management

- [ ] Export data to CSV
- [ ] Open CSV in spreadsheet app
- [ ] Verify all events exported correctly
- [ ] Test delete all data
- [ ] Confirm deletion warning shows
- [ ] Verify all data deleted

### 9. Settings & Preferences

- [ ] Toggle caregiver mode
- [ ] Verify text/buttons scale correctly
- [ ] Toggle dark mode
- [ ] Verify all screens readable
- [ ] Update notification settings
- [ ] Test notification permissions

### 10. Accessibility

**Screen Reader:**

- [ ] Enable VoiceOver (iOS) or TalkBack (Android)
- [ ] Navigate home screen with screen reader
- [ ] Log an event using only screen reader
- [ ] Verify all buttons have clear labels
- [ ] Check form inputs are properly labeled

**Keyboard Navigation:**

- [ ] Tab through home screen
- [ ] Tab through forms
- [ ] Press Enter to submit form
- [ ] Press Escape to close modals
- [ ] Verify focus indicators visible

**Color Contrast:**

- [ ] Run axe DevTools audit
- [ ] Check no contrast issues in light mode
- [ ] Check no contrast issues in dark mode

**Dynamic Type:**

- [ ] Enable iOS Large Text (Settings → Accessibility → Display & Text Size → Larger Text)
- [ ] Drag slider to max size
- [ ] Open app
- [ ] Verify all text scales properly
- [ ] Check no text truncation
- [ ] Verify buttons still ≥44pt

### 11. Performance

**Load Times:**

- [ ] Measure time from app open to interactive (should be <2s)
- [ ] Navigate between pages (should feel instant)
- [ ] Scroll timeline with 50+ events (should be 60fps)

**Lighthouse Audit:**

```bash
# Run production build
npm run build
npm run preview

# Open Chrome DevTools
# Run Lighthouse audit
# Target scores:
# Performance: >90
# Accessibility: >95
# Best Practices: >95
# SEO: >90
```

### 12. Error Handling

**Network Errors:**

- [ ] Disable network mid-action
- [ ] Verify friendly error message shows
- [ ] Re-enable network
- [ ] Verify retry works

**Edge Function Errors:**

- [ ] Test AI features without backend
- [ ] Verify graceful fallback UI
- [ ] Check error messages are user-friendly

**Form Validation:**

- [ ] Try submitting empty forms
- [ ] Try invalid data (negative amounts, etc.)
- [ ] Verify validation messages clear

### 13. Edge Cases

- [ ] Log event at midnight (date handling)
- [ ] Log event with very long note (truncation)
- [ ] Create baby with special characters in name
- [ ] Test with very old baby (2+ years)
- [ ] Test with newborn (0-7 days)
- [ ] Fill timeline with 100+ events (performance)

### 14. Production Build Test

```bash
# Clean install
rm -rf node_modules package-lock.json
npm install

# Build
npm run build

# Test production build
npm run preview

# Open http://localhost:4173
# Test all core features again
# Check console for errors
```

### 15. Browser Compatibility

**Desktop:**

- [ ] Chrome (latest)
- [ ] Safari (latest)
- [ ] Firefox (latest)

**Mobile:**

- [ ] Safari iOS (primary target)
- [ ] Chrome iOS
- [ ] Chrome Android (secondary)

## Success Criteria

All tests must pass with:

- ✅ No console errors in production
- ✅ No broken features
- ✅ Accessible with screen reader
- ✅ Works offline
- ✅ Fast load times (<2s)
- ✅ Smooth animations (60fps)
- ✅ Friendly error messages
- ✅ Data syncs correctly

## Bug Reporting Template

If you find a bug during testing:

```markdown
**Bug**: [Brief description]
**Severity**: Critical | High | Medium | Low
**Steps to Reproduce**:

1. [Step 1]
2. [Step 2]
3. [Step 3]

**Expected**: [What should happen]
**Actual**: [What actually happened]
**Screenshot**: [If applicable]
**Browser**: [Browser and version]
**Device**: [Device and OS]
```

## Post-Testing Checklist

Before marking MVP as "production ready":

- [ ] All critical bugs fixed
- [ ] All high-priority bugs fixed or documented
- [ ] Performance targets met
- [ ] Accessibility audit passed
- [ ] Privacy policy published
- [ ] Medical disclaimer visible
- [ ] App icons and screenshots ready
- [ ] App Store metadata prepared
- [ ] Error monitoring configured
- [ ] Analytics configured (optional)
- [ ] Backup strategy in place
- [ ] Support email set up
- [ ] Documentation updated

## Estimated Testing Time

- Initial pass: 2-3 hours
- Bug fixes and re-testing: 1-2 hours
- Final verification: 30 minutes
- **Total: 4-6 hours**

## Notes

- Test on real iOS device whenever possible (simulators don't fully test haptics, notifications, etc.)
- Document any flaky behavior even if not reproducible
- Pay special attention to 3am usability (tired parent test!)
- Get feedback from actual parents if possible
