import SwiftUI

struct FirstLogCard: View {
    let onLog: () -> Void
    let userGoal: String?
    @State private var pulse = false
    
    init(onLog: @escaping () -> Void, userGoal: String? = nil) {
        self.onLog = onLog
        self.userGoal = userGoal
    }
    
    private var cardConfig: (title: String, emoji: String, buttonText: String, icon: String) {
        switch userGoal {
        case "sleep":
            return ("Welcome! Let's track your first nap together", "😴", "Log First Nap", "moon.fill")
        case "feeding":
            return ("Welcome! Let's track your first feed together", "🍼", "Log First Feed", "drop.fill")
        case "health":
            return ("Welcome! Let's log your baby's health", "📊", "Log First Event", "heart.text.square.fill")
        case "survive":
            return ("You've got this! Let's log together", "💪", "Start Tracking", "sparkles")
        default:
            return ("Welcome! Let's track your first feed together", "🍼", "Log First Feed", "drop.fill")
        }
    }
    
    var body: some View {
        Button(action: {
            Haptics.medium()
            onLog()
        }) {
            VStack(spacing: .spacingLG) {
                // Icon with pulsing animation
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.15))
                        .frame(width: 80, height: 80)
                        .scaleEffect(pulse ? 1.1 : 1.0)
                    
                    Image(systemName: cardConfig.icon)
                        .font(.system(size: 36))
                        .foregroundColor(.primary)
                }
                
                VStack(spacing: .spacingSM) {
                    Text("\(cardConfig.title) \(cardConfig.emoji)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.foreground)
                        .multilineTextAlignment(.center)
                    
                    Text("This will take just 10 seconds")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(.mutedForeground)
                }
                
                // Action button
                HStack {
                    Text(cardConfig.buttonText)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Color.primary)
                .cornerRadius(.radiusLG)
            }
            .padding(.spacingXL)
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.elevated,
                    Color.surface
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(.radiusXL)
        .overlay(
            RoundedRectangle(cornerRadius: .radiusXL)
                .stroke(Color.primary.opacity(0.2), lineWidth: 1.5)
        )
        .shadow(color: Color.primary.opacity(0.1), radius: 12, x: 0, y: 6)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}

#Preview {
    FirstLogCard(onLog: {})
        .padding()
}





