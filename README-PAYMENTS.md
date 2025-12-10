# StoreKit 2 In-App Purchases Setup Guide

This guide explains how to set up and test in-app purchases for Nuzzle Pro subscriptions in Xcode and Cursor.

## Quick Start

### 1. Enable In-App Purchase Capability

1. Open `/Users/tyhorton/.cursor/worktrees/nestling-care-log/gnq/ios/Nuzzle/Nestling.xcodeproj` in Xcode
2. Select the **Nestling** target
3. Go to **Signing & Capabilities** tab
4. Click **+ Capability** → Add **In-App Purchase**

### 2. Configure StoreKit Testing

The app uses a `.storekit` configuration file for local testing:

```
ios/Nuzzle/Nuzzle.storekit
```

**Products configured:**
- `com.nestling.pro.monthly` - $5.99/month
- `com.nestling.pro.yearly` - $39.99/year (with 7-day free trial)

**To enable StoreKit testing:**

1. In Xcode, go to **Product** → **Scheme** → **Edit Scheme**
2. Select **Run** → **Options** tab
3. Under **StoreKit Configuration**, select `Nuzzle.storekit`
4. Check **Enable StoreKit Testing**

### 3. Create Sandbox Test Accounts

For testing on real devices:

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **Users and Access** → **Sandbox**
3. Click **+** to add a test user
4. Create a test Apple ID (use a real email you can access)
5. On your iPhone/iPad:
   - Settings → App Store → Sandbox Account
   - Sign in with test account

### 4. Test Subscription Flows

**Local Testing (Simulator):**
- Purchase flows complete instantly
- Subscriptions renew every few minutes for testing
- Use **Debug** → **StoreKit** → **Manage Transactions** to clear/manage test purchases

**Device Testing (Real iPhone):**
- Must use Sandbox test account
- Apple shows "[Environment: Sandbox]" on purchase sheets
- You won't be charged real money

### 5. Verify Subscription State

The app logs subscription status to console:

```swift
print("[Pro] Loaded X products")
print("[Pro] Starting purchase for product: ...")
print("[Pro] Purchase verified successfully")
print("[Pro] Time-based trial active: X days remaining")
```

**Dev Mode Toggle:**
- Settings → Developer Settings → Enable Pro Mode
- Bypasses all subscription checks (useful for testing Pro features)

## Product IDs

Current configuration uses `com.nestling.*` namespace for continuity:

```swift
monthlyProductID = "com.nestling.pro.monthly"  // $5.99/mo
yearlyProductID = "com.nestling.pro.yearly"    // $39.99/yr
```

**Note:** When transitioning to `com.nuzzle.*` bundle ID, product IDs remain unchanged to maintain subscription continuity.

## Trial System

### Time-Based Trial (7 Days)
- Starts automatically on first app launch
- Stored in UserDefaults: `trial_start_date`
- Calculated daily: `trialDaysRemaining`
- After 7 days, app shows paywall on launch

### StoreKit Introductory Offers
- Yearly plan includes 7-day free trial (configured in `Nuzzle.storekit`)
- Detected via `Transaction.offer?.type == .introductory`
- Managed automatically by StoreKit 2

## App Store Connect Setup (Production)

Before submitting to App Store:

1. **Create Subscription Group:**
   - Name: "Nuzzle Pro"
   - Products:
     - Monthly: `com.nestling.pro.monthly` at $5.99/month
     - Yearly: `com.nestling.pro.yearly` at $39.99/year
   
2. **Configure Introductory Offer:**
   - Yearly plan: 7-day free trial
   - Available to new subscribers only
   
3. **Set Subscription Level:**
   - Both products in same group (users can switch between them)
   - Yearly = Level 2 (higher benefits)
   
4. **Add Localized Descriptions:**
   - At minimum: English (US)
   - Recommended: All supported markets

## Troubleshooting

### "No subscription products found"

1. **Check StoreKit Configuration:**
   - Verify `Nuzzle.storekit` exists
   - Verify product IDs match code
   - Verify display prices are set

2. **Check Xcode Scheme:**
   - Ensure StoreKit testing is enabled
   - Try **Product** → **Clean Build Folder**
   - Restart Xcode

3. **Check Network (Real Device):**
   - App Store must be reachable
   - Sandbox test account must be signed in

### "Transaction verification failed"

- Clear sandbox transactions: Xcode → **Debug** → **StoreKit** → **Manage Transactions** → Delete all
- Sign out/in to sandbox account on device
- Verify time/date on device is correct

### Subscription not activating

- Check console for `[Pro]` log messages
- Verify `Transaction.currentEntitlements` returns data
- Try **Restore Purchases** from Settings

## Analytics Events

The app tracks these subscription events:

- `subscription_trial_started` - Trial began
- `paywall_viewed(source)` - User saw paywall
- `subscription_purchased` - Successful purchase
- `subscription_activated` - Entitlement granted
- `subscription_renewed` - Auto-renewal occurred
- `subscription_cancelled` - User cancelled

## Security Notes

- Never log actual transaction receipts
- All verification happens client-side via StoreKit 2
- No server-side receipt validation required for MVP
- Consider adding server validation before major launch

## Support Resources

- [StoreKit 2 Documentation](https://developer.apple.com/documentation/storekit/in-app_purchase)
- [Testing In-App Purchases](https://developer.apple.com/documentation/xcode/setting-up-storekit-testing-in-xcode)
- [App Store Connect Help](https://help.apple.com/app-store-connect/#/devb57be10e7)

