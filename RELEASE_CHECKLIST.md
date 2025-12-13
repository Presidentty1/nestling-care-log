# Release Checklist - Nuzzle iOS App

## Pre-Release Setup (15 minutes)

### 🔧 Development Environment
- [ ] Xcode 15+ installed and updated
- [ ] iOS Simulator set up (iPhone 15)
- [ ] Apple Developer account access
- [ ] App Store Connect access with Admin role

### 📱 App Store Connect
- [ ] App record created with bundle ID `com.nestling.Nestling`
- [ ] IAP products configured:
  - [ ] `com.nestling.pro.monthly` ($5.99/month)
  - [ ] `com.nestling.pro.yearly` ($39.99/year with 7-day free trial)
- [ ] App Store Connect API key generated (for Fastlane)
- [ ] Internal TestFlight testers added

### 🔐 Fastlane Configuration
- [ ] Copy `ios/fastlane/.env.example` to `ios/fastlane/.env`
- [ ] Fill in required values:
  - [ ] `APPLE_ID` - Your Apple ID email
  - [ ] `TEAM_ID` - Apple Developer Team ID (10 characters)
  - [ ] `APP_STORE_CONNECT_API_KEY_ID` - API Key ID
  - [ ] `APP_STORE_CONNECT_API_KEY_ISSUER_ID` - Issuer ID
  - [ ] `APP_STORE_CONNECT_API_KEY_PATH` - Path to .p8 file

### 📄 Legal Documents
- [ ] Update `ios/Nuzzle/Nestling/Resources/Legal/privacy_policy.html`:
  - [ ] Replace `[DATE]` with actual date (e.g., "December 12, 2024")
  - [ ] Replace `[REGION]` with "United States"
  - [ ] Remove template notes at bottom
- [ ] Update `ios/Nuzzle/Nestling/Resources/Legal/terms_of_use.html`:
  - [ ] Replace `[DATE]` with actual date
  - [ ] Replace `[JURISDICTION]` with legal jurisdiction (e.g., "State of California, USA")
  - [ ] Replace `[ARBITRATION/MEDIATION/COURTS]` with "binding arbitration"
  - [ ] Remove template notes at bottom

## Build & Test (20 minutes)

### 🏗️ Local Testing
- [ ] Debug build succeeds:
  ```bash
  xcodebuild -project ios/Nuzzle/Nestling.xcodeproj -scheme Nuzzle -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 15' build
  ```
- [ ] Release build succeeds:
  ```bash
  xcodebuild -project ios/Nuzzle/Nestling.xcodeproj -scheme Nuzzle -configuration Release -destination 'platform=iOS Simulator,name=iPhone 15' build
  ```

### 🧪 Functional Testing
- [ ] **Onboarding Flow**:
  - [ ] Skip authentication → Paywall → Main app
  - [ ] Auth flow → Email/password signup → Paywall
- [ ] **Core Features**:
  - [ ] Add feed, diaper, sleep events
  - [ ] View timeline and history
  - [ ] Settings access
- [ ] **Paywall & IAP**:
  - [ ] Products load correctly with StoreKit prices
  - [ ] Trial flow (7 days free)
  - [ ] Restore purchases works
- [ ] **Legal & Privacy**:
  - [ ] Privacy Policy opens in-app
  - [ ] Terms of Use opens in-app
  - [ ] AI data sharing defaults to OFF

### 🎨 UI/UX Verification
- [ ] No hardcoded prices visible
- [ ] No unverified marketing claims
- [ ] AI features properly labeled as experimental/beta
- [ ] Medical disclaimers present where needed
- [ ] Touch targets meet accessibility standards

## TestFlight Release (10 minutes)

### 🚀 Upload Build
- [ ] Run Fastlane beta:
  ```bash
  cd ios/fastlane
  fastlane beta
  ```
- [ ] Verify build uploads successfully to TestFlight
- [ ] Check TestFlight for processing status

### 👥 Internal Testing
- [ ] Send TestFlight invitation to internal testers
- [ ] Create testing instructions (see BETA_TEST_SCRIPT.md)
- [ ] Set up feedback collection process

## App Store Submission Preparation (30 minutes)

### 📊 App Store Metadata
- [ ] App name: "Nuzzle"
- [ ] Subtitle: "Smart Baby Care Tracker"
- [ ] Description: Write compelling description highlighting AI features and ease of use
- [ ] Keywords: "baby, tracker, care, feeding, sleep, diaper, parenting"
- [ ] Support URL: Your website or support page
- [ ] Marketing URL: Your website (optional)

### 📸 Screenshots (5 screenshots required)
- [ ] Screenshot 1: Onboarding/Home screen
- [ ] Screenshot 2: Adding an event (quick log)
- [ ] Screenshot 3: Timeline/history view
- [ ] Screenshot 4: AI insights or predictions
- [ ] Screenshot 5: Settings or family sharing

### 📝 Review Information
- [ ] Review notes: "Please test the complete onboarding flow, basic event logging, and paywall. AI features are clearly marked as experimental and not medical advice."
- [ ] Demo account: If needed for testing
- [ ] Additional testing instructions from APP_REVIEW_NOTES.md

### 💰 In-App Purchases
- [ ] Verify IAP products match StoreKit configuration
- [ ] Review pricing and trial terms
- [ ] Confirm no unverified claims in IAP descriptions

## Final Checks

### ✅ Compliance Verification
- [ ] No medical claims or FDA references
- [ ] AI features clearly marked as suggestions only
- [ ] Privacy policy and terms accessible in-app
- [ ] IAP terms are clear and accurate
- [ ] No hardcoded prices in user-facing text

### ✅ Technical Verification
- [ ] Bundle ID matches App Store Connect: `com.nestling.Nestling`
- [ ] Version number incremented appropriately
- [ ] Build number incremented
- [ ] No console errors in release build
- [ ] Network calls handle offline gracefully

### ✅ Content Verification
- [ ] All text is professional and appropriate
- [ ] No placeholder text remains
- [ ] Icons and images load correctly
- [ ] App icon meets guidelines (1024x1024, no transparency)

## Post-Release

### 📈 Monitoring
- [ ] Monitor TestFlight crash reports
- [ ] Review user feedback from beta testers
- [ ] Monitor App Store Connect analytics

### 🔄 Iteration
- [ ] Plan next release based on beta feedback
- [ ] Update marketing materials with real user metrics (once available)
- [ ] Consider A/B testing for paywall optimization

## Emergency Contacts
- **App Store Connect Issues**: Apple Developer Support
- **Build Issues**: Xcode and Fastlane documentation
- **Code Issues**: Check git history and commit messages

---
*Last Updated: December 12, 2024*