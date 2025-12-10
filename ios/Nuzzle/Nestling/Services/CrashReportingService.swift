import Foundation
import Sentry

// Avoid naming conflict with Sentry.Event
typealias SentryEvent = Sentry.Event

/// Service for crash reporting and error tracking using Sentry
@MainActor
class CrashReportingService {
    static let shared = CrashReportingService()

    private var enabled = true

    private init() {
        // Set up Sentry configuration
        setupSentry()
        print("✅ CrashReportingService initialized with Sentry")
    }

    private func setupSentry() {
        SentrySDK.start { options in
            // Configure Sentry DSN - will be set via environment variables
            if let dsn = ProcessInfo.processInfo.environment["SENTRY_DSN"] {
                options.dsn = dsn
            } else {
                // Fallback for development - replace with actual DSN
                options.dsn = "https://your-sentry-dsn@sentry.io/project-id"
                print("⚠️ Using placeholder Sentry DSN - configure SENTRY_DSN environment variable")
            }

            // Configure for iOS app
            options.environment = ProcessInfo.processInfo.environment["ENVIRONMENT"] ?? "development"
            options.releaseName = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"

            // Enable performance monitoring
            options.tracesSampleRate = 1.0
            options.enableAutoSessionTracking = true
            options.enableWatchdogTerminationTracking = true

            // Configure breadcrumbs
            options.maxBreadcrumbs = 100
            options.enableNetworkTracking = true
            // options.enableFileIOTracking = false // Not available in this version
        }
    }

    /// Log a non-fatal error
    func logError(_ error: Error, context: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        guard enabled else { return }

        // Create Sentry event
        let event = SentryEvent(level: .error)
        event.message = SentryMessage(formatted: error.localizedDescription)

        // Add context information
        let tags: [String: String] = [:]
        var extra: [String: Any] = [
            "file": URL(fileURLWithPath: file).lastPathComponent,
            "function": function,
            "line": line,
            "timestamp": Date().ISO8601Format()
        ]

        // Add custom context if provided
        if let context = context {
            extra.merge(context) { (_, new) in new }
        }

        event.tags = tags
        event.extra = extra

        // Capture the event
        SentrySDK.capture(event: event)

        // Also log to console for development
        print("🚨 Error logged: \(extra)")
    }

    /// Log a fatal crash (if we can catch it before termination)
    func logCrash(_ error: Error, context: [String: Any]? = nil) {
        guard enabled else { return }

        let event = SentryEvent(level: .fatal)
        event.message = SentryMessage(formatted: "Fatal crash: \(error.localizedDescription)")

        var extra: [String: Any] = [
            "crash": true,
            "timestamp": Date().ISO8601Format()
        ]

        if let context = context {
            extra.merge(context) { (_, new) in new }
        }

        event.extra = extra
        event.tags = ["crash": "true"]

        SentrySDK.capture(event: event)

        print("💥 Fatal crash logged: \(extra)")
    }

    /// Log a user action that might be relevant for debugging
    func logBreadcrumb(_ message: String, category: String, data: [String: Any]? = nil) {
        guard enabled else { return }

        let breadcrumb = Breadcrumb()
        breadcrumb.level = .info
        breadcrumb.category = category
        breadcrumb.message = message
        breadcrumb.timestamp = Date()

        if let data = data {
            breadcrumb.data = data
        }

        SentrySDK.addBreadcrumb(breadcrumb)

        // Also log to console for development
        print("📝 Breadcrumb: \(category) - \(message)")
    }

    /// Enable/disable crash reporting
    func setEnabled(_ enabled: Bool) {
        self.enabled = enabled
        print("📊 Crash reporting \(enabled ? "enabled" : "disabled")")
    }

    /// Get current status
    var isEnabled: Bool {
        enabled
    }
}
