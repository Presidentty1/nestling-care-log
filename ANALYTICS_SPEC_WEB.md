# Web Analytics Specification

This document describes all analytics events tracked in the Nestling web app.

## Implementation

Analytics are implemented via `src/analytics/analytics.ts` abstraction layer. Default implementation logs to console. Can be swapped with production analytics service (PostHog, Mixpanel, Amplitude, etc.).

## Event Taxonomy

### Event Logging

#### `event_logged`
Tracked when a user logs a new event.

**Properties**:
- `event_type`: `'feed' | 'diaper' | 'sleep' | 'tummy_time'`
- `subtype`: string (e.g., `'bottle'`, `'wet'`, `'nap'`)
- `amount`: number (optional, for feeds)
- `unit`: `'ml' | 'oz'` (optional, for feeds)
- `has_note`: boolean
- `baby_id`: string
- `source`: `'quick_action' | 'form' | 'voice'`

**Example**:
```ts
track('event_logged', {
  event_type: 'feed',
  subtype: 'bottle',
  amount: 120,
  unit: 'ml',
  has_note: false,
  baby_id: 'uuid-here',
  source: 'quick_action'
});
```

#### `event_edited`
Tracked when a user edits an existing event.

**Properties**:
- `event_type`: string
- `event_id`: string
- `changes`: string[] (array of changed fields, e.g., `['amount', 'note']`)

#### `event_deleted`
Tracked when a user deletes an event.

**Properties**:
- `event_type`: string
- `event_id`: string

### Settings & Preferences

#### `settings_changed`
Tracked when user changes any setting.

**Properties**:
- `setting_category`: `'units' | 'notifications' | 'ai' | 'privacy' | 'accessibility'`
- `setting_name`: string (specific setting name)
- `old_value`: any (optional)
- `new_value`: any

**Example**:
```ts
track('settings_changed', {
  setting_category: 'units',
  setting_name: 'preferred_unit',
  old_value: 'ml',
  new_value: 'oz'
});
```

#### `ai_consent_changed`
Tracked when user toggles AI data sharing.

**Properties**:
- `enabled`: boolean
- `source`: `'onboarding' | 'settings'`

### Predictions & AI

#### `predictions_viewed`
Tracked when user views the Predictions page.

**Properties**:
- `baby_id`: string
- `ai_enabled`: boolean

#### `prediction_generated`
Tracked when a prediction is generated.

**Properties**:
- `prediction_type`: `'next_feed' | 'next_nap'`
- `baby_id`: string
- `confidence`: number (0-1)
- `ai_enabled`: boolean

#### `ai_assistant_used`
Tracked when user interacts with AI Assistant.

**Properties**:
- `action`: `'question_asked' | 'quick_question_selected'`
- `question_length`: number (character count)
- `baby_id`: string

### Navigation & Engagement

#### `page_viewed`
Tracked on route changes (via React Router).

**Properties**:
- `page_name`: string (e.g., `'home'`, `'history'`, `'settings'`)
- `baby_id`: string (if applicable)

#### `baby_switched`
Tracked when user switches active baby.

**Properties**:
- `from_baby_id`: string
- `to_baby_id`: string

#### `quick_action_used`
Tracked when user uses quick action button.

**Properties**:
- `action_type`: `'feed' | 'diaper' | 'sleep' | 'tummy_time'`
- `method`: `'quick_log' | 'open_form'`

### Data Management

#### `data_exported`
Tracked when user exports data.

**Properties**:
- `export_format`: `'csv' | 'json' | 'pdf'`
- `date_range`: string (e.g., `'today' | 'week' | 'month' | 'all'`)

#### `data_deleted`
Tracked when user deletes data.

**Properties**:
- `delete_type`: `'event' | 'baby' | 'all_data'`
- `item_count`: number (for bulk deletions)

### Onboarding & Authentication

#### `user_signed_up`
Tracked on user registration.

**Properties**:
- `method`: `'email'`
- `has_baby`: boolean (whether baby was created during signup)

#### `user_signed_in`
Tracked on user login.

**Properties**:
- `method`: `'email'`

#### `onboarding_completed`
Tracked when user completes onboarding.

**Properties**:
- `steps_completed`: number
- `ai_consent_given`: boolean
- `notifications_enabled`: boolean

### Errors & Performance

#### `error_occurred`
Tracked when errors occur (via error boundary or catch blocks).

**Properties**:
- `error_type`: string (e.g., `'network_error'`, `'validation_error'`)
- `error_message`: string (sanitized, no PII)
- `page`: string
- `user_action`: string (what user was doing)

#### `performance_metric`
Tracked for performance monitoring.

**Properties**:
- `metric_name`: string (e.g., `'page_load_time'`, `'api_response_time'`)
- `value`: number (milliseconds or appropriate unit)
- `page`: string

## User Identification

Call `identify()` after user signs in:

```ts
import { identify } from '@/analytics/analytics';

// After successful auth
identify(user.id, {
  email: user.email,
  name: user.name,
  created_at: user.created_at
});
```

## Page Tracking

Track page views on route changes:

```ts
import { page } from '@/analytics/analytics';

// In App.tsx or route component
useEffect(() => {
  page('home', {
    baby_count: babies.length
  });
}, [location.pathname]);
```

## Privacy & Compliance

- **No PII**: Never track personally identifiable information beyond user ID
- **Opt-out**: Respect user preferences (can add opt-out mechanism)
- **GDPR**: Events are designed to be GDPR-compliant
- **Sanitization**: Error messages are sanitized before tracking

## Integration Examples

### PostHog
```ts
import { initAnalytics } from '@/analytics/analytics';
import posthog from 'posthog-js';

posthog.init('your-api-key');
initAnalytics({
  track: (name, props) => posthog.capture(name, props),
  identify: (id, traits) => posthog.identify(id, traits),
  page: (name, props) => posthog.capture('$pageview', { page: name, ...props })
});
```

### Mixpanel
```ts
import { initAnalytics } from '@/analytics/analytics';
import mixpanel from 'mixpanel-browser';

mixpanel.init('your-token');
initAnalytics({
  track: (name, props) => mixpanel.track(name, props),
  identify: (id, traits) => mixpanel.identify(id) && mixpanel.people.set(traits),
  page: (name, props) => mixpanel.track('Page View', { page: name, ...props })
});
```

## Current Implementation Status

✅ **Analytics abstraction created** (`src/analytics/analytics.ts`)  
⏳ **Instrumentation**: Events need to be added throughout the app  
⏳ **Production service**: Not yet integrated (using console logger)

## Next Steps

1. Add `track()` calls to event logging flows
2. Add `track()` calls to settings changes
3. Add `page()` calls to route changes
4. Add `identify()` call after authentication
5. Integrate production analytics service when ready


