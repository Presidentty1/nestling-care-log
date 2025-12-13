import SwiftUI

/// Button for predictive logging suggestions
struct PredictiveSuggestionButton: View {
    let prediction: PredictiveLoggingService.Prediction
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: .spacingXS) {
                HStack(spacing: .spacingSM) {
                    ZStack {
                        Circle()
                            .fill(prediction.type.color.opacity(0.2))
                            .frame(width: 32, height: 32)

                        Image(systemName: prediction.type.icon)
                            .font(.system(size: 16))
                            .foregroundColor(prediction.type.color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(prediction.type.title)
                            .font(.body.weight(.medium))
                            .foregroundColor(.foreground)
                            .lineLimit(1)

                        if let subtitle = prediction.type.subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(.mutedForeground)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    // Confidence indicator (subtle)
                    if prediction.confidence >= 0.8 {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundColor(.warning)
                    }
                }
            }
            .padding(.spacingMD)
            .background(Color.surface)
            .cornerRadius(.radiusLG)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusLG)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(prediction.type.title)
        .accessibilityHint("Double tap to log this event quickly")
    }
}

#Preview {
    let prediction = PredictiveLoggingService.Prediction(
        type: .feed(amount: 4.0, unit: "oz", side: "left"),
        confidence: 0.85,
        reason: "Based on recent pattern"
    )

    PredictiveSuggestionButton(prediction: prediction) {}
        .padding()
}
