# iOS Architecture Documentation

## Overview

This document describes the architecture for the Nestling iOS app, mirroring the web application's functionality while leveraging native iOS patterns and SwiftUI.

**Target Platform**: iOS 17+, Swift 5.9, SwiftUI, Combine

---

## High-Level Architecture

### MVVM Pattern with Domain Layer

```
┌─────────────────────────────────────────────────────────┐
│                    Feature Modules                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌────────┐│
│  │  Home    │  │ History  │  │   Labs   │  │Settings ││
│  │  View    │  │   View   │  │   View   │  │   View  ││
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └────┬────┘│
│       │             │              │              │      │
│       └─────────────┴──────────────┴──────────────┘      │
│                    │                                      │
│              ┌─────▼─────┐                                │
│              │ ViewModel │                                │
│              │   Layer   │                                │
│              └─────┬─────┘                                │
└────────────────────┼──────────────────────────────────────┘
                     │
┌────────────────────┼──────────────────────────────────────┐
│              ┌─────▼─────┐                                │
│              │  Domain    │                                │
│              │   Layer    │                                │
│              │            │                                │
│    ┌─────────┴─────────┐                                  │
│    │     Models        │                                  │
│    │ Baby, Event, etc. │                                  │
│    └─────────┬─────────┘                                  │
│              │                                            │
│    ┌─────────┴─────────┐                                  │
│    │    Services       │                                  │
│    │   DataStore       │                                  │
│    └─────────┬─────────┘                                  │
└──────────────┼────────────────────────────────────────────┘
               │
┌──────────────┼────────────────────────────────────────────┐
│       ┌──────▼──────┐                                      │
│       │ Data Layer  │                                      │
│       │             │                                      │
│  ┌────┴────┐  ┌────┴────┐                                │
│  │InMemory │  │   JSON   │                                │
│  │  Store  │  │  Store   │                                │
│  └─────────┘  └──────────┘                                │
│                                                             │
│  Future: RemoteDataStore (Supabase/Swift backend)          │
└─────────────────────────────────────────────────────────────┘
```

### Key Principles

1. **Separation of Concerns**: Views are pure SwiftUI, ViewModels handle business logic, Domain models are platform-agnostic
2. **Dependency Injection**: DataStore and other services injected via environment or dependency container
3. **Async/Await**: All data operations use async/await for future networking integration
4. **Mock-First**: InMemoryDataStore provides mock data for development and previews

---

## Navigation Structure

### Root Navigation: TabView

```
TabView
├── Home Tab
│   └── HomeView
│       ├── Baby Selector
│       ├── Summary Cards
│       ├── Quick Actions
│       └── Timeline
│
├── History Tab
│   └── HistoryView
│       ├── Date Picker
│       └── Timeline
│
├── Labs Tab
│   └── LabsView
│       ├── Smart Predictions Card → PredictionsView
│       └── Cry Insights Card → Coming Soon Sheet
│
└── Settings Tab
    └── SettingsRootView
        ├── Notifications → NotificationSettingsView
        ├── AI & Data Sharing → AIDataSharingSettingsView
        ├── Privacy & Data → PrivacyDataView
        ├── Manage Babies → ManageBabiesView
        └── Manage Caregivers → ManageCaregiversView
```

### Navigation Patterns

- **Tab Navigation**: `TabView` for main sections
- **Stack Navigation**: `NavigationStack` for Settings sub-screens
- **Sheet Presentation**: Bottom sheets for event logging forms, coming soon modals
- **Deep Linking**: Future support for push notifications and universal links

---

## Data Layer

### DataStore Protocol

The `DataStore` protocol abstracts data access, allowing us to swap implementations:

