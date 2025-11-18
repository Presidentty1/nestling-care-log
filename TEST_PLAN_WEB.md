# Web Test Plan

## Overview

This document describes the testing strategy for the Nestling web app, including unit tests, component tests, E2E tests, and manual QA procedures.

## Test Types

### 1. Unit Tests (Vitest)

**Location**: `tests/*.test.ts`, `tests/components/*.test.tsx`

**Coverage**:
- ✅ Utility functions (`time.test.ts`, `unitConversion.test.ts`)
- ✅ Service logic (`dataService.test.ts`, `napService.test.ts`)
- ✅ Component rendering (`SummaryChips.test.tsx`, `BabySwitcher.test.tsx`)

**Run**: `npm run test:unit`

**Examples**:
- `formatDuration()` formats minutes correctly
- `SummaryChips` displays feed count
- `BabySwitcher` calls onSelect when baby clicked

### 2. Component Tests (Vitest + React Testing Library)

**Location**: `tests/components/*.test.tsx`

**Coverage**:
- ✅ Core components: `SummaryChips`, `BabySwitcher`
- ⏳ Event forms: `FeedForm`, `DiaperForm`, `SleepForm`
- ⏳ Timeline components: `TimelineList`, `EventTimeline`

**Run**: `npm run test:unit`

**Test Cases**:
- Component renders correctly
- User interactions trigger callbacks
- Form validation works
- Edge cases handled (empty states, errors)

### 3. E2E Tests (Playwright)

**Location**: `tests/e2e/*.spec.ts`

**Coverage**:
- ✅ Critical path: `mvp-critical-path.spec.ts`
- ✅ Event logging: `events.spec.ts`
- ✅ History navigation: `history.spec.ts`
- ✅ Onboarding: `onboarding.spec.ts`
- ✅ Offline sync: `offline-sync.spec.ts`
- ✅ Voice logging: `voice-logging.spec.ts`
- ✅ Caregiver mode: `caregiver-mode.spec.ts`
- ✅ AI features: `ai-features.spec.ts`

**Run**: `npm run test:e2e`

**Test Scenarios**:
1. **Log Feed**: Open form → Enter amount → Save → Verify in timeline
2. **Edit Event**: Click event → Edit → Save → Verify changes
3. **Delete Event**: Swipe/click delete → Confirm → Verify removed
4. **Switch Baby**: Open switcher → Select baby → Verify context changes
5. **Navigate History**: Select date → View events → Navigate days

### 4. Integration Tests

**Coverage**:
- Supabase integration (mocked in tests)
- IndexedDB operations
- React Query cache invalidation

## Test Coverage Goals

- **Unit Tests**: > 80% coverage
- **Component Tests**: All core components
- **E2E Tests**: 100% of critical user flows
- **Integration Tests**: Key service integrations

## Manual QA Checklist

### Pre-Release Testing

#### Authentication
- [ ] Sign up with new email
- [ ] Sign in with existing account
- [ ] Sign out works correctly
- [ ] Session persists across page refresh
- [ ] Protected routes redirect to `/auth` when not logged in

#### Event Logging
- [ ] Log feed (bottle) with amount
- [ ] Log feed (breast) with side
- [ ] Log diaper (wet, dirty, both)
- [ ] Log sleep with start/end times
- [ ] Log tummy time with duration
- [ ] Quick log via quick actions
- [ ] Edit existing event
- [ ] Delete event with confirmation
- [ ] Form validation works (required fields)

#### Home Dashboard
- [ ] Summary cards show correct counts
- [ ] Timeline displays today's events
- [ ] Quick actions work
- [ ] Baby switcher works (if multiple babies)
- [ ] Nap prediction displays correctly
- [ ] Pull-to-refresh reloads data

#### History
- [ ] Navigate to previous days
- [ ] Events display correctly for selected date
- [ ] Date picker works
- [ ] Filter by event type (if implemented)
- [ ] Empty state shows when no events

#### Settings
- [ ] Toggle units (ml/oz)
- [ ] Toggle AI data sharing
- [ ] Notification settings save
- [ ] Baby management (add/edit/delete)
- [ ] Caregiver management (if implemented)
- [ ] Data export (CSV/JSON)
- [ ] Data deletion works

#### Offline Support
- [ ] App works offline (airplane mode)
- [ ] Events saved locally when offline
- [ ] Events sync when back online
- [ ] Offline indicator displays
- [ ] No data loss on refresh when offline

#### Responsive Design
- [ ] Mobile view (< 768px) works correctly
- [ ] Tablet view (768px - 1024px) works correctly
- [ ] Desktop view (> 1024px) works correctly
- [ ] Touch interactions work on mobile
- [ ] Keyboard navigation works

#### Accessibility
- [ ] Screen reader compatible (VoiceOver/TalkBack)
- [ ] Keyboard navigation works
- [ ] Focus indicators visible
- [ ] Color contrast meets WCAG AA
- [ ] Text scales with browser zoom

#### Performance
- [ ] Page load < 3 seconds on 3G
- [ ] Smooth scrolling (60 FPS)
- [ ] No console errors
- [ ] No memory leaks (check DevTools)

#### Browser Compatibility
- [ ] Chrome (latest)
- [ ] Safari (latest)
- [ ] Firefox (latest)
- [ ] Edge (latest)
- [ ] Mobile Safari (iOS)
- [ ] Chrome Mobile (Android)

## Test Data Setup

### Test User
- Email: `test@nestling.app`
- Password: `TestPassword123!`

### Test Baby
- Name: "Test Baby"
- DOB: 60 days ago
- Timezone: UTC

### Test Events
- 5 feeds (various amounts, types)
- 3 sleep sessions (various durations)
- 4 diapers (wet, dirty, both)
- 2 tummy time sessions

## Running Tests

### Unit Tests
```bash
# Run all unit tests
npm run test:unit

# Run in watch mode
npm run test

# Run with coverage
npm run test:coverage
```

### E2E Tests
```bash
# Run all E2E tests
npm run test:e2e

# Run in UI mode
npm run test:e2e:ui

# Run in debug mode
npm run test:e2e:debug

# Run specific test file
npx playwright test tests/e2e/events.spec.ts
```

## Continuous Integration

Tests run automatically on:
- Pull requests
- Commits to `main` branch

CI checks:
- ✅ Unit tests pass
- ✅ E2E tests pass
- ✅ Linting passes
- ✅ Type checking passes

## Known Test Gaps

- [ ] Component tests for all event forms
- [ ] Integration tests for Supabase edge functions
- [ ] Performance tests (Lighthouse CI)
- [ ] Visual regression tests
- [ ] Accessibility automated tests (axe-core)

## Test Maintenance

- Update tests when adding new features
- Fix flaky tests immediately
- Review test coverage quarterly
- Update manual QA checklist with new features


