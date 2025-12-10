import Foundation

/// Service for handling widget actions via App Groups.
/// Widgets can trigger actions that the app processes on launch.
class WidgetActionService {
    static let shared = WidgetActionService()
    
    private let appGroupID = "group.com.nestling.app.shared"
    private let userDefaults: UserDefaults?
    
    private init() {
        userDefaults = UserDefaults(suiteName: appGroupID)
    }
    
    enum WidgetAction: String, Codable {
        case logFeed120ml = "logFeed120ml"
        case logFeed150ml = "logFeed150ml"
        case startSleep = "startSleep"
        case stopSleep = "stopSleep"
    }
    
    /// Queue an action from a widget to be processed by the app
    func queueAction(_ action: WidgetAction, parameters: [String: Any]? = nil) {
        guard let userDefaults = userDefaults else { return }
        
        let actionData: [String: Any] = [
            "action": action.rawValue,
            "parameters": parameters ?? [:],
            "timestamp": Date().timeIntervalSince1970
        ]
        
        userDefaults.set(actionData, forKey: "pendingWidgetAction")
        userDefaults.synchronize()
    }
    
    /// Get and clear pending widget action (called by app on launch)
    func consumePendingAction() -> (action: WidgetAction, parameters: [String: Any])? {
        guard let userDefaults = userDefaults,
              let actionData = userDefaults.dictionary(forKey: "pendingWidgetAction"),
              let actionString = actionData["action"] as? String,
              let action = WidgetAction(rawValue: actionString) else {
            return nil
        }
        
        let parameters = actionData["parameters"] as? [String: Any] ?? [:]
        
        // Clear the action
        userDefaults.removeObject(forKey: "pendingWidgetAction")
        userDefaults.synchronize()
        
        return (action, parameters)
    }
}

