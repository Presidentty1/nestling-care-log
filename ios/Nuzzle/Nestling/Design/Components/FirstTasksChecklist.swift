import SwiftUI

/// First 3 tasks checklist to guide new users through initial activation
/// Shows on Home screen for first-time users
struct FirstTasksChecklist: View {
    @Binding var isVisible: Bool
    let hasLoggedFeed: Bool
    let hasLoggedSleep: Bool
    let hasViewedPredictions: Bool
    let onLogFeed: () -> Void
    let onLogSleep: () -> Void
    let onViewPredictions: () -> Void
    
    var body: some View {
        CardView(variant: .elevated) {
            VStack(alignment: .leading, spacing: .spacingMD) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Get Started")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.foreground)
                        Text("Complete these tasks to unlock the full experience")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.mutedForeground)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            isVisible = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.mutedForeground)
                    }
                }
                
                Divider()
                    .padding(.vertical, .spacingXS)
                
                // Tasks
                VStack(spacing: .spacingMD) {
                    TaskRow(
                        icon: "drop.fill",
                        title: "Log your first feed",
                        isCompleted: hasLoggedFeed,
                        action: hasLoggedFeed ? nil : onLogFeed
                    )
                    
                    TaskRow(
                        icon: "moon.fill",
                        title: "Log your first sleep",
                        isCompleted: hasLoggedSleep,
                        action: hasLoggedSleep ? nil : onLogSleep
                    )
                    
                    TaskRow(
                        icon: "brain.head.profile",
                        title: "Explore AI predictions",
                        isCompleted: hasViewedPredictions,
                        action: hasViewedPredictions ? nil : onViewPredictions,
                        isPremium: true
                    )
                }
                
                // Progress indicator
                let completedCount = [hasLoggedFeed, hasLoggedSleep, hasViewedPredictions].filter { $0 }.count
                ProgressView(value: Double(completedCount), total: 3.0)
                    .tint(.primary)
                    .padding(.top, .spacingSM)
                
                if completedCount == 3 {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.success)
                        Text("All done! You're a pro now 🎉")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.success)
                    }
                    .padding(.top, .spacingXS)
                }
            }
            .padding(.spacingLG)
        }
    }
}

// MARK: - Task Row
struct TaskRow: View {
    let icon: String
    let title: String
    let isCompleted: Bool
    let action: (() -> Void)?
    var isPremium: Bool = false
    
    var body: some View {
        Button(action: {
            action?()
            Haptics.light()
        }) {
            HStack(spacing: .spacingMD) {
                // Completion indicator
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundColor(isCompleted ? .success : .mutedForeground)
                
                // Icon
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(isCompleted ? .mutedForeground : .primary)
                    .frame(width: 24, height: 24)
                
                // Title
                Text(title)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(isCompleted ? .mutedForeground : .foreground)
                    .strikethrough(isCompleted)
                
                Spacer()
                
                // Premium badge
                if isPremium {
                    Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.primary)
                }
                
                // Chevron (if actionable)
                if !isCompleted && action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(.mutedForeground)
                }
            }
            .padding(.spacingMD)
            .background(isCompleted ? Color.surface.opacity(0.5) : Color.surface)
            .cornerRadius(.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusMD)
                    .stroke(isCompleted ? Color.success.opacity(0.3) : Color.cardBorder, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isCompleted || action == nil)
    }
}

#Preview {
    VStack(spacing: .spacingLG) {
        FirstTasksChecklist(
            isVisible: .constant(true),
            hasLoggedFeed: true,
            hasLoggedSleep: false,
            hasViewedPredictions: false,
            onLogFeed: {},
            onLogSleep: {},
            onViewPredictions: {}
        )
        
        FirstTasksChecklist(
            isVisible: .constant(true),
            hasLoggedFeed: true,
            hasLoggedSleep: true,
            hasViewedPredictions: true,
            onLogFeed: {},
            onLogSleep: {},
            onViewPredictions: {}
        )
    }
    .padding()
    .background(Color.background)
}

