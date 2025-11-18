import Foundation
import os.signpost

class SignpostLogger {
    static let dataStore = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "DataStore")
    static let predictions = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "Predictions")
    static let ui = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "UI")
    
    static func beginInterval(_ name: StaticString, log: OSLog = .default) -> OSSignpostID {
        let signpostID = OSSignpostID(log: log)
        os_signpost(.begin, log: log, name: name, signpostID: signpostID)
        return signpostID
    }
    
    static func endInterval(_ name: StaticString, signpostID: OSSignpostID, log: OSLog = .default) {
        os_signpost(.end, log: log, name: name, signpostID: signpostID)
    }
    
    static func event(_ name: StaticString, log: OSLog = .default) {
        let signpostID = OSSignpostID(log: log)
        os_signpost(.event, log: log, name: name, signpostID: signpostID)
    }
}


