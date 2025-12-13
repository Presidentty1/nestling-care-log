import SwiftUI

struct SpotlightOverlay: View {
    let targetFrame: CGRect
    let title: String
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            // Darkened background with cutout
            Color.black.opacity(0.7)
                .mask(
                    Rectangle()
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .frame(width: targetFrame.width + 16, height: targetFrame.height + 16)
                                .position(x: targetFrame.midX, y: targetFrame.midY)
                                .blendMode(.destinationOut)
                        )
                )

            // Tooltip
            VStack(alignment: .leading, spacing: .spacingSM) {
                Text(title).font(.headline)
                Text(message).font(.body).foregroundColor(.mutedForeground)
                Button("Got it") { onDismiss() }
            }
            .padding()
            .background(Color.surface)
            .cornerRadius(.radiusLG)
            .position(x: targetFrame.midX, y: targetFrame.maxY + 80)
        }
    }
}

#Preview {
    SpotlightOverlay(
        targetFrame: CGRect(x: 100, y: 100, width: 200, height: 60),
        title: "Quick Actions",
        message: "Tap these buttons to quickly log feeds, sleep, or diaper changes.",
        onDismiss: {}
    )
}
