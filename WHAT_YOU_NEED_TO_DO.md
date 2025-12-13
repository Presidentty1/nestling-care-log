# What You Need to Do Before App Store Submission

## ✅ Already Completed (By Me)

1. ✅ Updated all "Nestling" → "Nuzzle" in code
2. ✅ Updated Info.plist privacy descriptions
3. ✅ Updated APP_STORE_METADATA.md
4. ✅ Updated APP_STORE_CHECKLIST.md
5. ✅ Created PrivacyInfo.xcprivacy file
6. ✅ Fixed remaining "Nestling" references

## 🔴 Critical: You Must Do These

### 1. Add Privacy Manifest to Xcode Project (5 minutes)

The `PrivacyInfo.xcprivacy` file has been created at:

```
ios/Nuzzle/Nestling/PrivacyInfo.xcprivacy
```

**You need to add it to the Xcode project:**

1. Open `ios/Nuzzle/Nestling.xcodeproj` in Xcode
2. Right-click on the `Nestling` folder in the Project Navigator
3. Select "Add Files to 'Nuzzle'..."
4. Navigate to `ios/Nuzzle/Nestling/PrivacyInfo.xcprivacy`
5. Make sure "Copy items if needed" is **unchecked** (file is already in the right place)
6. Make sure "Add to targets: Nuzzle" is **checked**
7. Click "Add"

**Verify it's added:**

- The file should appear in the Project Navigator
- Select the file and check the "Target Membership" in the File Inspector
- "Nuzzle" should be checked

### 2. Set Version & Build Numbers (2 minutes)

In Xcode:

1. Select the "Nuzzle" project in Project Navigator
2. Select the "Nuzzle" target
3. Go to "General" tab
4. Set:
   - **Version**: `1.0.0`
   - **Build**: `1`

### 3. Verify App Icon (5 minutes)

1. In Xcode, select the "Nuzzle" target
2. Go to "General" tab → "App Icons and Launch Screen"
3. Verify you have a 1024x1024 PNG app icon
4. If missing, add one (no transparency, no alpha channel)

### 4. Create App Store Connect Record (15 minutes)

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Click "My Apps" → "+" → "New App"
3. Fill in:
   - **Platform**: iOS
   - **Name**: "Nuzzle"
   - **Primary Language**: English (U.S.)
   - **Bundle ID**: `com.nestling.Nestling` (preserved per plan)
   - **SKU**: `nuzzle-001` (or any unique identifier)
4. Click "Create"

### 5. Configure App Store Connect Metadata (30 minutes)

In App Store Connect, fill in all required fields:

**App Information:**

- **Subtitle**: "AI-powered feed & sleep log"
- **Category**: Primary: Health & Fitness, Secondary: Lifestyle
- **Age Rating**: 4+ (No Objectionable Content)

**Pricing and Availability:**

- **Price**: Free
- **Availability**: All countries (or select specific ones)

**App Privacy:**

- Complete the privacy questionnaire
- Declare data types collected (see APP_STORE_METADATA.md for details)
- Set "Data used for tracking": No
- Set "Data linked to user": Yes (for sync)

**Support Information:**

- **Support URL**: `https://nuzzle.app/support` (verify this is live)
- **Marketing URL**: `https://nuzzle.app` (verify this is live)
- **Privacy Policy URL**: `https://nuzzle.app/privacy` (verify this is live)

### 6. Set Up Subscriptions in App Store Connect (20 minutes)

1. In App Store Connect, go to your app → "Subscriptions"
2. Click "+" to create a subscription group
3. Name: "Nuzzle Pro"
4. Click "Create"

**Create Monthly Subscription:**

1. Click "+" next to "Nuzzle Pro" group
2. **Reference Name**: "Nuzzle Pro Monthly"
3. **Product ID**: `com.nestling.pro.monthly`
4. **Subscription Duration**: 1 Month
5. **Price**: $5.99/month
6. Click "Create"
7. Add localized description (English): "Unlock AI-powered nap predictions, unlimited cry analysis, AI assistant, and advanced analytics."
8. Set status to "Ready to Submit"

**Create Yearly Subscription:**

1. Click "+" next to "Nuzzle Pro" group
2. **Reference Name**: "Nuzzle Pro Yearly"
3. **Product ID**: `com.nestling.pro.yearly`
4. **Subscription Duration**: 1 Year
5. **Price**: $39.99/year
6. Click "Create"
7. Add localized description (English): "Unlock AI-powered nap predictions, unlimited cry analysis, AI assistant, and advanced analytics."
8. **Add Introductory Offer:**
   - Click "Add Introductory Offer"
   - Type: Free Trial
   - Duration: 7 days
   - Click "Create"
