# Performance & QA Guide

Comprehensive testing and optimization guide for Nestling iOS app.

## Performance Tuning

### Core Data Optimization

- [ ] **Fetch Limits**
  - `fetchLimit` set on all `NSFetchRequest` objects
  - Pagination implemented for large event lists
  - Batch size configured for large datasets
  - Check: `CoreDataDataStore.swift` has `fetchLimit = 1000`

- [ ] **Main Thread Usage**
  - All Core Data fetches happen on background context
  - UI updates on MainActor only
  - Heavy decoding on background thread
  - No blocking operations on main thread

- [ ] **Memory Profiling**
  - Profile with Instruments → Allocations
  - Check for memory leaks in:
    - `CryRecorder` (audio buffers)
    - Image loading (if photos added)
    - ViewModel retain cycles
  - Target: < 50MB typical usage

- [ ] **Startup Time**
  - Minimize work in `App.init()`
  - Lazy load Core Data stack
  - Defer non-critical initialization
  - Target: < 2 seconds to first screen

### Network Optimization

- [ ] **Sync Performance**
  - Batch operations when possible
  - Use compression for large payloads
  - Cache predictions locally
  - Retry with exponential backoff

- [ ] **Image Loading** (if photos added)
  - Lazy load images
  - Resize before upload
  - Cache thumbnails
  - Progressive loading

## Crash Reporting Setup

### Option 1: Sentry

1. Add Sentry via SPM:

   ```
   https://github.com/getsentry/sentry-cocoa
   ```

2. Configure in `AppDelegate` or `App.init()`:

   ```swift
   import Sentry

   SentrySDK.start { options in
       options.dsn = "YOUR_SENTRY_DSN"
       options.environment = "production"
       options.tracesSampleRate = 1.0
   }
   ```

3. Add breadcrumbs for key actions:
   ```swift
   SentrySDK.addBreadcrumb(crumb: Breadcrumb(level: .info, category: "user_action")) {
       $0.message = "User logged event"
       $0.data = ["event_type": "feed"]
   }
   ```

### Option 2: Firebase Crashlytics

1. Add Firebase SDK via SPM
2. Configure in `AppDelegate`
3. Enable Crashlytics in Firebase Console
4. Test crash reporting with `Crashlytics.crashlytics().crash()`

## Analytics Setup

### Basic Analytics Events

Track these key metrics:

- **User Actions**
  - `event_logged` (type: feed/sleep/diaper)
  - `baby_added`
  - `subscription_purchased`
  - `subscription_cancelled`

- **Performance**
  - `sync_latency` (milliseconds)
  - `sync_failure` (error type)
  - `app_crash` (crash type)

- **Business**
  - `paywall_viewed`
  - `subscription_conversion` (monthly/yearly)
  - `restore_purchases_attempted`

### Implementation

Use existing `AnalyticsService.swift` or add Firebase Analytics:

```swift
// Example event logging
Analytics.shared.log("event_logged", parameters: [
    "event_type": "feed",
    "has_amount": true,
    "has_note": false
])
```

## Testing Regime

### Unit Tests

Create tests for:

- [ ] **Data Migration Logic**

  ```swift
  func testMigrationMergesBabiesCorrectly() {
      // Test merging local and remote babies
  }
  ```

- [ ] **Sync Conflict Resolution**

  ```swift
  func testLastWriteWinsStrategy() {
      // Test conflict resolution
  }
  ```

- [ ] **Subscription Status Logic**
  ```swift
  func testSubscriptionStatusCalculation() {
      // Test status transitions
  }
  ```

### UI Tests

Create tests for:

- [ ] **Onboarding Flow**
  - Complete onboarding end-to-end
  - Skip onboarding works
  - Validation errors shown

- [ ] **Event Logging**
  - Log feed event
  - Verify event appears in timeline
  - Delete event works
  - Undo deletion works

- [ ] **Subscription Flow**
  - Purchase subscription (sandbox)
  - Restore purchases
  - Feature gating works

### Beta Testing

- [ ] **TestFlight Distribution**
  - Create TestFlight group
  - Add testers (5-10 initial testers)
  - Provide test instructions
  - Collect feedback via TestFlight

- [ ] **Test Devices**
  - iPhone 11 (iOS 16)
  - iPhone SE (iOS 17)
  - iPhone 15 Pro Max (latest)
  - iPad (if supported)

### Manual Testing Checklist

- [ ] **Auth Flow**
  - Sign up works
  - Sign in works
  - Session persists on relaunch
  - Sign out works
  - Wrong password shows error

- [ ] **Event Logging**
  - All event types log correctly
  - Amounts save correctly
  - Notes save correctly
  - Timestamps are correct
  - Events appear in timeline immediately

- [ ] **Sync**
  - Events sync across devices
  - Offline mode works
  - Sync resumes when online
  - Conflicts resolved correctly

- [ ] **Subscriptions**
  - Purchase flow works (sandbox)
  - Restore purchases works
  - Feature gating enforced
  - Subscription status updates

- [ ] **Edge Cases**
  - App launch with no internet
  - App launch with corrupted Core Data
  - Delete all babies
  - Delete all events
  - Date navigation beyond available data

## Performance Benchmarks

### Target Metrics

- **Launch Time**: < 2 seconds
- **Event Log Time**: < 500ms
- **Timeline Load**: < 1 second for 100 events
- **Sync Latency**: < 3 seconds for 50 events
- **Memory Usage**: < 50MB typical
- **Crash-Free Rate**: > 99%

### Measurement

Use Instruments:

1. **Time Profiler**: Measure launch time
2. **Allocations**: Check memory usage
3. **System Trace**: Check frame rates
4. **Network**: Check sync performance

## Pre-Launch Checklist

- [ ] All unit tests pass
- [ ] All UI tests pass
- [ ] Manual testing complete
- [ ] Beta testing complete
- [ ] Crash reporting working
- [ ] Analytics events firing
- [ ] Performance benchmarks met
- [ ] Memory leaks fixed
- [ ] No blocking operations on main thread
