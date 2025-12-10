# Nestling iOS App

Native SwiftUI iOS app mirroring the Nestling web application architecture.

## 🎉 Status: MVP CODE COMPLETE + AUTOMATION ADDED

**All core features are implemented and ready to build.** Automation scripts and Supabase integration added!

👉 **Quick Start**: See [`QUICK_START.md`](QUICK_START.md) for fastest setup  
👉 **Setup Scripts**: Run `bash scripts/setup_xcode_project.sh` to verify setup  
👉 **Detailed Setup**: See [`XCODE_SETUP.md`](XCODE_SETUP.md) for comprehensive instructions  
👉 **What's Implemented**: See [`MVP_CHECKLIST.md`](MVP_CHECKLIST.md)  
👉 **Testing**: See [`TEST_PLAN.md`](TEST_PLAN.md)  
👉 **Supabase Integration**: See [`SUPABASE_INTEGRATION.md`](SUPABASE_INTEGRATION.md)  
👉 **Performance**: See [`PERFORMANCE_OPTIMIZATIONS.md`](PERFORMANCE_OPTIMIZATIONS.md)

## Project Structure

```
ios/
├── Nuzzle/
│   └── Nestling.xcodeproj/            # Active Xcode project
│   └── Nestling/                      # Active source code
│       ├── App/
│       │   ├── NuzzleApp.swift        # App entry point (@main)
│       │   ├── AppEnvironment.swift   # Dependency injection
│       │   └── DesignSystem.swift     # Colors, spacing, typography
│       ├── Domain/
│       │   ├── Models/
│       │   │   ├── Baby.swift
│       │   │   ├── Event.swift
│       │   │   ├── Prediction.swift
│       │   │   ├── AppSettings.swift
│       │   │   └── CoreData/          # CoreData models (.xcdatamodeld)
│       │   └── Services/
│       │       ├── DataStore.swift    # Protocol
│       │       ├── CoreDataDataStore.swift
│       │       ├── CoreDataStack.swift
│       │       └── InMemoryDataStore.swift
│       ├── Features/
│       │   ├── Home/
│       │   ├── History/
│       │   ├── Labs/
│       │   ├── Settings/
│       │   ├── Onboarding/
│       │   └── ...
│       ├── Services/                  # Business logic services
│       ├── Design/                    # UI components
│       ├── Assets.xcassets/          # App icons, colors
│       ├── Info.plist                # App configuration
│       ├── Nestling.entitlements     # App capabilities
│       └── PrivacyInfo.xcprivacy     # Privacy manifest
├── Sources-archive/                   # Archived experimental code (SwiftData-based)
├── IOS_ARCHITECTURE.md                # Architecture documentation
└── README.md                          # This file
```

## Project Structure

**Active Code:**

- `ios/Nuzzle/Nestling/...` - **Active native iOS app code** (CoreData-based)
- `ios/Nuzzle/Nestling.xcodeproj` - **Active Xcode project**

**Archived:**

- `ios/Sources-archive/...` - Archived experimental code (SwiftData-based, not used)

**Note:** The active project uses **CoreData** for persistence and includes all native iOS resources (Assets, Info.plist, entitlements, PrivacyInfo). The archived `Sources-archive/` directory contained an experimental SwiftData-based implementation that was not integrated into the Xcode project.

## Features Implemented (P0 MVP)

### ✅ Core Features

1. **Home Dashboard**
   - Baby selector
   - Summary cards (feeds, diapers, sleep)
   - Quick actions (feed, sleep, diaper, tummy time)
   - Today's timeline with delete

2. **History View**
   - Date picker (last 7 days)
   - Timeline for selected day
   - Delete events

3. **Labs**
   - Smart Predictions card → PredictionsView
   - Cry Insights card → Coming Soon sheet

4. **Settings**
   - AI Data Sharing toggle
   - Privacy & Data (export stub, delete all)
   - Manage Babies (list view)
   - Manage Caregivers (coming soon message)

### ⚠️ Simplified Features

- **Manage Babies**: List view only (no add/edit forms yet)
- **Manage Caregivers**: Placeholder message
- **Notification Settings**: Placeholder
- **Event Forms**: Quick actions only (no detailed forms yet)

## Architecture

- **MVVM Pattern**: Views are pure SwiftUI, ViewModels handle business logic
- **Domain Layer**: Models and DataStore protocol are platform-agnostic
- **Dependency Injection**: AppEnvironment provides DataStore and shared state
- **Async/Await**: All data operations use async/await for future networking

## Data Layer

The app uses **CoreData** for local persistence with automatic fallback:

