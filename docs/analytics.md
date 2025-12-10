# Nuzzle Analytics

## Overview

Nuzzle uses Firebase Analytics for tracking user behavior, subscription events, and feature usage. All events are properly anonymized and respect user privacy.

## Analytics Service

The `Analytics` actor provides a unified interface for tracking events:

```swift
actor Analytics {
    static let shared = Analytics()

    func log(_ event: String, parameters: [String: Any]? = nil)
    func logOnboardingCompleted(babyId: String)
    func logSubscriptionTrialStarted(plan: String, source: String)
    // ... more convenience methods
}
```

## Event Categories

### Subscription Events

| Event                        | Parameters            | Description               |
| ---------------------------- | --------------------- | ------------------------- |
| `subscription_trial_started` | `plan`, `source`      | Trial initiated           |
| `subscription_activated`     | `plan`, `price`       | Subscription activated    |
| `subscription_renewed`       | `plan`                | Subscription auto-renewed |
| `subscription_cancelled`     | `plan`, `reason?`     | Subscription cancelled    |
| `subscription_purchased`     | `product_id`, `price` | Initial purchase          |

### Core Product Usage

| Event             | Parameters                      | Description           |
| ----------------- | ------------------------------- | --------------------- |
| `log_feed`        | `baby_id`, `quantity?`, `type?` | Feed event logged     |
| `log_diaper`      | `baby_id`, `type`               | Diaper event logged   |
| `log_sleep_start` | `baby_id`                       | Sleep session started |
| `log_sleep_stop`  | `baby_id`, `duration_minutes`   | Sleep session ended   |

### AI Feature Usage

| Event                         | Parameters          | Description            |
| ----------------------------- | ------------------- | ---------------------- |
| `ai_nap_prediction_requested` | `baby_id`, `is_pro` | Nap prediction viewed  |
| `ai_cry_analysis_requested`   | `baby_id`, `is_pro` | Cry analysis performed |
| `ai_assistant_opened`         | `baby_id`, `is_pro` | AI assistant accessed  |

### User Journey Events

| Event                       | Parameters                  | Description                   |
| --------------------------- | --------------------------- | ----------------------------- |
| `onboarding_completed`      | `baby_id`                   | User completed onboarding     |
| `first_log_created`         | `event_type`, `baby_id`     | First event logged            |
| `paywall_viewed`            | `source`                    | Upgrade paywall shown         |
| `prediction_shown`          | `type`, `is_pro`, `baby_id` | Prediction displayed          |
| `caregiver_invite_sent`     | `method`                    | Caregiver invitation sent     |
| `caregiver_invite_accepted` | -                           | Caregiver invitation accepted |

## Implementation Details

### Firebase Integration

Events are automatically converted to Firebase-friendly format:

- Event names: Alphanumeric + underscore, max 40 characters
- Parameter keys: Converted to snake_case, max 40 characters
- Parameter values: Strings, numbers, booleans only

### Privacy & Compliance

- No personally identifiable information tracked
- Baby IDs are anonymized/hashed
- Location data not collected
- Analytics disabled if Firebase not configured
- Console logging fallback for development

### User Properties

Set automatically:

- `subscription_status`: "free", "trial", "pro"
- `baby_age_months`: Age in months (if baby exists)

## Event Naming Conventions

- **snake_case**: All event names and parameter keys
- **Past tense**: `subscription_purchased`, `onboarding_completed`
- **Descriptive**: Include context (e.g., `ai_nap_prediction_requested`)
- **Consistent**: Use same patterns across similar events

## Parameter Standards

| Parameter | Type   | Description                 | Example               |
| --------- | ------ | --------------------------- | --------------------- |
| `baby_id` | String | Anonymized baby identifier  | "abc123"              |
| `plan`    | String | Subscription plan           | "monthly", "yearly"   |
| `is_pro`  | Bool   | Whether user has Pro access | true                  |
| `source`  | String | Where event originated      | "settings", "paywall" |
| `price`   | String | Formatted price             | "$5.99"               |

## Testing & Debugging

### Test Analytics

Use `TestAnalytics` for unit tests:

```swift
let analytics = TestAnalytics()
Analytics.setService(analytics)
// ... perform actions ...
XCTAssertEqual(analytics.events.count, 1)
```

### Debug Logging

In debug builds, events are logged to console:

```
[Analytics] subscription_purchased: ["product_id": "com.nestling.pro.monthly", "price": "$5.99"]
```

### Firebase Console

Monitor events in Firebase Analytics dashboard:

- **Events**: View event counts and parameters
- **Audiences**: Segment by subscription status
- **Funnels**: Track conversion from trial to paid
- **Crashes**: Monitor app stability

## Analytics Strategy

### Key Metrics

- **Subscription conversion**: Trial started → Subscription purchased
- **Feature adoption**: Paywall viewed → Feature used
- **User engagement**: Daily active users, session length
- **Retention**: Day 1, 7, 30 retention rates

### A/B Testing

Future: Use Firebase Remote Config for:

- Paywall copy variations
- Feature gating experiments
- Onboarding flow optimization

### Performance Monitoring

Track:

- App launch time
- Feature load times
- Error rates by feature
- Crash-free users

## Configuration

### Firebase Setup

1. Create Firebase project
2. Add iOS app with bundle ID
3. Download `GoogleService-Info.plist`
4. Add to Xcode project
5. Enable Analytics in Firebase console

### Environment Variables

- `FIREBASE_ENABLED=true`: Enable Firebase (default: auto-detect)

## Compliance

- **GDPR**: Analytics can be disabled
- **COPPA**: No tracking of children under 13
- **App Tracking Transparency**: Respects ATT permissions
- **Data minimization**: Only essential events tracked
