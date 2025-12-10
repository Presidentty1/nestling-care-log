import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    @Environment(\.colorScheme) private var colorScheme
    
    init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }
    
    var body: some View {
        VStack(spacing: .spacingMD) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(Color.adaptiveMutedForeground(colorScheme))

            Text(title)
                .font(.headline)
                .foregroundColor(Color.adaptiveForeground(colorScheme))

            Text(message)
                .font(.body)
                .foregroundColor(Color.adaptiveMutedForeground(colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, .spacingMD)
            
            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(actionTitle, action: action)
                    .padding(.horizontal, .spacingMD)
                    .padding(.top, .spacingSM)
            }
        }
        .padding(.spacingLG)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(message)")
    }
}

#Preview {
    EmptyStateView(
        icon: "calendar",
        title: "No events logged",
        message: "Start logging events to see them here",
        actionTitle: "Log Event",
        action: {}
    )
}


