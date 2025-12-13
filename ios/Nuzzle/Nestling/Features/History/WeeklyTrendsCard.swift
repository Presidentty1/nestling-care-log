import SwiftUI
import Charts

/// Weekly Trends Card - Visual comparison of this week vs last week
/// Research shows data visualization increases retention by 30%
struct WeeklyTrendsCard: View {
    let thisWeekData: InsightGenerationService.WeekSummary
    let lastWeekData: InsightGenerationService.WeekSummary?
    let isPro: Bool
    let onUpgradeTap: () -> Void

    private var sleepTrend: TrendDirection {
        guard let lastWeek = lastWeekData else { return .neutral }
        let diff = thisWeekData.avgSleepHours - lastWeek.avgSleepHours
        if diff > 0.5 { return .up }
        if diff < -0.5 { return .down }
        return .neutral
    }

    private var feedsTrend: TrendDirection {
        guard let lastWeek = lastWeekData else { return .neutral }
        let diff = thisWeekData.avgFeeds - lastWeek.avgFeeds
        if diff > 0.5 { return .up }
        if diff < -0.5 { return .down }
        return .neutral
    }

    private var diapersTrend: TrendDirection {
        guard let lastWeek = lastWeekData else { return .neutral }
        let diff = thisWeekData.avgDiapers - lastWeek.avgDiapers
        if diff > 0.5 { return .up }
        if diff < -0.5 { return .down }
        return .neutral
    }

    enum TrendDirection {
        case up, down, neutral

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .neutral: return "minus"
            }
        }

        var color: Color {
            switch self {
            case .up: return .success
            case .down: return .warning
            case .neutral: return .mutedForeground
            }
        }

        var description: String {
            switch self {
            case .up: return "up"
            case .down: return "down"
            case .neutral: return "same"
            }
        }
    }

    var body: some View {
        CardView(variant: .elevated) {
            VStack(alignment: .leading, spacing: .spacingMD) {
                // Header
                HStack {
                    Text("This Week")
                        .font(.headline)
                        .foregroundColor(.foreground)

                    Spacer()

                    if lastWeekData != nil {
                        HStack(spacing: 4) {
                            Image(systemName: sleepTrend.icon)
                            Text("vs last week")
                        }
                        .font(.caption)
                        .foregroundColor(sleepTrend.color)
                    }
                }

                // Quick stats row
                HStack(spacing: .spacingMD) {
                    TrendStatView(
                        icon: "moon.zzz.fill",
                        color: .eventSleep,
                        label: "Avg Sleep",
                        value: String(format: "%.1fh", thisWeekData.avgSleepHours),
                        trend: sleepTrend
                    )

                    TrendStatView(
                        icon: "drop.fill",
                        color: .eventFeed,
                        label: "Avg Feeds",
                        value: String(format: "%.1f/day", thisWeekData.avgFeeds),
                        trend: feedsTrend
                    )

                    TrendStatView(
                        icon: "drop.circle.fill",
                        color: .eventDiaper,
                        label: "Diapers",
                        value: String(format: "%.1f/day", thisWeekData.avgDiapers),
                        trend: diapersTrend
                    )
                }

                // Mini chart (Pro feature preview)
                if isPro {
                    // Full chart for Pro users
                    Chart {
                        ForEach(thisWeekData.dailyData) { day in
                            BarMark(
                                x: .value("Day", day.date, unit: .day),
                                y: .value("Sleep", day.sleepHours)
                            )
                            .foregroundStyle(Color.eventSleep.gradient)
                            .cornerRadius(4)
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { _ in
                            AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading)
                    }
                    .frame(height: 120)
                } else {
                    // Blurred preview for free users
                    ZStack {
                        Chart {
                            ForEach(thisWeekData.dailyData) { day in
                                BarMark(
                                    x: .value("Day", day.date, unit: .day),
                                    y: .value("Sleep", day.sleepHours)
                                )
                                .foregroundStyle(Color.eventSleep.gradient)
                            }
                        }
                        .frame(height: 100)
                        .blur(radius: 4)
                        .opacity(0.6)

                        VStack(spacing: .spacingSM) {
                            Image(systemName: "lock.fill")
                                .font(.title)
                                .foregroundColor(.primary)

                            Text("See daily trends")
                                .font(.caption)
                                .foregroundColor(.mutedForeground)

                            Button("Unlock with Pro") {
                                Haptics.light()
                                onUpgradeTap()
                            }
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
}

struct TrendStatView: View {
    let icon: String
    let color: Color
    let label: String
    let value: String
    let trend: WeeklyTrendsCard.TrendDirection

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingXS) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(color)

                if trend != .neutral {
                    Image(systemName: trend.icon)
                        .font(.system(size: 10))
                        .foregroundColor(trend.color)
                }
            }

            Text(value)
                .font(.title3.weight(.bold))
                .foregroundColor(.foreground)

            Text(label)
                .font(.caption2)
                .foregroundColor(.mutedForeground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    let sampleWeek = InsightGenerationService.WeekSummary(
        avgSleepHours: 12.5,
        avgFeeds: 7.8,
        avgDiapers: 5.2,
        dailyData: [
            .init(date: Date().addingTimeInterval(-6*24*3600), sleepHours: 11.5, feedCount: 8, diaperCount: 6),
            .init(date: Date().addingTimeInterval(-5*24*3600), sleepHours: 12.0, feedCount: 7, diaperCount: 5),
            .init(date: Date().addingTimeInterval(-4*24*3600), sleepHours: 13.0, feedCount: 8, diaperCount: 6),
            .init(date: Date().addingTimeInterval(-3*24*3600), sleepHours: 12.5, feedCount: 7, diaperCount: 5),
            .init(date: Date().addingTimeInterval(-2*24*3600), sleepHours: 13.5, feedCount: 8, diaperCount: 6),
            .init(date: Date().addingTimeInterval(-1*24*3600), sleepHours: 12.0, feedCount: 7, diaperCount: 5),
            .init(date: Date(), sleepHours: 12.8, feedCount: 8, diaperCount: 6)
        ]
    )

    VStack(spacing: .spacingLG) {
        WeeklyTrendsCard(
            thisWeekData: sampleWeek,
            lastWeekData: nil,
            isPro: true,
            onUpgradeTap: {}
        )

        WeeklyTrendsCard(
            thisWeekData: sampleWeek,
            lastWeekData: sampleWeek,
            isPro: false,
            onUpgradeTap: {}
        )
    }
    .padding()
    .background(Color.background)
}
