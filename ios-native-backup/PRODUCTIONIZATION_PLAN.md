# iOS Productionization Sprint Plan

## Overview

This sprint transforms the Nestling iOS app from a polished MVP into an App Store-ready production application. Focus areas: robust architecture, offline-first storage, native iOS features (Widgets, Live Activities, App Intents), and comprehensive testing/documentation.

**Target**: iOS 17+, Swift 5.9+, SwiftUI, Combine, ActivityKit, AppIntents  
**Timeline**: 17 phases, implemented sequentially  
**Risk Mitigation**: Feature flags, compile-time switches, graceful fallbacks

---

## Phase 0 — Plan Summary

### Phase 1: Xcode Project & Targets
**Goal**: Move from loose sources → real Xcode workspace

**Files to Create**:
- `ios/Nestling.xcodeproj/project.pbxproj` (Xcode project file)
- `ios/Nestling.xcodeproj/project.xcworkspace/contents.xcworkspacedata`
- `ios/Nestling/Info.plist`
- `ios/Nestling/Entitlements.entitlements` (App Groups, if needed)
- `ios/NestlingTests/Info.plist`
- `ios/NestlingUITests/Info.plist`
- `ios/NestlingWidgets/Info.plist`
- `ios/NestlingWidgets/WidgetBundle.swift`
- `ios/NestlingIntents/Info.plist`
- `ios/NestlingIntents/Intents.swift`

**Files to Modify**:
- `ios/README.md` (add Xcode setup instructions)
- All existing source files (add to project, fix imports if needed)

**Risks & Mitigation**:
- **Risk**: Xcode project file complexity
  - **Mitigation**: Use Xcode GUI to create project, then manually edit `pbxproj` only for minor tweaks
- **Risk**: Missing dependencies/references
  - **Mitigation**: Add all source files explicitly, verify imports compile

---

### Phase 2: Local-First Sync Architecture (CoreData)
**Goal**: Robust offline storage with migration path

**Files to Create**:
- `ios/Sources/Domain/Services/CoreDataDataStore.swift`
- `ios/Sources/Domain/Services/CoreDataStack.swift`
- `ios/Sources/Domain/Models/CoreData/Nestling.xcdatamodeld/Nestling.xcdatamodel/contents`
- `ios/Sources/Domain/Services/DataStoreSelector.swift`
- `ios/Sources/Domain/Services/DataMigrationService.swift`
- `ios/Sources/Features/Settings/DataMigrationView.swift`

**Files to Modify**:
- `ios/Sources/Domain/Services/DataStore.swift` (add migration methods)
- `ios/Sources/App/AppEnvironment.swift` (use DataStoreSelector)
- `ios/Sources/Features/Settings/PrivacyDataView.swift` (add import JSON → Core Data)
- `ios/Sources/Domain/Services/JSONBackedDataStore.swift` (keep for export/import)

**Risks & Mitigation**:
- **Risk**: Core Data migration failures
  - **Mitigation**: Versioned schema (v1 → v2), lightweight migration, test migration paths
- **Risk**: Performance with large datasets
  - **Mitigation**: Background context for saves, batch operations, precomputed summaries
- **Risk**: Data loss during migration
  - **Mitigation**: Backup before migration, rollback mechanism, validation checks

---

### Phase 3: Onboarding & First-Run Experience
**Goal**: Delightful, compliant first launch

**Files to Create**:
- `ios/Sources/Features/Onboarding/OnboardingCoordinator.swift`
- `ios/Sources/Features/Onboarding/WelcomeView.swift`
- `ios/Sources/Features/Onboarding/BabySetupView.swift`
- `ios/Sources/Features/Onboarding/PreferencesView.swift`
- `ios/Sources/Features/Onboarding/AIConsentView.swift`
- `ios/Sources/Features/Onboarding/NotificationsIntroView.swift`
- `ios/Sources/Services/OnboardingService.swift`

**Files to Modify**:
- `ios/Sources/App/NestlingApp.swift` (check onboarding state, show flow)
- `ios/Sources/Features/Settings/SettingsRootView.swift` (add "Reset Onboarding" debug option)
- `ios/Sources/Domain/Models/AppSettings.swift` (add onboarding flags)

