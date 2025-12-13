# TestFlight Beta Testing Guide

## Pre-Submission Checklist

- [ ] App builds successfully in Release configuration
- [ ] All critical blockers resolved (Bundle ID, purchase flow, etc.)
- [ ] E2E tests pass
- [ ] No known crashes
- [ ] Privacy policy and terms hosted
- [ ] Sentry configured (optional but recommended)

## Submission Steps

### 1. Archive Build in Xcode

1. Open project in Xcode
2. Select "Any iOS Device" or connected device
3. Product → Archive
4. Wait for archive to complete (5-10 minutes)

### 2. Upload to App Store Connect

1. Window → Organizer
2. Select your archive
3. Click "Distribute App"
4. Choose "App Store Connect"
5. Select "Upload"
6. Follow prompts to upload (10-20 minutes)

### 3. Configure TestFlight in App Store Connect

1. Go to https://appstoreconnect.apple.com
2. Select your app
3. Go to TestFlight tab
4. Wait for processing (1-2 hours for first build)

### 4. Add Internal Testers

1. In TestFlight, go to Internal Testing
2. Add your Apple Developer team members
3. They'll receive email invitation
4. Can test immediately after processing

### 5. Add External Testers (Beta)

1. Go to External Testing
2. Create a new group (e.g., "Beta Testers")
3. Add the build you want to test
4. Fill out required information:
   - What to Test
   - Beta App Description
   - Feedback Email
5. Submit for Beta App Review (1-2 days)
6. Once approved, add testers:
   - Add email addresses (up to 10,000)
   - Or create public link (unlimited testers)

## Beta Testing Plan

### Phase 1: Internal Testing (Week 1)
- **Testers**: Development team (5-10 people)
- **Focus**: Critical bugs, crashes, major flows
- **Duration**: 3-5 days
- **Success Criteria**: No critical bugs, purchase flow works

### Phase 2: Closed Beta (Week 2-3)
- **Testers**: 20-50 trusted users
- **Focus**: Real-world usage, edge cases, UX feedback
- **Recruitment**:
  - Personal network (friends, family with babies)
  - Parenting forums/communities
  - Social media (Twitter, Reddit r/beyondthebump)
- **Duration**: 1-2 weeks
- **Success Criteria**: Positive feedback, no major issues

### Phase 3: Public Beta (Week 4+)
- **Testers**: Unlimited via public link
- **Focus**: Scale testing, diverse devices, final polish
- **Duration**: 1-2 weeks
- **Success Criteria**: Ready for App Store submission

## Feedback Collection

### In-App Feedback
- Use TestFlight's built-in feedback mechanism
- Add feedback button in Settings
- Track via AnalyticsService

### Survey Questions
1. How easy was it to log your first event? (1-5)
2. Did the nap prediction help? (Yes/No)
3. Would you pay for Pro? (Yes/No/Maybe)
4. What features are missing?
5. What would make you delete the app?

### Metrics to Track
- Activation rate (onboarding completion)
- First log time (should be <2 minutes)
- Purchase conversion rate
- Crash rate (target: <1%)
- Daily active users
- Retention (D1, D7, D30)

## Beta Tester Communication

### Welcome Email Template
```
Subject: Welcome to Nuzzle Beta!

Hi [Name],

Thanks for helping us test Nuzzle! Your feedback will shape the final app.

What to test:
- Onboarding flow (should be 3 steps)
- Quick logging (feed, diaper, sleep)
- Nap predictions
- Purchase/subscription flow

How to give feedback:
- Use TestFlight's feedback button
- Email: support@nuzzle.app
- Report bugs immediately

We'll send updates weekly. Thanks for your help!

- The Nuzzle Team
```

### Weekly Update Template
```
Subject: Nuzzle Beta Update - Week [X]

Hi Beta Testers,

Quick update on what we've fixed:
- [Bug fixes]
- [New features]
- [Performance improvements]

Current focus: [What you're working on]

Please test: [Specific areas]

Thanks for your continued feedback!

- The Nuzzle Team
```

## Common Issues to Watch For

1. **Purchase Flow**: Test with real StoreKit sandbox accounts
2. **CloudKit Sync**: Test with multiple devices
3. **Offline Mode**: Test airplane mode functionality
4. **Notifications**: Test deep links from notifications
5. **Widgets**: Test widget updates and interactions
6. **Accessibility**: Test with VoiceOver enabled

## Success Metrics

### Must-Have Before Launch
- ✅ <1% crash rate
- ✅ Purchase flow works for 95%+ of testers
- ✅ Onboarding completion >80%
- ✅ First log in <2 minutes for 90%+ users
- ✅ No critical data loss bugs

### Nice-to-Have
- 4+ star average rating from beta testers
- 10+ positive testimonials
- 50+ active beta testers
- <5% churn during beta period

## Post-Beta Actions

1. **Collect Testimonials**: Ask happy users for quotes
2. **Fix Critical Issues**: Address all P0 bugs
3. **Polish UX**: Fix any confusing flows
4. **Prepare Launch**: Finalize App Store listing
5. **Plan Marketing**: Coordinate launch announcement

## Resources

- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Beta Testing Best Practices](https://developer.apple.com/app-store/review/guidelines/)


