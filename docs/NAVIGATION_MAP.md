# Navigation Map

Visual representation of the entire Nuzzle app navigation structure.

## App Structure

```
Nuzzle App
│
├── Unauthenticated Flow
│   ├── /auth (Login/Signup)
│   └── /accept-invite (Accept caregiver invite)
│
└── Authenticated Flow (Main App)
    │
    ├── Bottom Tab Navigation
    │   ├── Tab 1: Today (/home)
    │   ├── Tab 2: History (/history)
    │   ├── Tab 3: Insights (/insights)
    │   └── Tab 4: Settings (/settings)
    │
    └── Top-level Modals/Sheets
        ├── Baby Switcher
        ├── Log Event Sheet
        └── Voice Log Modal
```

---

## Detailed Route Map

### Authentication & Onboarding

```
/auth
├── Login tab
│   ├── Email/password login
│   └── Google OAuth (if enabled)
└── Sign Up tab
    ├── Email/password signup
    └── Auto-redirects to /onboarding

/onboarding-wizard
├── Step 1: Welcome
├── Step 2: Create baby profile
│   ├── Name
│   ├── Date of birth
│   └── Sex (optional)
├── Step 3: Setup preferences
│   ├── Units (metric/imperial)
│   ├── Notification preferences
│   └── AI consent
└── Step 4: Complete → Redirect to /home

/accept-invite/:token
└── Accept caregiver invitation
    ├── If logged in: Join family
    └── If not logged in: Sign up → Join family
```

---

## Main Tab Navigation

### Tab 1: Today (/home) [P0 Core]

```
/home
├── Baby Selector (top)
│   └── Tap → BabySwitcherModal
├── Next Nap Prediction Card
│   └── Tap "View Details" → /nap-predictor
├── Quick Actions Grid
│   ├── Log Feed → EventSheet (feed)
│   ├── Log Diaper → EventSheet (diaper)
│   ├── Log Sleep → EventSheet (sleep)
│   └── Tummy Time → EventSheet (tummy_time)
├── Summary Chips
│   ├── Total feeds today
│   ├── Total diapers today
│   └── Total sleep today
└── Timeline List
    ├── Event rows (grouped by time)
    │   ├── Tap row → EventDialog (view/edit)
    │   └── Swipe left → Delete
    └── Empty state: "No events logged today"

Bottom Nav Visible: Yes
Floating Action Button: Optional (voice logging)
```

**iOS Structure:**

```swift
struct HomeView: View {
    @State private var showBabySwitcher = false
    @State private var showLogSheet = false
    @State private var logType: EventType?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    BabySelectorCard()
                    NapPredictionCard()
                    QuickActionsGrid()
                    SummaryChips()
                    TimelineList()
                }
            }
            .navigationTitle("Today")
        }
    }
}
```

---

### Tab 2: History (/history) [P0 Core]

```
/history
├── Date Strip (horizontal scroll)
│   └── Select date → Filter timeline
├── Day Summary Card
│   ├── Total feeds, diapers, sleep
│   └── Export day → PDF/CSV
└── Timeline (for selected date)
    └── Same as /home timeline

Bottom Nav Visible: Yes
```

**iOS Structure:**

```swift
struct HistoryView: View {
    @State private var selectedDate = Date()

    var body: some View {
        NavigationStack {
            VStack {
                DateStripView(selection: $selectedDate)
                DaySummaryCard(date: selectedDate)
                TimelineList(date: selectedDate)
            }
            .navigationTitle("History")
        }
    }
}
```

---

### Tab 3: Insights (/insights) [P0 Core]

```
/insights
├── Cards Grid
│   ├── Smart Predictions → /predictions
│   ├── AI Assistant → /ai-assistant
│   ├── Cry Insights → /cry-insights
│   ├── Analytics → /analytics
│   └── Pattern Insights → inline display
└── Context Tips
    └── Based on recent activity

Bottom Nav Visible: Yes
```

