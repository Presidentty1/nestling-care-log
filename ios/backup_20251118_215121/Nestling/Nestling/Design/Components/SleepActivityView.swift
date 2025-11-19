import SwiftUI
import WidgetKit
import ActivityKit

/// Live Activity view for sleep tracking (Dynamic Island + Lock Screen)
@available(iOS 16.1, *)
struct SleepActivityView: View {
    let context: ActivityViewContext<SleepActivityAttributes>
    
    var body: some View {
        // Compact presentation (Dynamic Island compact)
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "moon.fill")
                    .font(.caption)
                Text(context.attributes.babyName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            Text(formatDuration(context.state.elapsedSeconds))
                .font(.caption2)
                .monospacedDigit()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

/// Expanded presentation (Dynamic Island expanded)
@available(iOS 16.1, *)
struct SleepActivityExpandedView: View {
    let context: ActivityViewContext<SleepActivityAttributes>
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "moon.fill")
                .font(.title2)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Sleep Tracking")
                    .font(.headline)
                Text(context.attributes.babyName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(formatDuration(context.state.elapsedSeconds))
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospacedDigit()
                Text("elapsed")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Button(intent: StopSleepIntent()) {
                Image(systemName: "stop.fill")
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.red)
                    .clipShape(Circle())
            }
        }
        .padding()
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

/// Lock screen presentation
@available(iOS 16.1, *)
struct SleepActivityLockScreenView: View {
    let context: ActivityViewContext<SleepActivityAttributes>
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "moon.fill")
                .font(.title3)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Sleep: \(context.attributes.babyName)")
                    .font(.headline)
                Text(formatDuration(context.state.elapsedSeconds))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

