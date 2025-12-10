# Component Inventory

Complete catalog of all UI components in the Nestling web app, organized by category. Use this as a reference when converting to iOS/SwiftUI.

## Layout Components

### MobileContainer

**File:** `src/components/layout/MobileContainer.tsx`
**Purpose:** Root container with safe areas, max-width, bottom padding for nav
**Props:**

- `children`: ReactNode
- `className?`: string
- `noPadding?`: boolean
- `noBottomPadding?`: boolean

**iOS Equivalent:**

```swift
struct MobileContainer<Content: View>: View {
    let content: Content
    let noPadding: Bool
    let noBottomPadding: Bool

    var body: some View {
        ScrollView {
            VStack {
                content
            }
            .frame(maxWidth: 600)
            .padding(noPadding ? 0 : 16)
            .padding(.bottom, noBottomPadding ? 0 : 80)
        }
    }
}
```

---

## Navigation Components

### MobileNav

**File:** `src/components/MobileNav.tsx`
**Purpose:** Bottom tab bar navigation
**Routes:** Home, History, Insights, Settings
**iOS Equivalent:** `TabView` with `.tabItem()`

### NavLink

**File:** `src/components/NavLink.tsx`
**Purpose:** Router link with active state styling
**iOS Equivalent:** `NavigationLink` with custom `isActive` check

---

## Button Components

### Button (from shadcn/ui)

**File:** `src/components/ui/button.tsx`
**Variants:**

- `default`: Primary blue background
- `secondary`: Muted background
- `outline`: Border with transparent background
- `ghost`: No background, hover effect
- `destructive`: Red background for dangerous actions

**Sizes:**

- `default`: 40px height
- `sm`: 36px height
- `lg`: 44px height
- `icon`: Square 40x40px

**Features:**

- Haptic feedback on click
- `asChild` support for composition

**iOS Equivalent:**

```swift
enum ButtonVariant {
    case primary, secondary, outline, ghost, destructive
}

struct NestlingButton: View {
    let title: String
    let variant: ButtonVariant
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticManager.impact(.medium)
            action()
        }) {
            Text(title)
        }
        .buttonStyle(NestlingButtonStyle(variant: variant))
    }
}
```

### FloatingActionButton

**File:** `src/components/FloatingActionButton.tsx`
**Purpose:** Fixed bottom-right FAB for quick actions
**iOS Equivalent:** `ZStack` with `.overlay()` modifier

### IconButton

**File:** `src/components/common/IconButton.tsx`
**Purpose:** Square icon-only button
**iOS Equivalent:** `Button` with `Image(systemName:)`

---

## Card Components

### Card (from shadcn/ui)

**File:** `src/components/ui/card.tsx`
**Sub-components:**

- `Card`: Container
- `CardHeader`
- `CardTitle`
- `CardDescription`
- `CardContent`
- `CardFooter`

**iOS Equivalent:**

```swift
struct NestlingCard<Content: View>: View {
    let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}
```

### NapPredictionCard

**File:** `src/components/NapPredictionCard.tsx`
**Purpose:** Shows next nap window prediction
**Key Features:**

- Time display
- Countdown timer
- Feedback buttons
  **iOS Equivalent:** Custom `VStack` with `Timer.publish()`

### ContextualTipCard

**File:** `src/components/ContextualTipCard.tsx`
**Purpose:** Contextual advice based on recent events
**iOS Equivalent:** `VStack` with gradient background

---

## Form Components

### Input

**File:** `src/components/ui/input.tsx`
**Purpose:** Text input field
**iOS Equivalent:** `TextField` with custom styling

### Textarea

**File:** `src/components/ui/textarea.tsx`
**Purpose:** Multi-line text input
**iOS Equivalent:** `TextEditor`

### Select

**File:** `src/components/ui/select.tsx`
**Purpose:** Dropdown select menu
**iOS Equivalent:** `Picker` with `.pickerStyle(.menu)`

### Switch

**File:** `src/components/ui/switch.tsx`
**Purpose:** Toggle on/off
**iOS Equivalent:** Native `Toggle`

### Slider

**File:** `src/components/ui/slider.tsx`
**Purpose:** Range input
**iOS Equivalent:** Native `Slider`

### RadioGroup

**File:** `src/components/ui/radio-group.tsx`
**Purpose:** Single selection from options
**iOS Equivalent:** Custom `VStack` with `Button` or `Picker`

### DateInput

**File:** `src/components/DateInput.tsx`
**Purpose:** Date/time picker
**iOS Equivalent:** `DatePicker`

---

## Sheet/Modal Components

### Sheet (from shadcn/ui)

**File:** `src/components/ui/sheet.tsx`
**Purpose:** Bottom sheet drawer
**iOS Equivalent:** `.sheet()` modifier or custom drawer

### Dialog

**File:** `src/components/ui/dialog.tsx`
**Purpose:** Modal dialog
**iOS Equivalent:** `.alert()` or `.sheet()`

