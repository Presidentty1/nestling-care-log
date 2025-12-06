import WidgetKit
import SwiftUI
import Nuzzle

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
        NextNapEntry(
            date: Date(),
            predictedTime: Date().addingTimeInterval(3600),
            confidence: 0.7,
            explanation: "Based on wake window patterns",
            hasData: false
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (NextNapEntry) -> Void) {
        let entry = createEntry()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<NextNapEntry>) -> Void) {
        let entry = createEntry()

        // Reload every 15 minutes for real-time updates
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func createEntry() -> NextNapEntry {
        if let prediction = SharedWidgetData.shared.getNextNapPrediction() {
            return NextNapEntry(
                date: Date(),
                predictedTime: prediction.predictedTime,
                confidence: prediction.confidence,
                explanation: prediction.explanation,
                hasData: true
            )
        } else {
            // Fallback to mock data when no prediction available
            return NextNapEntry(
                date: Date(),
                predictedTime: Date().addingTimeInterval(3600),
                confidence: 0.7,
                explanation: "Based on wake window patterns",
                hasData: false
            )
        }
    }
}

struct NextNapEntry: TimelineEntry {
    let date: Date
    let predictedTime: Date
    let confidence: Double
    let explanation: String
    let hasData: Bool
}

struct NextNapWidgetEntryView: View {
    var entry: NextNapTimelineProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        if !entry.hasData {
            // No data state
            switch family {
            case .accessoryCircular:
                VStack(spacing: 4) {
                    Image(systemName: "moon")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    Text("--")
                        .font(.caption2)
                }
            case .accessoryInline:
                HStack(spacing: 4) {
                    Image(systemName: "moon")
                    Text("Log naps to see predictions")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            default:
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "moon")
                            .foregroundColor(.secondary)
                        Text("Next Nap")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }

                    Text("Log some naps to see predictions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("Start tracking sleep patterns")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
        } else {
            // Has data state
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

