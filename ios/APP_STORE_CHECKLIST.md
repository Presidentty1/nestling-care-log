# App Store Submission Checklist

Complete checklist for submitting Nuzzle to the App Store.

## Pre-Submission Checks

### Bundle ID & Signing

- [ ] **Bundle ID Verified**
  - Bundle ID: `com.nestling.Nestling` (or your bundle ID)
  - Matches App Store Connect app record exactly
  - No typos or mismatches

- [ ] **Signing Certificates**
  - Distribution certificate valid (not expired)
  - Provisioning profile up to date
  - Signing configured correctly in Xcode

- [ ] **Version & Build**
  - Version: `1.0.0` (CFBundleShortVersionString)
  - Build: `1` (CFBundleVersion)
  - Increment build number for each upload

## Compliance & Legal

### Info.plist Keys

Verify all required privacy usage descriptions:

- [ ] **NSMicrophoneUsageDescription** ✅ (already exists)
  - Description: "Nuzzle needs microphone access to analyze your baby's cry patterns and provide insights."

- [ ] **NSPhotoLibraryUsageDescription**
  - Description: "Nuzzle needs photo library access to save and attach photos to baby profiles and events."

- [ ] **NSCameraUsageDescription**
  - Description: "Nuzzle needs camera access to take photos for baby profiles and events."

- [ ] **NSHealthShareUsageDescription** (if HealthKit integration)
  - Description: "Nuzzle needs health data access to sync baby care information with the Health app."

- [ ] **NSHealthUpdateUsageDescription** (if HealthKit integration)
  - Description: "Nestling needs health data write access to sync baby care information with the Health app."

- [ ] **NSLocationWhenInUseUsageDescription** (if location features)
  - Description: "Nuzzle needs location access to add location context to logged events."

### Encryption

- [ ] **ITSAppUsesNonExemptEncryption**
  - Set to `NO` in Info.plist (unless using custom encryption)
  - OR submit export compliance documentation if using custom encryption

### Privacy Policy & Terms

- [ ] **Privacy Policy URL**
  - URL: `https://nuzzle.app/privacy` (or your URL)
  - Policy is live and accessible
  - Includes data collection, AI usage, third-party services
  - Links in App Store Connect and app settings

- [ ] **Terms of Service URL**
  - URL: `https://nuzzle.app/terms` (or your URL)
  - Terms are live and accessible
  - Links in App Store Connect and subscription view

### Medical Disclaimers

- [ ] **AI Features Disclaimer**
  - Disclaimer shown on Predictions screen
  - Disclaimer shown on Cry Insights screen
  - Disclaimer shown on AI Assistant screen
  - Text: "Nuzzle is not a medical device and does not provide medical advice. Always consult your pediatrician for medical guidance."

- [ ] **App Review Notes**
  - Include disclaimer in review notes
  - Clarify AI features are informational only

## Marketing Assets

### App Icon

- [ ] **1024x1024 PNG**
  - No alpha channel
  - No transparency
  - Sharp at all sizes
  - Matches app design

### Screenshots

Required sizes (at least one set):

- [ ] **iPhone 6.5" Display (iPhone 14 Pro Max)**
  - Light mode screenshots
  - Dark mode screenshots (optional but recommended)
  - Show key features:
    - Home screen with timeline
    - Event logging form
    - History view
    - Settings/Pro subscription

- [ ] **iPhone 5.5" Display (iPhone 8 Plus)**
  - Light mode screenshots

- [ ] **iPad Pro 12.9"** (if iPad supported)
  - Light mode screenshots

### App Preview Video (Optional)

- [ ] **30-second video**
  - Shows app in action
  - Highlights key features
  - Professional voiceover (optional)
  - Auto-plays in App Store

### Metadata

- [ ] **App Name** (30 characters max)
  - "Nuzzle Baby Tracker"

- [ ] **Subtitle** (30 characters max)
  - "AI-powered feed & sleep log"

