import SwiftUI

/// Celebration view shown when user reaches a milestone
struct MilestoneCelebrationView: View {
    let milestone: Milestone
    @Environment(\.dismiss) private var dismiss
    @State private var showConfetti = false
    
    private var celebrationsEnabled: Bool {
        UserDefaults.standard.object(forKey: "celebrationsEnabled") as? Bool ?? true
    }
    
    enum Milestone {
        case firstLog
        case threeDays
        case oneWeek
        case twoWeeks
        
        var title: String {
            switch self {
            case .firstLog: return "First Log! 🎉"
            case .threeDays: return "3 Day Streak! 🔥"
            case .oneWeek: return "First Week Complete! 🎊"
            case .twoWeeks: return "Two Weeks Strong! 💪"
            }
        }
        
        var message: String {
            switch self {
            case .firstLog:
                return "You've started your tracking journey. Keep it up!"
            case .threeDays:
                return "You're building a great habit. Patterns are starting to emerge."
            case .oneWeek:
                return "Amazing! You've logged for a full week. Your baby's patterns are becoming clear."
            case .twoWeeks:
                return "Incredible dedication! Two weeks of tracking helps you understand your baby so much better."
            }
        }
        
        var icon: String {
            switch self {
            case .firstLog: return "star.fill"
            case .threeDays: return "flame.fill"
            case .oneWeek: return "rosette"
            case .twoWeeks: return "crown.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .firstLog: return .primary
            case .threeDays: return .orange
            case .oneWeek: return .red
            case .twoWeeks: return .yellow
            }
        }
    }
    
    var body: some View {
        VStack(spacing: .spacing2XL) {
            Spacer()
            
            // Animated icon
            ZStack {
                Circle()
                    .fill(milestone.color.opacity(0.2))
                    .frame(width: 120, height: 120)
                    .scaleEffect(showConfetti ? 1.2 : 1.0)
                
                Image(systemName: milestone.icon)
                    .font(.system(size: 60))
                    .foregroundColor(milestone.color)
                    .scaleEffect(showConfetti ? 1.0 : 0.8)
            }
            
            VStack(spacing: .spacingMD) {
                Text(milestone.title)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.foreground)
                    .multilineTextAlignment(.center)
                
                Text(milestone.message)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, .spacingLG)
            }
            
            Spacer()
            
            Button(action: {
                Haptics.light()
                dismiss()
            }) {
                Text("Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color.primary)
                    .cornerRadius(.radiusXL)
                    .shadow(color: Color.primary.opacity(0.3), radius: 12, x: 0, y: 6)
            }
            .padding(.horizontal, .spacingLG)
            .padding(.bottom, .spacing2XL)
        }
        .background(Color.background)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                if celebrationsEnabled {
                    showConfetti = true
                }
            }
            
            // Trigger haptic celebration
            if celebrationsEnabled {
                Haptics.success()
            }
        }
    }
}

#Preview("First Log") {
    MilestoneCelebrationView(milestone: .firstLog)
}

#Preview("One Week") {
    MilestoneCelebrationView(milestone: .oneWeek)
}

