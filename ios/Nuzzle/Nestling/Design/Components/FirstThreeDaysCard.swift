import SwiftUI

/// Card showing progress through the first 72 hours activation journey
struct FirstThreeDaysCard: View {
    @ObservedObject var journeyService = FirstThreeDaysJourneyService.shared

    var body: some View {
        CardView(variant: .default) {
            VStack(alignment: .leading, spacing: .spacingMD) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: .spacingXS) {
                        Text("Your First 3 Days")
                            .font(.headingMD)
                            .foregroundColor(.foreground)

                        Text("Building great tracking habits")
                            .font(.bodySM)
                            .foregroundColor(.mutedForeground)
                    }

                    Spacer()

                    // Progress indicator
                    ZStack {
                        Circle()
                            .stroke(Color.primary.opacity(0.2), lineWidth: 4)
                            .frame(width: 50, height: 50)

                        Circle()
                            .trim(from: 0, to: journeyService.journeyProgress)
                            .stroke(Color.primary, lineWidth: 4)
                            .frame(width: 50, height: 50)
                            .rotationEffect(.degrees(-90))

                        Text("\(Int(journeyService.journeyProgress * 100))%")
                            .font(.caption.weight(.bold))
                            .foregroundColor(.primary)
                    }
                }

                // Current day progress
                let currentDay = journeyService.currentDay
                let dayMilestones = journeyService.getMilestones(for: currentDay)

                VStack(alignment: .leading, spacing: .spacingSM) {
                    Text("Day \(currentDay)")
                        .font(.bodyMD.weight(.medium))
                        .foregroundColor(.foreground)

                    // Show next milestone or current progress
                    if let nextMilestone = dayMilestones.first(where: { !journeyService.isMilestoneCompleted($0) }) {
                        HStack(spacing: .spacingSM) {
                            Circle()
                                .fill(Color.primary.opacity(0.2))
                                .frame(width: 8, height: 8)

                            Text(nextMilestone.description)
                                .font(.bodySM)
                                .foregroundColor(.mutedForeground)
                        }
                    } else if !dayMilestones.isEmpty {
                        HStack(spacing: .spacingSM) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.success)
                                .font(.body)

                            Text("Day \(currentDay) complete!")
                                .font(.bodySM)
                                .foregroundColor(.success)
                        }
                    }
                }

                // Progress bars for milestones
                VStack(spacing: .spacingXS) {
                    ForEach(dayMilestones, id: \.self) { milestone in
                        HStack(spacing: .spacingSM) {
                            Image(systemName: journeyService.isMilestoneCompleted(milestone) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(journeyService.isMilestoneCompleted(milestone) ? .success : .mutedForeground)
                                .font(.caption)

                            Text(milestone.title)
                                .font(.caption)
                                .foregroundColor(journeyService.isMilestoneCompleted(milestone) ? .foreground : .mutedForeground)

                            Spacer()
                        }
                    }
                }

                // Encouragement message
                if journeyService.journeyProgress < 1.0 {
                    Text(getEncouragementMessage())
                        .font(.bodySM)
                        .foregroundColor(.primary)
                        .padding(.top, .spacingXS)
                } else {
                    Text("🎉 Congratulations! You've completed the journey.")
                        .font(.bodySM)
                        .foregroundColor(.success)
                        .padding(.top, .spacingXS)
                }
            }
            .padding(.spacingMD)
        }
    }

    private func getEncouragementMessage() -> String {
        let progress = journeyService.journeyProgress

        if progress < 0.25 {
            return "Keep going! Every log helps build better predictions."
        } else if progress < 0.5 {
            return "Great progress! You're discovering your baby's patterns."
        } else if progress < 0.75 {
            return "Almost there! Your predictions are getting more accurate."
        } else {
            return "You're doing amazing! Just a few more steps to complete the journey."
        }
    }
}

#Preview {
    FirstThreeDaysCard()
        .padding()
}
