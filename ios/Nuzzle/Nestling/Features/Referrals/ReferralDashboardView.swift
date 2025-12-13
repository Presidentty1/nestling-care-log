import SwiftUI

/// Dashboard showing referral stats, earned rewards, and sharing options
struct ReferralDashboardView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showShareSheet = false

    private var referralService: ReferralProgramService { .shared }
    private var activatedCount: Int { referralService.getActivatedReferees().count }
    private var availableRewards: [ReferralReward] { referralService.getAvailableRewards() }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: .spacingXL) {
                    // Header stats
                    VStack(spacing: .spacingMD) {
                        Text("Your Referral Impact")
                            .font(.headingLG)
                            .foregroundColor(.foreground)

                        // Stats cards
                        HStack(spacing: .spacingMD) {
                            StatCard(
                                title: "Friends Helped",
                                value: "\(activatedCount)",
                                icon: "person.2.fill",
                                color: .success
                            )

                            StatCard(
                                title: "Rewards Earned",
                                value: "\(availableRewards.count)",
                                icon: "gift.fill",
                                color: .warning
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Rewards section
                    if !availableRewards.isEmpty {
                        VStack(alignment: .leading, spacing: .spacingMD) {
                            Text("Your Rewards")
                                .font(.headingMD)
                                .foregroundColor(.foreground)

                            ForEach(availableRewards, id: \.self) { reward in
                                RewardCard(reward: reward)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Share section
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Text("Invite More Friends")
                            .font(.headingMD)
                            .foregroundColor(.foreground)

                        ReferralInviteCard(
                            onShareLink: { showShareSheet = true },
                            onViewDashboard: {} // Already on dashboard
                        )
                    }
                    .padding(.horizontal)

                    // How it works
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        Text("How It Works")
                            .font(.headingMD)
                            .foregroundColor(.foreground)

                        VStack(alignment: .leading, spacing: .spacingLG) {
                            StepView(
                                number: 1,
                                title: "Share your link",
                                description: "Send friends your unique referral link"
                            )

                            StepView(
                                number: 2,
                                title: "They sign up & log",
                                description: "Friends download Nestling and track their first events"
                            )

                            StepView(
                                number: 3,
                                title: "You get rewards",
                                description: "Earn badges and unlock bonus features"
                            )
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: .spacingXL)
                }
                .padding(.vertical)
            }
            .navigationBarItems(trailing: Button("Done") { dismiss() })
            .sheet(isPresented: $showShareSheet) {
                ShareReferralSheet()
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: .spacingSM) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
            }

            Text(value)
                .font(.headingLG)
                .foregroundColor(.foreground)

            Text(title)
                .font(.caption)
                .foregroundColor(.mutedForeground)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, .spacingMD)
        .background(Color.surface)
        .cornerRadius(.radiusLG)
    }
}

struct RewardCard: View {
    let reward: ReferralReward

    var body: some View {
        HStack(spacing: .spacingMD) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 48, height: 48)

                Image(systemName: reward.icon)
                    .font(.title2)
                    .foregroundColor(.primary)
            }

            VStack(alignment: .leading, spacing: .spacingXS) {
                Text(reward.title)
                    .font(.bodyMD.weight(.medium))
                    .foregroundColor(.foreground)

                Text(reward.description)
                    .font(.bodySM)
                    .foregroundColor(.mutedForeground)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundColor(.success)
        }
        .padding(.spacingMD)
        .background(Color.surface)
        .cornerRadius(.radiusLG)
    }
}

struct StepView: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: .spacingMD) {
            ZStack {
                Circle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 32, height: 32)

                Text("\(number)")
                    .font(.bodySM.weight(.bold))
                    .foregroundColor(.primary)
            }

            VStack(alignment: .leading, spacing: .spacingXS) {
                Text(title)
                    .font(.bodyMD.weight(.medium))
                    .foregroundColor(.foreground)

                Text(description)
                    .font(.bodySM)
                    .foregroundColor(.mutedForeground)
            }
        }
    }
}

struct ShareReferralSheet: View {
    @Environment(\.dismiss) var dismiss

    private var referralService: ReferralProgramService { .shared }

    var body: some View {
        NavigationView {
            VStack(spacing: .spacingXL) {
                Text("Share Nestling")
                    .font(.headingLG)
                    .foregroundColor(.foreground)

                Text("Choose how to share your referral link")
                    .font(.bodyMD)
                    .foregroundColor(.mutedForeground)
                    .multilineTextAlignment(.center)

                VStack(spacing: .spacingMD) {
                    ShareOptionButton(
                        title: "Copy Link",
                        subtitle: "Copy your referral link",
                        icon: "link",
                        action: { copyReferralLink() }
                    )

                    ShareOptionButton(
                        title: "Share via Messages",
                        subtitle: "Send via iMessage",
                        icon: "message.fill",
                        action: { shareViaMessages() }
                    )

                    ShareOptionButton(
                        title: "Share via WhatsApp",
                        subtitle: "Send via WhatsApp",
                        icon: "phone.bubble.fill",
                        action: { shareViaWhatsApp() }
                    )

                    ShareOptionButton(
                        title: "More Options",
                        subtitle: "Share sheet with all apps",
                        icon: "square.and.arrow.up",
                        action: { shareViaSystemSheet() }
                    )
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.vertical)
            .navigationBarItems(trailing: Button("Cancel") { dismiss() })
        }
    }

    private func copyReferralLink() {
        // Generate and copy referral link
        let userId = "current_user_id" // TODO: Get from auth service
        if let link = referralService.generateReferralLink(for: userId) {
            UIPasteboard.general.url = link
            Haptics.success()
            referralService.trackLinkShared(channel: "copy_link", referralCode: referralService.generateReferralCode(for: userId))
        }
        dismiss()
    }

    private func shareViaMessages() {
        let shareText = referralService.getShareText()
        let urlString = "sms:?body=\(shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? shareText)"

        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            trackShare(channel: "messages")
        }
        dismiss()
    }

    private func shareViaWhatsApp() {
        let shareText = referralService.getShareText()
        let urlString = "whatsapp://send?text=\(shareText.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? shareText)"

        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
            trackShare(channel: "whatsapp")
        } else {
            // Fallback to copy
            copyReferralLink()
        }
    }

    private func shareViaSystemSheet() {
        let shareText = referralService.getShareText()
        let userId = "current_user_id" // TODO: Get from auth service
        let referralCode = referralService.generateReferralCode(for: userId)

        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        // Find presenting VC and show sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {

            var presentingVC = rootVC
            while let presented = presentingVC.presentedViewController {
                presentingVC = presented
            }

            presentingVC.present(activityVC, animated: true)
            trackShare(channel: "system_sheet")
        }

        dismiss()
    }

    private func trackShare(channel: String) {
        let userId = "current_user_id" // TODO: Get from auth service
        referralService.trackLinkShared(channel: channel, referralCode: referralService.generateReferralCode(for: userId))
    }
}

struct ShareOptionButton: View {
    let title: String
    let subtitle: String
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacingMD) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text(title)
                        .font(.bodyMD.weight(.medium))
                        .foregroundColor(.foreground)

                    Text(subtitle)
                        .font(.bodySM)
                        .foregroundColor(.mutedForeground)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.bodySM)
                    .foregroundColor(.mutedForeground)
            }
            .padding(.spacingMD)
            .background(Color.surface)
            .cornerRadius(.radiusLG)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    ReferralDashboardView()
}