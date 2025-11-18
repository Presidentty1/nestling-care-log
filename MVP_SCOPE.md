# MVP Scope Definition

This document defines the **P0 features** that must be in the first iOS native release, and the **Phase 2+ features** that exist in the web app but are deferred for later.

---

## P0 MVP Features (iOS & Web v1.0)

These features are **essential** and must be implemented in the native iOS app.

### 1. Authentication & Onboarding
- **Email/Password Sign Up**
  - Auto-confirm email (no verification required for MVP)
  - Profile creation (name, email)
- **Sign In**
  - Email/password login
  - Session persistence
- **Initial Baby Profile Setup**
  - Name, date of birth, sex
  - Optional: due date, feeding style
- **No family invites or multi-caregiver support in MVP**
  - Defer caregiver invitations to Phase 2

**Screens:**
- `Auth.tsx` → Sign Up / Sign In
- `Onboarding.tsx` or `OnboardingSimple.tsx` → Baby profile setup

---

### 2. Home Dashboard (Today View)
- **Timeline of Today's Events**
  - Last feed, last diaper, sleep status
  - Chronological list of all events (swipeable to delete)
- **Summary Chips**
  - "3 feeds today", "4 diapers today", "2h 15m sleep today"
- **Next Nap Prediction Card**
  - Display predicted nap window (e.g., "Next nap in 45 min")
  - Simple, glanceable UI
- **Quick Log Buttons**
  - Floating Action Button (FAB) or bottom quick actions
  - Tap to open log sheets for Feed, Diaper, Sleep

**Screens:**
- `Home.tsx` → Main dashboard
- `FloatingActionButton.tsx` or `FloatingActionButtonRadial.tsx` → Quick actions

---

### 3. Event Logging

#### Feed Logging
- **Type Selection**: Breast, Bottle, Pumping
- **Side (Breast)**: Left, Right, or Both
- **Amount (Bottle/Pumping)**: Numeric input with unit (ml/oz)
- **Timer**: Optional timer for breastfeeding sessions
- **Notes**: Optional text notes
- **Timestamp**: Auto-set to "now" or manual adjustment

**Screens:**
- `FeedForm.tsx` (bottom sheet or modal)

#### Diaper Logging
- **Type**: Wet, Dirty, or Both
- **Optional**: Color, texture (defer to Phase 2 if too complex)
- **Notes**: Optional text notes
- **Timestamp**: Auto-set to "now" or manual adjustment

**Screens:**
- `DiaperForm.tsx` (bottom sheet or modal)

#### Sleep Logging
- **Start/End Time**
  - Timer-based (tap to start, tap to stop)
  - Or manual entry with time pickers
- **Subtype**: Nap or Night Sleep (optional, can defer)
- **Duration Calculation**: Auto-compute from start/end
- **Notes**: Optional text notes

**Screens:**
- `SleepForm.tsx` (bottom sheet or modal)
- `TimerControls.tsx` + `TimerDisplay.tsx` → Active sleep timer

---

### 4. History / Calendar View
- **Day-by-Day Event List**
  - Navigate forward/backward by day
  - Filter by event type (All, Feeds, Diapers, Sleep)
- **Event Details**
  - Tap to view/edit/delete
- **Date Selector**
  - Date strip or calendar picker

**Screens:**
- `History.tsx` → Historical event list
- `DayStrip.tsx` → Date navigation
- `TimelineList.tsx` → Event timeline

---

### 5. Nap Prediction (Next Nap / Wake Window)
- **Display Next Nap Window**
  - "Next nap around 3:00 PM - 3:30 PM"
  - Reasoning: "Typical wake window for age" or "Based on recent patterns"
- **Simple Feedback Buttons**
  - "Too Early", "Just Right", "Too Late"
  - Store feedback for future improvements
- **Medical Disclaimer**
  - "This is guidance based on typical patterns, not medical advice."

**Screens:**
- `NapPredictor.tsx` → Next nap prediction
- `NapPredictionCard.tsx` → Dashboard widget
- `NapFeedbackButtons.tsx` → User feedback

**Backend:**
- `calculate-nap-window` edge function
- `napPredictorService.ts` → Age-based wake windows

---

### 6. AI Assistant (Basic Q&A)
- **Chat Interface**
  - Text input for user questions
  - AI responses using Lovable AI (Gemini)
- **Baby Context**
  - Include baby age, recent events in prompt
  - System prompt: "You are a supportive parenting assistant"
- **Medical Disclaimer**
  - Always visible sticky disclaimer at top
  - "This is not medical advice. Always consult your pediatrician."