```swift
protocol DataStore {
    // Babies
    func fetchBabies() async throws -> [Baby]
    func addBaby(_ baby: Baby) async throws
    func updateBaby(_ baby: Baby) async throws
    func deleteBaby(_ baby: Baby) async throws
    
    // Events
    func fetchEvents(for baby: Baby, on date: Date) async throws -> [Event]
    func fetchEvents(for baby: Baby, from startDate: Date, to endDate: Date) async throws -> [Event]
    func addEvent(_ event: Event) async throws
    func updateEvent(_ event: Event) async throws
    func deleteEvent(_ event: Event) async throws
    
    // Predictions
    func fetchPredictions(for baby: Baby, type: PredictionType) async throws -> Prediction?
    func generatePrediction(for baby: Baby, type: PredictionType) async throws -> Prediction
    
    // Settings
    func fetchAppSettings() async throws -> AppSettings
    func saveAppSettings(_ settings: AppSettings) async throws
}
```

### DataStore Implementations

1. **InMemoryDataStore**: Mock data for development/previews
2. **JSONBackedDataStore**: File-based persistence (Documents directory)
3. **CoreDataDataStore**: Production persistence with Core Data
   - Schema: BabyEntity, EventEntity, AppSettingsEntity, PredictionCacheEntity, LastUsedValuesEntity
   - Migrations: Version-based migration support
   - Background contexts for performance

### DataStoreSelector
Automatically chooses implementation:
- Core Data (if available) → JSON → InMemory (fallback)

### Data Validation
- `EventValidator`: Domain-level validation before save
- Prevents invalid data (negative durations, end < start, zero amounts)
- Integrated into DataStore `addEvent`/`updateEvent` methods

### Future Implementation: RemoteDataStore

- Will implement same `DataStore` protocol
- Uses Supabase Swift SDK or custom Swift backend
- Handles authentication, RLS policies, real-time updates
- Can be swapped in via dependency injection

---

## Domain Models

### Core Models

#### Baby
```swift
struct Baby: Identifiable, Codable {
    let id: UUID
    let name: String
    let dateOfBirth: Date
    let sex: Sex? // 'm', 'f', 'other'
    let timezone: String
    let primaryFeedingStyle: FeedingStyle? // 'breast', 'bottle', 'both'
    let createdAt: Date
    let updatedAt: Date
    
    static func mock() -> Baby { ... }
}
```

#### Event
```swift
struct Event: Identifiable, Codable {
    let id: UUID
    let babyId: UUID
    let type: EventType // 'feed', 'diaper', 'sleep', 'tummy_time'
    let subtype: String? // e.g., 'breast', 'wet', 'nap'
    let startTime: Date
    let endTime: Date?
    let amount: Double? // ml for feeds, minutes for sleep
    let unit: String? // 'ml', 'oz', 'min'
    let note: String?
    let createdAt: Date
    let updatedAt: Date
    
    static func mockFeed() -> Event { ... }
    static func mockSleep() -> Event { ... }
    static func mockDiaper() -> Event { ... }
}
```

#### Prediction
```swift
struct Prediction: Identifiable, Codable {
    let id: UUID
    let babyId: UUID
    let type: PredictionType // 'nextFeed', 'nextNap'
    let predictedTime: Date
    let confidence: Double // 0.0 - 1.0
    let explanation: String
    let createdAt: Date
}
```

#### AppSettings
```swift
struct AppSettings: Codable {
    var aiDataSharingEnabled: Bool
    var feedReminderEnabled: Bool
    var feedReminderHours: Int
    var napWindowAlertEnabled: Bool
    var diaperReminderEnabled: Bool
    var diaperReminderHours: Int
    var quietHoursStart: Date?
    var quietHoursEnd: Date?
    
    static func `default`() -> AppSettings { ... }
}
```

### Enums

```swift
enum EventType: String, Codable {
    case feed
    case diaper
    case sleep
    case tummyTime = "tummy_time"
}

enum PredictionType: String, Codable {
    case nextFeed = "next_feed"
    case nextNap = "next_nap"
}

enum Sex: String, Codable {
    case male = "m"
    case female = "f"
    case other
}

enum FeedingStyle: String, Codable {
    case breast
    case bottle
    case both
}
```

---

