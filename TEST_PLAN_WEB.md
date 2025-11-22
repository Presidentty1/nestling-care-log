# Web Application Test Plan

## Overview

This document outlines the comprehensive testing strategy for the Nuzzle web application, covering unit tests, integration tests, E2E tests, and performance benchmarks.

## Testing Stack

- **Unit Tests**: Vitest 4.0+
- **E2E Tests**: Playwright 1.56+
- **Test Coverage**: Vitest coverage reports
- **CI/CD**: GitHub Actions

## Test Categories

### 1. Unit Tests

**Location**: `tests/` directory

**Coverage Targets:**
- ✅ Service functions (80%+ coverage)
- ✅ Utility functions (90%+ coverage)
- ✅ Custom hooks (70%+ coverage)
- ✅ Business logic (90%+ coverage)

**Current Test Files:**
- `tests/napService.test.ts` - Nap prediction logic
- `tests/dataService.test.ts` - Data export/import
- `tests/time.test.ts` - Time utilities
- `tests/unitConversion.test.ts` - Unit conversion
- `tests/haptics.test.ts` - Haptic feedback
- `tests/components/BabySwitcher.test.tsx` - Component tests
- `tests/components/SummaryChips.test.tsx` - Component tests

**Running Unit Tests:**
```bash
npm run test:unit          # Run once
npm run test              # Watch mode
npm run test:coverage      # With coverage report
```

### 2. Integration Tests

**Location**: `tests/integration/` (to be created)

**Coverage:**
- Service + Supabase integration
- React Query mutations
- Real-time subscriptions
- Offline queue processing

**Test Scenarios:**
- Create event → Verify database insert
- Update event → Verify optimistic update
- Delete event → Verify cache invalidation
- Real-time sync → Verify multi-device updates

### 3. E2E Tests

**Location**: `tests/e2e/`

**Current Test Files:**
- `mvp-critical-path.spec.ts` - Core user flows
- `onboarding.spec.ts` - User onboarding
- `events.spec.ts` - Event logging
- `history.spec.ts` - History navigation
- `offline-sync.spec.ts` - Offline functionality
- `caregiver-mode.spec.ts` - Caregiver features
- `ai-features.spec.ts` - AI features
- `voice-logging.spec.ts` - Voice logging

**Running E2E Tests:**
```bash
npm run test:e2e          # Run all E2E tests
npm run test:e2e:ui       # Playwright UI mode
npm run test:e2e:debug    # Debug mode
```

**E2E Test Scenarios:**

**Critical Path (MVP):**
1. Sign up → Onboarding → Log feed → View history
2. Log multiple events → Verify timeline
3. Switch babies → Verify data isolation
4. Offline logging → Online sync

**Event Logging:**
- Quick action → Form opens → Submit → Event appears
- Manual entry → All fields → Validation → Submit
- Edit event → Update → Verify change
- Delete event → Confirm → Verify removal

**History:**
- Date picker → Select date → Events load
- Filter by type → Verify filtered results
- Export data → Verify CSV/PDF generation

### 4. Performance Tests

**Targets:**
- **Lighthouse Score**: >90 (Performance, Accessibility, Best Practices, SEO)
- **First Contentful Paint**: <1.5s
- **Time to Interactive**: <3.5s
- **Largest Contentful Paint**: <2.5s
- **Cumulative Layout Shift**: <0.1

**Running Performance Tests:**
```bash
# Build production bundle
npm run build

# Run Lighthouse CI
npx lighthouse-ci --collect.url=http://localhost:4173
```

### 5. Accessibility Tests

**Targets:**
- **WCAG 2.1 AA Compliance**: 100%
- **Keyboard Navigation**: All features accessible
- **Screen Reader**: Compatible with NVDA/JAWS
- **Color Contrast**: WCAG AA minimum

**Testing Tools:**
- Lighthouse accessibility audit
- axe DevTools
- WAVE browser extension
- Manual keyboard navigation

**Test Checklist:**
- [ ] All interactive elements keyboard accessible
- [ ] Focus indicators visible
- [ ] ARIA labels on custom components
- [ ] Color contrast ratios meet WCAG AA
- [ ] Screen reader announcements correct

## Test Execution Strategy

### Pre-Commit

**Local Checks:**
```bash
# Type check
npx tsc --noEmit

# Lint
npm run lint

# Unit tests (fast)
npm run test:unit
```

### CI/CD Pipeline

**GitHub Actions Workflow** (`.github/workflows/web-ci.yml`):

