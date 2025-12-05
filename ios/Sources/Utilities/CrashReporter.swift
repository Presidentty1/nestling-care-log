import Foundation

/// Crash reporting service that integrates with Sentry
/// Provides structured error reporting and user context
class CrashReporter {
    static let shared = CrashReporter()

    private init() {
        // Initialize crash reporting in production
        #if !DEBUG
        configureSentry()
        #endif
    }

    private func configureSentry() {
        // NOTE: Sentry iOS SDK integration would be added here
        // For now, we log to console with structured format
        Logger.info("Crash reporter initialized (production mode)")
    }

    /// Report an error with context
    func reportError(_ error: Error, context: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        let errorInfo: [String: Any] = [
            "error": error.localizedDescription,
            "domain": (error as NSError).domain,
            "code": (error as NSError).code,
            "context": context ?? [:],
            "file": (file as NSString).lastPathComponent,
            "function": function,
            "line": line
        ]

        #if DEBUG
        Logger.error("Error reported: \(errorInfo)")
        #else
        // In production, send to Sentry/crash reporting service
        Logger.fault("Production error: \(errorInfo)")
        // FUTURE: Send to Sentry when SDK is integrated
        #endif
    }

    /// Report a non-fatal issue
    func reportIssue(_ message: String, context: [String: Any]? = nil, level: LogLevel = .error, file: String = #file, function: String = #function, line: Int = #line) {
        let issueInfo: [String: Any] = [
            "message": message,
            "context": context ?? [:],
            "level": level.rawValue,
            "file": (file as NSString).lastPathComponent,
            "function": function,
            "line": line
        ]

        #if DEBUG
        Logger.error("Issue reported: \(issueInfo)")
        #else
        Logger.fault("Production issue: \(issueInfo)")
        #endif
    }

    /// Add breadcrumb for debugging
    func addBreadcrumb(_ message: String, category: String = "user_action", level: LogLevel = .info, data: [String: Any]? = nil) {
        let breadcrumb: [String: Any] = [
            "message": message,
            "category": category,
            "level": level.rawValue,
            "timestamp": Date().timeIntervalSince1970,
            "data": data ?? [:]
        ]

        Logger.debug("Breadcrumb: \(breadcrumb)")
    }

    /// Set user context for crash reports
    func setUserContext(userId: String?, email: String?) {
        let userContext: [String: Any] = [
            "userId": userId ?? "anonymous",
            "email": email ?? "unknown"
        ]

        Logger.info("User context set: \(userContext)")
    }

    /// Clear user context (e.g., on logout)
    func clearUserContext() {
        Logger.info("User context cleared")
    }
}

enum LogLevel: String {
    case debug, info, warning, error, fatal
}

