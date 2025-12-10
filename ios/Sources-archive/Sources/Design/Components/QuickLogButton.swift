import SwiftUI

/// Large, accessible button for quick logging actions
struct QuickLogButton: View {
    let title: String
    let icon: String
    let color: Color
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            Haptics.light()
            action()
        }) {
            VStack(spacing: .spacingXS) {
                ZStack {
                    Circle()
                        .fill(color.opacity(isActive ? 0.2 : 0.1))
                        .frame(width: 64, height: 64)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(NuzzleTheme.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(height: 32) // Fixed height for consistent alignment
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, .spacingSM)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(title) quick log")
        .accessibilityHint(isActive ? "Currently active, tap to modify" : "Tap to quickly log \(title.lowercased())")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    HStack(spacing: .spacingMD) {
        QuickLogButton(
            title: "Feed",
            icon: "drop.fill",
            color: .blue,
            isActive: false,
            action: {}
        )

        QuickLogButton(
            title: "Stop Nap",
            icon: "moon.fill",
            color: .purple,
            isActive: true,
            action: {}
        )
    }
    .padding(.spacingMD)
    .background(NuzzleTheme.background)
}
