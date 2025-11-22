import WidgetKit
import SwiftUI
import ActivityKit

/// Widget configuration for Sleep Live Activity
@available(iOS 16.1, *)
struct SleepActivityWidget: Widget {
    let kind: String = "SleepActivityWidget"
    
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SleepActivityAttributes.self) { context in
            // Lock screen UI
            SleepActivityLockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Compact region (left side)
                DynamicIslandExpandedRegion(.leading) {
                    SleepActivityView(context: context)
                }
                
                // Compact region (right side)
                DynamicIslandExpandedRegion(.trailing) {
                    Button(intent: StopSleepIntent()) {
                        Image(systemName: "stop.fill")
                            .foregroundColor(.red)
                    }
                }
                
                // Expanded region (bottom)
                DynamicIslandExpandedRegion(.bottom) {
                    SleepActivityExpandedView(context: context)
                }
            } compactLeading: {
                Image(systemName: "moon.fill")
                    .foregroundColor(.blue)
            } compactTrailing: {
                Text(formatDuration(context.state.elapsedSeconds))
                    .font(.caption2)
                    .monospacedDigit()
            } minimal: {
                Image(systemName: "moon.fill")
                    .foregroundColor(.blue)
            }
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(minutes)m"
        }
    }
}


