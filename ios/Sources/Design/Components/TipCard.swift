import SwiftUI

struct TipCard: View {
    let tip: ParentalTip
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingMD) {
            HStack {
                Image(systemName: iconName(for: tip.category))
                    .foregroundColor(iconColor(for: tip.category))
                    .font(.system(size: 20))

                Text("Tip of the Week")
                    .font(.headline)
                    .foregroundColor(Color.adaptiveForeground(colorScheme))

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                        .font(.system(size: 16))
                }
            }

            Text(tip.title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(Color.adaptiveForeground(colorScheme))

            Text(tip.content)
                .font(.body)
                .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                .lineLimit(4)
        }
        .padding(.spacingLG)
        .background(Color.adaptiveSurface(colorScheme))
        .cornerRadius(.radiusMD)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, .spacingMD)
    }

    private func iconName(for category: ParentalTip.TipCategory) -> String {
        switch category {
        case .feeding: return "bottle.fill"
        case .sleep: return "moon.fill"
        case .diapering: return "arrow.triangle.2.circlepath.circle.fill"
        case .development: return "figure.play"
        case .general: return "heart.fill"
        }
    }

    private func iconColor(for category: ParentalTip.TipCategory) -> Color {
        switch category {
        case .feeding: return .blue
        case .sleep: return .purple
        case .diapering: return .green
        case .development: return .orange
        case .general: return .red
        }
    }
}

#Preview {
    let sampleTip = ParentalTip(
        id: "sample",
        title: "Sample Tip",
        content: "This is a sample tip to show how the tip card looks and feels in the interface.",
        category: .general,
        ageRange: 0...52
    )

    TipCard(tip: sampleTip, onDismiss: {})
        .padding()
}