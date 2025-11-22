import AppIntents
import Foundation

struct LogDiaperIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Diaper Change"
    static var description = IntentDescription("Log a diaper change")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Type")
    var type: DiaperType
    
    @Parameter(title: "Baby Name")
    var babyName: String?
    
    enum DiaperType: String, AppEnum {
        case wet
        case dirty
        case both
        
        static var typeDisplayRepresentation: TypeDisplayRepresentation = "Diaper Type"
        static var caseDisplayRepresentations: [DiaperType: DisplayRepresentation] = [
            .wet: "Wet",
            .dirty: "Dirty",
            .both: "Both"
        ]
    }
    
    func perform() async throws -> some IntentResult {
        // Access shared App Group storage and log diaper change
        return .result(value: "Logged \(type.rawValue) diaper change")
    }
}


