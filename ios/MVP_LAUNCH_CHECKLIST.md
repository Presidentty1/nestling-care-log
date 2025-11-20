# Nestling iOS MVP - Complete Launch Checklist

Master checklist for launching Nestling to the App Store. Check off items as you complete them.

## 🔧 Setup & Configuration

### Supabase Integration
- [ ] Add Supabase Swift SDK via Xcode (File → Add Package Dependencies)
- [ ] Package URL: `https://github.com/supabase/supabase-swift`
- [ ] Uncomment `import Supabase` in `SupabaseClient.swift`
- [ ] Uncomment client initialization in `SupabaseClientProvider`
- [ ] Update `Secrets.swift` with actual Supabase URL and anon key
- [ ] Uncomment Supabase code in `RemoteDataStore.swift`
- [ ] Uncomment Supabase code in `AuthViewModel.swift`
- [ ] Uncomment Supabase code in `AIAssistantService.swift`
- [ ] Test authentication flow
- [ ] Test data sync

### Project Configuration
- [ ] Verify Bundle ID: `com.nestling.Nestling`
- [ ] Verify Version: 1.0.0
- [ ] Verify Build: 1
- [ ] Verify Deployment Target: iOS 17.0+
- [ ] All Info.plist keys are set
- [ ] Signing certificates are valid

## 💰 Monetization Setup

### App Store Connect
- [ ] Create app record in App Store Connect
- [ ] Create subscription group: "Nestling Pro"
- [ ] Create product: `com.nestling.pro.monthly` ($4.99/month)
- [ ] Create product: `com.nestling.pro.yearly` ($39.99/year)
- [ ] Products show "Ready to Submit" status
- [ ] Test subscription flow in sandbox

### StoreKit Testing
- [ ] Open `Nestling.storekit` in Xcode
- [ ] Configure in Edit Scheme → Run → Options
- [ ] Test purchase flow locally
- [ ] Test restore purchases
- [ ] Test subscription expiration

### Feature Gating
- [ ] Test adding 2nd baby (should show paywall)
- [ ] Test history beyond 7 days (should show paywall)
- [ ] Verify Pro features are gated
- [ ] Test subscription unlocks features

## 🎨 UI/UX Verification

### Dark Mode
- [ ] Test app launch in dark mode (no white flash)
- [ ] All screens look good in dark mode
- [ ] Text is readable in dark mode
- [ ] Event colors visible in dark mode

### One-Handed Use
- [ ] Quick actions reachable one-handed
- [ ] Timer buttons reachable one-handed
- [ ] All buttons meet 44x44pt minimum
- [ ] Bottom sheets easy to dismiss

### Accessibility
- [ ] VoiceOver tested and working
- [ ] Dynamic Type tested (largest size)
- [ ] Reduce Motion respected
- [ ] All buttons have accessibility labels

### Empty States
- [ ] Empty history shows helpful message
- [ ] Empty baby list shows "Add Baby" prominently
- [ ] Empty search shows suggestions

## 🧪 Testing

### Functional Testing
- [ ] Sign up → Onboarding → Home flow works
- [ ] Log all event types (Feed, Sleep, Diaper, Tummy)
- [ ] Events appear in timeline immediately
- [ ] Edit event works
- [ ] Delete event works (with undo)
- [ ] Sync across devices works
- [ ] Offline mode works
- [ ] Data migration works (local → cloud)

### Subscription Testing
- [ ] Purchase monthly subscription (sandbox)
- [ ] Purchase yearly subscription (sandbox)
- [ ] Restore purchases works
- [ ] Feature gating enforced correctly
- [ ] Subscription status updates correctly

### Performance Testing
- [ ] App launches in < 2 seconds
- [ ] Event logging takes < 500ms
- [ ] Timeline loads in < 1 second (100 events)
- [ ] No memory leaks detected
- [ ] Smooth scrolling (no stuttering)
- [ ] Test on iPhone SE (smallest screen)
- [ ] Test on iPhone Pro Max (largest screen)

