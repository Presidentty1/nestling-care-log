import SwiftUI

/// A subtle card that prompts users to add widgets to their home screen
struct AddWidgetPromptCard: View {
    let onDismiss: () -> Void
    let onAddWidget: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingMD) {
            HStack {
                Image(systemName: "square.grid.2x2")
                    .font(.title2)
                    .foregroundColor(.primary)
                Text("Quick tip")
                    .font(.headingMD)
                    .foregroundColor(.foreground)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.mutedForeground)
                }
            }

            Text("Add a widget to your home screen to see nap predictions at a glance")
                .font(.bodyMD)
                .foregroundColor(.mutedForeground)
                .multilineTextAlignment(.leading)

            Button("Show me how") {
                onAddWidget()
            }
            .font(.bodyMD.weight(.semibold))
            .foregroundColor(.primary)
            .padding(.vertical, .spacingSM)
            .padding(.horizontal, .spacingMD)
            .background(Color.primary.opacity(0.1))
            .cornerRadius(.radiusMD)
        }
        .padding(.spacingMD)
        .background(Color.surface)
        .cornerRadius(.radiusMD)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    AddWidgetPromptCard(
        onDismiss: {},
        onAddWidget: {}
    )
    .padding()
}