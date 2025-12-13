import SwiftUI

/// Card for inviting friends to try Nestling with referral incentives
struct ReferralInviteCard: View {
    let onShareLink: () -> Void
    let onViewDashboard: () -> Void

    private var referralService: ReferralProgramService { .shared }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingMD) {
            // Header with rewards preview
            HStack {
                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text("Help friends sleep better")
                        .font(.headingMD)
                        .foregroundColor(.foreground)

                    Text("Share Nestling & earn rewards")
                        .font(.bodySM)
                        .foregroundColor(.mutedForeground)
                }

                Spacer()

                // Rewards indicator
                if referralService.getAvailableRewards().isEmpty {
                    Text("🎁")
                        .font(.title)
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.primary)
                            .frame(width: 32, height: 32)

                        Text("\(referralService.getAvailableRewards().count)")
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.white)
                    }
                }
            }

            // Main invite content
            VStack(alignment: .leading, spacing: .spacingSM) {
                Text(referralService.getReferralHeadline())
                    .font(.bodyMD.weight(.medium))
                    .foregroundColor(.foreground)

                Text(referralService.getReferralSubheadline())
                    .font(.bodySM)
                    .foregroundColor(.mutedForeground)
                    .lineLimit(2)

                // Benefit highlight
                HStack(spacing: .spacingXS) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(.warning)

                    Text(referralService.getReferralBenefit())
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                }
            }

            // Action buttons
            HStack(spacing: .spacingMD) {
                PrimaryButton("Share link", icon: "square.and.arrow.up") {
                    onShareLink()
                }
                .frame(maxWidth: .infinity)

                if !referralService.getAvailableRewards().isEmpty {
                    SecondaryButton("View rewards") {
                        onViewDashboard()
                    }
                }
            }
        }
        .padding(.spacingLG)
        .background(Color.surface)
        .cornerRadius(.radiusLG)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
    }
}

#Preview {
    ReferralInviteCard(
        onShareLink: {},
        onViewDashboard: {}
    )
    .padding()
}