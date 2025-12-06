import SwiftUI

struct FeedbackPrompt: View {
    let feature: String
    let onRating: (FeedbackRating) -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: .spacingMD) {
            HStack {
                Image(systemName: "hand.thumbsup.fill")
                    .foregroundColor(Color.adaptivePrimary(colorScheme))
                    .font(.system(size: 20))

                Text("Was this helpful?")
                    .font(.headline)
                    .foregroundColor(Color.adaptiveForeground(colorScheme))

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                        .font(.system(size: 16))
                }
            }

            Text("How was your experience with \(feature)?")
                .font(.body)
                .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                .multilineTextAlignment(.center)

            HStack(spacing: .spacingLG) {
                FeedbackButton(rating: .tooEarly, icon: "arrow.left", text: "Too early")
                FeedbackButton(rating: .justRight, icon: "checkmark.circle", text: "Just right")
                FeedbackButton(rating: .tooLate, icon: "arrow.right", text: "Too late")
            }
        }
        .padding(.spacingLG)
        .background(Color.adaptiveSurface(colorScheme))
        .cornerRadius(.radiusMD)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, .spacingMD)
    }
}

struct FeedbackButton: View {
    let rating: FeedbackRating
    let icon: String
    let text: String

    var body: some View {
        Button(action: {
            // This would be handled by the parent view
            Haptics.light()
        }) {
            VStack(spacing: .spacingXS) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(iconColor(for: rating))

                Text(text)
                    .font(.caption)
                    .foregroundColor(iconColor(for: rating))
            }
            .frame(width: 70, height: 60)
            .background(iconColor(for: rating).opacity(0.1))
            .cornerRadius(.radiusMD)
        }
        .buttonStyle(.plain)
    }

    private func iconColor(for rating: FeedbackRating) -> Color {
        switch rating {
        case .tooEarly: return .orange
        case .justRight: return .green
        case .tooLate: return .red
        }
    }
}

enum FeedbackRating {
    case tooEarly
    case justRight
    case tooLate

    var displayName: String {
        switch self {
        case .tooEarly: return "Too Early"
        case .justRight: return "Just Right"
        case .tooLate: return "Too Late"
        }
    }
}

#Preview {
    FeedbackPrompt(
        feature: "nap predictions",
        onRating: { rating in
            print("Rated: \(rating.displayName)")
        },
        onDismiss: {}
    )
    .padding()
}