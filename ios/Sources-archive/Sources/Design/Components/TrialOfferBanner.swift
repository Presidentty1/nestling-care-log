import SwiftUI

struct TrialOfferBanner: View {
    let onTryPro: () -> Void
    let onDismiss: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: .spacingSM) {
            HStack(spacing: .spacingSM) {
                Image(systemName: "star.fill")
                    .foregroundColor(Color.adaptivePrimary(colorScheme))
                    .font(.system(size: 20))

                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text("Love Nestling? Try Pro free!")
                        .font(.headline)
                        .foregroundColor(Color.adaptiveForeground(colorScheme))

                    Text("Unlock AI predictions, smart notifications, and more")
                        .font(.caption)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                        .lineLimit(2)
                }

                Spacer()

                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                        .font(.system(size: 16))
                }
            }

            HStack(spacing: .spacingMD) {
                SecondaryButton("Maybe Later", action: onDismiss)
                    .frame(maxWidth: .infinity)

                PrimaryButton("Try 7 Days Free", action: onTryPro)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.spacingMD)
        .background(Color.adaptiveSurface(colorScheme))
        .cornerRadius(.radiusMD)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, .spacingMD)
    }
}

#Preview {
    TrialOfferBanner(onTryPro: {}, onDismiss: {})
        .padding()
}


