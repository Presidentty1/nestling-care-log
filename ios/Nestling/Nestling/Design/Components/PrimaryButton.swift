import SwiftUI

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void
    var isDisabled: Bool = false
    
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
                        .symbolPulse()
                }
                Text(title)
            }
            .font(.body)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.spacingMD)
            .background(isDisabled ? Color.mutedForeground : Color.primary)
            .cornerRadius(.radiusMD)
        }
        .disabled(isDisabled)
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to activate")
    }
}

#Preview {
    VStack(spacing: 16) {
        PrimaryButton("Save", icon: "checkmark") {}
        PrimaryButton("Save", isDisabled: true) {}
    }
    .padding()
}

