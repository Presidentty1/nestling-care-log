import SwiftUI

struct AITeaseCard: View {
    let focusArea: FocusArea?
    let onCryAnalysisTap: () -> Void
    let onQATap: () -> Void
    
    var body: some View {
        CardView(variant: .default) {
            VStack(spacing: .spacingMD) {
                // Header
                HStack(spacing: .spacingSM) {
                    Image(systemName: "sparkles")
                        .font(.title3)
                        .foregroundColor(.primary)
                    
                    Text("AI Features")
                        .font(.headline)
                        .foregroundColor(.foreground)
                    
                    Spacer()
                    
                    // Beta badge
                    Text("Beta")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primary.opacity(0.1))
                        .cornerRadius(8)
                }
                
                // Focused feature based on user's goals
                if shouldShowCryAnalysis {
                    AIFeatureRow(
                        icon: "waveform",
                        iconColor: .eventCry,
                        title: "Record a cry to get a possible reason",
                        subtitle: "Tap to start recording",
                        badge: "Beta",
                        action: onCryAnalysisTap
                    )
                }
                
                AIFeatureRow(
                    icon: "bubble.left.and.bubble.right.fill",
                    iconColor: .info,
                    title: "Ask anything about \(babyPossessive) day",
                    subtitle: "Chat with AI about patterns and insights",
                    badge: nil,
                    action: onQATap
                )
                
                // Safety disclaimer
                Text("These suggestions can help you reflect, but they don't replace medical care.")
                    .font(.caption2)
                    .foregroundColor(.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.top, .spacingXS)
            }
            .padding(.spacingMD)
        }
        .accessibilityElement(children: .contain)
    }
    
    private var shouldShowCryAnalysis: Bool {
        guard let area = focusArea else { return true }
        return area == .cries || area == .all
    }
    
    private var babyPossessive: String {
        "your baby's"
    }
}

// MARK: - AI Feature Row
struct AIFeatureRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let badge: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            Haptics.light()
            action()
        }) {
            HStack(spacing: .spacingMD) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(iconColor)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.foreground)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.medium)
                                .foregroundColor(.mutedForeground)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.surface)
                                .cornerRadius(6)
                        }
                    }
                    
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.mutedForeground)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.mutedForeground)
            }
            .padding(.spacingSM)
            .background(Color.surface)
            .cornerRadius(.radiusMD)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(title). \(subtitle)")
        .accessibilityHint("Double tap to open")
    }
}

#Preview {
    VStack(spacing: .spacingLG) {
        AITeaseCard(
            focusArea: .all,
            onCryAnalysisTap: {
                logger.debug("Cry analysis tapped")
            },
            onQATap: {
                logger.debug("Q&A tapped")
            }
        )
        
        AITeaseCard(
            focusArea: .napsAndNights,
            onCryAnalysisTap: {
                logger.debug("Cry analysis tapped")
            },
            onQATap: {
                logger.debug("Q&A tapped")
            }
        )
    }
    .padding()
    .background(Color.background)
}

