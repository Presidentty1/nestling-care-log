import Foundation
import os.log

/// Centralized logging utility using OSLog
/// Replaces print statements with proper logging that integrates with Console.app and crash reporting
class Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.nestling.Nestling"

    // Create loggers for different categories
    private static let uiLogger = OSLog(subsystem: subsystem, category: "UI")
    private static let networkLogger = OSLog(subsystem: subsystem, category: "Network")
    private static let dataLogger = OSLog(subsystem: subsystem, category: "Data")
    private static let authLogger = OSLog(subsystem: subsystem, category: "Auth")
    private static let analyticsLogger = OSLog(subsystem: subsystem, category: "Analytics")

    // MARK: - UI Logging

    static func ui(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        os_log(.debug, log: uiLogger, "%{public}@ [%@:%d]", message, (file as NSString).lastPathComponent, line)
    }

    static func uiInfo(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        os_log(.info, log: uiLogger, "%{public}@ [%@:%d]", message, (file as NSString).lastPathComponent, line)
    }

    static func uiError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        os_log(.error, log: uiLogger, "%{public}@ [%@:%d]", message, (file as NSString).lastPathComponent, line)
    }

    // MARK: - Network Logging

    static func network(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        os_log(.debug, log: networkLogger, "%{public}@ [%@:%d]", message, (file as NSString).lastPathComponent, line)
    }

    static func networkError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        os_log(.error, log: networkLogger, "%{public}@ [%@:%d]", message, (file as NSString).lastPathComponent, line)
    }

    // MARK: - Data Logging

    static func data(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        os_log(.debug, log: dataLogger, "%{public}@ [%@:%d]", message, (file as NSString).lastPathComponent, line)
    }

    static func dataError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        os_log(.error, log: dataLogger, "%{public}@ [%@:%d]", message, (file as NSString).lastPathComponent, line)
    }

    // MARK: - Auth Logging

    static func auth(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        os_log(.debug, log: authLogger, "%{public}@ [%@:%d]", message, (file as NSString).lastPathComponent, line)
    }

    static func authError(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        os_log(.error, log: authLogger, "%{public}@ [%@:%d]", message, (file as NSString).lastPathComponent, line)
    }

    // MARK: - Analytics Logging

    static func analytics(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        os_log(.debug, log: analyticsLogger, "%{public}@ [%@:%d]", message, (file as NSString).lastPathComponent, line)
    }

    // MARK: - Generic Logging

    static func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        os_log(.debug, log: uiLogger, "%{public}@ [%@:%d]", message, (file as NSString).lastPathComponent, line)
    }

    static func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        os_log(.info, log: uiLogger, "%{public}@ [%@:%d]", message, (file as NSString).lastPathComponent, line)
    }

    static func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        os_log(.default, log: uiLogger, "%{public}@ [%@:%d]", message, (file as NSString).lastPathComponent, line)
    }

    static func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        os_log(.error, log: uiLogger, "%{public}@ [%@:%d]", message, (file as NSString).lastPathComponent, line)
    }

    static func fault(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        os_log(.fault, log: uiLogger, "%{public}@ [%@:%d]", message, (file as NSString).lastPathComponent, line)

        // Report faults to crash reporter in production
        #if !DEBUG
        CrashReporter.shared.reportIssue(message, level: .fatal, file: file, function: function, line: line)
        #endif
    }
}
