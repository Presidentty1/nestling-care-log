# UX/UI Audit Checklist - "The Sleep-Deprived Parent" Persona

This checklist ensures Nestling is optimized for exhausted parents using the app at 3 AM.

## Dark Mode Verification

- [ ] **No Blinding White Flashes**
  - Test app launch in dark mode - no white flash
  - Test all navigation transitions in dark mode
  - Test form modals in dark mode
  - Verify all backgrounds use `.background` color token

- [ ] **Contrast Ratios**
  - Test all text in dark mode (WCAG AA minimum)
  - Verify event colors are visible in dark mode
  - Test buttons have sufficient contrast
  - Verify icons are visible

- [ ] **Dark Mode Toggle**
  - Test system dark mode toggle while app is open
  - App should respect system preference
  - No layout breaks when switching

## One-Handed Usability

- [ ] **Primary Actions Reachable**
  - Quick action buttons (Feed, Sleep, Diaper, Tummy) within thumb reach
  - "Add Event" button accessible one-handed
  - Timer start/stop buttons reachable
  - Navigation tabs reachable from bottom

- [ ] **Button Sizes**
  - Minimum touch target: 44x44pt (Apple HIG)
  - Quick action buttons meet minimum size
  - Form submit buttons meet minimum size
  - Delete/confirm buttons meet minimum size

- [ ] **Bottom Sheet Accessibility**
  - Forms open from bottom (easy thumb reach)
  - Can dismiss by dragging down
  - Can dismiss by tapping outside (if appropriate)

## Legibility & Accessibility

- [ ] **Dynamic Type Support**
  - Test with largest text size (Accessibility)
  - All labels respect text size preference
  - Forms don't overflow at large sizes
  - Timers remain readable at large sizes

- [ ] **VoiceOver Labels**
  - All buttons have meaningful labels
  - Event cards have descriptive labels
  - Forms have proper accessibility labels
  - Navigation has clear announcements

- [ ] **Contrast in All Conditions**
  - Test with Reduce Transparency enabled
  - Test with Increase Contrast enabled
  - Test with Color Filters (colorblind mode)
  - Verify event type colors are distinguishable

## Error Recovery

- [ ] **Network Errors**
  - Show clear "Retry" button on sync failures
  - Offline mode message is clear
  - "Check Connection" button visible
  - No crash on network timeout

- [ ] **Data Errors**
  - Validation errors show inline in forms
  - Delete confirmations have undo
  - Import errors show what went wrong
  - Migration errors don't panic user

- [ ] **Loading States**
  - Loading indicators visible during operations
  - Skeleton loaders for content
  - Progress indicators for long operations (migration)
  - No infinite spinners (timeout after 5s)

## Empty States

- [ ] **Helpful Illustrations**
  - Empty history shows encouraging message
  - Empty baby list shows "Add Baby" prominently
  - No events message is friendly, not scary
  - Empty search shows suggestions

- [ ] **Action-Oriented**
  - Empty states have clear call-to-action buttons
  - "Add Baby" button in empty state
  - "Log First Event" guidance
  - Helpful tips in empty states

## Animations & Feedback

- [ ] **Haptic Feedback**
  - Primary actions have haptics (quick actions)
  - Form submissions have success haptic
  - Errors have error haptic
  - Swipe actions have light haptics

- [ ] **Visual Feedback**
  - Button press states visible
  - Loading states clear
  - Success/error messages obvious
  - Timer countdown smooth

- [ ] **Animation Performance**
  - No stuttering during navigation
  - Smooth transitions between tabs
  - Fast form animations
  - No lag when scrolling timeline

## 3 AM Usability Test

Run this test when you're tired:

1. [ ] Launch app in dark room
2. [ ] Log a feed one-handed (right hand)
3. [ ] Start sleep timer one-handed (left hand)
4. [ ] Stop sleep timer half-asleep
5. [ ] Find last diaper change without thinking
6. [ ] Log diaper change in under 5 seconds

All should work without reading or thinking.

## Keyboard Handling

- [ ] **Dismiss on Drag**
  - Keyboard dismisses when scrolling forms
  - Keyboard dismisses when tapping outside
  - Keyboard doesn't cover important content
  - Input focus is clear

- [ ] **Smart Keyboard**
  - Numeric keyboard for amounts
  - Email keyboard for email fields
  - Appropriate keyboards for each field
  - Return key advances to next field

## Accessibility Features

- [ ] **Reduce Motion**
  - Animations respect Reduce Motion setting
  - Transitions are subtle when enabled
  - No parallax effects when enabled

- [ ] **Voice Control**
  - Test with Voice Control enabled
  - All buttons can be activated by voice
  - Navigation works with voice

## Testing Checklist

- [ ] Test on iPhone SE (smallest screen)
- [ ] Test on iPhone Pro Max (largest screen)
- [ ] Test on iPad (if supported)
- [ ] Test in landscape orientation
- [ ] Test with smallest and largest text sizes
- [ ] Test with VoiceOver enabled
- [ ] Test with Reduce Motion enabled
- [ ] Test with Increase Contrast enabled

## Priority Fixes

If time is limited, prioritize:

1. **P0**: One-handed reachability of quick actions
2. **P0**: Dark mode with no white flashes
3. **P1**: Clear error messages with retry buttons
4. **P1**: Empty states with helpful CTAs
5. **P2**: Animation smoothness
6. **P2**: Keyboard handling