- **Primary**: `CoreDataDataStore` - Full CoreData implementation with `.xcdatamodeld`
- **Fallback**: `JSONBackedDataStore` - JSON file-based storage
- **Development**: `InMemoryDataStore` - In-memory mock data for testing

The `DataStoreSelector` automatically chooses the best available implementation. CoreData provides:
- Native iOS persistence
- Efficient querying and relationships
- Background context support
- Migration support

Future: Add `RemoteDataStore` (Supabase/Swift backend) for cloud sync in `NuzzleApp.swift`.

## Design System

Mapped from `DESIGN_SYSTEM.md`:

- Colors: Primary, semantic, event-specific
- Typography: Headline, title, body, caption, label
- Spacing: XS (4pt) to 2XL (48pt)
- Corner Radius: XS (8pt) to XL (24pt)

## Quick Actions Business Rules

Mirroring web app requirements:

- **Feed**: Minimum 10ml, default 120ml (4oz)
- **Sleep**: 10-minute nap with note
- **Diaper**: Default "wet"
- **Tummy Time**: 5-minute default

## How to Use

### Prerequisites

1. Xcode 15+ with iOS 17+ SDK
2. Swift 5.9+

### Setup

#### Option 1: Xcode Project (Recommended)

1. **Create Xcode Project**:
   - Open Xcode → File → New → Project
   - Select iOS → App
   - Product Name: `Nestling`
   - Organization Identifier: `com.nestling`
   - Interface: SwiftUI
   - Language: Swift
   - Save to `ios/` directory

2. **Open Existing Project**:
   - Open `ios/Nuzzle/Nestling.xcodeproj` in Xcode
   - The project is already configured with all source files
   - All files are in `ios/Nuzzle/Nestling/` directory

3. **Configure Targets**:
   - See `XCODE_SETUP.md` for detailed instructions
   - Create Widgets and App Intents extension targets
   - Set deployment target to iOS 17.0
   - Configure signing and capabilities

4. **Build & Run**:
   - Product → Build (⌘B)
   - Product → Run (⌘R)

#### Option 2: Swift Package Manager (Alternative)

1. Create `Package.swift` in `ios/` directory
2. Add all source files as targets
3. Note: Widgets and App Intents require Xcode project targets

**See `XCODE_SETUP.md` for complete setup instructions.**

### Development

- All views have `#Preview` implementations
- Use `InMemoryDataStore` for previews and development
- ViewModels are `@MainActor` for UI updates

## Manual QA Checklist

### Fresh Install Flow

- [ ] App launches and seeds mock data on first run
- [ ] Data persists across app relaunches (JSON storage)
- [ ] Home view shows baby selector, summary cards, quick actions, timeline

### Quick Actions

- [ ] Feed quick action logs with sensible defaults (min 10ml)
- [ ] Sleep quick action: first tap starts timer, second tap stops and logs
- [ ] Active sleep shows "Stop Sleep" button state
- [ ] Diaper quick action logs with last-used subtype
- [ ] Tummy time quick action logs with default duration

### Event Forms

- [ ] Feed form: supports bottle/breast/pumping, amount/unit, side (breast), notes
- [ ] Sleep form: timer mode (start/stop) and manual mode (start/end times)
- [ ] Diaper form: wet/dirty/both selection, notes
- [ ] Tummy time form: timer mode and manual duration
- [ ] All forms prefill correctly when editing existing events
- [ ] Forms validate inputs (min amounts, required fields)

### Timeline & History

- [ ] Home timeline shows today's events with edit/delete menu
- [ ] Swipe actions work (swipe right to delete/edit)
- [ ] History view shows last 7 days with date picker
- [ ] Edit from History opens correct form with prefill
- [ ] Delete asks for confirmation
- [ ] Pull-to-refresh works in History

### Predictions

- [ ] PredictionsView gates on AI Data Sharing setting
- [ ] Shows medical disclaimer banner
- [ ] Shows "Enable AI" message if disabled
- [ ] Generate buttons show loading state
- [ ] Predictions display with time, confidence, explanation
- [ ] Empty state shows when no predictions

### Labs

- [ ] Cry Insights opens "Coming Soon" sheet
- [ ] "Notify me" toggle saves to settings
- [ ] Smart Predictions navigates to PredictionsView

### Settings

- [ ] AI Data Sharing toggle updates immediately
- [ ] Notification settings persist (no real notifications yet)
- [ ] Quiet hours pickers work
- [ ] Privacy/Data: CSV export generates file and opens share sheet
- [ ] Delete All requires typing "DELETE" to confirm
- [ ] Delete All reseeds mock data
- [ ] Manage Babies: Add/Edit forms with validation
- [ ] Manage Babies: Delete baby works
- [ ] Manage Caregivers: Shows placeholder (not broken)

