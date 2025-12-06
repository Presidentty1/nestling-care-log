import SwiftUI

struct UpgradePromptModal: View {
    @Binding var isPresented: Bool
    let trigger: UpgradeTrigger
    let onUpgrade: () -> Void
    
    enum UpgradeTrigger {
        case fiftyEvents
        case sevenDays
        case thirdPrediction
        
        var title: String {
            switch self {
            case .fiftyEvents: return "You're Logging Consistently!"
            case .sevenDays: return "You're an Active User!"
            case .thirdPrediction: return "Daily Limit Reached"
            }
        }
        
        var message: String {
            switch self {
            case .fiftyEvents: return "You've logged 50 events! Unlock weekly insights and AI predictions with Premium."
            case .sevenDays: return "After 7 days of tracking, you're ready for advanced features. Upgrade to unlock AI insights and premium analytics."
            case .thirdPrediction: return "You've used your 3 daily predictions. Upgrade for unlimited AI-powered predictions."
            }
        }
        
        var icon: String {
            switch self {
            case .fiftyEvents: return "chart.line.uptrend.xyaxis"
            case .sevenDays: return "star.fill"
            case .thirdPrediction: return "brain.head.profile"
            }
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.easeInOut) {
                        isPresented = false
                    }
                }
            
            VStack(spacing: .spacingXL) {
                // Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.primary.opacity(0.2), Color.primary.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: trigger.icon)
                        .font(.system(size: 36))
                        .foregroundColor(.primary)
                }
                
                // Title and message
                VStack(spacing: .spacingMD) {
                    Text(trigger.title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.foreground)
                        .multilineTextAlignment(.center)
                    
                    Text(trigger.message)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Benefits list
                VStack(alignment: .leading, spacing: .spacingMD) {
                    BenefitRow(icon: "brain.head.profile", text: "Unlimited AI predictions")
                    BenefitRow(icon: "chart.bar.fill", text: "Weekly insights & trends")
                    BenefitRow(icon: "calendar", text: "Calendar heatmap")
                    BenefitRow(icon: "doc.text.fill", text: "PDF doctor reports")
                }
                .padding()
                .background(Color.surface.opacity(0.5))
                .cornerRadius(.radiusLG)
                
                // Action buttons
                VStack(spacing: .spacingMD) {
                    Button(action: {
                        Haptics.medium()
                        onUpgrade()
                        isPresented = false
                    }) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .font(.system(size: 16))
                            Text("Start 7-Day Free Trial")
                                .font(.system(size: 17, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [Color.primary, Color.primary.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(.radiusLG)
                        .shadow(color: Color.primary.opacity(0.4), radius: 12, x: 0, y: 6)
                    }
                    
                    Button("Maybe Later") {
                        Haptics.light()
                        withAnimation(.easeInOut) {
                            isPresented = false
                        }
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.mutedForeground)
                }
                
                Text("No credit card required")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(.mutedForeground)
            }
            .padding(.spacingXL)
            .background(Color.background)
            .cornerRadius(.radius2XL)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, .spacingLG)
        }
    }
}

struct BenefitRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: .spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.primary)
                .frame(width: 24)
            
            Text(text)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.foreground)
            
            Spacer()
        }
    }
}

#Preview {
    @Previewable @State var isPresented = true
    return UpgradePromptModal(
        isPresented: $isPresented,
        trigger: .fiftyEvents,
        onUpgrade: {}
    )
}

