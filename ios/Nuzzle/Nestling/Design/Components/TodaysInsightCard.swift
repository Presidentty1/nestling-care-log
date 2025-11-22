import SwiftUI

/// Card displaying personalized recommendations and insights
struct TodaysInsightCard: View {
    let recommendation: PersonalizedRecommendationsService.Recommendation

    var body: some View {
        CardView(variant: .default) {
            HStack(alignment: .top, spacing: .spacingMD) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.1))
                        .frame(width: 40, height: 40)

                    Image(systemName: recommendation.type.iconName)
                        .foregroundColor(.primary)
                        .font(.system(size: 18))
                }

                // Content
                VStack(alignment: .leading, spacing: .spacingXS) {
                    HStack {
                        Text(recommendation.title)
                            .font(.headline)
                            .foregroundColor(.foreground)

                        Spacer()

                        if recommendation.isNew {
                            Text("NEW")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal, .spacingXS)
                                .padding(.vertical, 2)
                                .background(Color.success)
                                .cornerRadius(.radiusSM)
                        }
                    }

                    Text(recommendation.message)
                        .font(.subheadline)
                        .foregroundColor(.mutedForeground)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)

                    if recommendation.actionable {
                        Text("Tap for more details")
                            .font(.caption)
                            .foregroundColor(.primary)
                            .padding(.top, .spacingXS)
                    }

                    // Medical disclaimer for AI-generated insights
                    Text("Not medical advice")
                        .font(.caption2)
                        .foregroundColor(.mutedForeground)
                        .padding(.top, .spacingXS)
                }
            }
            .padding(.spacingMD)
        }
        .contentShape(Rectangle()) // Make entire card tappable
    }
}

#Preview {
    let sampleRecommendation = PersonalizedRecommendationsService.Recommendation(
        id: "sample",
        type: .feedTiming,
        title: "Consider an early feed",
        message: "It's been longer than usual since the last feed. Your baby might be getting hungry.",
        priority: 1,
        actionable: true,
        createdAt: Date()
    )

    return VStack {
        TodaysInsightCard(recommendation: sampleRecommendation)

        let oldRecommendation = PersonalizedRecommendationsService.Recommendation(
            id: "old",
            type: .general,
            title: "Keep going!",
            message: "You're doing a great job tracking your baby's day!",
            priority: 2,
            actionable: false,
            createdAt: Date().addingTimeInterval(-86401) // More than 24 hours ago
        )

        TodaysInsightCard(recommendation: oldRecommendation)
    }
    .padding()
}