### Accessibility

- [ ] VoiceOver reads all buttons and labels correctly
- [ ] Dynamic Type: Text scales without clipping
- [ ] Dark Mode: Contrast is acceptable
- [ ] All interactive elements have accessibility labels

### State Persistence

- [ ] Close and reopen app: data persists
- [ ] Events, babies, settings all persist
- [ ] Active sleep state persists (if app killed during sleep)

## How to Reset JSON Storage

To reset the app to fresh state (useful for testing):

1. Delete the app from simulator/device
2. Reinstall and launch
3. OR: Use Settings → Privacy & Data → Delete All Data

## Time Edge Cases

The app handles various time-related edge cases:

### DST (Daylight Saving Time) Transitions

- **Spring Forward**: When clocks jump forward (e.g., 2 AM → 3 AM), durations are calculated correctly
- **Fall Back**: When clocks fall back (e.g., 2 AM → 1 AM), no negative durations occur
- **Day Buckets**: Events are grouped by local day, respecting DST boundaries

### Timezone Changes

- **Traveling**: If device timezone changes mid-day, events maintain their original timestamps
- **Duration Calculation**: Uses `Calendar.dateComponents` for DST-safe duration calculations
- **Day Boundaries**: Midnight rollover uses local timezone, not UTC

### Testing DST Scenarios

```swift
// Test DST forward transition
let beforeDST = Date() // Before spring forward
let afterDST = Date() // After spring forward
let duration = DateUtils.durationMinutes(from: beforeDST, to: afterDST)
// Duration should be >= 0, accounting for DST jump
```

### Known Behaviors

- Events created during DST transitions maintain correct timestamps
- "Today" grouping uses local calendar day boundaries
- Duration calculations use absolute values (never negative)

## Deep Links

Nestling supports custom URL scheme `nestling://` for quick actions and navigation. All deep links work from both cold and warm app states.

### Deep Link Matrix

| URL                           | Purpose                  | Query Parameters                                                     | Behavior                                                   |
| ----------------------------- | ------------------------ | -------------------------------------------------------------------- | ---------------------------------------------------------- |
| `nestling://log/feed`         | Log a feed               | `amount` (Double, optional), `unit` (String: "ml" or "oz", optional) | Opens Home tab, presents Feed form with prefill data       |
| `nestling://log/diaper`       | Log a diaper change      | `type` (String: "wet", "dirty", "both", optional)                    | Opens Home tab, presents Diaper form                       |
| `nestling://log/tummy`        | Log tummy time           | `duration` (Double, minutes, optional)                               | Opens Home tab, presents Tummy Time form                   |
| `nestling://sleep/start`      | Start active sleep timer | None                                                                 | Opens Home tab, presents Sleep form to start timer         |
| `nestling://sleep/stop`       | Stop active sleep timer  | None                                                                 | Opens Home tab, stops active sleep and saves event         |
| `nestling://open/home`        | Navigate to Home tab     | None                                                                 | Switches to Home tab (index 0)                             |
| `nestling://open/history`     | Navigate to History tab  | None                                                                 | Switches to History tab (index 1)                          |
| `nestling://open/predictions` | Open Predictions view    | None                                                                 | Switches to Labs tab (index 2), presents Predictions sheet |
| `nestling://open/settings`    | Navigate to Settings tab | None                                                                 | Switches to Settings tab (index 3)                         |

### Examples

**Log a feed with amount:**

```
nestling://log/feed?amount=120&unit=ml
```

**Log a diaper change:**

```
nestling://log/diaper?type=wet
```

**Start sleep timer:**

```
nestling://sleep/start
```

**Navigate to Predictions:**

```
nestling://open/predictions
```

### Testing Deep Links

**Simulator**:

```bash
# Log feed
xcrun simctl openurl booted "nestling://log/feed?amount=120&unit=ml"

# Start sleep
xcrun simctl openurl booted "nestling://sleep/start"

# Open predictions
xcrun simctl openurl booted "nestling://open/predictions"
```

**Device** (via Safari or Shortcuts):

```
nestling://log/feed?amount=120&unit=ml
```

**Xcode UI Tests:**
All deep links are covered by smoke tests in `DeepLinkTests.swift`. Run:

```bash
xcodebuild test -scheme Nestling -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:NestlingUITests/DeepLinkTests
```

### Universal Links

The app also supports Universal Links (requires server configuration):

- `https://nestling.app/log/feed`
- `https://nestling.app/sleep/start`
- `https://nestling.app/open/predictions`

Universal Links are parsed by `DeepLinkRouter` and routed identically to custom URL scheme links.

The JSON file is stored at: `Documents/nestling_data.json`