- [ ] **Description** (4000 characters max)
  - See `APP_STORE_METADATA.md` for template
  - Highlights key features
  - Includes medical disclaimer

- [ ] **Keywords** (100 characters max, comma-separated)
  - "baby tracker,newborn log,feeding timer,sleep tracker,diaper log"

- [ ] **Promotional Text** (170 characters, editable after release)
  - "Track feeding, sleep & diapers in 2 taps. Get AI nap predictions. Sync with partner. Perfect for sleep-deprived parents. 🍼✨"

- [ ] **Support URL**
  - `https://nuzzle.app/support` (or your URL)

- [ ] **Marketing URL**
  - `https://nuzzle.app` (or your URL)

- [ ] **Privacy Policy URL**
  - `https://nestling.app/privacy` (or your URL)

- [ ] **Age Rating**
  - 4+ (No Objectionable Content)

## App Store Connect Setup

### App Information

- [ ] **App Created**
  - App record exists in App Store Connect
  - Bundle ID matches
  - Name matches

- [ ] **Pricing & Availability**
  - Price: Free
  - Available in all countries (or selected regions)
  - Subscription products configured (see `APP_STORE_CONNECT_SETUP.md`)

- [ ] **App Privacy**
  - Privacy questionnaire completed
  - Data types listed correctly
  - Tracking disclosure accurate
  - Data linked to user: Yes (for sync)

### Subscriptions

- [ ] **Subscription Group Created**
  - Group name: "Nuzzle Pro"

- [ ] **Products Created**
  - `com.nestling.pro.monthly` ($4.99/month)
  - `com.nestling.pro.yearly` ($39.99/year)

- [ ] **Products Ready for Sale**
  - Status: "Ready to Submit" or "Approved"
  - Localized descriptions added
  - Pricing configured

### Build Upload

- [ ] **Build Uploaded**
  - Build uploaded via Xcode
  - Build appears in App Store Connect
  - Build processing complete (wait ~10-30 minutes)

- [ ] **Build Selected**
  - Latest build selected for submission
  - Build shows "Ready for Review"

## Review Notes

### App Review Information

Include in review notes:

```
App Overview:
Nuzzle helps parents track baby care activities (feeding, sleep, diapers) with AI-powered insights.

Key Points:
- Not a medical device; all features are informational only
- AI features are clearly marked as non-medical advice
- Subscription is optional; core features are free
- Privacy policy: [URL]
- Support: support@nuzzle.app

Test Account:
- Email: test@nuzzle.app
- Password: [provided separately]

Notes:
- AI predictions require 7+ days of data for accuracy
- Sync requires internet connection
- TestFlight build available for testing
```

## Submission Checklist

Before clicking "Submit for Review":

- [ ] All screenshots uploaded
- [ ] All metadata filled in
- [ ] Privacy policy URL working
- [ ] Support URL working
- [ ] Test account credentials provided
- [ ] Review notes complete
- [ ] Build selected and ready
- [ ] Subscription products ready
- [ ] Age rating set
- [ ] Export compliance handled

## Post-Submission

### First 24 Hours

- [ ] Monitor App Store Connect for review status
- [ ] Respond to review team questions within 24 hours
- [ ] Fix any critical issues immediately

### Common Rejection Reasons

Be prepared for:

- **Privacy Policy Missing/Inaccessible**
  - Fix: Ensure URL is live and accessible

- **Medical Claims**
  - Fix: Clarify in review notes that AI is informational only

- **Subscription Issues**
  - Fix: Test subscription flow thoroughly in sandbox

- [ ] **Data Privacy Answers**
  - Fix: Ensure privacy questionnaire is accurate

### Approval

After approval:

- [ ] Set release timing (manual or automatic)
- [ ] Prepare marketing materials
- [ ] Notify beta testers
- [ ] Monitor crash reports
- [ ] Respond to reviews

