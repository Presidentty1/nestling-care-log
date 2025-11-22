# Pre-Launch Checklist for App Store Submission

## Critical Items Before Submission

### 1. ✅ Code Rebranding (Complete)
- [x] Swift code renamed (NestlingApp → NuzzleApp)
- [x] User-facing strings updated
- [x] Directories renamed
- [x] Module imports updated
- [x] Info.plist privacy descriptions updated
- [x] APP_STORE_METADATA.md updated
- [x] APP_STORE_CHECKLIST.md updated

### 2. ✅ Privacy Usage Descriptions (Complete)
- [x] **NSMicrophoneUsageDescription**: Updated to "Nuzzle"
- [x] **NSPhotoLibraryUsageDescription**: Updated to "Nuzzle"  
- [x] **NSCameraUsageDescription**: Updated to "Nuzzle"
- [x] **NSFaceIDUsageDescription**: Updated to "Nuzzle"
- [x] **NSUserNotificationsUsageDescription**: Updated to "Nuzzle"

### 3. ✅ Privacy Manifest (Complete)
- [x] **PrivacyInfo.xcprivacy file created**
  - Location: `ios/Nuzzle/Nestling/PrivacyInfo.xcprivacy`
  - Declares UserDefaults API usage (CA92.1)
  - Declares FileTimestamp API usage (C617.1)
  - Declares collected data types (email, health, user ID, photos)
  - No tracking declared
- [ ] **Add to Xcode project** (manual step required)

### 4. 📱 App Store Connect Setup

#### App Information
- [ ] **Create app record** with bundle ID: `com.nestling.Nestling` (preserved per plan)
- [ ] **App Name**: "Nuzzle" (30 chars max)
- [ ] **Subtitle**: "AI-powered feed & sleep log" (30 chars max)
- [ ] **Primary Language**: English (US)

#### Metadata (Update from APP_STORE_METADATA.md)
- [ ] **Description**: Update all "Nestling" → "Nuzzle" references
- [ ] **Keywords**: baby tracker,newborn log,feeding timer,sleep tracker,diaper log
- [ ] **Support URL**: `https://nuzzle.app/support` (verify domain is live)
- [ ] **Marketing URL**: `https://nuzzle.app` (verify domain is live)
- [ ] **Privacy Policy URL**: `https://nuzzle.app/privacy` (verify domain is live)
- [ ] **Support Email**: `support@nuzzle.app` (verify email is configured)

#### Screenshots (Required)
- [ ] **iPhone 6.5" Display** (iPhone 14 Pro Max / 15 Pro Max)
  - 5 screenshots minimum
  - Show: Home screen, Event logging, History, Settings, Pro features
- [ ] **iPhone 5.5" Display** (iPhone 8 Plus)
  - 5 screenshots minimum
- [ ] **iPad Pro 12.9"** (if iPad supported)
  - 5 screenshots minimum

#### App Preview Video (Optional but Recommended)
- [ ] 30-second video showing key features
- [ ] Auto-plays in App Store

### 5. 🔐 Subscriptions Setup

#### App Store Connect
- [ ] **Subscription Group**: "Nuzzle Pro" (already updated in storekit)
- [ ] **Monthly Product**: `com.nestling.pro.monthly` ($5.99/month)
  - Status: "Ready to Submit"
  - Localized descriptions added
- [ ] **Yearly Product**: `com.nestling.pro.yearly` ($39.99/year)
  - Status: "Ready to Submit"
  - 7-day free trial configured
  - Localized descriptions added

#### StoreKit Configuration
- [x] Storekit file renamed to Nuzzle.storekit
- [x] Product display names updated to "Nuzzle Pro"
- [x] Product IDs preserved (for continuity)

### 6. 📋 Legal & Compliance

#### Privacy Policy
- [ ] **Privacy Policy** live at `https://nuzzle.app/privacy`
  - Must include: Data collection, AI usage, third-party services
  - Must comply with App Store guidelines
  - Must be accessible without login

#### Terms of Service
- [ ] **Terms of Service** live at `https://nuzzle.app/terms`
  - Must be accessible
  - Links in App Store Connect and subscription view

#### Medical Disclaimers
- [x] AI features have disclaimers in app
- [ ] **App Review Notes** include disclaimer:
  - "Nuzzle is not a medical device and does not provide medical advice. All AI features are informational only."

#### Export Compliance
- [ ] **ITSAppUsesNonExemptEncryption** set to `NO` in Info.plist
  - (Unless using custom encryption, then submit documentation)

### 7. 🏗️ Build Configuration

#### Version & Build Numbers
- [ ] **Version**: Set to `1.0.0` (CFBundleShortVersionString)
- [ ] **Build**: Set to `1` (CFBundleVersion)
  - Increment for each App Store upload

#### Signing & Capabilities
- [ ] **Distribution Certificate**: Valid and not expired
- [ ] **Provisioning Profile**: Up to date for App Store distribution
- [ ] **App Groups**: `group.com.nestling.Nestling` configured (preserved per plan)
- [ ] **Push Notifications**: Configured (if used)
- [ ] **Background Modes**: Configured (if used)