**Risks & Mitigation**:
- **Risk**: Onboarding state persistence
  - **Mitigation**: Store completion flag in AppSettings, check on launch
- **Risk**: User skips critical steps
  - **Mitigation**: Required fields (baby name), sensible defaults for optional fields

---

### Phase 4: Predictions Engine v1 (On-Device)
**Goal**: Reliable, explainable predictor with NO networking

**Files to Create**:
- `ios/Sources/Services/PredictionsEngine.swift`
- `ios/Sources/Services/WakeWindowCalculator.swift`
- `ios/Sources/Services/FeedSpacingCalculator.swift`
- `ios/Sources/Domain/Models/PredictionCache.swift` (Core Data entity)
- `ios/Sources/Features/Labs/PredictionsView.swift` (update to use engine)

**Files to Modify**:
- `ios/Sources/Features/Labs/PredictionsViewModel.swift` (use PredictionsEngine)
- `ios/Sources/Domain/Services/DataStore.swift` (add prediction cache methods)
- `ios/Sources/Domain/Services/CoreDataDataStore.swift` (implement cache)

**Risks & Mitigation**:
- **Risk**: Prediction accuracy/explainability
  - **Mitigation**: Deterministic heuristics, clear confidence levels, unit tests for edge cases
- **Risk**: Performance with complex calculations
  - **Mitigation**: Cache results, background calculation, debounce recalculations

---

### Phase 5: Cry Insights (Beta) with Local Recording
**Goal**: Honest beta with local recording, rule-based classification

**Files to Create**:
- `ios/Sources/Features/CryInsights/CryRecorderView.swift`
- `ios/Sources/Features/CryInsights/CryRecorderViewModel.swift`
- `ios/Sources/Services/AudioRecorderService.swift`
- `ios/Sources/Services/CryClassifier.swift` (rule-based, NO ML)
- `ios/Sources/Features/CryInsights/CryAnalysisResultView.swift`

**Files to Modify**:
- `ios/Sources/Features/Labs/LabsView.swift` (navigate to CryRecorderView)
- `ios/Sources/Domain/Models/Event.swift` (add cry insight note support)

**Risks & Mitigation**:
- **Risk**: Audio recording permissions/privacy
  - **Mitigation**: Clear explanations, auto-delete after analysis, prominent disclaimers
- **Risk**: Background recording interruptions
  - **Mitigation**: Handle AVAudioSession interruptions, save partial recordings gracefully
- **Risk**: Medical claims/liability
  - **Mitigation**: Explicit "not medical advice" disclaimers, rule-based only (no ML), "unknown" as default

---

### Phase 6: Widgets & Live Activities
**Goal**: iOS presence outside the app

**Files to Create**:
- `ios/NestlingWidgets/NextNapWidget.swift`
- `ios/NestlingWidgets/NextFeedWidget.swift`
- `ios/NestlingWidgets/TodaySummaryWidget.swift`
- `ios/NestlingWidgets/WidgetTimelineProvider.swift`
- `ios/NestlingWidgets/WidgetViews.swift`
- `ios/Sources/Services/LiveActivityManager.swift`
- `ios/Sources/Features/Sleep/SleepLiveActivity.swift`

**Files to Modify**:
- `ios/Sources/Features/Home/HomeViewModel.swift` (start Live Activity on sleep)
- `ios/Sources/Features/Forms/SleepFormViewModel.swift` (integrate Live Activity)

**Risks & Mitigation**:
- **Risk**: Widget data freshness
  - **Mitigation**: Timeline reload policy, App Groups for shared data, background refresh
- **Risk**: Live Activity state sync
  - **Mitigation**: Single source of truth (DataStore), update Live Activity on state changes

---

### Phase 7: App Intents (Shortcuts & Siri)
**Goal**: Hands-free quick logging

