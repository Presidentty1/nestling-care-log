import SwiftUI

struct FirstTasksChecklistCard: View {
    let hasLoggedFeed: Bool
    let hasLoggedSleep: Bool
    let onExploreAI: () -> Void
    let onDismiss: () -> Void
    
    private var completedCount: Int {
        var count = 0
        if hasLoggedFeed { count += 1 }
        if hasLoggedSleep { count += 1 }
        return count
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingMD) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Get Started")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.foreground)
                    
                    Text("\(completedCount) of 3 complete")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.mutedForeground)
                }
                
                Spacer()
                
                Button(action: {
                    Haptics.light()
                    onDismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.mutedForeground)
                }
            }
            
            VStack(alignment: .leading, spacing: .spacingMD) {
                TaskRow(
                    icon: "drop.fill",
                    iconColor: .eventFeed,
                    title: "Log first feed",
                    isCompleted: hasLoggedFeed
                )
                
                TaskRow(
                    icon: "moon.fill",
                    iconColor: .eventSleep,
                    title: "Log first sleep",
                    isCompleted: hasLoggedSleep
                )
                
                Button(action: {
                    Haptics.light()
                    onExploreAI()
                }) {
                    HStack(spacing: .spacingMD) {
                        ZStack {
                            Circle()
                                .fill(Color.primary.opacity(0.1))
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 16))
                                .foregroundColor(.primary)
                        }
                        
                        HStack {
                            Text("Explore AI Predictions")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.foreground)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.primary)
                                Text("Pro")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.primary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.primary.opacity(0.1))
                            .cornerRadius(8)
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.mutedForeground)
                        }
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.mutedForeground.opacity(0.2))
                        .frame(height: 4)
                        .cornerRadius(2)
                    
                    Rectangle()
                        .fill(Color.primary)
                        .frame(width: geometry.size.width * (CGFloat(completedCount) / 3.0), height: 4)
                        .cornerRadius(2)
                        .animation(.easeInOut(duration: 0.3), value: completedCount)
                }
            }
            .frame(height: 4)
        }
        .padding(.spacingLG)
        .background(Color.surface)
        .cornerRadius(.radiusLG)
        .overlay(
            RoundedRectangle(cornerRadius: .radiusLG)
                .stroke(Color.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

struct TaskRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let isCompleted: Bool
    
    var body: some View {
        HStack(spacing: .spacingMD) {
            ZStack {
                Circle()
                    .fill(isCompleted ? iconColor.opacity(0.2) : Color.mutedForeground.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(iconColor)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 16))
                        .foregroundColor(.mutedForeground)
                }
            }
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isCompleted ? .mutedForeground : .foreground)
                .strikethrough(isCompleted)
        }
    }
}

#Preview {
    VStack(spacing: .spacingLG) {
        FirstTasksChecklistCard(
            hasLoggedFeed: true,
            hasLoggedSleep: false,
            onExploreAI: {},
            onDismiss: {}
        )
        
        FirstTasksChecklistCard(
            hasLoggedFeed: true,
            hasLoggedSleep: true,
            onExploreAI: {},
            onDismiss: {}
        )
    }
    .padding()
    .background(Color.background)
}
