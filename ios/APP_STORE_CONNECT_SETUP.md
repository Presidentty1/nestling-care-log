# App Store Connect Setup Guide

This guide walks you through setting up subscriptions in App Store Connect for Nestling Pro.

## Prerequisites

- Apple Developer Account ($99/year)
- App Store Connect access
- Xcode 15.0 or later
- Product IDs ready (defined in code)

## Step 1: Create App Record

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click **My Apps** → **+** → **New App**
3. Fill in:
   - **Platform**: iOS
   - **Name**: Nestling Baby Tracker
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: `com.nestling.Nestling` (or your bundle ID)
   - **SKU**: `nestling-ios-001`
   - **User Access**: Full Access

## Step 2: Create Subscription Group

1. In your app, go to **Features** → **In-App Purchases**
2. Click **+** next to **Subscription Groups**
3. Name: **Nestling Pro**
4. Click **Create**

## Step 3: Create Subscription Products

### Monthly Subscription

1. Click **+** next to your subscription group
2. Select **Auto-Renewable Subscription**
3. Fill in:
   - **Product ID**: `com.nestling.pro.monthly`
   - **Reference Name**: Nestling Pro Monthly
   - **Subscription Duration**: 1 Month
4. Click **Create**
5. Add localized information:
   - **Display Name**: Nestling Pro
   - **Description**: Unlock advanced features for tracking your baby's care
6. Set pricing:
   - **Price**: $4.99/month
   - Select all countries or specific regions
7. Click **Save**

### Yearly Subscription

1. Repeat steps above with:
   - **Product ID**: `com.nestling.pro.yearly`
   - **Reference Name**: Nestling Pro Yearly
   - **Subscription Duration**: 1 Year
   - **Price**: $39.99/year

## Step 4: Configure Subscription Benefits

For each subscription:
1. Scroll to **Subscription Benefits**
2. Add benefits:
   - Unlimited babies
   - Full history access
   - Advanced AI insights
   - CSV export
   - Priority support

## Step 5: Configure Introductory Offers

### Free Trial (Recommended)

1. In subscription settings, find **Subscription Offers**
2. Click **+** → **Free Trial**
3. Configure:
   - **Duration**: 7 days
   - **Eligibility**: All users (or "New Subscribers Only" if preferred)
4. Click **Create**

### Introductory Pricing (Alternative)

1. Instead of Free Trial, select **Introductory Price**
2. Configure:
   - **Type**: Pay as You Go
   - **Price**: 50% off first 3 months (e.g., $2.49/month instead of $4.99)
   - **Duration**: 3 months
   - **Eligibility**: New Subscribers Only (or "All Users")
3. Click **Create**

**Note:** You can have both a Free Trial AND Introductory Pricing (trial first, then intro price).

## Step 6: Enable Family Sharing

Family Sharing allows one subscription to be shared across all family members (up to 6 people).

1. In subscription settings, find **Family Sharing**
2. Toggle **Enable Family Sharing** to ON
3. Click **Save**

**Benefits:**
- One parent subscribes, both parents get access (perfect for co-parenting)
- Increases perceived value ("Buy once, use for both parents")
- Aligns with "The Co-Parenting Team" persona (see MRR Growth Plan)

**Important:** Family Sharing must be enabled BEFORE the app is submitted for review. It cannot be changed after approval.

## Step 7: Verify Apple Pay Integration (Native StoreKit)

**Good News:** Apple Pay, Face ID, and saved cards are **automatically supported** when using StoreKit 2 with the native purchase sheet. No additional setup required.

### How It Works

1. When `ProSubscriptionService.purchase(productID:)` is called, StoreKit 2 automatically presents the native iOS purchase sheet
2. This sheet includes:
   - **Apple Pay** (if user has Apple Pay configured)
   - **Face ID/Touch ID** authentication
   - **Saved credit cards** from Wallet
   - **Family Sharing** toggle (if enabled)
   - **Subscription details** and auto-renewal info

### Verify in Code

Ensure `ProSubscriptionView.swift` uses `ProSubscriptionService.purchase()` which calls StoreKit 2's native `Product.purchase()` method. The native sheet is presented automatically.

**Test Checklist:**
- [ ] Purchase sheet appears with Apple Pay option (if configured)
- [ ] Face ID/Touch ID prompts correctly
- [ ] Saved cards appear in payment options
- [ ] Family Sharing toggle appears (if enabled)
- [ ] Subscription terms are clearly displayed