**Files to Create**:
- `ios/NestlingIntents/LogFeedIntent.swift`
- `ios/NestlingIntents/LogSleepIntent.swift`
- `ios/NestlingIntents/LogDiaperIntent.swift`
- `ios/NestlingIntents/LogTummyTimeIntent.swift`
- `ios/NestlingIntents/StartSleepIntent.swift`
- `ios/NestlingIntents/StopSleepIntent.swift`
- `ios/NestlingIntents/IntentHandler.swift`

**Files to Modify**:
- `ios/Sources/Domain/Services/DataStore.swift` (ensure thread-safe for intents)
- `ios/NestlingIntents/Info.plist` (add intent definitions)

**Risks & Mitigation**:
- **Risk**: Intent execution in background
  - **Mitigation**: Use App Groups for shared DataStore access, handle errors gracefully
- **Risk**: Current baby context
  - **Mitigation**: Store current baby ID in App Groups, fallback to first baby

---

### Phase 8: Local Notifications
**Goal**: Useful, configurable reminders

**Files to Create**:
- `ios/Sources/Services/NotificationScheduler.swift`
- `ios/Sources/Services/NotificationPermissionManager.swift`
- `ios/Sources/Features/Settings/NotificationSettingsView.swift` (enhance with test buttons)

**Files to Modify**:
- `ios/Sources/Features/Settings/NotificationSettingsView.swift` (add permission request, test buttons)
- `ios/Sources/Domain/Models/AppSettings.swift` (notification preferences)
- `ios/Sources/App/NestlingApp.swift` (register notification delegate)

**Risks & Mitigation**:
- **Risk**: Notification permission denial
  - **Mitigation**: Graceful degradation, explain value, allow retry
- **Risk**: Quiet hours edge cases
  - **Mitigation**: Test DST transitions, midnight boundaries, timezone changes

---

### Phase 9: Deep Links & URL Schemes
**Goal**: Jump directly into actions

**Files to Create**:
- `ios/Sources/Services/DeepLinkRouter.swift`
- `ios/Sources/Features/Navigation/NavigationCoordinator.swift`

**Files to Modify**:
- `ios/Sources/App/NestlingApp.swift` (handle URL schemes)
- `ios/Nestling/Info.plist` (add URL scheme declaration)
- `ios/README.md` (add deep link examples)

**Risks & Mitigation**:
- **Risk**: Navigation state conflicts
  - **Mitigation**: Centralized NavigationCoordinator, handle deep links when app is backgrounded/foregrounded

---

### Phase 10: Privacy, Security & Caregiver Mode
**Goal**: Respectful defaults for family app

**Files to Create**:
- `ios/Sources/Services/PrivacyManager.swift`
- `ios/Sources/Services/AuthenticationManager.swift`
- `ios/Sources/Features/Settings/PrivacySettingsView.swift`
- `ios/Sources/Features/Settings/CaregiverModeView.swift`

**Files to Modify**:
- `ios/Sources/App/NestlingApp.swift` (handle app privacy, Face ID)
- `ios/Sources/Features/Home/HomeView.swift` (simplified UI for caregiver mode)
- All views (add blur/redaction support)

**Risks & Mitigation**:
- **Risk**: Face ID failure handling
  - **Mitigation**: Fallback to passcode, allow disable, clear error messages
- **Risk**: Caregiver mode complexity
  - **Mitigation**: Feature flag, simple toggle, test both modes

---

### Phase 11: Exports (CSV + PDF) & Backups
**Goal**: Get data out easily

**Files to Create**:
- `ios/Sources/Services/PDFExportService.swift`
- `ios/Sources/Services/BackupService.swift`
- `ios/Sources/Features/Settings/BackupRestoreView.swift`

**Files to Modify**:
- `ios/Sources/Features/Settings/PrivacyDataView.swift` (add PDF export, backup/restore)
- `ios/Sources/Services/CSVExportService.swift` (enhance existing)

**Risks & Mitigation**:
- **Risk**: Large PDF generation performance
  - **Mitigation**: Background generation, progress indicator, pagination
- **Risk**: Backup/restore data conflicts
  - **Mitigation**: New IDs on restore, conflict resolution UI, validation

---

### Phase 12: Achievements & Streaks
**Goal**: Gentle motivation

