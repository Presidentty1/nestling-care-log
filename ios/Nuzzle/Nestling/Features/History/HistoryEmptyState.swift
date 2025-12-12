import SwiftUI

struct HistoryEmptyState: View {
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    init(title: String = "No history yet", message: String = "Once you log sleep, feeds, or diapers on the Today tab, they'll show up here.", actionTitle: String? = "Go to Today", action: (() -> Void)? = nil) {
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        VStack(spacing: .spacingMD) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 48, weight: .semibold))
                .foregroundColor(.mutedForeground)

            VStack(spacing: 6) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(.foreground)
                Text(message)
                    .font(.body)
                    .foregroundColor(.mutedForeground)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, .spacingLG)

            if let actionTitle, let action {
                PrimaryButton(actionTitle) {
                    Haptics.selection()
                    action()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .padding()
    }
}

#Preview {
    HistoryEmptyState(action: {})
        .background(Color.background)
}


