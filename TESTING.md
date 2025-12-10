# Nestling Testing Guide

## Overview

Nestling uses a comprehensive testing strategy with both unit tests (Vitest) and end-to-end tests (Playwright).

## Unit Tests

Unit tests are located in `tests/` and use Vitest.

### Running Unit Tests

```bash
npm run test
```

### Test Coverage

```bash
npm run test:coverage
```

### Writing Unit Tests

Example test structure:

```typescript
import { describe, it, expect } from 'vitest';
import { formatDuration } from '@/services/time';

describe('Time Service', () => {
  it('should format duration correctly', () => {
    expect(formatDuration(90)).toBe('1h 30m');
    expect(formatDuration(45)).toBe('45m');
  });
});
```

## E2E Tests

End-to-end tests use Playwright and are located in `tests/e2e/`.

### Running E2E Tests

```bash
# Install Playwright browsers (first time only)
npx playwright install

# Run all E2E tests
npm run test:e2e

# Run in UI mode
npm run test:e2e:ui

# Run specific test file
npx playwright test tests/e2e/onboarding.spec.ts
```

### E2E Test Structure

Tests are organized by feature:

- `onboarding.spec.ts` - User onboarding flow
- `events.spec.ts` - Event logging (feed, sleep, diaper, tummy time)
- `history.spec.ts` - History navigation and data display

### Writing E2E Tests

Example:

```typescript
import { test, expect } from '@playwright/test';

test('should log a feed', async ({ page }) => {
  await page.goto('/home');
  await page.click('button:has-text("Feed")');
  await page.fill('input[type="number"]', '120');
  await page.click('button:has-text("Save")');
  await expect(page.locator('text=120 ml')).toBeVisible();
});
```

## Test Data Management

### Clearing Test Data

E2E tests automatically clear IndexedDB before each test:

```typescript
test.beforeEach(async ({ page }) => {
  await page.evaluate(() => {
    localStorage.clear();
    indexedDB.deleteDatabase('nestling');
  });
});
```

### Creating Test Fixtures

For consistent test data, use fixtures:

```typescript
const testBaby = {
  name: 'Test Baby',
  date_of_birth: '2024-01-01',
  timezone: 'America/New_York',
  units: 'metric',
};
```

## Debugging Tests

### Unit Tests

```bash
# Run tests in watch mode
npm run test -- --watch

# Run specific test file
npm run test time.test.ts
```

### E2E Tests

```bash
# Run in headed mode (see browser)
npx playwright test --headed

# Debug mode (pause on each action)
npx playwright test --debug

# Show test report
npx playwright show-report
```

## Continuous Integration

Tests run automatically on:

- Pull requests
- Commits to main branch

## Test Checklist

Before submitting a PR, ensure:

- [ ] All unit tests pass
- [ ] All E2E tests pass
- [ ] New features have tests
- [ ] Edge cases are covered
- [ ] No console errors in tests

## Performance Testing

Monitor test performance:

```bash
# Run with timing
npm run test -- --reporter=verbose
```

Target test durations:

- Unit tests: < 100ms each
- E2E tests: < 30s each

## Best Practices

1. **Keep tests isolated** - Each test should be independent
2. **Use descriptive names** - Test names should explain what they test
3. **Test user flows** - E2E tests should mirror real user behavior
4. **Mock external dependencies** - Don't rely on external services
5. **Clean up after tests** - Reset state between tests
6. **Test error cases** - Include negative test cases

## Coverage Goals

- Unit test coverage: > 80%
- E2E critical paths: 100%
- Accessibility: WCAG 2.1 AA compliance

## Troubleshooting

### Tests Timeout

Increase timeout in playwright.config.ts:

```typescript
use: {
  actionTimeout: 10000, // 10 seconds
}
```

### Flaky Tests

Add retry logic:

```typescript
test.describe.configure({ retries: 2 });
```

### IndexedDB Issues

Ensure proper cleanup:

```typescript
await page.evaluate(() => {
  indexedDB.databases().then(dbs => {
    dbs.forEach(db => indexedDB.deleteDatabase(db.name));
  });
});
```