## Step 8: Submit for Review

1. Ensure both subscriptions show **Ready to Submit**
2. Add **Review Information** (optional for subscriptions)
3. Submit for review (subscriptions are reviewed separately from app)

## Step 9: Testing

### Sandbox Testing

1. In App Store Connect, go to **Users and Access** → **Sandbox Testers**
2. Create test accounts (use different emails from your real account)
3. Sign out of App Store on test device
4. Open Nestling app
5. Attempt purchase (will use sandbox account)

### StoreKit Configuration (Local Testing)

1. In Xcode, go to **File** → **New** → **File**
2. Select **StoreKit Configuration File**
3. Name it `Nestling.storekit`
4. Add your subscription products:
   - Product ID: `com.nestling.pro.monthly`
   - Product ID: `com.nestling.pro.yearly`
   - Set prices and durations
5. Go to **Edit Scheme** → **Run** → **Options**
6. Set **StoreKit Configuration** to `Nestling.storekit`

## Step 10: Verify Product IDs in Code

Ensure `ProSubscriptionService.swift` has correct product IDs:

```swift
private let monthlyProductID = "com.nestling.pro.monthly"
private let yearlyProductID = "com.nestling.pro.yearly"
```

## Troubleshooting

### Products Not Loading
- Verify product IDs match App Store Connect exactly
- Ensure products are **Ready to Submit** or **Approved**
- Check that subscriptions are in correct subscription group
- Verify you're using sandbox account for testing

### Purchase Fails
- Check device has valid payment method (sandbox)
- Verify you're signed out of real App Store account
- Check App Store Connect for any rejection messages
- Ensure StoreKit Configuration file is set in Xcode scheme (for local testing)

### Apple Pay Not Appearing
- **This is normal in Sandbox**: Apple Pay is typically NOT available in sandbox testing
- Apple Pay appears automatically in production if user has:
  - Apple Pay configured in Wallet
  - Valid payment cards added
- Test with regular credit card in sandbox, Apple Pay will work in production

### Family Sharing Not Working
- Ensure Family Sharing is enabled in App Store Connect **before** app submission
- Verify subscription is in a subscription group (required for Family Sharing)
- Test with actual family member accounts (not sandbox testers)
- Check that both family members are signed into iCloud and part of same Family Sharing group

### Introductory Offers Not Showing
- Verify offer is **Active** (not Draft) in App Store Connect
- Check eligibility criteria (New Subscribers Only vs All Users)
- Ensure offer duration is correct (7 days, 3 months, etc.)
- Test with fresh sandbox account that hasn't subscribed before

### Restore Purchases Fails
- Ensure transactions are completed in sandbox
- Check that restore is called on same device/account
- Verify receipt validation is working

## Summary: Native Payment Features

### ✅ Automatically Supported (No Setup Required)

- **Apple Pay**: Works automatically via native StoreKit purchase sheet
- **Face ID/Touch ID**: Biometric authentication built into purchase flow
- **Saved Cards**: Payment methods from Wallet appear automatically
- **Subscription Management**: Users can manage in Settings → Subscriptions

### 🔧 Requires App Store Connect Configuration

- **Family Sharing**: Enable in subscription settings (Step 6)
- **Introductory Offers**: Configure Free Trial or Intro Pricing (Step 5)
- **Subscription Groups**: Create group and add products (Step 2-3)

### 📱 Code Implementation Status

- ✅ StoreKit 2 integration (`ProSubscriptionService.swift`)
- ✅ Native purchase sheet (`Product.purchase()`)
- ✅ Transaction monitoring (`Transaction.updates`)
- ✅ Subscription status checking (`Transaction.currentEntitlements`)
- ✅ Feature gating (`FeatureGate.swift`)
- ✅ UI components (`ProSubscriptionView.swift`, `ProTrialView.swift`)

## Next Steps

After setup is complete:
1. Test subscription flow end-to-end (sandbox)
2. Verify Family Sharing (requires real family accounts)
3. Test Introductory Offers with fresh accounts
4. Test restore purchases flow
5. Submit app for review with subscriptions

**Related Documentation:**
- `nestling-strategic-review-mrr-growth-plan.plan.md` - MRR optimization strategy
- `MVP_LAUNCH_CHECKLIST.md` - Complete launch checklist
- `ios/Nestling/Nestling/Services/ProSubscriptionService.swift` - Implementation code

