# Demo Script for App Store Reviewers

## Overview

Nestling is a baby tracking app that helps parents log feeds, sleep, diapers, and tummy time quickly and easily.

## Quick Start

1. **Launch App**: App opens to onboarding (first time) or Home screen
2. **Onboarding**:
   - Welcome screen → Create baby → Set preferences → Enable AI (optional)
3. **Home Screen**:
   - See summary cards (Feeds, Diapers, Sleep)
   - Use quick actions to log events
   - View today's timeline

## Key Features to Demonstrate

### 1. Quick Logging

- Tap "Feed" quick action → Event logged instantly
- Tap "Sleep" → Start timer → Stop timer → Duration calculated
- Tap "Diaper" → Event logged

### 2. Detailed Forms

- Long-press any quick action → Opens detailed form
- Fill form → Save → Event appears in timeline

### 3. History

- Navigate to History tab
- Select different dates → See events for that day
- Swipe to delete → Undo appears

### 4. Predictions

- Navigate to Labs → Smart Predictions
- Tap "Predict Next Feed" → See prediction with confidence
- Note: Requires AI Data Sharing enabled (can enable in Settings)

### 5. Settings

- Navigate to Settings
- Toggle AI Data Sharing
- View Privacy & Data options
- Export data (CSV/JSON)

## Test Accounts

**No account required** - App works fully offline with local data.

## Test Data

Use Settings → Debug → Load Scenario to populate test data:

- **Demo**: Basic scenario with today's events
- **Heavy Usage**: 7 days of extensive logging
- **Newborn**: Frequent feeds and diapers

## Known Limitations

- Predictions are local heuristics (not cloud-based AI)
- Cry Insights is beta (rule-based, not ML)
- Multi-caregiver sync requires cloud setup (not in MVP)

## Support

For questions or issues, contact: [support@nestling.app]
