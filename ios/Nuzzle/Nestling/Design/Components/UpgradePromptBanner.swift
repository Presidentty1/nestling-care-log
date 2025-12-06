import SwiftUI

/// Banner prompting users to upgrade to Premium
/// Shows contextual upgrade messages based on user behavior
struct UpgradePromptBanner: View {
    let trigger: UpgradeTrigger
    let onUpgrade: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        HStack(spacing: .spacingMD) {
            // Icon
            Image(systemName: trigger.icon)
                .font(.system(size: 24))
                .foregroundColor(.primary)
                .frame(width: 40, height: 40)
                .background(Color.primary.opacity(0.1))
                .cornerRadius(.radiusMD)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(trigger.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.foreground)
                
                Text(trigger.message)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.mutedForeground)
                    .lineLimit(2)
            }
            
            Spacer()
            
            // CTA Button
            Button(action: {
                Haptics.light()
                onUpgrade()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 12))
                    Text("Upgrade")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, .spacingMD)
                .padding(.vertical, .spacingSM)
                .background(
                    LinearGradient(
                        colors: [Color.primary, Color.primary.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .cornerRadius(.radiusMD)
            }
            
            // Dismiss button
            Button(action: {
                Haptics.light()
                onDismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14))
                    .foregroundColor(.mutedForeground)
                    .frame(width: 28, height: 28)
            }
        }
        .padding(.spacingMD)
        .background(
            LinearGradient(
                colors: [
                    Color.primary.opacity(0.05),
                    Color.primary.opacity(0.02)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(.radiusLG)
        .overlay(
            RoundedRectangle(cornerRadius: .radiusLG)
                .stroke(Color.primary.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Upgrade Triggers

enum UpgradeTrigger {
    case fiftyEventsLogged
    case sevenDaysUsage
    case dailyLimitReached
    case weeklyInsight
    case growthTracking
    
    var icon: String {
        switch self {
        case .fiftyEventsLogged: return "chart.bar.fill"
        case .sevenDaysUsage: return "calendar.badge.checkmark"
        case .dailyLimitReached: return "exclamationmark.circle.fill"
        case .weeklyInsight: return "lightbulb.fill"
        case .growthTracking: return "chart.line.uptrend.xyaxis"
        }
    }
    
    var title: String {
        switch self {
        case .fiftyEventsLogged: return "50 events logged!"
        case .sevenDaysUsage: return "You're an active user!"
        case .dailyLimitReached: return "Daily limit reached"
        case .weeklyInsight: return "Unlock weekly insights"
        case .growthTracking: return "Track growth & milestones"
        }
    }
    
    var message: String {
        switch self {
        case .fiftyEventsLogged: return "Unlock AI insights and advanced analytics"
        case .sevenDaysUsage: return "Get unlimited predictions with Premium"
        case .dailyLimitReached: return "You've used your 3 daily predictions"
        case .weeklyInsight: return "See patterns and trends over time"
        case .growthTracking: return "Chart weight, height, and percentiles"
        }
    }
}

#Preview {
    VStack(spacing: .spacingMD) {
        UpgradePromptBanner(
            trigger: .fiftyEventsLogged,
            onUpgrade: {},
            onDismiss: {}
        )
        
        UpgradePromptBanner(
            trigger: .dailyLimitReached,
            onUpgrade: {},
            onDismiss: {}
        )
    }
    .padding()
    .background(Color.background)
}

