import SwiftUI

/// Card showing proactive feature suggestions to guide user discovery
struct ProactiveSuggestionCard: View {
    let suggestion: ProactiveFeatureDiscoveryService.FeatureSuggestion
    let onTap: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingMD) {
            // Header with dismiss button
            HStack {
                HStack(spacing: .spacingSM) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.warning)
                        .font(.body)

                    Text("Discover")
                        .font(.body.weight(.medium))
                        .foregroundColor(.foreground)
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.mutedForeground)
                        .font(.body)
                }
                .accessibilityLabel("Dismiss suggestion")
            }

            // Suggestion content
            Button(action: onTap) {
                HStack(alignment: .top, spacing: .spacingMD) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.primary.opacity(0.1))
                            .frame(width: 48, height: 48)

                        Image(systemName: suggestion.icon)
                            .font(.title2)
                            .foregroundColor(.primary)
                    }

                    // Content
                    VStack(alignment: .leading, spacing: .spacingXS) {
                        Text(suggestion.title)
                            .font(.body.weight(.medium))
                            .foregroundColor(.foreground)
                            .multilineTextAlignment(.leading)

                        Text(suggestion.description)
                            .font(.body)
                            .foregroundColor(.mutedForeground)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)

                        // Action hint
                        Text("Tap to explore")
                            .font(.caption)
                            .foregroundColor(.primary)
                            .padding(.top, .spacingXS)
                    }

                    Spacer()

                    // Chevron
                    Image(systemName: "chevron.right")
                        .foregroundColor(.mutedForeground)
                        .font(.caption)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.spacingLG)
        .background(Color.surface)
        .cornerRadius(.radiusLG)
        .overlay(
            RoundedRectangle(cornerRadius: .radiusLG)
                .stroke(Color.primary.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    VStack(spacing: 16) {
        ProactiveSuggestionCard(
            suggestion: .aiInsights,
            onTap: {},
            onDismiss: {}
        )

        ProactiveSuggestionCard(
            suggestion: .cryAnalysis,
            onTap: {},
            onDismiss: {}
        )
    }
    .padding()
}
