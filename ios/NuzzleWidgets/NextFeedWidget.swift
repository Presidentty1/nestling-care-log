import WidgetKit
import SwiftUI

struct NextFeedWidget: Widget {
    let kind: String = "NextFeedWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextFeedTimelineProvider()) { entry in
            NextFeedWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next Feed")
        .description("Shows predicted next feed time")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryInline])
    }
}

struct NextFeedTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextFeedEntry {
        NextFeedEntry(date: Date(), predictedTime: Date().addingTimeInterval(7200), confidence: 0.8, explanation: "Based on feed spacing")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (NextFeedEntry) -> Void) {
        let entry = NextFeedEntry(date: Date(), predictedTime: Date().addingTimeInterval(7200), confidence: 0.8, explanation: "Based on feed spacing")
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<NextFeedEntry>) -> Void) {
        let entry = NextFeedEntry(date: Date(), predictedTime: Date().addingTimeInterval(7200), confidence: 0.8, explanation: "Based on feed spacing")
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct NextFeedEntry: TimelineEntry {
    let date: Date
    let predictedTime: Date
    let confidence: Double
    let explanation: String
}

struct NextFeedWidgetEntryView: View {
    var entry: NextFeedTimelineProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            VStack(spacing: 4) {
                Image(systemName: "drop.fill")
                    .font(.title3)
                Text(formatTime(entry.predictedTime))
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
        case .accessoryInline:
            HStack(spacing: 4) {
                Image(systemName: "drop.fill")
                Text("Next feed: \(formatTime(entry.predictedTime))")
            }
            .font(.caption)
        default:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "drop.fill")
                        .foregroundColor(.green)
                    Text("Next Feed")
                        .font(.headline)
                }
                
                Text(formatTime(entry.predictedTime))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(Int(entry.confidence * 100))% confidence")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Interactive buttons
                if family == .systemSmall || family == .systemMedium {
                    HStack(spacing: 8) {
                        Button(intent: LogFeed120mlIntent()) {
                            Label("120ml", systemImage: "drop.fill")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.green)
                        
                        Button(intent: LogFeed150mlIntent()) {
                            Label("150ml", systemImage: "drop.fill")
                                .font(.caption)
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.top, 4)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview(as: .systemSmall) {
    NextFeedWidget()
} timeline: {
    NextFeedEntry(date: Date(), predictedTime: Date().addingTimeInterval(7200), confidence: 0.8, explanation: "Test")
}

