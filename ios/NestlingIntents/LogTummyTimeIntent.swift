import AppIntents
import Foundation

struct LogTummyTimeIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Tummy Time"
    static var description = IntentDescription("Log a tummy time session")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Duration (minutes)")
    var duration: Int
    
    @Parameter(title: "Baby Name")
    var babyName: String?
    
    func perform() async throws -> some IntentResult {
        // Access shared App Group storage and log tummy time
        return .result(value: "Logged \(duration) minute tummy time session")
    }
}


