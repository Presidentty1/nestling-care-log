# Marketing Claims Documentation

This document tracks all marketing claims made in the app and provides evidence/sources for each claim.

## Status: Draft - Requires Validation

⚠️ **IMPORTANT:** All claims must be verified before app store submission to comply with FTC guidelines and Apple App Store Review Guidelines.

---

## Claims Requiring Validation

### 1. "Get 2 More Hours of Sleep"

**Status:** ⚠️ UNVERIFIED - Needs user study data

**Current usage:**

- AuthView.swift (line 41)
- WelcomeView.swift (line 15)
- Marketing materials

**Recommended actions:**

- **Option A:** Conduct user study with 100+ parents tracking for 30 days
  - Measure: Average sleep duration before/after using app
  - Target: ≥2 hour improvement for 50%+ of users
- **Option B:** Soften claim to: "Track better, sleep better" or "Trusted by 1,200+ parents"
- **Option C:** Add disclaimer: "Based on internal testing with early users"

---

### 2. "87% accurate nap predictions"

**Status:** ⚠️ UNVERIFIED - Needs ML model validation

**Current usage:**

- AuthView.swift (line 65)
- Marketing materials

**Recommended actions:**

- **Option A:** Run ML model validation:
  - Test set: 1,000+ nap predictions across 100+ babies
  - Calculate: Predictions within ±15 min of actual nap time
  - Document: Model version, training data size, validation methodology
- **Option B:** Soften claim to: "Highly accurate nap predictions" or remove percentage
- **Option C:** Add qualifier: "Up to 87% accurate for babies 0-6 months"

---

### 3. "4.8 • 1,200+ parents"

**Status:** ⚠️ UNVERIFIED - Requires App Store data

**Current usage:**

- ProSubscriptionView.swift (line 199)
- Social proof elements

**Verification needed:**

- **4.8 rating:** Must match actual App Store rating (update monthly)
- **1,200+ parents:** Must match actual download/user count
  - Source: App Store Connect analytics
  - Update threshold: When user count changes significantly (e.g., 1,500, 2,000)

**Recommended actions:**

- If TestFlight only: Change to "Trusted by beta testers"
- If post-launch: Pull actual metrics from App Store Connect weekly
- Add date of measurement: "4.8 rating (as of Dec 2025)"

---

### 4. "Track baby care in 2 taps"

**Status:** ✅ VERIFIABLE

**How to verify:**

1. Open app to Home screen
2. Tap Quick Action button (Feed/Sleep/Diaper/Tummy)
3. Sheet opens with defaults pre-filled
4. Tap "Save"
   = **2 taps total ✓**

**Evidence:** User flow analysis, can be demonstrated in screenshots

---

### 5. "AI predicts naps"

**Status:** ✅ IMPLEMENTED

**How it works:**

- Free tier: Age-based predictions from `NapPredictorService.swift`
- Pro tier: Pattern-based predictions using recent logs + wake windows
- Algorithm: Combines age-appropriate wake windows with individual baby's patterns

**Evidence:** Code implementation in `PredictionsEngine.swift`

---

### 6. "Sync with partner"

**Status:** ✅ IMPLEMENTED (via Supabase/CloudKit)

**How it works:**

- Real-time sync via Supabase realtime subscriptions
- Multi-caregiver support in `BackupService.swift`
- Invite caregivers via share sheet

**Evidence:** Code implementation, can be demonstrated

---

### 7. "Works offline • Privacy-first"

**Status:** ✅ IMPLEMENTED

**How it works:**

- IndexedDB/CoreData local-first architecture
- All data stored locally first
- Sync happens in background when online
- AI data sharing is opt-in

**Evidence:**

- Code: `CoreDataStore.swift`, `BackupService.swift`
- Privacy: `PrivacyInfo.xcprivacy`, `PrivacyManager.swift`

---

### 8. "Setup < 60s"

**Status:** ✅ VERIFIABLE

**How to verify:**

1. Fresh install → Welcome screen
2. Tap "Let's Go!"
3. Fill in baby name + DOB (10-15s)
4. Select goal (5s)
5. Reach Home screen

**Target:** ≤60 seconds (currently achieves ~30-45s)

---

## Compliance Checklist

Before app store submission:

- [ ] Validate or soften "Get 2 More Hours of Sleep" claim
- [ ] Validate or remove "87% accurate nap predictions" percentage
- [ ] Verify "4.8 • 1,200+ parents" against actual App Store data
- [ ] Ensure all product pricing matches StoreKit config ($5.99/mo, $39.99/yr)
- [ ] Add "Results may vary" disclaimer to outcome-based claims
- [ ] Review all marketing materials for consistency
- [ ] Add non-medical disclaimer to AI features

## Recommended Disclaimers

### For AI Features (Nap Predictions, Cry Insights, Daily Insights)

> "Nuzzle provides informational suggestions based on patterns in your baby's data. This is not medical advice. Always consult your pediatrician for health concerns."

### For Outcome Claims ("Get 2 More Hours of Sleep")

> "Results may vary. Based on internal testing with early users. Individual outcomes depend on many factors."

### For Accuracy Claims ("87% accurate")

> "Accuracy varies by baby age, logging consistency, and other factors. Predictions improve with more data."

---

## Update Schedule

- **Monthly:** Review App Store ratings and user count
- **Quarterly:** Validate prediction accuracy with ML team
- **Annually:** Conduct user outcome survey

Last updated: December 6, 2025
