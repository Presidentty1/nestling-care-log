import SwiftUI

/// Pattern Progress Card - Visual progress indicator toward AI insights
/// Research: Progress bars increase completion by 127% (LinkedIn study)
/// Psychology: Zeigarnik effect - incomplete tasks create motivation
struct PatternProgressCard: View {
    let totalLogs: Int
    let daysActive: Int
    let isPro: Bool
    let onUpgradeTap: () -> Void

    // Milestones based on research - early wins are crucial
    private let milestones: [(logs: Int, feature: String, icon: String)] = [
        (3, "Basic patterns", "chart.bar"),
        (10, "Nap predictions", "moon.zzz.fill"),
        (25, "Weekly insights", "chart.line.uptrend.xyaxis"),
        (50, "Full AI analysis", "brain.head.profile")
    ]

    private var currentMilestone: (logs: Int, feature: String, icon: String) {
        milestones.first { $0.logs > totalLogs } ?? milestones.last!
    }

    private var progress: Double {
        let previousMilestone = milestones.last { $0.logs <= totalLogs }?.logs ?? 0
        let range = Double(currentMilestone.logs - previousMilestone)
        let current = Double(totalLogs - previousMilestone)
        return min(1.0, current / range)
    }

    private var isComplete: Bool {
        totalLogs >= 50
    }

    private func estimatedDaysToNextMilestone() -> Int {
        guard daysActive > 0 else { return 0 }

        let logsRemaining = currentMilestone.logs - totalLogs
        let dailyAverage = Double(totalLogs) / Double(max(1, daysActive))
        let estimatedDays = Int(ceil(Double(logsRemaining) / dailyAverage))

        return max(1, estimatedDays) // At least 1 day to keep it encouraging
    }

    @State private var animatedProgress: Double = 0

    var body: some View {
        CardView(variant: isComplete ? .success : .emphasis) {
            VStack(alignment: .leading, spacing: .spacingMD) {
                // Header
                HStack {
                    HStack(spacing: .spacingSM) {
                        Image(systemName: isComplete ? "checkmark.circle.fill" : "chart.line.uptrend.xyaxis")
                            .foregroundColor(isComplete ? .success : .primary)

                        Text(isComplete ? "Pattern Analysis Active" : "Building Your Patterns")
                            .font(.headline)
                            .foregroundColor(.foreground)
                    }

                    Spacer()

                    Text("\(totalLogs) logs")
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                }

                if !isComplete {
                    // Progress bar with milestones
                    VStack(spacing: .spacingSM) {
                        // Animated progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background track
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.primary.opacity(0.1))
                                    .frame(height: 8)

                                // Filled progress
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(
                                        LinearGradient(
                                            colors: [.primary.opacity(0.7), .primary],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geometry.size.width * animatedProgress, height: 8)
                            }
                        }
                        .frame(height: 8)

                        // Next milestone info
                        HStack {
                            Image(systemName: currentMilestone.icon)
                                .font(.caption)
                                .foregroundColor(.primary)

                            Text("\(currentMilestone.logs - totalLogs) more logs to unlock \(currentMilestone.feature)")
                                .font(.caption)
                                .foregroundColor(.mutedForeground)

                            Spacer()
                        }
                    }

                    // Milestone dots
                    HStack(spacing: 0) {
                        ForEach(milestones, id: \.logs) { milestone in
                            let isCompleted = totalLogs >= milestone.logs
                            let isCurrent = milestone.logs == currentMilestone.logs

                            VStack(spacing: 4) {
                                ZStack {
                                    Circle()
                                        .fill(isCompleted ? Color.success : (isCurrent ? Color.primary.opacity(0.3) : Color.mutedForeground.opacity(0.2)))
                                        .frame(width: 24, height: 24)

                                    if isCompleted {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    } else {
                                        Text("\(milestone.logs)")
                                            .font(.system(size: 9, weight: .medium))
                                            .foregroundColor(isCurrent ? .primary : .mutedForeground)
                                    }
                                }

                                Text(milestone.feature)
                                    .font(.system(size: 9))
                                    .foregroundColor(isCompleted ? .foreground : .mutedForeground)
                                    .lineLimit(2)
                                    .multilineTextAlignment(.center)
                                    .frame(width: 60)
                            }

                            if milestone.logs != milestones.last?.logs {
                                Spacer()
                            }
                        }
                    }

                    // Pace prediction encouragement
                    if !isComplete && daysActive > 0 {
                        let estimatedDays = estimatedDaysToNextMilestone()
                        if estimatedDays > 0 {
                            Text("At your current pace, \(currentMilestone.feature) unlock in \(estimatedDays) days")
                                .font(.caption)
                                .foregroundColor(.mutedForeground)
                                .padding(.top, .spacingXS)
                        }
                    }
                } else {
                    // Completed state - conversion opportunity
                    if !isPro {
                        Divider()

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Ready for AI insights")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.foreground)

                                Text("Your data is ready for personalized predictions")
                                    .font(.caption)
                                    .foregroundColor(.mutedForeground)
                            }

                            Spacer()

                            Button(action: {
                                Haptics.medium()
                                onUpgradeTap()
                            }) {
                                Text("Unlock")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, .spacingMD)
                                    .padding(.vertical, .spacingSM)
                                    .background(Color.primary)
                                    .cornerRadius(.radiusSM)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            // Animate progress bar - research shows animation increases engagement
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                animatedProgress = progress
            }
        }
    }
}

#Preview {
    VStack(spacing: .spacingLG) {
        // Early progress
        PatternProgressCard(
            totalLogs: 7,
            daysActive: 3,
            isPro: false,
            onUpgradeTap: {}
        )

        // Mid progress
        PatternProgressCard(
            totalLogs: 15,
            daysActive: 7,
            isPro: false,
            onUpgradeTap: {}
        )

        // Completed
        PatternProgressCard(
            totalLogs: 52,
            daysActive: 14,
            isPro: false,
            onUpgradeTap: {}
        )
    }
    .padding()
    .background(Color.background)
}