### EventSheet

**File:** `src/components/sheets/EventSheet.tsx`
**Purpose:** Master sheet component for logging events
**Contains:** FeedForm, DiaperForm, SleepForm, TummyTimeForm

### FeedForm

**File:** `src/components/sheets/FeedForm.tsx`
**Fields:**

- Feed type (breast/bottle/pumping)
- Side (left/right/both)
- Amount + unit
- Duration
- Start time
- Note

### DiaperForm

**File:** `src/components/sheets/DiaperForm.tsx`
**Fields:**

- Type (wet/dirty/mixed)
- Time
- Note

### SleepForm

**File:** `src/components/sheets/SleepForm.tsx`
**Fields:**

- Start time
- End time (optional, for completed sleep)
- Note

### TummyTimeForm

**File:** `src/components/sheets/TummyTimeForm.tsx`
**Fields:**

- Duration (minutes)
- Time
- Note

---

## Display Components

### Badge

**File:** `src/components/ui/badge.tsx`
**Purpose:** Small status indicator
**Variants:** default, secondary, destructive, outline
**iOS Equivalent:** `Text` with `.padding()` and `.background()`

### Chip

**File:** `src/components/ui/chip.tsx`
**Purpose:** Pill-shaped label (like Badge but more prominent)
**iOS Equivalent:** Capsule shape with background

### Avatar

**File:** `src/components/ui/avatar.tsx`
**Purpose:** User profile image
**iOS Equivalent:** `AsyncImage` with `.clipShape(Circle())`

### Separator

**File:** `src/components/ui/separator.tsx`
**Purpose:** Visual divider line
**iOS Equivalent:** `Divider()`

---

## Timeline Components

### TimelineRow

**File:** `src/components/today/TimelineRow.tsx`
**Purpose:** Single event in today's timeline
**Features:**

- Icon with event-type color
- Time display
- Event details
- Edit/delete actions

### SwipeableTimelineRow

**File:** `src/components/today/SwipeableTimelineRow.tsx`
**Purpose:** TimelineRow with swipe-to-delete
**iOS Equivalent:** `.swipeActions()`

### TimelineList

**File:** `src/components/today/TimelineList.tsx`
**Purpose:** Full list of today's events
**iOS Equivalent:** `List` or `LazyVStack`

### SummaryChips

**File:** `src/components/today/SummaryChips.tsx`
**Purpose:** Quick stats (total feeds, diapers, sleep)
**iOS Equivalent:** `HStack` with custom chips

---

## State Components

### LoadingState

**File:** `src/components/common/LoadingState.tsx`
**Purpose:** Full-screen loading indicator
**iOS Equivalent:** `ProgressView()` centered

### LoadingSpinner

**File:** `src/components/common/LoadingSpinner.tsx`
**Purpose:** Inline spinner
**iOS Equivalent:** `ProgressView()` inline

### SkeletonCard

**File:** `src/components/common/SkeletonCard.tsx`
**Purpose:** Placeholder while loading
**iOS Equivalent:** `.redacted(reason: .placeholder)`

### EmptyState

**File:** `src/components/common/EmptyState.tsx`
**Purpose:** No data message with CTA
**Props:** title, description, icon, actionLabel, onAction
**iOS Equivalent:** `VStack` with `Image` and `Text`

### ErrorState

**File:** `src/components/common/ErrorState.tsx`
**Purpose:** Error message with retry
**iOS Equivalent:** `VStack` with error icon and retry button

---

## Quick Action Components

### QuickActions

**File:** `src/components/QuickActions.tsx`
**Purpose:** Grid of quick log buttons on home screen
**Buttons:** Feed, Diaper, Sleep, Tummy Time
**iOS Equivalent:** `LazyVGrid` with 2 columns

### QuickQuestions

**File:** `src/components/QuickQuestions.tsx`
**Purpose:** Pre-set AI questions for quick answers
**iOS Equivalent:** `ScrollView(.horizontal)` with chips

---

## Baby Management Components

### BabySelector

**File:** `src/components/BabySelector.tsx`
**Purpose:** Dropdown to switch active baby
**iOS Equivalent:** `Menu` or `Picker`

### BabySwitcher

**File:** `src/components/BabySwitcher.tsx`
**Purpose:** Card showing current baby with switch action
**iOS Equivalent:** `Button` with sheet presentation

### BabySwitcherModal

**File:** `src/components/BabySwitcherModal.tsx`
**Purpose:** Modal to select from multiple babies
**iOS Equivalent:** `.sheet()` with `List`

---

## Analytics Components

### PatternVisualization

**File:** `src/components/analytics/PatternVisualization.tsx`
**Purpose:** Charts showing behavior patterns
**iOS Equivalent:** Use SwiftUI Charts framework

### FeedingAnalysis