#### App Icon
- [ ] **1024x1024 PNG** app icon
  - No alpha channel
  - No transparency
  - Sharp at all sizes
  - Matches "Nuzzle" branding

### 8. 🧪 Testing

#### Pre-Submission Testing
- [ ] **TestFlight Beta** uploaded and tested
- [ ] **Subscription flow** tested in sandbox
  - Monthly purchase works
  - Yearly purchase with trial works
  - Restore purchases works
  - Paywall displays correctly
- [ ] **Core features** tested:
  - App launches successfully
  - Onboarding completes
  - Event logging works
  - Timeline displays correctly
  - Settings accessible
- [ ] **Offline mode** tested
- [ ] **Multi-device sync** tested (if applicable)

#### Device Testing
- [ ] Tested on iPhone (latest iOS)
- [ ] Tested on iPad (if supported)
- [ ] Tested with VoiceOver (accessibility)
- [ ] Tested with Dynamic Type (accessibility)

### 9. 📝 App Review Information

#### Review Notes Template
```
App Overview:
Nuzzle helps parents track baby care activities (feeding, sleep, diapers) with AI-powered insights.

Key Points:
- Not a medical device; all features are informational only
- AI features are clearly marked as non-medical advice
- Subscription is optional; core features are free
- Privacy policy: https://nuzzle.app/privacy
- Support: support@nuzzle.app

Test Account (if required):
- Email: [test account email]
- Password: [provided separately]

Notes:
- AI predictions require 7+ days of data for accuracy
- Sync requires internet connection
- TestFlight build available for testing
```

### 10. 🔍 Final Verification

#### Code Review
- [ ] No "Nestling" references in user-facing code
- [ ] All "Nestling Pro" → "Nuzzle Pro" updated
- [ ] All URLs updated to nuzzle.app (or TODOs added)
- [ ] All email addresses updated to @nuzzle.app (or TODOs added)

#### Documentation
- [ ] APP_STORE_METADATA.md updated with "Nuzzle"
- [ ] APP_STORE_CHECKLIST.md updated with "Nuzzle"
- [ ] All docs/ files reviewed for "Nestling" references

#### Xcode Project
- [ ] Scheme name: "Nuzzle" (not "Nestling")
- [ ] Target names: "Nuzzle", "NuzzleTests", "NuzzleUITests"
- [ ] Display name shows "Nuzzle" in app
- [ ] Build succeeds without errors

### 11. 📤 Submission Steps

1. **Archive Build**
   - Product → Archive in Xcode
   - Wait for processing

2. **Upload to App Store Connect**
   - Window → Organizer
   - Select archive
   - Distribute App → App Store Connect
   - Upload (takes 10-30 minutes)

3. **Select Build in App Store Connect**
   - Wait for processing to complete
   - Select build for submission

4. **Complete App Store Listing**
   - All metadata filled
   - Screenshots uploaded
   - Privacy policy URL verified
   - Support URL verified

5. **Submit for Review**
   - Review all information
   - Add review notes
   - Submit

### 12. ⏱️ Post-Submission

#### First 24 Hours
- [ ] Monitor App Store Connect for review status
- [ ] Respond to review team questions within 24 hours
- [ ] Fix any critical issues immediately

#### Common Rejection Reasons to Avoid
- **Privacy Policy Missing/Inaccessible** - Ensure URL is live
- **Medical Claims** - Clarify AI is informational only
- **Subscription Issues** - Test thoroughly in sandbox
- **Missing Privacy Manifest** - Add PrivacyInfo.xcprivacy
- **Incorrect Privacy Usage Descriptions** - Update all "Nestling" → "Nuzzle"

## Priority Actions

### 🔴 Critical (Must Do Before Submission)
1. Update Info.plist privacy descriptions ("Nestling" → "Nuzzle")
2. Create PrivacyInfo.xcprivacy file
3. Update APP_STORE_METADATA.md with "Nuzzle" branding
4. Verify all URLs (privacy policy, support, terms) are live
5. Set version and build numbers
6. Upload screenshots to App Store Connect

### 🟡 Important (Should Do)
1. Update APP_STORE_CHECKLIST.md
2. Test subscription flow in sandbox
3. TestFlight beta testing
4. Verify app icon is correct
5. Complete App Store Connect metadata

### 🟢 Nice to Have
1. App preview video
2. Additional screenshot sets
3. Localized descriptions
4. Marketing materials

## Estimated Timeline

- **Code Updates**: 1-2 hours (privacy descriptions, metadata files)
- **Privacy Manifest**: 1 hour (create and configure)
- **Screenshots**: 2-4 hours (capture and prepare)
- **App Store Connect Setup**: 2-3 hours (metadata, subscriptions)
- **Testing**: 4-8 hours (comprehensive testing)
- **Submission**: 30 minutes (upload and submit)

**Total: ~12-20 hours of work before ready to submit**