- **Quick Question Buttons**
  - "Why is my baby crying?"
  - "How much should they eat?"
  - "Is this sleep pattern normal?"

**Screens:**
- `AIAssistant.tsx` → Chat UI
- `MedicalDisclaimer.tsx` → Disclaimer component
- `QuickQuestions.tsx` → Suggested prompts

**Backend:**
- `ai-assistant` edge function
- `useAIChat.ts` hook

---

### 7. Settings (Minimal)
- **Baby Profile Management**
  - Edit baby name, DOB, sex
  - Switch between babies (if multiple)
- **Account Settings**
  - View profile (name, email)
  - Sign out
- **App Settings**
  - Units (metric/imperial) → defer if time-constrained
  - Theme (light/dark) → defer if time-constrained
- **No caregiver management, no notifications, no privacy settings in MVP**

**Screens:**
- `Settings.tsx` → Main settings hub
- `Settings/ManageBabies.tsx` → Baby profiles

---

### 8. Empty, Loading, Error States
- **Empty States**
  - "No events logged yet. Tap + to log your first feed!"
  - Friendly, encouraging copy
- **Loading States**
  - Skeleton loaders or subtle spinners
  - No jarring jumps when data loads
- **Error States**
  - "Oops, something went wrong. Please try again."
  - Retry buttons where appropriate
  - Calm, supportive tone

**Components:**
- `EmptyState.tsx` → Reusable empty state
- `LoadingSpinner.tsx` / `SkeletonCard.tsx` → Loading UI
- `ErrorState.tsx` → Error handling

---

### 9. Medical Disclaimers
- **AI Assistant**: Always visible sticky disclaimer
- **Nap Predictor**: Small disclaimer above prediction
- **Sleep Training** (if included): Disclaimer on first screen

**Components:**
- `MedicalDisclaimer.tsx` (variants: `ai`, `sleep`, `predictions`)

---

## Phase 2+ Features (Web Only, Not in iOS MVP)

These features exist in the web app but are **deferred** for later iOS releases.

### Analytics & Insights
- `Analytics.tsx` → Feeding/sleep charts
- `Insights.tsx` → Pattern analysis
- `PatternInsights.tsx` → AI-generated insights
- `PatternVisualization.tsx` → Visual charts

**Reason for Deferral**: Complex charting libraries, non-essential for core logging.

---

### Growth Tracking
- `GrowthTracker.tsx` → Weight, length, head circumference
- `GrowthChart.tsx` → WHO percentile curves

**Reason for Deferral**: Requires charting, less frequently used than daily logging.

---

### Health Records & Vaccines
- `HealthRecords.tsx` → Illnesses, doctor visits
- `VaccineScheduleView.tsx` → Vaccine tracking
- `MedicationTracker.tsx` → Baby medication reminders

**Reason for Deferral**: Non-daily feature, can be added after MVP validation.

---

### Milestones
- `Milestones.tsx` → Developmental milestone tracking
- `MilestoneModal.tsx` → Log milestones with photos

**Reason for Deferral**: Nice-to-have, not critical for MVP.

---

### Journal & Photo Gallery
- `Journal.tsx` → Daily journal entries
- `JournalEntry.tsx` → Rich text editor with photos
- `PhotoGallery.tsx` → Photo albums and galleries

**Reason for Deferral**: Media-heavy feature, requires storage management.

---

### Cry Insights (Prototype)
- `CryInsights.tsx` → Cry pattern analysis
- `CryRecorder.tsx` → Audio recording and AI analysis
- `CryAnalysisResult.tsx` → Display cry category

**Reason for Deferral**: Prototype feature, AI accuracy needs improvement.

---

### Sleep Training
- `SleepTraining.tsx` → Sleep training session management
- `NewSleepTrainingSession.tsx` → Create training plans

**Reason for Deferral**: Advanced feature, not essential for basic tracking.

---

### Parent Wellness
- `ParentWellness.tsx` → Parent mood and water intake tracking
- `MoodTracker.tsx` → Daily mood logging
- `WaterIntakeTracker.tsx` → Hydration tracking
- `ParentMedicationTracker.tsx` → Parent medication reminders

**Reason for Deferral**: Focus on baby tracking first, add parent features later.

---

### Multi-Caregiver / Family Sharing
- `CaregiverManagement.tsx` → Invite caregivers
- `AcceptInvite.tsx` → Accept family invites
- `Settings/ManageCaregivers.tsx` → Manage family members
- `ActivityFeed.tsx` → Family activity log

**Reason for Deferral**: Adds complexity, defer until after single-user MVP is validated.

