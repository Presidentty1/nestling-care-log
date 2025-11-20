import Foundation

/// Service for crash reporting and error tracking
/// MVP implementation uses console logging, can be upgraded to Sentry/Firebase
@MainActor
class CrashReportingService {
    static let shared = CrashReportingService()

    private var enabled = true

    private init() {
        // Set up any initial configuration
        print("✅ CrashReportingService initialized")
    }

    /// Log a non-fatal error
    func logError(_ error: Error, context: [String: Any]? = nil, file: String = #file, function: String = #function, line: Int = #line) {
        guard enabled else { return }

        let errorInfo: [String: Any] = [
            "error": error.localizedDescription,
            "file": URL(fileURLWithPath: file).lastPathComponent,
            "function": function,
            "line": line,
            "timestamp": Date().ISO8601Format(),
            "context": context ?? [:]
        ]

        print("🚨 Error logged: \(errorInfo)")

        // TODO: Send to crash reporting service (Sentry, Firebase, etc.)
        // For MVP, just log to console
    }

    /// Log a fatal crash (if we can catch it before termination)
    func logCrash(_ error: Error, context: [String: Any]? = nil) {
        guard enabled else { return }

        let crashInfo: [String: Any] = [
            "crash": true,
            "error": error.localizedDescription,
            "timestamp": Date().ISO8601Format(),
            "context": context ?? [:]
        ]

        print("💥 Crash logged: \(crashInfo)")

        // TODO: Send critical crash data to service
    }

    /// Log a user action that might be relevant for debugging
    func logBreadcrumb(_ message: String, category: String, data: [String: Any]? = nil) {
        guard enabled else { return }

        let breadcrumb: [String: Any] = [
            "message": message,
            "category": category,
            "timestamp": Date().ISO8601Format(),
            "data": data ?? [:]
        ]

        print("📝 Breadcrumb: \(breadcrumb)")
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
