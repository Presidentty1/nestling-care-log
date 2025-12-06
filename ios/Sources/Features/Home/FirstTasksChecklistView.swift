import SwiftUI

/// First Tasks Checklist shown to new users after onboarding
/// Guides them through their first 3 actions to increase activation
struct FirstTasksChecklistView: View {
    @Environment(\.colorScheme) private var colorScheme
    let tasksCompleted: FirstTasksProgress
    let onLogFeed: () -> Void
    let onLogSleep: () -> Void
    let onExplorePredictions: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingMD) {
            // Header
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(Color.adaptivePrimary(colorScheme))
                    .font(.system(size: 24))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Get Started")
                        .font(.headline)
                        .foregroundColor(Color.adaptiveForeground(colorScheme))
                    
                    Text("\(tasksCompleted.completedCount) of 3 completed")
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                }
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                        .font(.system(size: 14))
                }
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.adaptiveSurface(colorScheme))
                        .frame(height: 6)
                    
                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.adaptivePrimary(colorScheme))
                        .frame(width: geometry.size.width * tasksCompleted.progressPercentage, height: 6)
                        .animation(.easeInOut, value: tasksCompleted.progressPercentage)
                }
            }
            .frame(height: 6)
            
            // Tasks
            VStack(spacing: .spacingSM) {
                TaskRow(
                    title: "Log your first feed",
                    isCompleted: tasksCompleted.hasLoggedFeed,
                    icon: "bottle.fill",
                    action: tasksCompleted.hasLoggedFeed ? nil : onLogFeed
                )
                
                TaskRow(
                    title: "Log your first sleep",
                    isCompleted: tasksCompleted.hasLoggedSleep,
                    icon: "moon.fill",
                    action: tasksCompleted.hasLoggedSleep ? nil : onLogSleep
                )
                
                TaskRow(
                    title: "Explore AI predictions",
                    isCompleted: tasksCompleted.hasExploredPredictions,
                    icon: "sparkles",
                    action: tasksCompleted.hasExploredPredictions ? nil : onExplorePredictions,
                    isProFeature: true
                )
            }
            
            // Celebration message when all complete
            if tasksCompleted.allCompleted {
                HStack(spacing: .spacingSM) {
                    Image(systemName: "party.popper.fill")
                        .foregroundColor(.yellow)
                    
                    Text("You're all set! Keep logging to unlock insights.")
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                        .multilineTextAlignment(.leading)
                }
                .padding(.top, .spacingSM)
            }
        }
        .padding(.spacingMD)
        .background(Color.adaptiveSurface(colorScheme))
        .cornerRadius(.radiusMD)
        .overlay(
            RoundedRectangle(cornerRadius: .radiusMD)
                .stroke(Color.adaptivePrimary(colorScheme).opacity(0.3), lineWidth: 1)
        )
    }
}

struct TaskRow: View {
    @Environment(\.colorScheme) private var colorScheme
    let title: String
    let isCompleted: Bool
    let icon: String
    let action: (() -> Void)?
    var isProFeature: Bool = false
    
    var body: some View {
        Button(action: {
            if !isCompleted, let action = action {
                Haptics.light()
                action()
            }
        }) {
            HStack(spacing: .spacingMD) {
                // Checkbox
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleted ? .green : Color.adaptiveTextTertiary(colorScheme))
                    .font(.system(size: 20))
                
                // Icon
                Image(systemName: icon)
                    .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                    .font(.system(size: 16))
                    .frame(width: 20)
                
                // Title
                Text(title)
                    .font(.body)
                    .foregroundColor(isCompleted ? Color.adaptiveTextSecondary(colorScheme) : Color.adaptiveForeground(colorScheme))
                    .strikethrough(isCompleted)
                
                Spacer()
                
                // Pro badge if needed
                if isProFeature && !isCompleted {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 12))
                }
                
                // Arrow for incomplete tasks
                if !isCompleted {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color.adaptiveTextTertiary(colorScheme))
                        .font(.system(size: 12))
                }
            }
            .padding(.vertical, .spacingXS)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isCompleted)
    }
}

/// Tracks progress of first tasks for new users
struct FirstTasksProgress {
    var hasLoggedFeed: Bool = false
    var hasLoggedSleep: Bool = false
    var hasExploredPredictions: Bool = false
    
    var completedCount: Int {
        var count = 0
        if hasLoggedFeed { count += 1 }
        if hasLoggedSleep { count += 1 }
        if hasExploredPredictions { count += 1 }
        return count
    }
    
    var progressPercentage: CGFloat {
        return CGFloat(completedCount) / 3.0
    }
    
    var allCompleted: Bool {
        return completedCount == 3
    }
}

#Preview {
    VStack(spacing: .spacingLG) {
        // No tasks completed
        FirstTasksChecklistView(
            tasksCompleted: FirstTasksProgress(),
            onLogFeed: {},
            onLogSleep: {},
            onExplorePredictions: {},
            onDismiss: {}
        )
        .padding()
        
        // Some tasks completed
        FirstTasksChecklistView(
            tasksCompleted: FirstTasksProgress(hasLoggedFeed: true, hasLoggedSleep: true),
            onLogFeed: {},
            onLogSleep: {},
            onExplorePredictions: {},
            onDismiss: {}
        )
        .padding()
        
        // All tasks completed
        FirstTasksChecklistView(
            tasksCompleted: FirstTasksProgress(hasLoggedFeed: true, hasLoggedSleep: true, hasExploredPredictions: true),
            onLogFeed: {},
            onLogSleep: {},
            onExplorePredictions: {},
            onDismiss: {}
        )
        .padding()
    }
}

