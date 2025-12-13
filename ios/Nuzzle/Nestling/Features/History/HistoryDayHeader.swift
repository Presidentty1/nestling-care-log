import SwiftUI

struct HistoryDayHeader: View {
    let date: Date
    let summary: HistoryDaySummary

    private var title: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return "Today" }
        if calendar.isDateInYesterday(date) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }

    private var subtitle: String {
        var parts: [String] = []
        if summary.totalSleepMinutes > 0 {
            let hours = summary.totalSleepMinutes / 60
            let mins = summary.totalSleepMinutes % 60
            let sleepString = hours > 0 ? "\(hours)h \(mins)m" : "\(mins)m"
            parts.append("Sleep \(sleepString)")
        }
        if summary.feedCount > 0 { parts.append("\(summary.feedCount) feeds") }
        if summary.diaperCount > 0 { parts.append("\(summary.diaperCount) diapers") }
        if summary.cryCount > 0 { parts.append("\(summary.cryCount) cries") }
        return parts.joined(separator: " • ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.semibold))
                .foregroundColor(.foreground)
            if !subtitle.isEmpty {
                Text(subtitle)
                    .font(.footnote)
                    .foregroundColor(.mutedForeground)
            }
        }
        .padding(.vertical, .spacingSM)
        .padding(.horizontal, .spacingMD)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(subtitle)")
    }
}

#Preview {
    HistoryDayHeader(
        date: Date(),
        summary: HistoryDaySummary(
            totalSleepMinutes: 840,
            napCount: 3,
            feedCount: 8,
            diaperCount: 6,
            wetDiaperCount: 4,
            dirtyDiaperCount: 2,
            tummyTimeCount: 1,
            cryCount: 2
        )
    )
    .background(Color.background)
}



