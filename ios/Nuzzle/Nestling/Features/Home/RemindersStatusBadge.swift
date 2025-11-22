import SwiftUI

struct RemindersStatusBadge: View {
    let feedReminderEnabled: Bool
    let napWindowAlertEnabled: Bool
    let diaperReminderEnabled: Bool
    let onTap: () -> Void

    var body: some View {
        if feedReminderEnabled || napWindowAlertEnabled || diaperReminderEnabled {
            Button(action: onTap) {
                CardView(variant: .default) {
                    HStack(spacing: .spacingSM) {
                        Text("Reminders Active:")
                            .font(.caption)
                            .foregroundColor(.foreground)

                        if feedReminderEnabled {
                            Badge("Feed")
                        }
                        if napWindowAlertEnabled {
                            Badge("Nap")
                        }
                        if diaperReminderEnabled {
                            Badge("Diaper")
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundColor(.mutedForeground)
                    }
                    .padding(.vertical, 4)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

#Preview {
    VStack(spacing: .spacingMD) {
        RemindersStatusBadge(feedReminderEnabled: true, napWindowAlertEnabled: true, diaperReminderEnabled: false, onTap: {})
        RemindersStatusBadge(feedReminderEnabled: false, napWindowAlertEnabled: true, diaperReminderEnabled: true, onTap: {})
        RemindersStatusBadge(feedReminderEnabled: true, napWindowAlertEnabled: false, diaperReminderEnabled: false, onTap: {})
        RemindersStatusBadge(feedReminderEnabled: false, napWindowAlertEnabled: false, diaperReminderEnabled: false, onTap: {})
    }
    .padding()
    .background(Color.background)
}