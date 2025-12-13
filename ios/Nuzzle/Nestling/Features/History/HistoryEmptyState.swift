import SwiftUI

/// Enhanced History Empty State - Shows sample data preview to reduce anxiety
/// Research shows previewing future value increases conversion rates
struct HistoryEmptyState: View {
    let action: (() -> Void)?

    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: .spacingXL) {
            Spacer()

            // Sample data preview (blurred for free users)
            ZStack {
                // Blurred sample timeline
                VStack(spacing: .spacingSM) {
                    // Sample day header
                    HStack {
                        Text("Yesterday")
                            .font(.headline)
                        Spacer()
                        Text("5 events")
                            .font(.caption)
                            .foregroundColor(.mutedForeground)
                    }
                    .padding(.horizontal, .spacingLG)

                    // Sample timeline rows
                    ForEach(0..<3) { _ in
                        HStack(spacing: .spacingMD) {
                            Circle()
                                .fill(Color.eventFeed.opacity(0.2))
                                .frame(width: 32, height: 32)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Feed")
                                    .font(.subheadline.weight(.semibold))
                                Text("120 ml bottle • 2:30 PM")
                                    .font(.caption)
                                    .foregroundColor(.mutedForeground)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, .spacingLG)
                        .padding(.vertical, .spacingXS)
                    }
                }
                .blur(radius: 4)
                .opacity(0.6)

                // Lock overlay
                VStack(spacing: .spacingMD) {
                    Image(systemName: "lock.fill")
                        .font(.title)
                        .foregroundColor(.primary)

                    Text("Your baby's story will appear here")
                        .font(.headline)
                        .foregroundColor(.foreground)

                    Text("Start logging to see patterns emerge")
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, .spacingLG)
                }
            }
            .padding(.vertical, .spacingLG)
            .background(Color.surface.opacity(0.5))
            .cornerRadius(.radiusLG)
            .padding(.horizontal, .spacingLG)

            // Reassuring message
            VStack(spacing: .spacingMD) {
                Text("Every log builds your baby's story")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.foreground)
                    .multilineTextAlignment(.center)

                Text("We'll help you spot sleep patterns, feeding rhythms, and developmental milestones.")
                    .font(.body)
                    .foregroundColor(.mutedForeground)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, .spacingLG)

            Spacer()

            if let action = action {
                Button(action: {
                    Haptics.medium()
                    action()
                }) {
                    Text("Start Your Story")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.primary)
                        .cornerRadius(.radiusXL)
                        .shadow(color: Color.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .padding(.horizontal, .spacingLG)
                .padding(.bottom, .spacing2XL)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.0).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

#Preview {
    HistoryEmptyState(action: {})
        .background(Color.background)
}


