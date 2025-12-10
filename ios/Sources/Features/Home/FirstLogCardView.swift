import SwiftUI

struct FirstLogCardView: View {
    let onLogFirstEvent: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingMD) {
            HStack(spacing: .spacingSM) {
                Image(systemName: "star.fill")
                    .foregroundColor(Color.adaptivePrimary(colorScheme))
                    .font(.system(size: 20))

                Text("Let's get started!")
                    .font(.headline)
                    .foregroundColor(Color.adaptiveForeground(colorScheme))
            }

            Text("Log your first feed to see Nuzzle in action and unlock nap predictions.")
                .font(.body)
                .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                .lineLimit(3)

            PrimaryButton("Log first feed") {
                Haptics.light()
                onLogFirstEvent()
            }
            .padding(.top, .spacingSM)
        }
        .padding(.spacingLG)
        .background(Color.adaptiveSurface(colorScheme))
        .cornerRadius(.radiusMD)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, .spacingMD)
    }
}

#Preview {
    FirstLogCardView(onLogFirstEvent: {})
        .padding()
}

