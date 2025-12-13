import SwiftUI

/// Share sheet for milestone sharing with preview and platform options
struct MilestoneShareSheet: View {
    let milestone: ShareableMilestoneCard.ShareableMilestone
    let babyName: String
    let onDismiss: () -> Void

    @State private var selectedPlatform: SharePlatform = .messages
    @State private var showPreview = false

    enum SharePlatform {
        case messages, whatsapp, instagram, copyText

        var icon: String {
            switch self {
            case .messages: return "message.fill"
            case .whatsapp: return "phone.bubble.fill"
            case .instagram: return "camera.fill"
            case .copyText: return "doc.on.doc.fill"
            }
        }

        var name: String {
            switch self {
            case .messages: return "Messages"
            case .whatsapp: return "WhatsApp"
            case .instagram: return "Instagram"
            case .copyText: return "Copy Text"
            }
        }

        var color: Color {
            switch self {
            case .messages: return .blue
            case .whatsapp: return .green
            case .instagram: return Color(red: 0.8, green: 0.2, blue: 0.5)
            case .copyText: return .gray
            }
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Share Your Win!")
                        .font(.headingLG)
                        .foregroundColor(.foreground)

                    Text("Choose how to share this milestone")
                        .font(.bodyMD)
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal)

                // Milestone preview (small version)
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(milestone.color.opacity(0.1))
                        .frame(height: 120)

                    HStack(spacing: 16) {
                        Text(milestone.emoji)
                            .font(.system(size: 40))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(milestone.title)
                                .font(.headingMD)
                                .foregroundColor(.foreground)

                            Text(milestone.subtitle)
                                .font(.bodySM)
                                .foregroundColor(.mutedForeground)

                            if !babyName.isEmpty {
                                Text("• \(babyName)")
                                    .font(.bodySM)
                                    .foregroundColor(.primary)
                            }
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.horizontal)

                // Privacy note
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                        .font(.caption)

                    Text("Only first names are included for privacy. No personal data or timestamps are shared.")
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal)

                // Share options
                VStack(spacing: 12) {
                    ForEach([SharePlatform.messages, .whatsapp, .instagram, .copyText], id: \.self) { platform in
                        ShareOptionRow(
                            platform: platform,
                            isSelected: selectedPlatform == platform,
                            action: {
                                selectedPlatform = platform
                                shareViaPlatform(platform)
                            }
                        )
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    onDismiss()
                },
                trailing: Button("Preview") {
                    showPreview = true
                }
            )
            .sheet(isPresented: $showPreview) {
                SharePreviewView(
                    milestone: milestone,
                    babyName: babyName,
                    onDismiss: { showPreview = false }
                )
            }
        }
    }

    private func shareViaPlatform(_ platform: SharePlatform) {
        // Get the share text
        let shareText = getShareText()

        switch platform {
        case .messages:
            shareViaMessages(shareText)
        case .whatsapp:
            shareViaWhatsApp(shareText)
        case .instagram:
            shareViaInstagram(shareText)
        case .copyText:
            copyToClipboard(shareText)
        }

        // Track the share
        AnalyticsService.shared.track(event: "milestone_shared", properties: [
            "platform": platform.name,
            "milestone_type": String(describing: milestone)
        ])

        onDismiss()
    }

    private func getShareText() -> String {
        let title = milestone.title
        let subtitle = milestone.subtitle
        let nameText = babyName.isEmpty ? "" : " for \(babyName)"

        return """
        \(title)
        \(subtitle)\(nameText)

        Tracking with Nestling - baby sleep made simple! 📱
        """
    }

    private func shareViaMessages(_ text: String) {
        let urlString = "sms:?body=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text)"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private func shareViaWhatsApp(_ text: String) {
        let urlString = "whatsapp://send?text=\(text.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? text)"
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Fallback to copy
            copyToClipboard(text)
        }
    }

    private func shareViaInstagram(_ text: String) {
        // Copy to clipboard first, then open Instagram
        copyToClipboard(text)

        let urlString = "instagram://camera"
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text

        // Show brief confirmation
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

struct ShareOptionRow: View {
    let platform: MilestoneShareSheet.SharePlatform
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: platform.icon)
                    .font(.system(size: 24))
                    .foregroundColor(platform.color)
                    .frame(width: 32, height: 32)

                Text(platform.name)
                    .font(.bodyMD)
                    .foregroundColor(.foreground)

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.primary)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(isSelected ? Color.primary.opacity(0.1) : Color.surface)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SharePreviewView: View {
    let milestone: ShareableMilestoneCard.ShareableMilestone
    let babyName: String
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                ShareableMilestoneCard(
                    milestone: milestone,
                    babyName: babyName
                )
                .aspectRatio(1080/1920, contentMode: .fit)
                .padding()
            }
            .navigationBarItems(trailing: Button("Done") { onDismiss() })
            .navigationTitle("Preview")
        }
    }
}

#Preview {
    MilestoneShareSheet(
        milestone: .sleepBreakthrough(hours: 8),
        babyName: "Emma",
        onDismiss: {}
    )
}
