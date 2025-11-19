import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?
    
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
                .foregroundColor(.mutedForeground)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.foreground)
            
            Text(message)
                .font(.body)
                .foregroundColor(.mutedForeground)
                .multilineTextAlignment(.center)
                .padding(.horizontal, .spacingMD)
            
            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(actionTitle, action: action)
                    .padding(.horizontal, .spacingMD)
                    .padding(.top, .spacingSM)
            }
        }
        .padding(.spacing2XL)
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

