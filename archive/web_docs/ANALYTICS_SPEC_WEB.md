# Analytics Specification - Web Application

## Overview

Nuzzle uses Firebase Analytics for user behavior tracking and Sentry for error tracking. This document describes the analytics implementation, tracked events, and privacy considerations.

## Analytics Stack

- **Primary**: Firebase Analytics (Google Analytics 4)
- **Error Tracking**: Sentry
- **Implementation**: `src/analytics/analytics.ts`
- **Service Layer**: `src/services/analyticsService.ts`

## Event Tracking

### Core Events

**User Lifecycle:**

- `user_signed_in` - User signs in
- `user_signed_up` - New user registration
- `onboarding_completed` - Onboarding flow completed
- `page_view` - Page navigation

**Event Logging:**

- `event_saved` - Event created (type, subtype)
- `event_edited` - Event updated (eventId, type)
- `event_deleted` - Event removed (eventId, type)

**Baby Management:**

- `baby_created` - New baby profile (babyId)
- `baby_updated` - Baby profile edited (babyId)
- `baby_deleted` - Baby removed (babyId)
- `baby_switched` - User switches active baby (babyId)

**Features:**

- `nap_recalculated` - Nap prediction updated (ageMonths)
- `nap_feedback_submitted` - User feedback on prediction (rating)
- `data_exported` - Data export (format: csv/pdf)
- `delete_all_data` - User deletes all data

**Settings:**

- `notification_settings_saved` - Notification preferences updated
- `notification_permission_requested` - Permission prompt shown
- `caregiver_mode_toggled` - Caregiver mode enabled/disabled (enabled)

**Errors:**

- `error` - Application error (error message, context)

## Implementation Details

### Firebase Analytics Setup

**Configuration:**

```typescript
// src/lib/firebase.ts
import { initializeApp } from 'firebase/app';
import { getAnalytics } from 'firebase/analytics';

const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY,
  // ... other config
};

const app = initializeApp(firebaseConfig);
export const analytics = getAnalytics(app);
```

**Event Naming:**

- Firebase event names: alphanumeric + underscores, max 40 chars
- Automatic sanitization in `analytics.ts`
- Example: `event_saved` → `event_saved` (valid)

### Tracking Functions

**Track Event:**

```typescript
import { track } from '@/analytics/analytics';

track('event_saved', {
  type: 'feed',
  subtype: 'bottle',
  amount: 120,
  unit: 'ml',
});
```

**Identify User:**

```typescript
import { identify } from '@/analytics/analytics';

identify(user.id, {
  email: user.email,
  name: user.name,
  created_at: user.created_at,
});
```

**Page View:**

```typescript
import { page } from '@/analytics/analytics';

page('home', {
  baby_count: 2,
});
```

### Service Layer

**AnalyticsService** (`src/services/analyticsService.ts`):

Provides high-level tracking methods:

- `trackOnboardingComplete(babyId)`
- `trackEventSaved(type, subtype)`
- `trackBabySwitch(babyId)`
- `trackNapRecalc(ageMonths)`
- `trackExport(format)`
- etc.

**Usage:**

```typescript
import { analyticsService } from '@/services/analyticsService';

analyticsService.trackEventSaved('feed', 'bottle');
```

### Sentry Integration

**Error Tracking:**

- Automatic error capture via Sentry
- User action breadcrumbs
- Contextual error information

**Breadcrumbs:**

```typescript
Sentry.addBreadcrumb({
  message: 'event_saved',
  category: 'user_action',
  level: 'info',
  data: { type: 'feed' },
});
```

## Privacy & Compliance

### Data Collection

**Collected Data:**

- User ID (hashed/anonymized)
- Event types and timestamps
- Feature usage patterns
- Error logs

**NOT Collected:**

- Personal health information
- Baby names or PII
- Exact event details (amounts, notes)
- Location data

### User Consent

**AI Data Sharing:**

- Separate consent for AI features
- Stored in `profiles.ai_data_sharing_enabled`
- Analytics tracking independent of AI consent

**Opt-Out:**

- Analytics can be disabled via environment variable
- No user-facing toggle (complies with privacy policy)

### GDPR Compliance

**Data Retention:**

- Firebase Analytics: 14 months default
- Sentry: 90 days default
- User can request data deletion

**User Rights:**

- Data export available
- Account deletion removes analytics data
- Privacy policy linked in app

## Event Properties

### Standard Properties

**All Events:**

- `timestamp` - Event timestamp (auto-added)
- `user_id` - User identifier (hashed)

**Event-Specific:**

- `event_type` - Type of event (feed, sleep, etc.)
- `event_subtype` - Subtype (bottle, nap, etc.)
- `baby_id` - Baby identifier (hashed)
- `format` - Export format (csv, pdf)

### Property Limits

**Firebase Constraints:**

- Event name: 40 characters max
- Property name: 24 characters max
- Property value: 100 characters max (strings)
- Max 25 custom parameters per event

**Sanitization:**

- Automatic in `analytics.ts`
- Invalid characters replaced with underscores
- Values truncated if necessary

## Analytics Dashboard

### Key Metrics

**User Engagement:**

- Daily Active Users (DAU)
- Weekly Active Users (WAU)
- Monthly Active Users (MAU)
- Session duration
- Events per session

**Feature Usage:**

- Event logging frequency
- Feature adoption rates
- Nap prediction usage
- Export feature usage

**Retention:**

- Day 1, 7, 30 retention
- Churn rate
- Return user rate

### Custom Reports

**Firebase Console:**

- Custom events dashboard
- User property analysis
- Funnel analysis
- Cohort analysis

**Sentry Dashboard:**

- Error frequency
- Error trends
- User impact
- Stack traces

## Testing Analytics

### Development Mode

**Console Logging:**

- Analytics events logged to console
- No data sent to Firebase in dev
- Useful for debugging

**Test Events:**

```typescript
// In development
track('test_event', { test: true });
// Logs: [Analytics] test_event { test: true }
```

### Production Verification

**Firebase DebugView:**

- Real-time event monitoring
- Verify events are firing
- Check event properties

**Sentry Test Events:**

```typescript
Sentry.captureMessage('Test error', 'info');
```

## Best Practices

### Event Naming

**Do:**

- Use snake_case
- Be descriptive (`event_saved` not `save`)
- Keep under 40 characters
- Use consistent naming

**Don't:**

- Include PII in event names
- Use special characters
- Create too many unique events
- Track sensitive data

### Property Usage

**Do:**

- Use consistent property names
- Keep values concise
- Use enums for categorical data
- Document all properties

**Don't:**

- Include PII in properties
- Track exact amounts/values
- Use free-form text
- Exceed property limits

## Related Documentation

- `ARCHITECTURE_WEB.md` - Application architecture
- `PRIVACY.md` - Privacy policy
- `ENVIRONMENT_VARIABLES.md` - Configuration
