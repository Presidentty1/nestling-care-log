import Foundation
import OSLog

extension Logger {
    private static var subsystem = Bundle.main.bundleIdentifier!
    
    static let dataStore = Logger(subsystem: subsystem, category: "DataStore")
    static let predictions = Logger(subsystem: subsystem, category: "Predictions")
    static let ui = Logger(subsystem: subsystem, category: "UI")
    static let network = Logger(subsystem: subsystem, category: "Network")
    static let performance = Logger(subsystem: subsystem, category: "Performance")
}

class PerformanceLogger {
    static func logTiming<T>(_ operation: String, category: Logger, _ block: () throws -> T) rethrows -> T {
        let startTime = Date()
        defer {
            let duration = Date().timeIntervalSince(startTime)
            category.info("\(operation) completed in \(String(format: "%.3f", duration))s")
        }
        return try block()
    }
    
    static func logTimingAsync<T>(_ operation: String, category: Logger, _ block: () async throws -> T) async rethrows -> T {
        let startTime = Date()
        defer {
            let duration = Date().timeIntervalSince(startTime)
            category.info("\(operation) completed in \(String(format: "%.3f", duration))s")
        }
        return try await block()
    }
}