9. Set status to "Ready to Submit"

### 7. Prepare Screenshots (2-4 hours)

You need screenshots for:

- **iPhone 6.5" Display** (iPhone 14 Pro Max / 15 Pro Max): 5 screenshots minimum
- **iPhone 5.5" Display** (iPhone 8 Plus): 5 screenshots minimum

**Screenshot Ideas:**

1. Home screen with timeline and quick actions
2. Event logging form (feed/diaper/sleep)
3. History view with date picker
4. Settings/Pro subscription screen
5. AI predictions or insights screen

**How to Capture:**

1. Run app on simulator or device
2. Use Cmd+S in simulator or screenshot on device
3. Edit to remove status bar if needed
4. Save as PNG files

### 8. Set Up Legal Pages (1-2 hours)

**Privacy Policy** (`https://nuzzle.app/privacy`):

- Must be live and accessible
- Include: data collection, AI usage, third-party services
- Must comply with App Store guidelines

**Terms of Service** (`https://nuzzle.app/terms`):

- Must be live and accessible
- Include: usage terms, subscription terms, refund policy

**Support Page** (`https://nuzzle.app/support`):

- Contact information
- FAQ
- How to get help

### 9. Test Subscription Flow (30 minutes)

1. Build and run app on device or simulator
2. Navigate to Settings → Pro Subscription
3. Test purchase flow in sandbox:
   - Create sandbox test account in App Store Connect
   - Sign out of App Store on device
   - Try to purchase → sign in with sandbox account
   - Verify purchase completes
   - Verify Pro features unlock
4. Test restore purchases
5. Test trial activation (yearly subscription)

### 10. Build Archive for Submission (15 minutes)

1. In Xcode, select "Any iOS Device" or your connected device
2. Product → Archive
3. Wait for archive to complete (5-10 minutes)
4. Window → Organizer
5. Select your archive
6. Click "Distribute App"
7. Choose "App Store Connect"
8. Click "Next" through options
9. Click "Upload"
10. Wait for upload to complete (10-30 minutes)

### 11. Submit for Review (10 minutes)

1. Go to App Store Connect
2. Select your app
3. Go to the version you want to submit
4. Select the build you just uploaded (wait for processing to complete)
5. Fill in "What's New" section (see APP_STORE_METADATA.md)
6. Add App Review Information:
   - Test account (if required)
   - Review notes (see APP_STORE_CHECKLIST.md)
   - Contact information
7. Click "Submit for Review"

## 🟡 Important: Should Do Before Launch

### 12. TestFlight Beta Testing (Optional but Recommended)

1. Upload build to App Store Connect (same as step 10)
2. Go to TestFlight tab in App Store Connect
3. Add internal testers (your team)
4. Add external testers (beta users)
5. Wait for Apple review (1-2 days for first build)
6. Invite testers via TestFlight app

### 13. Marketing Preparation

- Prepare social media posts
- Prepare press release (if applicable)
- Prepare landing page updates
- Prepare email to beta testers

## 📋 Quick Checklist

- [ ] Add PrivacyInfo.xcprivacy to Xcode project
- [ ] Set version to 1.0.0 and build to 1
- [ ] Verify app icon exists
- [ ] Create App Store Connect app record
- [ ] Fill in all App Store Connect metadata
- [ ] Set up subscription products
- [ ] Prepare screenshots (5 per device size)
- [ ] Set up privacy policy, terms, support pages
- [ ] Test subscription flow in sandbox
- [ ] Build and upload archive
- [ ] Submit for review

## ⏱️ Estimated Time

- **Minimum (Critical Only)**: ~3-4 hours
- **Recommended (Including Testing)**: ~6-8 hours
- **Complete (Including Marketing)**: ~10-12 hours

## 🆘 If You Get Stuck

- **Xcode Issues**: Check PRE_LAUNCH_CHECKLIST.md
- **App Store Connect Issues**: Check APP_STORE_CHECKLIST.md
- **Subscription Issues**: Check docs/subscriptions.md
- **Build Issues**: Check ios/README.md

## 📝 Notes

- Bundle ID `com.nestling.Nestling` is preserved for App Store continuity
- Product IDs `com.nestling.pro.monthly` and `com.nestling.pro.yearly` are preserved
- All URLs should point to `nuzzle.app` domain
- All email addresses should use `@nuzzle.app`


