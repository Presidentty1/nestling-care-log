import SwiftUI

struct NuzzlePrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body)
            .foregroundColor(NuzzleTheme.textPrimary)
            .frame(maxWidth: .infinity)
            .padding(.spacingMD)
            .background(
                RoundedRectangle(cornerRadius: .radiusMD)
                    .fill(NuzzleTheme.primary.opacity(configuration.isPressed ? 0.8 : 1.0))
            )
            .frame(minHeight: 44) // Ensure minimum 44pt tap target
    }
}

#Preview {
    VStack(spacing: 16) {
        Button("Primary Button", action: {})
            .buttonStyle(NuzzlePrimaryButtonStyle())

        Button("Disabled Button", action: {})
            .buttonStyle(NuzzlePrimaryButtonStyle())
            .disabled(true)
    }
    .padding()
    .background(NuzzleTheme.background)
}




