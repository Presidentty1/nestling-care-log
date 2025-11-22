import SwiftUI

struct DestructiveButton: View {
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
            Haptics.error()
            action()
        }) {
            HStack(spacing: .spacingSM) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.body)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.spacingMD)
            .background(isDisabled ? Color.mutedForeground : Color.destructive)
            .cornerRadius(.radiusMD)
        }
        .disabled(isDisabled)
        .accessibilityLabel(title)
        .accessibilityHint("Double tap to confirm destructive action")
    }
}

#Preview {
    VStack(spacing: 16) {
        DestructiveButton("Delete", icon: "trash") {}
        DestructiveButton("Delete", isDisabled: true) {}
    }
    .padding()
}

