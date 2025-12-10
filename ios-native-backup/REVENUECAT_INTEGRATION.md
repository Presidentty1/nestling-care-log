# RevenueCat Integration Guide

## Status

RevenueCat service is **prepared but not fully integrated**. The SDK needs to be added to the Xcode project.

## Current Implementation

The `RevenueCatService` class exists at `ios/Sources/Services/RevenuCatService.swift` but is currently mocked. The service interface is complete and ready for SDK integration.

## Integration Steps

### 1. Add RevenueCat SDK

**Option A: Swift Package Manager (Recommended)**

1. In Xcode, go to File → Add Package Dependencies
2. Enter: `https://github.com/RevenueCat/purchases-ios`
3. Select version: `7.0.0` or latest
4. Add to target: `Nestling`

**Option B: CocoaPods**

```ruby
pod 'Purchases', '~> 7.0'
```

### 2. Configure API Key

1. Get your RevenueCat API key from https://app.revenuecat.com
2. Add to `Info.plist`:

```xml
<key>REVENUECAT_API_KEY</key>
<string>your_api_key_here</string>
```

Or set as environment variable in Xcode scheme.

### 3. Update RevenueCatService

Uncomment the SDK imports and implementation in `ios/Sources/Services/RevenuCatService.swift`:

```swift
import RevenueCat

// Replace mocked methods with actual SDK calls:
func checkSubscriptionStatus() async {
    do {
        let customerInfo = try await Purchases.shared.customerInfo()
        // Update subscription status based on customerInfo
        if customerInfo.entitlements.active["pro"] != nil {
            subscriptionStatus = .subscribed
            isProUser = true
        } else {
            subscriptionStatus = .notSubscribed
            isProUser = false
        }
    } catch {
        Logger.dataError("Failed to check RevenueCat subscription status: \(error.localizedDescription)")
        subscriptionStatus = .notSubscribed
        isProUser = false
    }
}
```

### 4. Configure Products in RevenueCat Dashboard

1. Create subscription group "Pro"
2. Add products:
   - Monthly: `com.nestling.pro.monthly` ($4.99/month)
   - Yearly: `com.nestling.pro.yearly` ($49.99/year)
3. Configure offerings and entitlements

### 5. Test

Use StoreKit Testing in Xcode:

1. Xcode → Product → Scheme → Edit Scheme
2. Run → Options → StoreKit Configuration
3. Select test configuration file

## Current Mock Behavior

The service currently:

- Returns mock subscription status (always `.notSubscribed`)
- Returns mock offerings (monthly/yearly with placeholder prices)
- Simulates successful purchases (for testing UI)

## Integration Checklist

- [ ] Add RevenueCat SDK package
- [ ] Configure API key
- [ ] Uncomment SDK code in `RevenueCatService.swift`
- [ ] Create products in App Store Connect
- [ ] Configure offerings in RevenueCat dashboard
- [ ] Test purchase flow
- [ ] Test restore purchases
- [ ] Test subscription status updates
- [ ] Test trial periods
- [ ] Update `ProSubscriptionService` to use real RevenueCat service

## Notes

- The service interface is already designed to work with RevenueCat
- All UI components (`ProSubscriptionView`) are ready
- Paywall triggers are implemented and will work once SDK is integrated
- Backend subscription checks (edge functions) work independently
