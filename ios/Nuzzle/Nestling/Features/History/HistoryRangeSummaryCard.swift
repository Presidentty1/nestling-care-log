import SwiftUI

struct HistoryRangeSummaryCard: View {
    let summary: HistoryRangeSummary

    private var title: String {
        switch summary.range {
        case .last24Hours: return "Last 24 hours"
        case .last7Days: return "Last 7 days"
        case .last30Days: return "Last 30 days"
        }
    }

    var body: some View {
        CardView(variant: .elevated) {
            VStack(alignment: .leading, spacing: .spacingSM) {
                HStack {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.foreground)
                    Spacer()
                }

                switch summary.range {
                case .last24Hours:
                    totalsRow
                case .last7Days, .last30Days:
                    averagesRow
                }
            }
            .padding(.spacingMD)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("\(title). Sleep \(sleepString). Feeds \(summary.totalFeeds). Diapers \(summary.totalDiapers).")
        }
    }

    private var totalsRow: some View {
        HStack(spacing: .spacingMD) {
            metric(icon: "moon.zzz.fill", color: .eventSleep, title: "Sleep", value: sleepString)
            metric(icon: "drop.fill", color: .eventFeed, title: "Feeds", value: "\(summary.totalFeeds)")
            metric(icon: "drop.circle.fill", color: .eventDiaper, title: "Diapers", value: "\(summary.totalDiapers)")
            metric(icon: "waveform", color: .eventCry, title: "Cry", value: "\(summary.totalCries)")
        }
    }

    private var averagesRow: some View {
        HStack(spacing: .spacingMD) {
            metric(icon: "moon.zzz.fill", color: .eventSleep, title: "Avg sleep", value: String(format: "%.1fh", summary.avgSleepHoursPerDay))
            metric(icon: "fork.knife", color: .eventFeed, title: "Avg feeds", value: String(format: "%.1f", summary.avgFeedsPerDay))
            metric(icon: "tshirt.fill", color: .eventDiaper, title: "Avg diapers", value: String(format: "%.1f", summary.avgDiapersPerDay))
            metric(icon: "waveform", color: .eventCry, title: "Cry", value: "\(summary.totalCries)")
        }
    }

    private func metric(icon: String, color: Color, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption.weight(.semibold))
                Text(title)
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
            }
            Text(value)
                .font(.title3.weight(.semibold))
                .foregroundColor(.foreground)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var sleepString: String {
        let hours = summary.totalSleepMinutes / 60
        let minutes = summary.totalSleepMinutes % 60
        if hours > 0 && minutes > 0 { return "\(hours)h \(minutes)m" }
        if hours > 0 { return "\(hours)h" }
        return "\(minutes)m"
    }
}

#Preview {
    VStack(spacing: 16) {
        HistoryRangeSummaryCard(
            summary: HistoryRangeSummary(
                range: .last24Hours,
                totalDays: 1,
                totalFeeds: 8,
                totalDiapers: 6,
                totalSleepMinutes: 860,
                totalCries: 2
            )
        )

        HistoryRangeSummaryCard(
            summary: HistoryRangeSummary(
                range: .last7Days,
                totalDays: 7,
                totalFeeds: 52,
                totalDiapers: 42,
                totalSleepMinutes: 7 * 840,
                totalCries: 6
            )
        )
    }
    .padding()
    .background(Color.background)
}


