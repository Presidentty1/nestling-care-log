import SwiftUI

struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isDisabled: Bool = false
    @Environment(\.colorScheme) private var colorScheme
    
    init(_ title: String, icon: String? = nil, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isDisabled = isDisabled
        self.action = action
    }
    
    var body: some View {
        Button(action: {
            Haptics.light()
            action()
        }) {
            HStack(spacing: .spacingSM) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.body)
            .foregroundColor(Color.adaptivePrimary(colorScheme))
            .frame(maxWidth: .infinity)
            .padding(.spacingMD)
            .background(Color.adaptiveSurface(colorScheme))
            .overlay(
                RoundedRectangle(cornerRadius: .radiusMD)
                    .stroke(Color.adaptivePrimary(colorScheme), lineWidth: 1)
            )
            .cornerRadius(.radiusMD)
        }
        .disabled(isDisabled)
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to activate")
    }
}

#Preview {
    VStack(spacing: 16) {
        SecondaryButton("Cancel", icon: "xmark") {}
        SecondaryButton("Cancel", isDisabled: true) {}
    }
    .padding()
}


