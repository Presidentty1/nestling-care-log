# App Store Review Notes - Nuzzle iOS App

## App Information
- **App Name**: Nuzzle
- **Bundle ID**: com.nestling.Nestling
- **Version**: 1.0
- **Primary Category**: Health & Fitness
- **Secondary Category**: Lifestyle

## Reviewer's Testing Guide

### Critical Path to Test (5 minutes)
1. **Launch App** → Skip authentication → Paywall → Continue with free tracking
2. **Add Baby** → Quick log: Feed (4oz breastmilk) → Diaper (wet) → Sleep (30 min)
3. **View Timeline** → Verify events display with correct colors/icons
4. **Settings** → Privacy & Data → View Privacy Policy and Terms of Use in-app
5. **Labs** → Cry Insights → Verify beta disclaimers and opt-in AI data sharing

### What to Verify
- ✅ **Onboarding completes** without crashing
- ✅ **Event logging works** and saves data
- ✅ **Paywall loads** StoreKit products with correct pricing
- ✅ **Legal documents** open in-app (not external links)
- ✅ **AI features** have clear disclaimers and are opt-in
- ✅ **No medical claims** - all AI suggestions clearly labeled as "not medical advice"

## In-App Purchase Information

### Products
- **com.nestling.pro.monthly**: $5.99/month - Unlimited AI features, advanced analytics
- **com.nestling.pro.yearly**: $39.99/year - Same features with annual discount, includes 7-day free trial

### IAP Compliance Notes
- ✅ **StoreKit 2**: Uses modern StoreKit 2 for reliable purchase handling
- ✅ **Dynamic Pricing**: All prices use `Product.displayPrice` (no hardcoding)
- ✅ **Clear Terms**: 7-day free trial clearly communicated
- ✅ **Restore Purchases**: Working restore flow in Settings
- ✅ **No Auto-Renewal Tricks**: Standard subscription terms

## AI Features & Medical Disclaimers

### AI Capabilities
- **Nap Predictions**: Age-based wake window calculations
- **AI Assistant**: Answers parenting questions using baby's logged patterns
- **Cry Analysis**: Analyzes cry patterns (beta feature, on-device processing)

### Compliance Statements Present
- ✅ **"Not Medical Advice"**: Every AI feature includes clear disclaimers
- ✅ **"Experimental"**: Cry analysis labeled as "beta" and "experimental"
- ✅ **Opt-In Only**: AI data sharing defaults to OFF, requires explicit consent
- ✅ **No Medical Claims**: All suggestions framed as "possibilities" not diagnoses

### Example Disclaimers in App
```
"These AI features suggest patterns and possibilities.
They don't replace medical care or professional advice."

"This is an experimental tool and not a medical device.
If you're worried about your baby's health, contact a pediatric professional."
```

## Privacy & Data Handling

### Data Collection
- **Required**: Baby care events (feeds, sleep, diapers) stored locally
- **Optional**: AI features require opt-in data sharing
- **Never Sold**: No advertising, no data brokers
- **Encrypted**: All data encrypted in transit and at rest

### Privacy Policy Highlights
- ✅ **No Location Tracking**: App doesn't request location permissions
- ✅ **No Third-Party Sharing**: Data stays within Supabase (EU region)
- ✅ **Data Deletion**: Complete account deletion removes all data
- ✅ **Children's Privacy**: Designed for parents, no direct child data collection

## App Store Guidelines Compliance

### 5.1.1 - Legal/Regulatory Information
- ✅ **Medical Disclaimers**: All AI features clearly marked as non-medical
- ✅ **No FDA Claims**: No references to FDA approval or medical device status
- ✅ **Age Appropriate**: Designed for adults tracking their babies

### 3.1.1 - In-App Purchase Rules
- ✅ **Clear IAP Terms**: Subscription details clearly communicated
- ✅ **No Hidden Costs**: Free trial and pricing transparent
- ✅ **Working Restore**: Restore purchases function properly

### 2.1 - App Completeness
- ✅ **Fully Functional**: All advertised features work
- ✅ **No Placeholder Content**: No "coming soon" in live features
- ✅ **Stable Build**: Tested on multiple iOS versions

### 4.1 - Copycats
- ✅ **Original Content**: Unique baby tracking approach with AI insights
- ✅ **No IP Violations**: Original design and functionality

## Common Review Rejection Scenarios (How We Avoided Them)

### ❌ Medical App Rejections
**Prevention**: Clear "not medical advice" disclaimers throughout AI features

### ❌ IAP Implementation Issues
**Prevention**: StoreKit 2 with proper error handling and restore purchases

### ❌ Privacy Policy Issues
**Prevention**: Comprehensive privacy policy accessible in-app, no external links

### ❌ Unverified Claims
**Prevention**: Removed all accuracy percentages and user counts from marketing

### ❌ Incomplete App
**Prevention**: Fully functional MVP with all core features working

## Testing Instructions for Reviewers

### Step-by-Step Test Flow
1. **Launch** → Accept any permissions → Skip auth
2. **Paywall** → Verify products load → Continue free
3. **Add Baby** → Name: "Test Baby", DOB: yesterday
4. **Log Events** → Feed: 4oz, Diaper: wet, Sleep: 45 min
5. **Check Timeline** → All events display correctly
6. **Settings** → Privacy Policy opens in-app
7. **Labs** → Cry Insights shows beta disclaimers

### Expected Behavior
- No crashes during normal usage
- All buttons respond appropriately
- Data saves and displays correctly
- Legal documents load in-app
- AI features require opt-in consent

## Support Contact
**Email**: support@nuzzle.app (configured in app)
**Response Time**: Within 24 hours during review period

## Version Notes
- **Build**: First public release
- **Previous Versions**: Internal testing only
- **Major Changes**: Initial release with AI baby care features

---
*Review Notes Version: 1.0 | December 12, 2024*