**iOS Structure:**

```swift
struct InsightsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    NavigationLink(destination: PredictionsView()) {
                        InsightCard(title: "Smart Predictions")
                    }
                    NavigationLink(destination: AIAssistantView()) {
                        InsightCard(title: "AI Assistant")
                    }
                    // ... more cards
                }
            }
            .navigationTitle("Insights")
        }
    }
}
```

---

### Tab 4: Settings (/settings) [P0 Core]

```
/settings
├── Profile Section
│   ├── Name, email
│   └── Avatar (future)
├── Account Settings
│   ├── Manage Babies → /settings/manage-babies
│   ├── Manage Caregivers → /settings/manage-caregivers
│   └── Notification Settings → /settings/notification-settings
├── Privacy & Data
│   ├── AI & Data Sharing → /settings/ai-data-sharing
│   ├── Privacy Center → /privacy-center
│   └── Data Export/Import
├── App Preferences
│   ├── Theme (light/dark/auto)
│   ├── Units (metric/imperial)
│   ├── Shortcuts → /shortcuts-settings
│   └── Caregiver Mode toggle
├── Support
│   ├── Send Feedback → /feedback
│   ├── Privacy Policy → External link
│   └── Terms of Use → External link
└── Danger Zone
    └── Sign Out

Bottom Nav Visible: Yes
```

---

## Settings Sub-Routes

### /settings/manage-babies [P0]

```
/settings/manage-babies
├── List of babies
│   └── Each baby card:
│       ├── Edit → EditBabySheet
│       ├── Delete → ConfirmDialog
│       └── Set as active
└── Add Baby button → AddBabySheet
```

### /settings/manage-caregivers [P1]

```
/settings/manage-caregivers
├── Current caregivers list
│   └── Each caregiver:
│       ├── Name, role
│       ├── Edit role (admin only)
│       └── Remove (admin only)
└── Invite Caregiver button
    └── InviteModal
        ├── Email input
        ├── Role selector
        └── Send invite
```

### /settings/notification-settings [P0]

```
/settings/notification-settings
├── Permission Status
│   └── Request permission button (if denied)
├── Feed Reminders
│   ├── Enable toggle
│   └── Interval slider (hours)
├── Nap Window Reminders
│   ├── Enable toggle
│   └── Advance warning (minutes)
├── Diaper Reminders
│   ├── Enable toggle
│   └── Interval slider (hours)
└── Quiet Hours
    ├── Enable toggle
    ├── Start time
    └── End time
```

### /settings/ai-data-sharing [P0]

```
/settings/ai-data-sharing
├── Explanation card
│   └── What data is shared, why, with whom
├── AI Features Toggle
│   ├── "Allow AI features to use my data"
│   └── Description of consequences
└── Affected Features List
    ├── Smart Predictions
    ├── Cry Analysis
    └── AI Assistant
```

---

## AI & Advanced Features

### /predictions [P0]

```
/predictions
├── Generate New Prediction
│   ├── Type selector
│   │   ├── Nap window
│   │   ├── Feeding pattern
│   │   ├── Sleep regression
│   │   └── Growth spurt
│   └── Generate button (requires AI consent)
└── Prediction History
    └── List of past predictions
        └── Tap → PredictionDetailView
            ├── Prediction details
            ├── Confidence score
            └── Accuracy feedback

Requires: AI consent enabled
```

### /ai-assistant [P0]

```
/ai-assistant
├── Conversation history
│   └── User/AI message bubbles
├── Quick Questions (chips)
│   └── Tap → Send question
├── Input field
│   └── Type custom question
└── Medical Disclaimer (top)

Requires: AI consent enabled
```

### /cry-insights [P1]

