# Sentry Setup Instructions

## Overview
Sentry is configured for crash reporting and error tracking. You need to create a Sentry account and configure the DSN.

## Steps

1. **Create Sentry Account**
   - Go to https://sentry.io/signup/
   - Create a free account (or use existing)
   - Create a new project for iOS

2. **Get Your DSN**
   - In Sentry dashboard, go to Settings → Projects → [Your Project] → Client Keys (DSN)
   - Copy the DSN (format: `https://xxxxx@xxxxx.ingest.sentry.io/xxxxx`)

3. **Configure Environment Variable**
   - Add `SENTRY_DSN` to your Xcode scheme environment variables:
     - Edit Scheme → Run → Arguments → Environment Variables
     - Add: `SENTRY_DSN` = `https://your-dsn-here@sentry.io/project-id`
   - OR add to `Environment.xcconfig`:
     ```
     SENTRY_DSN = https://your-dsn-here@sentry.io/project-id
     ```

4. **For Production Builds**
   - Add `SENTRY_DSN` to your CI/CD environment variables
   - Or configure in App Store Connect build settings

## Current Status
- ✅ Sentry SDK integrated
- ✅ CrashReportingService configured
- ⚠️ **ACTION REQUIRED**: Replace placeholder DSN with real DSN from Sentry account

## Testing
After configuring, test by triggering an error:
```swift
CrashReportingService.shared.logError(
    NSError(domain: "Test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"]),
    context: ["test": true]
)
```

Check your Sentry dashboard to confirm events are being received.