### Edge Cases
- [ ] App launch with no internet
- [ ] Launch with corrupted Core Data
- [ ] Delete all babies
- [ ] Delete all events
- [ ] Wrong password handling
- [ ] Network timeout handling
- [ ] Large dataset (1000+ events)

## 📱 App Store Submission

### Assets
- [ ] App icon (1024x1024 PNG, no alpha)
- [ ] Screenshots for all required sizes
  - [ ] iPhone 6.5" (light mode)
  - [ ] iPhone 6.5" (dark mode)
  - [ ] iPhone 5.5"
  - [ ] iPad 12.9" (if supported)
- [ ] App preview video (optional)

### Metadata
- [ ] App name: "Nestling Baby Tracker"
- [ ] Subtitle: "AI-powered feed & sleep log"
- [ ] Description (4000 chars max)
- [ ] Keywords (100 chars max)
- [ ] Promotional text (170 chars)
- [ ] Support URL: `https://nestling.app/support`
- [ ] Marketing URL: `https://nestling.app`
- [ ] Privacy Policy URL: `https://nestling.app/privacy`
- [ ] Terms of Service URL: `https://nestling.app/terms`

### Legal & Compliance
- [ ] Privacy Policy hosted and accessible
- [ ] Terms of Service hosted and accessible
- [ ] App Privacy questionnaire completed
- [ ] Medical disclaimers on AI screens
- [ ] Review notes prepared with test account

### Build & Upload
- [ ] Build for Release configuration
- [ ] Archive build in Xcode
- [ ] Upload to App Store Connect
- [ ] Wait for processing (10-30 minutes)
- [ ] Select build for submission
- [ ] Complete submission information
- [ ] Click "Submit for Review"

## 📊 Post-Submission

### First 24 Hours
- [ ] Monitor App Store Connect for review status
- [ ] Respond to review team questions within 24 hours
- [ ] Fix any critical issues if needed

### First Week
- [ ] Monitor crash reports daily
- [ ] Track user sign-ups
- [ ] Track subscription conversions
- [ ] Respond to App Store reviews
- [ ] Monitor support emails

### Ongoing
- [ ] Weekly metrics review
- [ ] Monthly business review
- [ ] Feature request prioritization
- [ ] Bug fix prioritization
- [ ] Performance optimization

## 🎯 Launch Day

### Pre-Launch (Day Before)
- [ ] Final build tested
- [ ] All metadata finalized
- [ ] Marketing materials ready
- [ ] Support team briefed

### Launch Day
- [ ] App approved in App Store
- [ ] Set release to "Automatically" or "Manually"
- [ ] Announce on social media (if applicable)
- [ ] Notify beta testers
- [ ] Monitor crash reports
- [ ] Monitor reviews

### First 48 Hours
- [ ] Respond to all reviews
- [ ] Monitor crash-free rate
- [ ] Track key metrics
- [ ] Address any critical issues
- [ ] Celebrate! 🎉

## 📋 Documentation Reference

All implementation details are documented in:
- `IMPLEMENTATION_SUMMARY.md` - Complete implementation overview
- `SUPABASE_SETUP.md` - Supabase SDK integration
- `APP_STORE_CONNECT_SETUP.md` - Subscription setup
- `APP_STORE_CHECKLIST.md` - Detailed submission checklist
- `UX_UI_AUDIT_CHECKLIST.md` - UX review checklist
- `PERFORMANCE_QA_GUIDE.md` - Testing guide
- `POST_LAUNCH_MONITORING.md` - Monitoring guide

## ✅ Implementation Status

**Code Implementation**: ~95% Complete
- All infrastructure in place
- All UI components created
- All services structured
- Ready for SDK integration and testing

**Next Critical Steps**:
1. Add Supabase Swift SDK
2. Configure Secrets.swift
3. Test end-to-end
4. Complete App Store Connect setup
5. Submit for review

Good luck with your launch! 🚀