**Files to Create**:
- `ios/Sources/Services/StreakService.swift`
- `ios/Sources/Services/AchievementService.swift`
- `ios/Sources/Domain/Models/Achievement.swift`
- `ios/Sources/Features/Settings/AchievementsView.swift`

**Files to Modify**:
- `ios/Sources/Features/Home/HomeViewModel.swift` (track logging for streaks)
- `ios/Sources/Domain/Services/DataStore.swift` (add achievement methods)

**Risks & Mitigation**:
- **Risk**: Performance with streak calculations
  - **Mitigation**: Precompute on save, cache results, background updates
- **Risk**: Guilt-inducing notifications
  - **Mitigation**: Opt-in only, celebratory tone, respect Reduce Motion

---

### Phase 13: Performance & Reliability
**Goal**: Smooth, testable app

**Files to Create**:
- `ios/Sources/Utilities/PerformanceLogger.swift`
- `ios/Sources/Utilities/SignpostLogger.swift`

**Files to Modify**:
- All ViewModels (add OSLog categories)
- `ios/Sources/Features/Home/HomeViewModel.swift` (add signposts)
- `ios/Sources/Domain/Services/CoreDataDataStore.swift` (background context optimization)
- `ios/README.md` (add performance notes)

**Risks & Mitigation**:
- **Risk**: Main thread blocking
  - **Mitigation**: Profile with Instruments, move heavy work to background, use @MainActor carefully
- **Risk**: Memory leaks
  - **Mitigation**: Audit retain cycles, use weak references, test with large datasets

---

### Phase 14: UI Tests & Screenshots
**Goal**: Basic automation

**Files to Create**:
- `ios/NestlingUITests/OnboardingFlowTests.swift`
- `ios/NestlingUITests/QuickActionsTests.swift`
- `ios/NestlingUITests/SleepTimerTests.swift`
- `ios/NestlingUITests/PredictionsTests.swift`
- `ios/NestlingUITests/ExportTests.swift`
- `ios/NestlingUITests/TestHelpers.swift`

**Files to Modify**:
- `ios/NestlingUITests/NestlingUITests.swift` (base test class)

**Risks & Mitigation**:
- **Risk**: Flaky tests
  - **Mitigation**: Use stable identifiers, wait for elements, retry logic
- **Risk**: Screenshot consistency
  - **Mitigation**: Fixed test data, consistent device sizes, clear naming

---

### Phase 15: Localization Expansion
**Goal**: International-ready

**Files to Create**:
- `ios/es.lproj/Localizable.strings` (Spanish)
- `ios/Sources/Utilities/LocalizationHelper.swift`

**Files to Modify**:
- `ios/en.lproj/Localizable.strings` (expand with all new strings)
- All views (use LocalizedStringKey)
- `ios/Sources/Features/Settings/PreferencesView.swift` (unit toggle)

**Risks & Mitigation**:
- **Risk**: Incomplete translations
  - **Mitigation**: Use English as fallback, mark incomplete keys, test language switching
- **Risk**: Unit conversion bugs
  - **Mitigation**: Centralized conversion service, unit tests, validate exports

---

### Phase 16: Branding & App Store Assets
**Goal**: Presentable build

**Files to Create**:
- `ios/Nestling/Assets.xcassets/AppIcon.appiconset/Contents.json` + images
- `ios/Nestling/Assets.xcassets/AccentColor.colorset/Contents.json`
- `ios/Nestling/LaunchScreen.storyboard` (or SwiftUI launch)
- `ios/Sources/Features/Settings/AboutView.swift`

**Files to Modify**:
- `ios/Sources/Features/Settings/SettingsRootView.swift` (add About link)
- `ios/README.md` (add demo script, screenshot shot list)

**Risks & Mitigation**:
- **Risk**: Asset generation complexity
  - **Mitigation**: Use asset catalog templates, placeholder images for now, document requirements

---

### Phase 17: Documentation & Ops
**Goal**: Team-ready repository

**Files to Create**:
- `ios/RELEASE_NOTES.md`
- `ios/OPERATIONS_RUNBOOK.md`
- `ios/TEST_PLAN.md`