**File:** `src/components/analytics/FeedingAnalysis.tsx`
**Purpose:** Feeding trends and insights
**iOS Equivalent:** SwiftUI Charts

### SleepAnalysis

**File:** `src/components/analytics/SleepAnalysis.tsx`
**Purpose:** Sleep patterns and quality
**iOS Equivalent:** SwiftUI Charts

### PatternInsights

**File:** `src/components/PatternInsights.tsx`
**Purpose:** AI-detected patterns card
**iOS Equivalent:** Custom `VStack` with insights

---

## AI Feature Components

### CryRecorder

**File:** `src/components/CryRecorder.tsx`
**Purpose:** Record and analyze baby cry
**Features:**

- Microphone permission request
- Recording timer
- Waveform visualization
  **iOS Equivalent:** `AVAudioRecorder` + custom UI

### CryAnalysisResult

**File:** `src/components/CryAnalysisResult.tsx`
**Purpose:** Display cry analysis results
**Shows:** Category, confidence, suggested actions
**iOS Equivalent:** `VStack` with gradient card

### VoiceButton

**File:** `src/components/VoiceButton.tsx`
**Purpose:** Microphone button for voice commands
**iOS Equivalent:** `Button` with microphone icon

### VoiceLogModal

**File:** `src/components/VoiceLogModal.tsx`
**Purpose:** Voice-to-text logging interface
**iOS Equivalent:** `.sheet()` with SFSpeechRecognizer

---

## Notification Components

### NotificationBanner

**File:** `src/components/NotificationBanner.tsx`
**Purpose:** Top banner for important messages
**iOS Equivalent:** Custom banner with `.offset()` animation

### NotificationPermissionCard

**File:** `src/components/NotificationPermissionCard.tsx`
**Purpose:** Request notification permissions
**iOS Equivalent:** `VStack` with UNUserNotificationCenter

### OfflineIndicator

**File:** `src/components/OfflineIndicator.tsx`
**Purpose:** Show when app is offline
**iOS Equivalent:** Network reachability indicator

---

## Utility Components

### MedicalDisclaimer

**File:** `src/components/MedicalDisclaimer.tsx`
**Purpose:** Legal disclaimer for AI features
**Variants:** ai, sleep, predictions
**iOS Equivalent:** `Text` with styling

### Toast (Sonner)

**File:** `src/components/ui/sonner.tsx`
**Purpose:** Temporary notification popups
**iOS Equivalent:** Custom toast view or native alerts

### ConfirmDialog

**File:** `src/components/common/ConfirmDialog.tsx`
**Purpose:** Confirmation before destructive action
**iOS Equivalent:** `.alert()` with buttons

---

## Specialized Components

### GrowthChart

**File:** `src/components/GrowthChart.tsx`
**Purpose:** WHO percentile growth curves
**iOS Equivalent:** SwiftUI Charts with custom paths

### MilestoneModal

**File:** `src/components/MilestoneModal.tsx`
**Purpose:** Log developmental milestones
**iOS Equivalent:** `.sheet()` with form

### VaccineScheduleView

**File:** `src/components/VaccineScheduleView.tsx`
**Purpose:** Vaccine schedule tracker
**iOS Equivalent:** `List` with sections

### DoctorShareModal

**File:** `src/components/DoctorShareModal.tsx`
**Purpose:** Export report for doctor
**iOS Equivalent:** Share sheet with PDF

### StreakCounter

**File:** `src/components/StreakCounter.tsx`
**Purpose:** Daily logging streak gamification
**iOS Equivalent:** `HStack` with flame icon and counter

### TrialCountdown

**File:** `src/components/TrialCountdown.tsx`
**Purpose:** Show days remaining in trial
**iOS Equivalent:** `HStack` with countdown

### WaterIntakeTracker

**File:** `src/components/WaterIntakeTracker.tsx`
**Purpose:** Parent water intake tracking
**iOS Equivalent:** Progress bar with increment buttons

---

## Design System Tokens

All components use tokens from:

- `src/lib/designTokens.ts` (web)
- `src/index.css` (Tailwind CSS variables)
- `tailwind.config.ts` (theme configuration)

For iOS mapping, see `docs/DESIGN_TOKENS_IOS.md`.

---

## Common Patterns

### Haptic Feedback

All buttons use `hapticFeedback.medium()` on interaction.
iOS equivalent: `UIImpactFeedbackGenerator.impact()`

### Loading States

Most data-fetching components show:

1. Loading skeleton
2. Data view
3. Empty state (if no data)
4. Error state (if error)

### Form Validation

Forms use `react-hook-form` + `zod` schemas.
iOS equivalent: Manual validation or Combine publishers

### Responsive Design

Components use Tailwind breakpoints:

- Mobile-first (default)
- `sm:` 640px+
- `md:` 768px+
- `lg:` 1024px+

iOS should adapt to iPhone SE (375pt) through iPhone Pro Max (430pt).