## Feature Mapping: Web → iOS

### P0 MVP Features (First Release)

| Web Route | Web Component | iOS View | iOS ViewModel | Status |
|-----------|--------------|----------|--------------|--------|
| `/home` | `Home.tsx` | `HomeView` | `HomeViewModel` | ✅ P0 |
| `/history` | `History.tsx` | `HistoryView` | `HistoryViewModel` | ✅ P0 |
| `/labs` | `Labs.tsx` | `LabsView` | `LabsViewModel` | ✅ P0 |
| `/predictions` | `Predictions.tsx` | `PredictionsView` | `PredictionsViewModel` | ✅ P0 |
| `/settings` | `Settings.tsx` | `SettingsRootView` | `SettingsViewModel` | ✅ P0 |
| `/settings/ai-data-sharing` | `AIDataSharing.tsx` | `AIDataSharingSettingsView` | `AIDataSharingViewModel` | ✅ P0 |
| `/settings/privacy-data` | `PrivacyData.tsx` | `PrivacyDataView` | `PrivacyDataViewModel` | ✅ P0 |
| `/settings/babies` | `ManageBabies.tsx` | `ManageBabiesView` | `ManageBabiesViewModel` | ⚠️ P0 (Simple) |
| `/settings/caregivers` | `ManageCaregivers.tsx` | `ManageCaregiversView` | `ManageCaregiversViewModel` | ⚠️ P0 (Simple) |

### P1 Features (Future Releases)

| Web Route | Web Component | iOS View | Priority |
|-----------|--------------|----------|----------|
| `/onboarding` | `Onboarding.tsx` | `OnboardingView` | P1 |
| `/analytics` | `Analytics.tsx` | `AnalyticsView` | P1 |
| `/growth` | `GrowthTracker.tsx` | `GrowthTrackerView` | P1 |
| `/health` | `HealthRecords.tsx` | `HealthRecordsView` | P1 |
| `/milestones` | `Milestones.tsx` | `MilestonesView` | P1 |
| `/ai-assistant` | `AIAssistant.tsx` | `AIAssistantView` | P1 |
| `/cry-insights` | `CryInsights.tsx` | `CryInsightsView` | P2 (Beta) |

---

## Dependency Injection

### AppEnvironment

Central dependency container injected via `@EnvironmentObject`:

```swift
class AppEnvironment: ObservableObject {
    let dataStore: DataStore
    let appSettings: AppSettingsViewModel
    let currentBaby: CurrentBabyViewModel
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
        self.appSettings = AppSettingsViewModel(dataStore: dataStore)
        self.currentBaby = CurrentBabyViewModel(dataStore: dataStore)
    }
}
```

### Usage in Views

```swift
struct HomeView: View {
    @EnvironmentObject var environment: AppEnvironment
    @StateObject private var viewModel: HomeViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: HomeViewModel(dataStore: environment.dataStore))
    }
}
```

---

## Design System Mapping

### Colors

Mapped from `DESIGN_SYSTEM.md`:

```swift
extension Color {
    // Brand
    static let primary = Color("Primary") // #2E7D6A
    static let primaryForeground = Color.white
    
    // Semantic
    static let success = Color("Success")
    static let warning = Color("Warning") // #F5A623
    static let destructive = Color("Destructive") // #D64545
    
    // Event Colors
    static let eventFeed = Color("EventFeed") // Blue
    static let eventSleep = Color("EventSleep") // Purple
    static let eventDiaper = Color("EventDiaper") // Orange
    static let eventTummy = Color("EventTummy") // Green
    
    // Backgrounds
    static let background = Color("Background") // #F8FAFB
    static let surface = Color("Surface") // #FFFFFF
    
    // Text
    static let foreground = Color("Foreground") // #0D1B1E
    static let mutedForeground = Color("MutedForeground") // #8FA1A8
}
```

### Typography