## Performance Budgets

### Launch Time

- **Target**: < 400ms to first content in release builds
- **Measurement**: Time from app launch to Home view visible
- **Tools**: Xcode Instruments (Time Profiler), OSLog signposts
- **Signposts**: `AppLaunch` (from `NestlingApp` init to `ContentView` visible)
- **Notes**:
  - Core Data initialization happens asynchronously
  - Onboarding check is non-blocking
  - TabView renders immediately with loading states

### Scrolling Performance

- **Target**: 60 FPS on timeline with 100+ events
- **Measurement**: Instruments (Core Animation FPS), Xcode Debug Navigator
- **Optimization**:
  - `LazyVStack` for timeline rows (only visible items rendered)
  - View recycling via SwiftUI's built-in optimization
  - Minimal work in `body` computed properties
- **Test**: `PerformanceTests.testHeavyTimelineScrolling()` loads 200 events and scrolls
- **Signposts**: `TimelineRender` (when timeline view appears)

### Memory Usage

- **Target**: < 50MB for typical usage (Home + History loaded)
- **Measurement**: Instruments (Allocations), Xcode Debug Navigator
- **Optimization**:
  - Background context for Core Data fetches
  - Lazy loading of events (only current day + selected history day)
  - No image caching (no images yet)
  - ViewModels released when views disappear
- **Notes**:
  - Core Data uses faulting to minimize memory
  - Large timelines (>100 events) may spike to ~60MB temporarily

### Battery Impact

- **Target**: Minimal background activity
- **Measurement**: Instruments (Energy Log), Settings → Battery
- **Optimization**:
  - Sleep timer uses `Timer.scheduledTimer` with 1s interval (efficient)
  - No background location or significant background processing
  - Notifications scheduled via `UNUserNotificationCenter` (system-managed)
- **Notes**:
  - Active sleep timer runs only when form is open
  - No continuous background tasks

### Network Performance

- **Target**: N/A (local-first, no networking yet)
- **Future**: When Supabase integration is added, target < 500ms for API calls

### Performance Monitoring

Signposts are added around critical paths using `SignpostLogger`:

| Signpost Name        | Category    | When Fired                       | Expected Duration |
| -------------------- | ----------- | -------------------------------- | ----------------- |
| `TimelineLoad`       | UI          | Loading events for a day         | < 100ms           |
| `PredictionGenerate` | Predictions | Generating on-device predictions | < 50ms            |
| `DataStoreSave`      | DataStore   | Saving event to Core Data        | < 50ms            |
| `AppLaunch`          | UI          | App initialization to first view | < 400ms           |
| `ViewRender`         | UI          | View body computation            | < 16ms (60 FPS)   |

**Viewing Signposts:**

1. Run app in Xcode
2. Open Instruments → "os_signpost" instrument
3. Filter by subsystem: `com.nestling.app`
4. View intervals and events

**Performance Logging:**

- `PerformanceLogger` wraps operations with timing logs
- Logs visible in Xcode Console (filter by "Performance" category)
- Example: `Performance.info("TimelineLoad completed in 0.045s")`

### Performance Testing

**Heavy Timeline Test:**

```swift
// ios/Tests/PerformanceTests.swift
func testHeavyTimelineScrolling() {
    // Load 200 events, verify smooth scrolling
    // Measure FPS during scroll
}
```

**Launch Time Test:**

```swift
func testLaunchTime() {
    // Measure time from app start to Home view visible
    // Should be < 400ms in release builds
}
```

Run performance tests:

```bash
xcodebuild test -scheme Nestling -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:NestlingTests/PerformanceTests
```

View in Instruments → Logging → Points of Interest

## Next Steps

### Phase 1: Networking

- Implement `RemoteDataStore` with Supabase Swift SDK
- Add authentication flow
- Real-time event synchronization

### Phase 2: Advanced Features

- Push notifications (real scheduling)
- Widgets (Home Screen, Lock Screen)
- HealthKit integration
- Multi-caregiver support

## Notes

- **CoreData Persistence**: Primary data storage uses CoreData with `.xcdatamodeld` models
- **Native iOS Resources**: Includes Assets.xcassets, Info.plist, entitlements, and PrivacyInfo.xcprivacy
- **SwiftUI Previews**: All views have preview implementations
- **Type Safety**: Strong typing with Swift enums and structs
- **Design Parity**: UI matches web app semantics, uses iOS-native patterns
- **Localization**: Strings scaffolded in `Localizable.strings` (English only for now)
- **App Store Ready**: Configured with privacy descriptions, entitlements, and app groups for widgets

---

**Version**: 1.1  
**Last Updated**: November 2025
