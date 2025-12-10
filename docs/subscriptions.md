# Nuzzle Subscription System

## Overview

Nuzzle uses StoreKit 2 for in-app purchases with a simple Free vs Pro model. Pro features unlock advanced AI capabilities and analytics.

## Pricing

- **Monthly**: $5.99/month (`com.nestling.pro.monthly`)
- **Yearly**: $39.99/year (`com.nestling.pro.yearly`) with 7-day free trial
- **Trial**: 7 days on yearly subscription (introductory offer via StoreKit)

## Product IDs

```swift
private let monthlyProductID = "com.nestling.pro.monthly"
private let yearlyProductID = "com.nestling.pro.yearly"
```

## Feature Gating

### Free Features (Always Available)

- Unlimited logging (feeds/diapers/sleep)
- Multi-caregiver sync
- Dashboard with last feed/diaper/sleep status
- Basic time-since-feed and nap-window reminders

### Pro Features (Requires Subscription)

- `smartPredictions`: AI nap predictor with personalized suggestions
- `cryInsights`: Cry analysis (3 free uses, unlimited with Pro)
- `aiAssistant`: AI-powered parenting assistance
- `todaysInsight`: Personalized recommendations based on patterns
- `advancedAnalytics`: Detailed charts and insights

## StoreKit Configuration

### App Store Connect Setup

1. Create subscription group "Nuzzle Pro"
2. Add monthly subscription ($5.99/month)
   - Product ID: `com.nestling.pro.monthly`
   - Recurring period: Monthly
3. Add yearly subscription ($39.99/year)
   - Product ID: `com.nestling.pro.yearly`
   - Recurring period: Yearly
   - Introductory offer: 7-day free trial
4. Configure shared secret for server-side validation (optional)

### Local StoreKit Configuration

Update `Nuzzle.storekit`:

- Monthly price: "5.99"
- Yearly price: "39.99"
- Add introductory offer to yearly: `{"type": "FreeTrial", "duration": "P7D"}`

## Subscription Management

### ProSubscriptionService

Core service handling all subscription logic:

```swift
@MainActor
class ProSubscriptionService: ObservableObject {
    static let shared = ProSubscriptionService()

    @Published var subscriptionStatus: SubscriptionStatus = .notSubscribed
    @Published var isProUser: Bool = false
    @Published var trialDaysRemaining: Int? = nil

    // Check if user has access to feature
    func hasAccess(to feature: ProFeature) -> Bool

    // Purchase subscription
    func purchase(productID: String) async -> Bool

    // Restore purchases
    func restorePurchases() async -> Bool

    // Get expiration date
    var proExpirationDate: Date? { get async }

    // Refresh entitlements
    func refreshEntitlements() async
}
```

### Subscription States

```swift
enum SubscriptionStatus {
    case notSubscribed      // No active subscription
    case subscribed         // Active subscription
    case expired           // Subscription expired
    case inGracePeriod     // In grace period
    case inBillingRetryPeriod // Billing retry
}
```

## Trial Logic

- **Automatic**: Trials come from StoreKit introductory offers
- **Duration**: 7 days on yearly subscription
- **Detection**: Checked via `Transaction.currentEntitlements` with `offer?.type == .introductory`
- **Status**: Stored in `trialDaysRemaining` property

## Feature Gating Implementation

Use `FeatureGate` helper for consistent gating:

```swift
FeatureGate.check(.smartPredictions, accessible: {
    // Show Pro feature
    SmartPredictionsView()
}, paywall: {
    // Show upgrade prompt
    UpgradePromptView(feature: .smartPredictions)
})
```

## Analytics Events

Key subscription events tracked:

- `subscription_trial_started` - Trial initiated
- `subscription_activated` - Subscription activated
- `subscription_renewed` - Subscription renewed
- `subscription_cancelled` - Subscription cancelled
- `subscription_purchased` - Initial purchase
- `paywall_viewed` - Paywall shown

## Testing

### Sandbox Testing

1. Create StoreKit Configuration file in Xcode
2. Test purchase flows with sandbox accounts
3. Test trial activation and expiration
4. Test restore purchases

### Debug Tools

Available in Developer Settings (debug builds only):

- **Force Pro Status**: Toggle to simulate Pro subscription
- **Simulate Trial Expiration**: Force trial to expire
- **Clear Subscription Data**: Reset all subscription state
- **Reset Trial Eligibility**: Allow trial to be started again

## Manual App Store Steps

1. **Create Products**: Set up monthly and yearly subscriptions in App Store Connect
2. **Configure Pricing**: Set prices and introductory offers
3. **Submit for Review**: Include subscription details in app submission
4. **Monitor**: Check subscription metrics in App Store Connect

## Error Handling

- **Network failures**: Retry with exponential backoff
- **Purchase failures**: Show user-friendly error messages
- **Entitlement verification**: Handle StoreKit verification failures gracefully
- **Trial detection**: Fallback to free tier if trial status unclear

## Security

- All transactions verified using StoreKit 2's `VerificationResult`
- Server-side receipt validation recommended for production
- No sensitive data stored locally
- UserDefaults used only for trial state (not sensitive)
