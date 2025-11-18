import WidgetKit
import SwiftUI

struct NextNapWidget: Widget {
    let kind: String = "NextNapWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: NextNapTimelineProvider()) { entry in
            NextNapWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Next Nap")
        .description("Shows predicted next nap time")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryInline])
    }
}

struct NextNapTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> NextNapEntry {
        NextNapEntry(date: Date(), predictedTime: Date().addingTimeInterval(3600), confidence: 0.7, explanation: "Based on wake window patterns")
    }
    
    func getSnapshot(in context: Context, completion: @escaping (NextNapEntry) -> Void) {
        let entry = NextNapEntry(date: Date(), predictedTime: Date().addingTimeInterval(3600), confidence: 0.7, explanation: "Based on wake window patterns")
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<NextNapEntry>) -> Void) {
        // In a real implementation, fetch from shared App Group storage
        let entry = NextNapEntry(date: Date(), predictedTime: Date().addingTimeInterval(3600), confidence: 0.7, explanation: "Based on wake window patterns")
        
        // Reload every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct NextNapEntry: TimelineEntry {
    let date: Date
    let predictedTime: Date
    let confidence: Double
    let explanation: String
}

struct NextNapWidgetEntryView: View {
    var entry: NextNapTimelineProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .accessoryCircular:
            VStack(spacing: 4) {
                Image(systemName: "moon.fill")
                    .font(.title3)
                Text(formatTime(entry.predictedTime))
                    .font(.caption2)
                    .fontWeight(.semibold)
            }
        case .accessoryInline:
            HStack(spacing: 4) {
                Image(systemName: "moon.fill")
                Text("Next nap: \(formatTime(entry.predictedTime))")
            }
            .font(.caption)
        default:
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundColor(.blue)
                    Text("Next Nap")
                        .font(.headline)
                }
                
                Text(formatTime(entry.predictedTime))
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("\(Int(entry.confidence * 100))% confidence")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Interactive button for sleep toggle
                if family == .systemSmall || family == .systemMedium {
                    Button(intent: ToggleSleepIntent(isActive: false)) {
                        Label("Start Sleep", systemImage: "moon.fill")
                            .font(.caption)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
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
    NextNapWidget()
} timeline: {
    NextNapEntry(date: Date(), predictedTime: Date().addingTimeInterval(3600), confidence: 0.7, explanation: "Test")
}

