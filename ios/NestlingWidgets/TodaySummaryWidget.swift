import WidgetKit
import SwiftUI

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
        TodaySummaryEntry(date: Date(), feeds: 5, diapers: 6, sleepHours: 14.5)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (TodaySummaryEntry) -> Void) {
        let entry = TodaySummaryEntry(date: Date(), feeds: 5, diapers: 6, sleepHours: 14.5)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<TodaySummaryEntry>) -> Void) {
        let entry = TodaySummaryEntry(date: Date(), feeds: 5, diapers: 6, sleepHours: 14.5)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct TodaySummaryEntry: TimelineEntry {
    let date: Date
    let feeds: Int
    let diapers: Int
    let sleepHours: Double
}

struct TodaySummaryWidgetEntryView: View {
    var entry: TodaySummaryTimelineProvider.Entry
    
    var body: some View {
        HStack(spacing: 16) {
            SummaryItem(icon: "drop.fill", value: "\(entry.feeds)", label: "Feeds", color: .green)
            SummaryItem(icon: "drop.circle.fill", value: "\(entry.diapers)", label: "Diapers", color: .blue)
            SummaryItem(icon: "moon.fill", value: String(format: "%.1f", entry.sleepHours), label: "Hours", color: .purple)
        }
        .padding()
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


