import SwiftUI

struct NuzzleSecondaryButtonStyle: ButtonStyle {
    var isDisabled: Bool = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .foregroundColor(NuzzleTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.spacingMD)
            .background(NuzzleTheme.surface)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusMD)
                    .stroke(NuzzleTheme.primary, lineWidth: 1)
            )
            .cornerRadius(.radiusMD)
            .frame(minHeight: 44) // Ensure minimum 44pt tap target
            .opacity(isDisabled ? 0.6 : (configuration.isPressed ? 0.8 : 1.0))
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

#Preview {
    VStack(spacing: 16) {
        Button("Secondary Button", action: {})
            .buttonStyle(NuzzleSecondaryButtonStyle())

        Button("Disabled Button", action: {})
            .buttonStyle(NuzzleSecondaryButtonStyle(isDisabled: true))
            .disabled(true)
    }
    .padding()
    .background(NuzzleTheme.background)
}