```swift
extension Font {
    static let headline = Font.system(size: 22, weight: .bold)
    static let title = Font.system(size: 17, weight: .semibold)
    static let body = Font.system(size: 15, weight: .regular)
    static let caption = Font.system(size: 13, weight: .regular)
    static let label = Font.system(size: 11, weight: .medium)
}

// Caregiver Mode fonts (larger)
extension Font {
    static let caregiverHeadline = Font.system(size: 26, weight: .bold)
    static let caregiverTitle = Font.system(size: 20, weight: .semibold)
    static let caregiverBody = Font.system(size: 18, weight: .regular)
}
```

### Spacing

```swift
extension CGFloat {
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32
    static let spacing2XL: CGFloat = 48
}
```

### Corner Radius

```swift
extension CGFloat {
    static let radiusXS: CGFloat = 8
    static let radiusSM: CGFloat = 12
    static let radiusMD: CGFloat = 16
    static let radiusLG: CGFloat = 20
    static let radiusXL: CGFloat = 24
}
```

---

## Quick Actions Business Rules

Mirroring `MVP_SCOPE.md` requirements:

### Feed Quick Actions
- **Minimum**: 10ml (0.33oz)
- **Default**: Use last used amount/unit, or 120ml (4oz) if none
- **Side**: Use last used side for breast feeds
- **Never create**: 0ml feeds

### Sleep Quick Actions
- **Default Duration**: 10 minutes
- **Note**: Add "Quick log nap (10 min)" note
- **Start Time**: Calculated backwards from current time
- **Never create**: 0-second sleep events

### Diaper Quick Actions
- **Default**: Wet
- **No amount needed**: Can quick log immediately

### Tummy Time Quick Actions
- **Default Duration**: 5 minutes
- **Use last used**: If available

---

## How to Run and Iterate

### Prerequisites

1. Xcode 15+ with iOS 17+ SDK
2. Swift 5.9+
3. (Future) Supabase Swift SDK for networking

### Project Structure

```
ios/
├── Sources/
│   ├── App/
│   │   ├── NestlingApp.swift
│   │   └── AppEnvironment.swift
│   ├── Domain/
│   │   ├── Models/
│   │   │   ├── Baby.swift
│   │   │   ├── Event.swift
│   │   │   ├── Prediction.swift
│   │   │   └── AppSettings.swift
│   │   └── Services/
│   │       ├── DataStore.swift
│   │       └── InMemoryDataStore.swift
│   └── Features/
│       ├── Home/
│       │   ├── HomeView.swift
│       │   └── HomeViewModel.swift
│       ├── History/
│       │   ├── HistoryView.swift
│       │   └── HistoryViewModel.swift
│       ├── Labs/
│       │   ├── LabsView.swift
│       │   ├── PredictionsView.swift
│       │   └── PredictionsViewModel.swift
│       └── Settings/
│           ├── SettingsRootView.swift
│           ├── AIDataSharingSettingsView.swift
│           ├── PrivacyDataView.swift
│           ├── ManageBabiesView.swift
│           └── ManageCaregiversView.swift
└── IOS_ARCHITECTURE.md
```

### Development Workflow

1. **Preview Development**: Use SwiftUI previews for rapid iteration
   ```swift
   #Preview {
       HomeView()
           .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
   }
   ```

2. **Mock Data**: All previews use `InMemoryDataStore` with seeded mock data

3. **Testing**: Unit tests for ViewModels and DataStore implementations

4. **Future Networking**: When ready, swap `InMemoryDataStore` for `RemoteDataStore` in `AppEnvironment`

---

## Services Layer

### Core Services

1. **PredictionsEngine**: On-device deterministic predictions
   - Wake window calculator (age-based)
   - Feed spacing heuristics
   - Returns: predicted time, confidence, explanation
   - Cached in Core Data

2. **NotificationScheduler**: Local notification management
   - Feed/diaper reminders (interval-based)
   - Nap window alerts (prediction-based)
   - Quiet hours support
   - Permission handling

