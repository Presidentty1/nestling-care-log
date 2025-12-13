import SwiftUI
/// Trial countdown banner shown at top of Home screen
struct TrialBannerView: View {
    let daysRemaining: Int
    let onUpgrade: () -> Void
    
    var body: some View {
        HStack(spacing: .spacingSM) {
            Image(systemName: "star.fill")
                .font(.system(size: 16))
                .foregroundColor(.yellow)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(bannerTitle)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.foreground)
                
                Text(bannerSubtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.mutedForeground)
            }
            
            Spacer()
            
            Button(action: {
                Haptics.selection()
                onUpgrade()
            }) {
                Text("Upgrade")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, .spacingMD)
                    .padding(.vertical, .spacingXS)
                    .background(Color.primary)
                    .cornerRadius(.radiusSM)
            }
        }
        .padding(.spacingMD)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.primary.opacity(0.1),
                    Color.primary.opacity(0.05)
                ]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(.radiusMD)
        .overlay(
            RoundedRectangle(cornerRadius: .radiusMD)
                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
        )
    }
    
    private var bannerTitle: String {
        if daysRemaining == 0 {
            return "Trial ends today"
        } else if daysRemaining == 1 {
            return "1 day left in your trial"
        } else if daysRemaining <= 2 {
            return "\(daysRemaining) days left in trial ⚡"
        } else {
            return "\(daysRemaining) days left in your trial"
        }
    }
    
    private var bannerSubtitle: String {
        if daysRemaining <= 1 {
            return "Upgrade now to keep all features"
        } else {
            return "Unlock all Pro features"
        }
    }
}

/// Celebration view shown after trial starts
struct TrialStartedCelebrationView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: .spacingXL) {
            Spacer()
            
            // Animated star
            Image(systemName: "star.fill")
                .font(.system(size: 80))
                .foregroundColor(.yellow)
                .scaleEffect(1.2)
                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: true)
            
            VStack(spacing: .spacingMD) {
                Text("Welcome! 🎉")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.foreground)
                
                Text("Your 7-day free trial has started")
                    .font(.system(size: 18, weight: .regular))
                    .foregroundColor(.mutedForeground)
                    .multilineTextAlignment(.center)
                
                Text("Explore all Pro features at no cost")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.top, .spacingXS)
            }
            
            Spacer()
            
            Button(action: {
                Haptics.light()
                dismiss()
            }) {
                Text("Start Tracking")
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
    }
}

#Preview("Trial Banner - 5 days") {
    VStack {
        TrialBannerView(daysRemaining: 5) {
            logger.debug("Upgrade tapped")
        }
        .padding()
        
        Spacer()
    }
    .background(Color.background)
}

#Preview("Trial Banner - 1 day") {
    VStack {
        TrialBannerView(daysRemaining: 1) {
            logger.debug("Upgrade tapped")
        }
        .padding()
        
        Spacer()
    }
    .background(Color.background)
}

#Preview("Trial Started Celebration") {
    TrialStartedCelebrationView()
}

