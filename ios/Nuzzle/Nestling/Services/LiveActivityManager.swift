import Foundation
import ActivityKit
import WidgetKit

@available(iOS 16.1, *)
class LiveActivityManager {
    static let shared = LiveActivityManager()
    
    private var currentActivity: Activity<SleepActivityAttributes>?
    
    private init() {}
    
    /// Start Live Activity for sleep tracking with Dynamic Island support
    func startSleepActivity(for baby: Baby, startTime: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logger.debug("Live Activities not enabled")
            return
        }
        
        let attributes = SleepActivityAttributes(babyName: baby.name)
        let initialState = SleepActivityAttributes.ContentState(
            startTime: startTime,
            elapsedSeconds: 0,
            babyName: baby.name
        )
        
        do {
            let activity = try Activity<SleepActivityAttributes>.request(
                attributes: attributes,
                contentState: initialState,
                pushType: nil
            )
            currentActivity = activity
            Haptics.success()
        } catch {
            logger.debug("Failed to start Live Activity: \(error)")
        }
    }
    
    /// Update Live Activity with elapsed time
    func updateSleepActivity(elapsedSeconds: Int) {
        guard let activity = currentActivity else { return }
        
        let updatedState = SleepActivityAttributes.ContentState(
            startTime: activity.contentState.startTime,
            elapsedSeconds: elapsedSeconds,
            babyName: activity.attributes.babyName
        )
        
        Task {
            await activity.update(using: updatedState)
        }
    }
    
    /// Stop Live Activity
    func stopSleepActivity() {
        guard let activity = currentActivity else { return }
        
        let finalState = SleepActivityAttributes.ContentState(
            startTime: activity.contentState.startTime,
            elapsedSeconds: activity.contentState.elapsedSeconds,
            babyName: activity.attributes.babyName
        )
        
        Task {
            await activity.end(using: finalState, dismissalPolicy: .immediate)
            currentActivity = nil
            Haptics.success()
        }
    }
    
    /// Check if activity is active
    var isActive: Bool {
        currentActivity != nil
    }
}