3. **AudioRecorderService**: Cry Insights audio recording
   - AVAudioSession management
   - Interruption handling
   - Rule-based classification (no ML)
   - Auto-deletion after analysis

4. **AnalyticsService**: Event tracking
   - ConsoleAnalytics (development)
   - TestAnalytics (unit tests)
   - No PII, local-only

5. **UndoManager**: Deletion undo system
   - 7-second undo window
   - Restores deleted events

6. **DiagnosticsService**: Support bundle generation
   - App/device info
   - Settings snapshot
   - Data summary (no PII)

7. **ScenarioSeeder**: QA test data
   - Predefined scenarios (Demo, Light, Heavy, Newborn, etc.)
   - One-tap data loading

### Widgets & Extensions

1. **WidgetKit Widgets**:
   - NextNapWidget: Shows predicted nap time
   - NextFeedWidget: Shows predicted feed time
   - TodaySummaryWidget: Today's event counts

2. **Live Activities**:
   - ActiveSleepActivity: Shows elapsed time for active sleep

3. **App Intents**:
   - LogFeedIntent, LogSleepIntent, LogDiaperIntent, LogTummyTimeIntent
   - Siri/Shortcuts integration

---

## Future Enhancements

### Phase 1: Networking
- Implement `RemoteDataStore` with Supabase Swift SDK
- Add authentication flow
- Real-time event synchronization

### Phase 2: Advanced Features
- Real-time widget updates
- HealthKit integration
- Apple Watch companion app
- Advanced analytics/insights

### Phase 3: Multi-Caregiver
- Family sharing
- Caregiver invites
- Activity feed

---

## Notes

- **No Real Networking Yet**: All data is mocked via `InMemoryDataStore`
- **SwiftUI Previews**: All views have preview implementations
- **Type Safety**: Strong typing throughout with Swift enums and structs
- **Async/Await**: All data operations use async/await for future networking
- **Design Parity**: UI matches web app semantics, not pixel-perfect (iOS-native patterns)

---

## Modern iOS Interaction Pack

The app includes a Modern iOS Interaction Pack (iOS 17+) with the following features:

### Bottom-Sheet Detents
- All forms use `.presentationDetents([.medium, .large])`
- User preference for default detent (Settings → AI & Smart Features)
- `.interactiveDismissDisabled(isSaving)` prevents accidental dismissal

### Searchable Timelines
- `.searchable(text:, suggestions:)` on Home and History views
- Filter chips: All, Feeds, Diapers, Sleep, Tummy
- Search matches type keywords, note text, and time tokens
- Suggestions include recent note terms

### Context Menus
- Long-press on TimelineRow shows context menu
- Actions: Edit, Duplicate, Copy Summary, Delete
- Duplicate creates new event with current time
- Copy Summary formats event details to pasteboard

### Interactive Widgets
- Lock-screen widgets: `accessoryCircular` and `accessoryInline`
- Interactive buttons via AppIntents
- Actions forward to DataStore
- Widgets reload after actions

### Dynamic Island + Live Activity
- Sleep timer uses Live Activity with Dynamic Island support
- Compact/expanded Dynamic Island UI
- Fallback UI for devices without Dynamic Island
- Updates elapsed time every second

### Keyboard Shortcuts
- ⌘N: Quick Log Feed
- ⌘S: Start/Stop Sleep
- ⌘D: Log Diaper
- ⌘T: Start Tummy Timer
- Available on iPad and with external keyboards

### Core Spotlight Indexing
- Indexes latest ~500 events for system-wide search
- Searchable by event type, baby name, note text
- Tapping Spotlight result opens History on correct date
- Settings toggle: "Index Events in Spotlight"

### SF Symbols Effects
- Pulse effect on PrimaryButton icons
- Bounce effect on QuickActionButton icons (when active)
- Bounce effect on Save button checkmarks (when saving)
- All effects respect Reduce Motion accessibility setting

See `MODERN_IOS_INTERACTION_PACK.md` for detailed documentation.

---

**Version**: 1.1  
**Last Updated**: December 2024