1. **Lint Job**: ESLint + TypeScript check
2. **Unit Tests Job**: Vitest with coverage
3. **E2E Tests Job**: Playwright (smoke tests)
4. **Build Job**: Production build verification
5. **Lighthouse Job**: Performance audit (main branch only)

### Pre-Release

**Full Test Suite:**
```bash
# Complete test run
npm run lint
npm run test:unit
npm run test:e2e
npm run build

# Performance audit
npm run lighthouse

# Accessibility audit
npm run a11y
```

## Test Data Management

### Test Users

**Development:**
- Use Supabase seed data (`supabase/seed.sql`)
- Test user: `test@example.com` / `testpassword`

**E2E Tests:**
- Create test users programmatically
- Clean up after test runs
- Use unique email addresses per test run

### Test Data Isolation

- Each test creates its own data
- Cleanup after each test
- No shared state between tests

## Mocking Strategy

### Supabase Client

**Unit Tests:**
```typescript
import { vi } from 'vitest';

const mockSupabase = {
  from: vi.fn(() => ({
    select: vi.fn(() => ({
      eq: vi.fn(() => ({
        data: mockData,
        error: null,
      })),
    })),
  })),
};
```

### React Query

**Component Tests:**
```typescript
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: { retry: false },
  },
});
```

## Test Coverage Goals

### Current Coverage

- **Overall**: ~60% (target: 80%+)
- **Services**: ~75% (target: 90%+)
- **Components**: ~40% (target: 70%+)
- **Hooks**: ~50% (target: 80%+)

### Coverage Reports

**Generate Report:**
```bash
npm run test:coverage
```

**View Report:**
- HTML report: `coverage/index.html`
- CI integration: Codecov

## Critical Test Scenarios

### 1. Authentication Flow

**Test Cases:**
- [ ] Sign up with valid email/password
- [ ] Sign in with correct credentials
- [ ] Sign in with incorrect credentials (error handling)
- [ ] Session persistence across page reloads
- [ ] Auto-redirect to onboarding for new users
- [ ] Protected routes redirect to auth when unauthenticated

### 2. Event Logging

**Test Cases:**
- [ ] Quick action button opens correct form
- [ ] Form validation (required fields)
- [ ] Submit event → Appears in timeline
- [ ] Optimistic update → Server confirmation
- [ ] Error handling → Rollback on failure
- [ ] Offline logging → Queue → Sync when online

### 3. Data Synchronization

**Test Cases:**
- [ ] Real-time updates across devices
- [ ] Conflict resolution (last write wins)
- [ ] Offline queue processing
- [ ] Cache invalidation on updates
- [ ] Background refetch on reconnect

### 4. Baby Management

**Test Cases:**
- [ ] Create baby profile
- [ ] Switch between babies
- [ ] Edit baby profile
- [ ] Delete baby (with data cleanup)
- [ ] Family member access control

### 5. History & Analytics

**Test Cases:**
- [ ] Date picker navigation
- [ ] Event filtering by type
- [ ] Export CSV/PDF
- [ ] Charts render correctly
- [ ] Data aggregation accuracy

## Regression Testing

### Smoke Tests (Every PR)

**Critical Paths:**
1. Sign up → Onboarding → Log event → View history
2. Sign in → View home → Log feed → Verify timeline

### Full Regression (Pre-Release)

**All Test Suites:**
- Unit tests (100% pass rate)
- E2E tests (all scenarios)
- Performance benchmarks
- Accessibility audit

## Bug Triage

### Test Failures

**Priority Levels:**
1. **P0 (Critical)**: Blocks release, core functionality broken
2. **P1 (High)**: Major feature broken, workaround exists
3. **P2 (Medium)**: Minor feature issue, non-blocking
4. **P3 (Low)**: Cosmetic issue, edge case

**Response Times:**
- P0: Immediate fix or rollback
- P1: Fix within 24 hours
- P2: Fix in next release
- P3: Backlog

## Continuous Improvement

### Test Metrics

**Track:**
- Test execution time
- Coverage trends
- Flaky test rate
- Bug detection rate

### Test Maintenance

**Regular Tasks:**
- Update tests for new features
- Remove obsolete tests
- Refactor flaky tests
- Improve test performance

## Related Documentation

- `ARCHITECTURE_WEB.md` - Application architecture
- `DEPLOYMENT.md` - Deployment procedures
- `PRE_LAUNCH_CHECKLIST.md` - Pre-release checklist
