import SwiftUI

/// Reusable upgrade prompt card for Premium features
/// Used throughout the app to drive conversion
struct UpgradePromptCard: View {
    @Environment(\.colorScheme) private var colorScheme
    let feature: String
    let description: String
    let icon: String
    let onUpgrade: () -> Void
    let onDismiss: (() -> Void)?
    
    init(
        feature: String,
        description: String,
        icon: String = "crown.fill",
        onUpgrade: @escaping () -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        self.feature = feature
        self.description = description
        self.icon = icon
        self.onUpgrade = onUpgrade
        self.onDismiss = onDismiss
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingMD) {
            // Header with dismiss button
            HStack {
                HStack(spacing: .spacingSM) {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(.yellow)
                    
                    Text("Premium Feature")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                }
                
                Spacer()
                
                if let dismiss = onDismiss {
                    Button(action: dismiss) {
                        Image(systemName: "xmark")
                            .font(.system(size: 12))
                            .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                    }
                }
            }
            
            // Feature title
            Text(feature)
                .font(.title3.bold())
                .foregroundColor(Color.adaptiveForeground(colorScheme))
            
            // Description
            Text(description)
                .font(.body)
                .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                .fixedSize(horizontal: false, vertical: true)
            
            // Upgrade button
            Button(action: onUpgrade) {
                HStack {
                    Image(systemName: "crown.fill")
                        .font(.body)
                    
                    Text("Upgrade to Premium")
                        .font(.body.weight(.semibold))
                    
                    Spacer()
                    
                    Image(systemName: "arrow.right")
                        .font(.body)
                }
                .foregroundColor(.white)
                .padding(.spacingMD)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color.adaptivePrimary(colorScheme), Color.adaptivePrimary(colorScheme).opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(.radiusMD)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.spacingMD)
        .background(
            RoundedRectangle(cornerRadius: .radiusMD)
                .fill(Color.adaptivePrimary(colorScheme).opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: .radiusMD)
                .stroke(Color.adaptivePrimary(colorScheme).opacity(0.2), lineWidth: 1)
        )
    }
}

/// Inline upgrade prompt (smaller, for list items)
struct InlineUpgradePrompt: View {
    @Environment(\.colorScheme) private var colorScheme
    let text: String
    let onUpgrade: () -> Void
    
    var body: some View {
        Button(action: onUpgrade) {
            HStack(spacing: .spacingSM) {
                Image(systemName: "crown.fill")
                    .font(.caption)
                    .foregroundColor(.yellow)
                
                Text(text)
                    .font(.caption.weight(.medium))
                    .foregroundColor(Color.adaptivePrimary(colorScheme))
                
                Image(systemName: "arrow.right")
                    .font(.caption2)
                    .foregroundColor(Color.adaptivePrimary(colorScheme))
            }
            .padding(.horizontal, .spacingMD)
            .padding(.vertical, .spacingSM)
            .background(Color.adaptivePrimary(colorScheme).opacity(0.1))
            .cornerRadius(.radiusSM)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    VStack(spacing: .spacingLG) {
        // Full card
        UpgradePromptCard(
            feature: "Calendar Heatmap",
            description: "Visualize your baby's activity patterns with an interactive heatmap. See busy vs. calm days at a glance.",
            onUpgrade: {
                print("Upgrade tapped")
            },
            onDismiss: {
                print("Dismissed")
            }
        )
        
        // Without dismiss
        UpgradePromptCard(
            feature: "Growth Tracking",
            description: "Track weight, length, and head circumference with WHO percentile charts.",
            icon: "chart.line.uptrend.xyaxis",
            onUpgrade: {
                print("Upgrade tapped")
            }
        )
        
        // Inline version
        InlineUpgradePrompt(
            text: "Unlock Premium",
            onUpgrade: {
                print("Upgrade tapped")
            }
        )
    }
    .padding()
}