**Files to Modify**:
- `ios/IOS_ARCHITECTURE.md` (update with new layers)
- `ios/README.md` (build/run instructions, deep links, feature flags)

**Risks & Mitigation**:
- **Risk**: Documentation drift
  - **Mitigation**: Update docs alongside code, review in PRs, version docs

---

## Risk Summary

### High-Risk Areas

1. **Core Data Migration** (Phase 2)
   - **Risk**: Data loss during migration
   - **Mitigation**: Backup before migration, versioned schema, test migration paths, rollback mechanism

2. **Audio Recording** (Phase 5)
   - **Risk**: Privacy concerns, background interruptions
   - **Mitigation**: Clear disclaimers, auto-delete, handle interruptions gracefully, prominent privacy messaging

3. **Widget Data Freshness** (Phase 6)
   - **Risk**: Stale widget data
   - **Mitigation**: App Groups for shared storage, timeline reload policy, background refresh

4. **Performance** (Phase 13)
   - **Risk**: Main thread blocking, memory issues
   - **Mitigation**: Profile with Instruments, background contexts, memory audits, signposts

### Medium-Risk Areas

1. **Onboarding State** (Phase 3)
   - **Risk**: State persistence issues
   - **Mitigation**: Store in AppSettings, validate on launch

2. **Deep Links** (Phase 9)
   - **Risk**: Navigation state conflicts
   - **Mitigation**: Centralized NavigationCoordinator

3. **Localization** (Phase 15)
   - **Risk**: Incomplete translations, unit conversion bugs
   - **Mitigation**: Fallback to English, centralized conversion service

### Feature Flags & Compile-Time Switches

- `ENABLE_CRY_INSIGHTS`: Gate Cry Insights feature (default: true)
- `ENABLE_WIDGETS`: Gate Widgets extension (default: true)
- `ENABLE_LIVE_ACTIVITIES`: Gate Live Activities (default: true)
- `ENABLE_APP_INTENTS`: Gate App Intents (default: true)
- `ENABLE_FACE_ID`: Gate Face ID authentication (default: true)
- `ENABLE_CAREGIVER_MODE`: Gate caregiver mode (default: true)
- `USE_CORE_DATA`: Switch between JSON and Core Data (default: Core Data after Phase 2)

---

## Implementation Order

1. **Phase 1** (Foundation): Xcode project setup
2. **Phase 2** (Core): Core Data migration
3. **Phase 3** (UX): Onboarding
4. **Phase 4** (Features): Predictions engine
5. **Phase 5** (Features): Cry Insights
6. **Phase 6** (Platform): Widgets & Live Activities
7. **Phase 7** (Platform): App Intents
8. **Phase 8** (Platform): Local notifications
9. **Phase 9** (Platform): Deep links
10. **Phase 10** (Security): Privacy & security
11. **Phase 11** (Features): Exports & backups
12. **Phase 12** (Features): Achievements
13. **Phase 13** (Quality): Performance
14. **Phase 14** (Quality): UI tests
15. **Phase 15** (Quality): Localization
16. **Phase 16** (Polish): Branding
17. **Phase 17** (Docs): Documentation

---

## Acceptance Criteria Summary

- ✅ Xcode project compiles cleanly
- ✅ Core Data persists data across launches
- ✅ Onboarding flow completes successfully
- ✅ Predictions show meaningful results
- ✅ Cry Insights records and classifies (rule-based)
- ✅ Widgets display in preview
- ✅ Live Activity starts/stops with sleep
- ✅ App Intents appear in Shortcuts app
- ✅ Notifications schedule and respect quiet hours
- ✅ Deep links navigate correctly
- ✅ Face ID and privacy features work
- ✅ CSV and PDF export successfully
- ✅ Achievements unlock correctly
- ✅ Performance is smooth (no blocking)
- ✅ UI tests run and capture screenshots
- ✅ Spanish localization works
- ✅ App icons and branding present
- ✅ Documentation is comprehensive

---

## Estimated File Count

- **New Files**: ~80-100 files
- **Modified Files**: ~40-50 files
- **Total Impact**: ~120-150 files

---

**Ready for approval to proceed with implementation.**


