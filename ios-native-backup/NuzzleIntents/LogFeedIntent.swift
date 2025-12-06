import AppIntents
import Foundation
import WidgetKit

struct LogFeedIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Feed"
    static var description = IntentDescription("Log a feed for your baby")
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "Amount")
    var amount: Double?
    
    @Parameter(title: "Unit")
    var unit: String?
    
    func perform() async throws -> some IntentResult {
        // Queue action for app to process
        let action: WidgetActionService.WidgetAction
        if let amount = amount, amount == 120 {
            action = .logFeed120ml
        } else if let amount = amount, amount == 150 {
            action = .logFeed150ml
        } else {
            action = .logFeed120ml // Default
        }
        
        WidgetActionService.shared.queueAction(action, parameters: [
            "amount": amount ?? 120,
            "unit": unit ?? "ml"
        ])
        
        // Reload widget timelines
        WidgetCenter.shared.reloadTimelines(ofKind: "NextFeedWidget")
        
        return .result(value: "Feed logged")
    }
}

// Convenience intents for common amounts
struct LogFeed120mlIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Feed 120 ml"
    static var description = IntentDescription("Quick log a 120ml feed")
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult {
        WidgetActionService.shared.queueAction(.logFeed120ml)
        WidgetCenter.shared.reloadTimelines(ofKind: "NextFeedWidget")
        return .result()
    }
}

struct LogFeed150mlIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Feed 150 ml"
    static var description = IntentDescription("Quick log a 150ml feed")
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult {
        WidgetActionService.shared.queueAction(.logFeed150ml)
        WidgetCenter.shared.reloadTimelines(ofKind: "NextFeedWidget")
        return .result()
    }
}

struct LogFeedIntent_Previews: PreviewProvider {
    static var previews: some View {
        Text("Log Feed Intent")
    }
}

