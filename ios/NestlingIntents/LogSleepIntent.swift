import AppIntents
import Foundation
import WidgetKit

struct StartSleepIntent: AppIntent {
    static var title: LocalizedStringResource = "Start Sleep"
    static var description = IntentDescription("Start tracking a sleep session")
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult {
        WidgetActionService.shared.queueAction(.startSleep)
        WidgetCenter.shared.reloadTimelines(ofKind: "NextNapWidget")
        return .result(value: "Sleep started")
    }
}

struct StopSleepIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Sleep"
    static var description = IntentDescription("Stop tracking the current sleep session")
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult {
        WidgetActionService.shared.queueAction(.stopSleep)
        WidgetCenter.shared.reloadTimelines(ofKind: "NextNapWidget")
        return .result(value: "Sleep stopped")
    }
}

// Toggle sleep intent (for widget buttons)
struct ToggleSleepIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Sleep"
    static var description = IntentDescription("Start or stop sleep tracking")
    static var openAppWhenRun: Bool = false
    
    @Parameter(title: "Is Active")
    var isActive: Bool
    
    func perform() async throws -> some IntentResult {
        if isActive {
            WidgetActionService.shared.queueAction(.stopSleep)
        } else {
            WidgetActionService.shared.queueAction(.startSleep)
        }
        WidgetCenter.shared.reloadTimelines(ofKind: "NextNapWidget")
        return .result()
    }
}

