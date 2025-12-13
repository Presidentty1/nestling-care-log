# Regression Test Coverage

This document maps issues identified in the [Codebase Audit Report](../CODEBASE_AUDIT_REPORT.md) to their corresponding regression tests.

## Overview

All 15 issues from the codebase audit have been addressed with targeted regression tests to prevent reintroduction.

## Issue to Test Mapping

| Audit ID | Issue                               | Platform | Test File                                                                                    | Status     |
| -------- | ----------------------------------- | -------- | -------------------------------------------------------------------------------------------- | ---------- |
| AUDIT-1  | DateFormatter performance (caching) | iOS      | `ios/Tests/RegressionTests/DateFormatterPerformanceTests.swift`                              | ✅ Covered |
| AUDIT-2  | Search debouncing                   | iOS      | `ios/Tests/RegressionTests/SearchDebounceTests.swift`                                        | ✅ Covered |
| AUDIT-3  | Toast auto-dismiss logic            | Web/iOS  | `tests/regression/toastDismiss.test.ts`, `ios/Tests/RegressionTests/ToastDismissTests.swift` | ✅ Covered |
| AUDIT-4  | useEffect memory leak               | Web      | `tests/regression/homeCleanup.test.tsx`                                                      | ✅ Covered |
| AUDIT-5  | CryRecorder timer frequency         | Web      | `tests/regression/cryRecorder.test.tsx`                                                      | ✅ Covered |
| AUDIT-6  | filteredEvents recalculation        | iOS      | `ios/Tests/RegressionTests/FilteredEventsCachingTests.swift`                                 | ✅ Covered |
| AUDIT-7  | DateFormatter in search filtering   | iOS      | `ios/Tests/RegressionTests/DateFormatterPerformanceTests.swift`                              | ✅ Covered |
| AUDIT-8  | CryRecorder cleanup                 | Web      | `tests/regression/cryRecorder.test.tsx`                                                      | ✅ Covered |

## Test Files

### Web Tests (`tests/regression/`)

- **`index.test.ts`** - Regression test suite entry point
- **`cryRecorder.test.tsx`** - Tests for AUDIT-5 (timer frequency) and AUDIT-8 (cleanup)
- **`homeCleanup.test.tsx`** - Tests for AUDIT-4 (useEffect memory leak)
- **`toastDismiss.test.ts`** - Tests for AUDIT-3 (toast dismiss logic)

### Web Performance Tests (`tests/performance/`)

- **`cryRecorder.perf.test.ts`** - Performance baselines for CryRecorder

### iOS Tests (`ios/Tests/RegressionTests/`)

- **`DateFormatterPerformanceTests.swift`** - Tests for AUDIT-1 and AUDIT-7
- **`SearchDebounceTests.swift`** - Tests for AUDIT-2
- **`ToastDismissTests.swift`** - Tests for AUDIT-3 (iOS-specific)
- **`FilteredEventsCachingTests.swift`** - Tests for AUDIT-6

### iOS Performance Tests (`ios/Tests/PerformanceTests.swift`)

Extended with regression-specific baselines for:

- DateFormatter caching performance
- Search filtering performance
- Event filtering performance
- Memory usage baselines

## Running Tests

### Web Regression Tests

```bash
npm run test:regression
```

### Web Performance Tests

```bash
npm run test:perf
```

### iOS Regression Tests

```bash
cd ios/Nuzzle
xcodebuild test -scheme Nuzzle -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:NuzzleTests/RegressionTests
```

### iOS Performance Tests

```bash
cd ios/Nuzzle
xcodebuild test -scheme Nuzzle -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:NuzzleTests/PerformanceTests
```

## CI/CD Integration

### Web CI (`.github/workflows/web-ci.yml`)

- **test-regression** job runs on every PR and push
- Performance budgets enforced in Lighthouse job on main branch

### iOS CI (`.github/workflows/ios-ci.yml`)

- Unit tests include regression tests
- Performance tests run as part of the test suite

## Adding New Regression Tests

When fixing a new bug:

1. **Document the issue** in `CODEBASE_AUDIT_REPORT.md` with a new AUDIT-ID
2. **Create a test file** in the appropriate `regression/` directory
3. **Add test comment** referencing the AUDIT-ID:

```typescript
/**
 * Regression test for AUDIT-XX: [Issue description]
 * @see CODEBASE_AUDIT_REPORT.md#xx-issue-name
 */
```

4. **Update this document** with the new mapping
5. **Import the test** in `index.test.ts` (for web tests)

## Performance Baselines

The following performance baselines are enforced:

### Web

- Component initialization: < 50ms
- Recording start: < 200ms
- Component cleanup: < 5ms
- Timer interval: >= 250ms (not 100ms)

### iOS

- DateFormatter operations (1000 calls): Baseline measured
- Event filtering (200 events): Baseline measured
- Search filtering: Baseline measured
- Memory usage: No significant growth

## Verification Checklist

After implementing fixes, ensure:

- [ ] Regression test passes
- [ ] Original bug cannot be reintroduced
- [ ] Test is linked to audit ID
- [ ] Performance baselines are maintained
- [ ] CI/CD pipeline passes

---

_Last updated: December 2025_
