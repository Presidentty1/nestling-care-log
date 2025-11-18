# Final Polish & Pre-Flight Super-Sprint Plan

## Phase Summary

### Phase A: Micro-interaction & Motion Polish
**Goal**: Add subtle haptics and smooth transitions while respecting Reduce Motion preferences.

**Files to Modify**:
- `ios/Sources/Design/Components/Haptics.swift` - Enhance with Reduce Motion check
- `ios/Sources/Features/Home/HomeView.swift` - Add transitions to quick actions
- `ios/Sources/Design/Components/TimelineRow.swift` - Add transition for edits
- `ios/Sources/Features/Forms/*.swift` - Add haptics to save actions
- `DESIGN_SYSTEM.md` - Add motion guidelines

### Phase B: Accessibility Deep Pass
**Goal**: Comprehensive VoiceOver, Dynamic Type, and contrast improvements.

**Files to Create**:
- `ios/AccessibilityAudit.md`

**Files to Modify**:
- `ios/Sources/Design/Components/TimelineRow.swift` - Rotor order, hints
- `ios/Sources/Design/Components/ToastView.swift` - VoiceOver announcements
- `ios/Sources/Features/Forms/*.swift` - Hit areas, hints
- `ios/Sources/Features/Settings/*.swift` - Dynamic Type support
- `ios/Sources/Features/Labs/PredictionsView.swift` - Banner accessibility

### Phase C: Undo for Deletions + Safe Edits
**Goal**: Implement undo functionality and prevent double-submission.

**Files to Create**:
- `ios/Sources/Services/UndoManager.swift`

**Files to Modify**:
- `ios/Sources/Design/Components/ToastView.swift` - Add undo button support
- `ios/Sources/Features/Home/HomeViewModel.swift` - Integrate undo
- `ios/Sources/Features/History/HistoryViewModel.swift` - Integrate undo
- `ios/Sources/Features/Forms/*ViewModel.swift` - Prevent double-submission

### Phase D: State Restoration & Resilience
**Goal**: Persist active sleep and handle interruptions gracefully.

**Files to Create**:
- `ios/Tests/ResilienceTests.swift`

**Files to Modify**:
- `ios/Sources/Domain/Services/DataStore.swift` - Add active sleep persistence methods
- `ios/Sources/Domain/Services/CoreDataDataStore.swift` - Implement persistence
- `ios/Sources/Features/Home/HomeViewModel.swift` - Restore active sleep on launch
- `ios/Sources/Services/AudioRecorderService.swift` - Handle interruptions
- `ios/Sources/App/NestlingApp.swift` - Scene restoration

### Phase E: Time/Locale & DST Tests
**Goal**: Robust date handling across timezones and DST boundaries.

**Files to Modify**:
- `ios/Sources/Utilities/DateUtils.swift` - Enhanced timezone handling
- `ios/Tests/DateUtilsTests.swift` - DST/timezone tests
- `ios/README.md` - Add "Time Edge Cases" section

### Phase F: Localization QA & Pseudo-Locale
**Goal**: Pseudo-localization and RTL support verification.

**Files to Create**:
- `ios/psuedo.lproj/Localizable.strings` - Pseudo-locale strings

**Files to Modify**:
- `ios/Sources/Features/Settings/SettingsRootView.swift` - Add RTL preview toggle (debug)
- `ios/NestlingUITests/*.swift` - Screenshot tests in multiple languages

### Phase G: Analytics Taxonomy + Coverage
**Goal**: Comprehensive event tracking specification and implementation.

**Files to Create**:
- `ios/ANALYTICS_SPEC.md`
- `ios/Sources/Services/TestAnalytics.swift`

**Files to Modify**:
- `ios/Sources/Services/AnalyticsService.swift` - Enhanced with taxonomy
- All ViewModels - Add event logging

### Phase H: QA Fixtures & Scenario Seeding
**Goal**: Reproducible test data scenarios.

**Files to Create**:
- `ios/Sources/Services/ScenarioSeeder.swift`

**Files to Modify**:
- `ios/Sources/Features/Settings/SettingsRootView.swift` - Add Developer section
- `ios/TEST_PLAN.md` - Reference scenarios

### Phase I: Copywriting Pass & Microcopy Consistency
**Goal**: Consistent, supportive tone across all copy.

**Files to Create**:
- `ios/COPY_GUIDE.md`

**Files to Modify**:
- All view files - Update user-facing strings
- `ios/Sources/Design/Components/MedicalDisclaimer.swift` - Standardize

### Phase J: Data Correctness Guards
**Goal**: Prevent invalid data at domain level.

**Files to Create**:
- `ios/Sources/Domain/Validators/EventValidator.swift`

**Files to Modify**:
- `ios/Sources/Domain/Services/DataStore.swift` - Add validation
- `ios/Sources/Features/Forms/*ViewModel.swift` - Use validators
- `ios/Tests/DataStoreTests.swift` - Invalid input tests

### Phase K: Diagnostics & Support Bundle
**Goal**: One-tap diagnostics export for support.

**Files to Create**:
- `ios/Sources/Services/DiagnosticsService.swift`

**Files to Modify**:
- `ios/Sources/Features/Settings/SettingsRootView.swift` - Add Support section

### Phase L: Notifications Polish & Quiet Hours QA
**Goal**: Robust notification scheduling and quiet hours handling.

**Files to Modify**:
- `ios/Sources/Services/NotificationScheduler.swift` - Enhanced quiet hours logic
- `ios/Tests/NotificationSchedulerTests.swift` - New test file
- `ios/Sources/Features/Settings/NotificationSettingsView.swift` - Test buttons per category

### Phase M: Deep Link Matrix + Smoke Tests
**Goal**: Comprehensive deep link coverage and testing.

**Files to Modify**:
- `ios/README.md` - Add deep link matrix
- `ios/NestlingUITests/DeepLinkTests.swift` - New test file

### Phase N: Battery & Performance Budgets
**Goal**: Performance targets and monitoring.

**Files to Modify**:
- `ios/README.md` - Add performance notes
- `ios/Sources/Utilities/SignpostLogger.swift` - Enhanced signposts
- `ios/Tests/PerformanceTests.swift` - New test file

### Phase O: Caregiver Mode Usability
**Goal**: Simplified, larger-touch-target interface.

**Files to Modify**:
- `ios/Sources/Features/Home/HomeView.swift` - Apply caregiver mode styles
- `ios/Sources/Features/Forms/*.swift` - Simplified forms
- `ios/Sources/App/DesignSystem.swift` - Caregiver mode constants

### Phase P: App Store Submission Pack
**Goal**: Complete submission materials.

**Files to Create**:
- `ios/APP_STORE_PACK/` directory with all materials
- `ios/APP_STORE_PACK/README.md`

### Phase Q: Final Doc Sweep & Checklists
**Goal**: Complete documentation and pre-flight checklist.

**Files to Create**:
- `ios/PRE_FLIGHT_CHECKLIST.md`
- `ios/KNOWN_ISSUES.md`

**Files to Modify**:
- `ios/IOS_ARCHITECTURE.md`
- `ios/TEST_PLAN.md`
- `ios/OPERATIONS_RUNBOOK.md`

---

## Implementation Order

Proceeding sequentially: A → B → C → ... → Q