```
/cry-insights
├── Record Cry button
│   └── Microphone permission → Recording UI
│       ├── Timer
│       ├── Waveform visualization
│       └── Stop → Analyze
├── Analysis Result
│   ├── Category (hungry/tired/discomfort/pain)
│   ├── Confidence score
│   └── Suggested actions
└── Recent Sessions
    └── History of past analyses

Requires: AI consent + microphone permission
```

### /nap-predictor [P0]

```
/nap-predictor
├── Next Nap Card (large)
│   ├── Predicted start time
│   ├── Predicted end time
│   ├── Countdown
│   └── Confidence indicator
├── Wake Window Info
│   ├── Current wake time
│   └── Recommended window for age
├── Feedback Buttons
│   ├── "Was this accurate?"
│   └── Thumbs up/down
└── Tips for Better Sleep
    └── Contextual advice

Does NOT require AI consent (rule-based)
```

---

## Analytics Routes [P1]

### /analytics

```
/analytics
├── Time Range Selector
│   ├── Last 7 days
│   ├── Last 30 days
│   └── Custom range
├── Feeding Analysis
│   ├── Total feeds chart
│   ├── Average amount
│   └── Feeding frequency
├── Sleep Analysis
│   ├── Total sleep chart
│   ├── Sleep quality score
│   └── Nap duration trends
├── Diaper Analysis
│   └── Frequency chart
└── Export Report button
```

---

## Health & Growth [P1+]

### /growth-tracker

```
/growth-tracker
├── Growth Chart
│   ├── Weight curve
│   ├── Length curve
│   └── Head circumference curve
├── WHO Percentiles overlay
├── Add Measurement button
│   └── GrowthRecordForm
│       ├── Weight
│       ├── Length
│       ├── Head circumference
│       ├── Date
│       └── Note
└── Measurement History
```

### /health-records

```
/health-records
├── Vaccine Schedule
│   ├── Upcoming vaccines
│   └── Completed vaccines
├── Doctor Visits
│   └── List of visits
│       └── Add Visit → HealthRecordForm
├── Medications
│   └── Current medications list
└── Export for Doctor button
```

### /milestones

```
/milestones
├── Age-Based Categories
│   ├── Motor skills
│   ├── Language
│   ├── Social
│   └── Cognitive
├── Milestone List
│   ├── Achieved (checked)
│   └── Not yet (unchecked)
│       └── Tap → LogMilestoneModal
│           ├── Date achieved
│           ├── Note
│           └── Photo (optional)
└── Timeline View
    └── Chronological milestone history
```

---

## Memory Features [P2+]

### /photo-gallery

```
/photo-gallery
├── Grid view of photos
│   └── Filter by:
│       ├── Date
│       ├── Milestone
│       └── Tag
├── Tap photo → PhotoDetailView
│   ├── Full screen image
│   ├── Date, note
│   ├── Linked milestone
│   ├── Share
│   ├── Edit
│   └── Delete
└── Upload button
```

### /journal

```
/journal
├── Calendar view
│   └── Dates with entries highlighted
├── Entry list
│   └── Tap → /journal/:id
│       ├── Entry content
│       ├── Photos/videos
│       ├── Mood
│       ├── Activities
│       ├── Firsts
│       └── Edit/Delete
└── New Entry button
    └── JournalEntryForm
```

---

## Parent Wellness [P2]

### /parent-wellness

```
/parent-wellness
├── Today's Check-In
│   ├── Mood tracker
│   ├── Sleep quality
│   └── Water intake
├── Medication Tracker
│   └── Parent medications list
└── Wellness History
    └── Past logs
```

---

## Gamification & Social [P2]

### /achievements

```
/achievements
├── Streak Counter
│   └── Days of consecutive logging
├── Badges Grid
│   ├── Earned badges
│   └── Locked badges
└── Leaderboard (if multi-user)
```

### /referrals

```
/referrals
├── Your Referral Code
│   └── Share button
├── Referral Stats
│   ├── Friends invited
│   ├── Rewards earned
│   └── Pending invites
└── Invite Friends button
    └── Share sheet
```