---

### Advanced Predictions
- `Predictions.tsx` → Historical prediction accuracy
- `generate-predictions` edge function → General prediction engine

**Reason for Deferral**: Nap prediction is sufficient for MVP, defer advanced predictions.

---

### Weekly/Monthly Recaps
- `WeeklyReports.tsx` → Auto-generated weekly summaries
- `generate-weekly-summary` edge function
- `generate-monthly-recap` edge function

**Reason for Deferral**: Requires substantial data, defer until users have logged for weeks.

---

### Notifications & Reminders
- `NotificationSettings.tsx` → Configure reminders
- `notificationManager.ts` → Schedule local notifications
- `reminderService.ts` → Feed/diaper reminders

**Reason for Deferral**: Can be added incrementally, not essential for MVP.

---

### Voice Logging (Experimental)
- `VoiceLogModal.tsx` → Voice command logging
- `VoiceButton.tsx` → Voice input trigger
- `process-voice-command` edge function

**Reason for Deferral**: Experimental feature, accuracy needs improvement.

---

### Data Export & Privacy
- `Settings/PrivacyData.tsx` → Export data, delete account
- `dataExport.ts` → CSV/PDF export
- `doctorReportPDF.ts` → Generate doctor reports

**Reason for Deferral**: Important for data portability, but can be added post-MVP.

---

### Achievements & Gamification
- `Achievements.tsx` → Logging streaks and badges
- `StreakCounter.tsx` → Display logging streaks
- `achievementService.ts` → Achievement logic

**Reason for Deferral**: Nice-to-have engagement feature, not core functionality.

---

### Referrals
- `Referrals.tsx` → Referral program UI
- `referralService.ts` → Referral tracking

**Reason for Deferral**: Growth feature, not needed for MVP.

---

### Labs / Experimental Features
- `Labs.tsx` → Beta feature toggles

**Reason for Deferral**: Internal testing page, not user-facing.

---

## Summary Checklist

### iOS MVP Must-Haves (P0)
- ✅ Email/password auth
- ✅ Onboarding (baby profile)
- ✅ Home dashboard with timeline
- ✅ Feed logging (breast, bottle, pumping)
- ✅ Diaper logging (wet, dirty, both)
- ✅ Sleep logging (timer or manual)
- ✅ History (day-by-day events)
- ✅ Next nap prediction (age-based wake windows)
- ✅ AI assistant (basic Q&A with disclaimers)
- ✅ Settings (baby profile, sign out)
- ✅ Empty/loading/error states
- ✅ Medical disclaimers

### Defer to Phase 2+
- ❌ Analytics & charts
- ❌ Growth tracking
- ❌ Health records & vaccines
- ❌ Milestones
- ❌ Journal & photo gallery
- ❌ Cry insights
- ❌ Sleep training
- ❌ Parent wellness
- ❌ Multi-caregiver / family sharing
- ❌ Advanced predictions
- ❌ Weekly/monthly recaps
- ❌ Notifications & reminders
- ❌ Voice logging
- ❌ Data export & privacy
- ❌ Achievements & gamification
- ❌ Referrals

---

## iOS-Specific Considerations

When implementing the iOS native app, consider:

1. **SwiftUI Design System**
   - Map web design tokens to SwiftUI colors, fonts, spacing
   - Use SF Symbols for icons
   - Native navigation patterns (tab bar, navigation stack)

2. **Data Sync**
   - Use Supabase Swift client for auth and database
   - Implement offline-first with local Core Data or Realm
   - Real-time sync via Supabase Realtime

3. **Native Features**
   - Haptic feedback (use UIFeedbackGenerator)
   - System notifications (UNUserNotificationCenter)
   - Widget support (baby's next nap on home screen)

4. **Performance**
   - Lazy loading for timeline
   - Image caching for baby photos
   - Background sync for events

5. **Accessibility**
   - VoiceOver support
   - Dynamic Type for text scaling
   - High contrast mode

---

## Migration Path

1. **Phase 1 (MVP)**: Build iOS app with P0 features only
2. **Phase 2**: Add most-requested Phase 2 features (e.g., charts, milestones)
3. **Phase 3**: Feature parity with web app (multi-caregiver, journal, etc.)
4. **Phase 4**: iOS-exclusive features (widgets, Siri shortcuts, Apple Watch)

---

## Contact

For questions about this scope document, refer to:
- `ARCHITECTURE.md` → Overall system design
- `DATA_MODEL.md` → Database schema details
- `DESIGN_SYSTEM.md` → UI component standards
