# iOS Improvements - Quick Start Guide

## What Changed (TL;DR)

### For You (Developer):

1. **7-day trial** now starts automatically on first launch
2. **Subscription loading fixed** - errors now visible to users with retry option
3. **All pricing updated** to $5.99/mo and $39.99/yr
4. **10 paywall triggers** tracked for conversion optimization
5. **Onboarding streamlined** to 3 screens

### For Users (Parents):

1. **Trial countdown** shows "5 days left" on Home
2. **Next Nap bigger** and shows Free vs Pro differentiation
3. **First log personalized** based on their goal
4. **Progress tracker** replaces confusing "Example day" banner
5. **Skip buttons** everywhere in onboarding

---

## Test This First

### 1. Fresh Install Flow

```
1. Delete app from simulator
2. Run in Xcode
3. Should see: Auth screen with "7-day free trial • Then $5.99/mo"
4. Tap "Continue without account"
5. Onboarding: Welcome → Baby Setup (skip if you want) → Goal Selection
6. Select any goal (e.g., "Better Sleep")
7. Should see celebration: "Your 7-day free trial has started 🎉"
8. Home screen should show:
   - Trial banner: "7 days left in your trial"
   - First log card: "Let's track your first nap together 😴" (if you picked Sleep goal)
   - Next Nap prediction (with age-based subtitle)
```

### 2. Subscription Testing

```
1. Go to Settings → Nuzzle Pro
2. Should load products (or show friendly error with Retry)
3. Verify pricing:
   - Monthly: $5.99/mo
   - Yearly: $39.99/yr + "Save $32/year" + "7-day free trial"
4. Tap Subscribe
5. StoreKit sheet should appear
```

### 3. Paywall Triggers to Test

```
- Tap trial banner "Upgrade" button
- Tap blurred "Today's Insight" card
- Go to Labs → Tap "Smart Predictions" (without Pro)
- Try 4th Cry Insight recording
- Wait until Day 7 (or manually set trialStartDate to 8 days ago)
- Settings → Tap "Nuzzle Pro"
```

---

## If Something Breaks

### Subscription Products Not Loading

1. Check Xcode scheme has StoreKit testing enabled
2. Verify `Nuzzle.storekit` exists at `ios/Nuzzle/Nuzzle.storekit`
3. Product → Clean Build Folder
4. Restart Xcode

### Trial Not Starting

1. Delete UserDefaults: Settings app → Nuzzle → Reset
2. Or manually: `UserDefaults.standard.removeObject(forKey: "trial_start_date")`
3. Reinstall app

### Pricing Still Shows $4.99

1. Hard refresh: Product → Clean Build Folder
2. Check you're in gnq worktree: `pwd` should show `/Users/tyhorton/.cursor/worktrees/nestling-care-log/gnq`
3. Verify file edits: `grep -r "\$4.99" ios/Nuzzle/Nestling/` should return 0 results

---

## Key Files to Know

### Trial System:

- `ProSubscriptionService.swift` - Core trial logic
- `TrialBannerView.swift` - UI component for countdown
- `NotificationScheduler.swift` - Day 5 warning

### Paywall:

- `ProSubscriptionView.swift` - Main subscription screen
- `UpgradePromptView.swift` - Contextual upgrade prompts
- `AnalyticsService.swift` - Source tracking

### Onboarding:

- `OnboardingCoordinator.swift` - Flow control (3 screens)
- `WelcomeView.swift`, `BabySetupView.swift`, `GoalSelectionView.swift`
- `FirstLogCard.swift` - Goal-based personalization

### Home:

- `HomeContentView.swift` - Trial banner, layout personalization
- `StatusTilesView.swift` - Enhanced Next Nap card
- `ExampleDataBanner.swift` - Progress tracker

---

## Analytics Dashboard (Recommended)

Track these funnels:

### Trial Conversion:

```
onboarding_completed
  ↓
paywall_viewed (source: X)
  ↓
subscription_purchased
  ↓
subscription_activated
```

### Onboarding Drop-off:

```
onboarding_step_viewed (step: welcome) → 100%
onboarding_step_viewed (step: baby_setup) → ?%
onboarding_step_viewed (step: goal_selection) → ?%
onboarding_completed → ?%
```

### Paywall Sources (Conversion Rates):

- trial_ended (expect high conversion)
- trial_banner_home
- todays_insight_card
- cry_insights_quota_exceeded
- labs_smart_predictions
- settings
- first_tasks_checklist

---

## StoreKit Testing Quick Commands

### Xcode Menu:

```
Debug → StoreKit → Manage Transactions → Delete All
Debug → StoreKit → Manage Transactions → Approve Pending
Debug → StoreKit → Enable Interruptions (test renewal failures)
```

### Enable Dev Mode (Bypass Subscription):

```swift
// In Settings → Developer Settings
UserDefaults.standard.set(true, forKey: "dev_pro_mode_enabled")
// App restart required
```

---

## Common Questions

**Q: How do I test the Day 7 paywall without waiting 7 days?**
A: Manually set trial start date:

```swift
UserDefaults.standard.set(Date().addingTimeInterval(-8 * 86400), forKey: "trial_start_date")
// Relaunch app
```

**Q: How do I reset onboarding?**
A: Settings → Debug → Reset Onboarding (DEBUG builds only)

**Q: Can I test with real money?**
A: No! Always use Sandbox test accounts or Xcode StoreKit testing. Never test production IAP in dev.

**Q: Where are analytics logged?**
A: Currently print statements. Integrate with Firebase Analytics, Mixpanel, or PostHog for production.

---

Last updated: December 6, 2025  
Worktree: `/Users/tyhorton/.cursor/worktrees/nestling-care-log/gnq`
