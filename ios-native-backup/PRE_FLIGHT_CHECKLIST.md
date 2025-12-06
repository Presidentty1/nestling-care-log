# Pre-Flight Checklist

Use this checklist before submitting to App Store.

## Build Configuration

- [ ] Build number incremented
- [ ] Version number updated
- [ ] Signing configured (Development & Distribution)
- [ ] Bundle ID matches App Store Connect
- [ ] Provisioning profiles valid
- [ ] Entitlements configured (App Groups, Push Notifications, etc.)

## Privacy & Compliance

- [ ] Privacy nutrition labels completed in App Store Connect
- [ ] Privacy policy URL added (if required)
- [ ] Support URL added
- [ ] Marketing URL added (optional)
- [ ] Age rating questionnaire completed
- [ ] Medical disclaimers present on all prediction/guidance screens
- [ ] Data export functionality tested

## Assets

- [ ] App Icon (1024x1024) added to Assets.xcassets
- [ ] Launch screen configured
- [ ] Accent color set
- [ ] Screenshots captured for all required sizes:
  - [ ] 6.7" iPhone (iPhone 14 Pro Max)
  - [ ] 6.5" iPhone (iPhone 11 Pro Max)
  - [ ] 5.5" iPhone (iPhone 8 Plus)
- [ ] Screenshots in Light mode
- [ ] Screenshots in Dark mode (optional)
- [ ] Screenshots in Spanish (if localized)

## App Store Connect

- [ ] App description written (4000 char max)
- [ ] Subtitle added (30 char max)
- [ ] Keywords added (100 char max)
- [ ] Promo text added (170 char max)
- [ ] Release notes prepared
- [ ] Category selected
- [ ] Age rating set
- [ ] Pricing configured

## Testing

- [ ] All unit tests pass
- [ ] UI tests pass (if implemented)
- [ ] Manual QA checklist completed
- [ ] TestFlight build tested on physical device
- [ ] Onboarding flow tested
- [ ] Data persistence tested (kill app, relaunch)
- [ ] Deep links tested
- [ ] Notifications tested (if enabled)
- [ ] Export functionality tested

## Performance

- [ ] Launch time < 400ms (release build)
- [ ] No memory leaks (Instruments)
- [ ] Smooth scrolling on large timelines
- [ ] Battery impact acceptable

## Accessibility

- [ ] VoiceOver tested
- [ ] Dynamic Type tested (AX5)
- [ ] High Contrast tested
- [ ] All interactive elements ≥44pt

## Localization

- [ ] English strings complete
- [ ] Spanish strings complete (if localized)
- [ ] Pseudo-localization tested
- [ ] RTL layout tested (if applicable)

## Known Issues

- [ ] Known issues documented in `KNOWN_ISSUES.md`
- [ ] Workarounds provided
- [ ] Timeline for fixes noted

## Final Checks

- [ ] Archive created successfully
- [ ] Archive validated in Xcode
- [ ] Archive uploaded to App Store Connect
- [ ] Build processing completed
- [ ] Build selected for submission
- [ ] Submission notes added (if any)
- [ ] Submit for Review clicked

## Post-Submission

- [ ] Monitor App Store Connect for review status
- [ ] Respond to reviewer questions promptly
- [ ] Test any fixes requested by reviewers
- [ ] Resubmit if needed


