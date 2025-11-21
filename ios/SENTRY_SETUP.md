# Sentry Setup for iOS

## Adding Sentry Swift Package

Since the automated script has issues, follow these manual steps to add Sentry to the Xcode project:

### 1. Open Xcode Project
```bash
cd ios/Nestling
open Nestling.xcodeproj
```

### 2. Add Package Dependencies
1. In Xcode, go to **File → Add Package Dependencies...**
2. Enter the Sentry package URL: `https://github.com/getsentry/sentry-cocoa.git`
3. Set dependency rule to **Up to Next Major Version** and version **8.0.0**
4. Add both products to the Nestling target:
   - **Sentry** (required)
   - **SentrySwiftUI** (optional, for SwiftUI integration)

### 3. Configure Environment Variables
Add these to your Xcode scheme (or create a `.xcconfig` file):

```bash
# In Xcode: Product → Scheme → Edit Scheme → Run → Arguments → Environment Variables
SENTRY_DSN=https://your-actual-sentry-dsn@sentry.io/project-id
ENVIRONMENT=development  # or production
```

### 4. Build and Test
```bash
# Build the project
xcodebuild -project Nestling.xcodeproj -scheme Nestling -sdk iphonesimulator build

# Run on simulator
xcodebuild -project Nestling.xcodeproj -scheme Nestling -sdk iphonesimulator build test
```

## Sentry Configuration

The app is already configured to use Sentry through the `CrashReportingService`. It will:

- Capture unhandled exceptions
- Log custom errors with context
- Add breadcrumbs for user actions
- Track app launches and performance
- Monitor network requests

## Testing Sentry Integration

1. **Trigger a test error:**
   ```swift
   CrashReportingService.shared.logError(NSError(domain: "test", code: 1, userInfo: ["test": "data"]))
   ```

2. **Add a breadcrumb:**
   ```swift
   CrashReportingService.shared.logBreadcrumb("User tapped settings", category: "navigation")
   ```

3. **Check Sentry dashboard** for events after triggering errors.

## Environment Variables Needed

Create a `.env` file or configure in your CI/CD:

```bash
# Sentry Configuration
VITE_SENTRY_DSN=https://your-web-sentry-dsn@sentry.io/project-id
SENTRY_DSN=https://your-ios-sentry-dsn@sentry.io/project-id
ENVIRONMENT=production
VITE_APP_VERSION=1.0.0
```