---

## Support Routes

### /feedback

```
/feedback
├── Feedback Form
│   ├── Type (bug/feature/general)
│   ├── Subject
│   ├── Message
│   ├── Rating (optional)
│   └── Screenshots (optional)
└── Submit button
```

### /privacy-center [P0]

```
/privacy-center
├── Privacy Overview
│   └── What data we collect and why
├── Quick Actions
│   ├── Export My Data
│   │   └── Format: JSON/CSV
│   ├── Import Data
│   │   └── Upload JSON file
│   ├── Clear Local Data
│   │   └── ConfirmDialog
│   └── Delete Account
│       └── ConfirmDialog + password
└── Privacy Links
    ├── Privacy Policy
    ├── Terms of Use
    └── AI Data Sharing → /settings/ai-data-sharing
```

### /shortcuts-settings [P1]

```
/shortcuts-settings
├── Voice Logging
│   ├── Enable toggle
│   └── Example commands
├── Quick Actions
│   ├── Enable toggle
│   └── Customize order (future)
└── Floating Button
    └── Enable toggle
```

---

## Special Routes

### /labs [P2]

```
/labs
├── Experimental Features Toggle
│   ├── Sleep training
│   ├── Advanced analytics
│   └── Beta AI models
└── Send Feedback on Labs
```

### /sleep-training [P2]

```
/sleep-training
├── Active Session
│   ├── Method (CIO, Ferber, etc.)
│   ├── Progress tracker
│   └── Log Tonight button
├── Session History
└── Start New Session
    └── NewSessionForm
```

---

## Modal/Sheet Components

### EventSheet (Global)

```
EventSheet
├── Feed Form
│   ├── Type (breast/bottle/pumping)
│   ├── Side (if breast)
│   ├── Amount + unit
│   ├── Duration
│   ├── Start time
│   └── Note
├── Diaper Form
│   ├── Type (wet/dirty/mixed)
│   ├── Time
│   └── Note
├── Sleep Form
│   ├── Start time
│   ├── End time (optional)
│   └── Note
└── Tummy Time Form
    ├── Duration
    ├── Time
    └── Note
```

### BabySwitcherModal

```
BabySwitcherModal
├── List of babies
│   └── Tap → Set as active + close
└── Add New Baby button
    └── AddBabySheet
```

### VoiceLogModal

```
VoiceLogModal
├── Microphone button (center)
├── Recording state
│   ├── Waveform animation
│   └── Transcript preview
└── Parsed result
    ├── Event type detected
    ├── Details extracted
    └── Confirm/Edit buttons
```

---

## Deep Links

```
nestling://home
nestling://history
nestling://insights
nestling://settings
nestling://log/feed
nestling://log/diaper
nestling://log/sleep
nestling://baby/:babyId
nestling://invite/:token
nestling://conversation/:conversationId
```

---

## iOS Navigation Patterns

### NavigationStack (Primary)

Use for main tab content and drill-down flows.

### Sheet (Modals)

Use for:

- Event logging
- Baby switcher
- Add/edit forms
- Confirmations

### Alert

Use for:

- Quick confirmations
- Error messages
- Success toasts

### TabView

Use for bottom navigation.

---

## Priority Mapping for iOS Migration

**P0 (Must Have):**

- /home
- /history
- /insights (basic)
- /settings (core)
- /ai-assistant
- /predictions
- /nap-predictor
- EventSheet (all forms)

**P1 (Should Have):**

- /analytics
- /cry-insights
- /growth-tracker
- /health-records
- /milestones
- Caregiver management
- Full notification settings

**P2+ (Nice to Have):**

- /photo-gallery
- /journal
- /parent-wellness
- /achievements
- /referrals
- /sleep-training
- /labs

This navigation map provides a complete blueprint for implementing the iOS version with SwiftUI's native navigation patterns.
