import WidgetKit
import SwiftUI
import Nestling

struct TodaySummaryWidget: Widget {
    let kind: String = "TodaySummaryWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TodaySummaryTimelineProvider()) { entry in
            TodaySummaryWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Today Summary")
        .description("Shows today's feed, diaper, and sleep counts")
        .supportedFamilies([.systemMedium])
    }
}

struct TodaySummaryTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> TodaySummaryEntry {
        TodaySummaryEntry(date: Date(), feeds: 0, diapers: 0, sleepHours: 0, hasData: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (TodaySummaryEntry) -> Void) {
        let entry = createEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TodaySummaryEntry>) -> Void) {
        let entry = createEntry()

        // Update every 30 minutes for real-time data
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func createEntry() -> TodaySummaryEntry {
        let summary = SharedWidgetData.shared.getTodaySummary()

        return TodaySummaryEntry(
            date: Date(),
            feeds: summary.feedCount,
            diapers: summary.diaperCount,
            sleepHours: summary.totalSleepHours,
            hasData: summary.feedCount > 0 || summary.diaperCount > 0 || summary.totalSleepMinutes > 0
        )
    }
}

struct TodaySummaryEntry: TimelineEntry {
    let date: Date
    let feeds: Int
    let diapers: Int
    let sleepHours: Double
    let hasData: Bool
}

struct TodaySummaryWidgetEntryView: View {
    var entry: TodaySummaryTimelineProvider.Entry

    var body: some View {
        if !entry.hasData {
            // No data state
            VStack(spacing: 8) {
                Image(systemName: "chart.bar.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)

                Text("No activity yet today")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("Start logging to see your summary")
                    .font(.caption)
                    .foregroundColor(.secondary.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            // Has data state
            HStack(spacing: 16) {
                SummaryItem(icon: "drop.fill", value: "\(entry.feeds)", label: "Feeds", color: .green)
                SummaryItem(icon: "drop.circle.fill", value: "\(entry.diapers)", label: "Diapers", color: .blue)
                SummaryItem(icon: "moon.fill", value: String(format: "%.1f", entry.sleepHours), label: "Hours", color: .purple)
            }
            .padding()
        }
    }
}

struct SummaryItem: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title2)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview(as: .systemMedium) {
    TodaySummaryWidget()
} timeline: {
    TodaySummaryEntry(date: Date(), feeds: 5, diapers: 6, sleepHours: 14.5)
}


