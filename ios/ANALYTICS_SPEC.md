# Analytics Event Taxonomy

## Overview

Nestling uses a lightweight analytics system (`ConsoleAnalytics`) for development and debugging. All events are logged locally with no PII (Personally Identifiable Information) sent to external services.

## Event Structure

```swift
struct AnalyticsEvent {
    let name: String
    let properties: [String: Any]
    let timestamp: Date
}
```

## Event Categories

### 1. User Actions

#### `event_added`

**When**: User logs a new event (feed, sleep, diaper, tummy time)
**Properties**:

- `event_type`: String (feed, sleep, diaper, tummyTime)
- `subtype`: String? (bottle, breast, nap, etc.)
- `has_amount`: Bool (for feeds)
- `has_duration`: Bool (for sleep/tummyTime)
- `has_note`: Bool

**KPI**: Event logging frequency, most common event types

#### `event_edited`

**When**: User edits an existing event
**Properties**:

- `event_type`: String
- `time_since_creation_minutes`: Int

**KPI**: Edit frequency, time to edit

#### `event_deleted`

**When**: User deletes an event
**Properties**:

- `event_type`: String
- `time_since_creation_minutes`: Int
- `undo_used`: Bool (whether undo was triggered)

**KPI**: Deletion rate, undo usage

#### `event_undo`

**When**: User undoes a deletion
**Properties**:

- `time_since_deletion_seconds`: Int

**KPI**: Undo success rate

### 2. Quick Actions

#### `quick_action_tapped`

**When**: User taps a quick action button
**Properties**:

- `action_type`: String (feed, sleep, diaper, tummyTime)
- `was_active_sleep`: Bool (for sleep actions)

**KPI**: Quick action usage vs form usage

#### `quick_action_long_pressed`

**When**: User long-presses a quick action (opens form)
**Properties**:

- `action_type`: String

**KPI**: Form vs quick action preference

### 3. Predictions

#### `prediction_requested`

**When**: User requests a prediction
**Properties**:

- `prediction_type`: String (nextFeed, nextNap)
- `ai_enabled`: Bool
- `baby_age_days`: Int

**KPI**: Prediction request frequency

#### `prediction_generated`

**When**: Prediction is successfully generated
**Properties**:

- `prediction_type`: String
- `confidence`: String (low, medium, high)
- `time_until_prediction_minutes`: Int

**KPI**: Prediction accuracy (user feedback)

### 4. Onboarding

#### `onboarding_started`

**When**: User starts onboarding
**Properties**: None

**KPI**: Onboarding completion rate

#### `onboarding_step_completed`

**When**: User completes an onboarding step
**Properties**:

- `step`: String (welcome, babySetup, preferences, aiConsent, notifications)
- `step_number`: Int

**KPI**: Step completion rates, drop-off points

#### `onboarding_completed`

**When**: User completes entire onboarding
**Properties**:

- `total_time_seconds`: Int
- `ai_data_sharing_enabled`: Bool
- `notifications_enabled`: Bool

**KPI**: Onboarding completion rate, time to complete

### 5. Settings

#### `settings_changed`

**When**: User changes a setting
**Properties**:

- `setting_category`: String (notifications, aiDataSharing, privacy, etc.)
- `setting_name`: String
- `new_value`: String (serialized)

**KPI**: Settings usage patterns

#### `export_initiated`

**When**: User initiates data export
**Properties**:

- `export_type`: String (csv, json, pdf, backup)

**KPI**: Export frequency

#### `export_completed`

**When**: Export completes successfully
**Properties**:

- `export_type`: String
- `file_size_bytes`: Int

**KPI**: Export success rate

### 6. Cry Insights

#### `cry_recording_started`

**When**: User starts recording a cry
**Properties**: None

**KPI**: Feature usage

#### `cry_recording_stopped`

**When**: User stops recording
**Properties**:

- `duration_seconds`: Double
- `was_interrupted`: Bool

**KPI**: Recording patterns

#### `cry_insight_saved`

**When**: User saves a cry insight
**Properties**:

- `classification`: String (hungry, tired, discomfort, unknown)
- `confidence`: Double

**KPI**: Classification distribution

### 7. Errors

#### `error_occurred`

**When**: An error occurs
**Properties**:

- `error_type`: String (validation, network, storage, etc.)
- `error_message`: String (sanitized, no PII)
- `context`: String (where error occurred)

**KPI**: Error frequency, error types

### 8. Performance

#### `view_load_time`

**When**: A view finishes loading
**Properties**:

- `view_name`: String
- `load_time_ms`: Int

**KPI**: Performance monitoring

#### `data_store_operation`

**When**: DataStore operation completes
**Properties**:

- `operation`: String (fetch, add, update, delete)
- `entity_type`: String (baby, event, settings)
- `duration_ms`: Int

**KPI**: Database performance

## Privacy & PII

**No PII is logged**:

- No baby names
- No exact timestamps (only relative times)
- No location data
- No user identifiers

**Sanitized data only**:

- Event types (not specific details)
- Aggregated metrics (age in days, not exact DOB)
- Error messages (sanitized)

## Implementation

See `ios/Sources/Services/AnalyticsService.swift` and `ios/Sources/Services/ConsoleAnalytics.swift` for implementation.

## Testing

Use `TestAnalytics` sink to verify events are fired correctly:

```swift
let testAnalytics = TestAnalytics()
AnalyticsService.shared = testAnalytics

// Perform action
viewModel.addEvent(...)

// Verify event
XCTAssertEqual(testAnalytics.events.count, 1)
XCTAssertEqual(testAnalytics.events.first?.name, "event_added")
```
