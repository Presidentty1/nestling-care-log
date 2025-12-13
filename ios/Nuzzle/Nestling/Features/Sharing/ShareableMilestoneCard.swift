import SwiftUI

/// Beautiful shareable milestone card for social sharing
struct ShareableMilestoneCard: View {
    let milestone: ShareService.MilestoneType
    let babyName: String

    // Instagram Stories: 1080x1920, Square: 1080x1080
    private let cardWidth: CGFloat = 1080
    private let cardHeight: CGFloat = 1920

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(hex: "667EEA"), // Soft blue
                    Color(hex: "764BA2")  // Purple
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack(spacing: 40) {
                Spacer()

                // Emoji and celebration
                Text(milestone.emoji)
                    .font(.system(size: 120))
                    .padding(.bottom, 20)

                // Main achievement
                VStack(spacing: 16) {
                    Text(milestone.title)
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)

                    Text(milestone.subtitle)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                }

                // Baby name
                Text(babyName.isEmpty ? "Your Baby" : babyName)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.white.opacity(0.2))
                    .cornerRadius(24)
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)

                // Encouragement
                Text(getEncouragementText())
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 20)

                Spacer()

                // Nestling branding
                HStack(spacing: 8) {
                    Image(systemName: "bird.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.7))

                    Text("Nestling")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.bottom, 60)
            }
            .padding(.horizontal, 60)
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(RoundedRectangle(cornerRadius: 0)) // Full screen for sharing
    }

    private func getEncouragementText() -> String {
        switch milestone {
        case .streakAchieved:
            return "Amazing consistency! You're building habits that will help you understand your baby better every day."
        case .sleepRecord:
            return "Rest is so important for both of you. Cherish these peaceful moments!"
        case .weekComplete:
            return "Another week of precious memories captured. You're doing an incredible job!"
        case .patternUnlocked:
            return "Your dedication is paying off. Patterns are emerging that will help make parenting clearer."
        }
    }

    /// Generate a shareable UIImage from this view
    func generateShareableImage() async throws -> UIImage {
        // Create hosting controller
        let hostingController = UIHostingController(rootView: self)
        hostingController.view.frame = CGRect(x: 0, y: 0, width: cardWidth, height: cardHeight)

        // Render to image
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cardWidth, height: cardHeight))
        let image = renderer.image { context in
            hostingController.view.layer.render(in: context.cgContext)
        }

        return image
    }
}

// MARK: - Preview

#Preview {
    ShareableMilestoneCard(
        milestone: .streakAchieved(days: 7),
        babyName: "Emma"
    )
}
