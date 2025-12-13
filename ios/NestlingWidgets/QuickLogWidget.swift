import WidgetKit
import SwiftUI
import AppIntents

/// Quick Log Widget - Allows logging events directly from the home screen
struct QuickLogWidget: Widget {
    let kind: String = "QuickLogWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickLogWidgetProvider()) { entry in
            QuickLogWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Quick Log")
        .description("Log feeds, sleep, and diapers with one tap")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// Timeline provider for the Quick Log widget
struct QuickLogWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickLogWidgetEntry {
        QuickLogWidgetEntry(
            date: Date(),
            lastEvent: "No recent events",
            babyName: "Baby"
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickLogWidgetEntry) -> ()) {
        let entry = QuickLogWidgetEntry(
            date: Date(),
            lastEvent: "Last feed 2h ago",
            babyName: "Emma"
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickLogWidgetEntry>) -> ()) {
        Task {
            // In a real implementation, this would fetch data from shared container
            // For now, create a mock timeline
            let currentDate = Date()
            let entry = QuickLogWidgetEntry(
                date: currentDate,
                lastEvent: await getLastEventDescription(),
                babyName: await getCurrentBabyName()
            )

            // Update every 15 minutes
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate)!
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))

            completion(timeline)
        }
    }

    private func getLastEventDescription() async -> String {
        // In real implementation, read from shared UserDefaults or CoreData
        return "Last feed 2h ago"
    }

    private func getCurrentBabyName() async -> String {
        // In real implementation, read from shared UserDefaults
        return "Emma"
    }
}

/// Entry for the Quick Log widget
struct QuickLogWidgetEntry: TimelineEntry {
    let date: Date
    let lastEvent: String
    let babyName: String
}

/// View for the Quick Log widget entry
struct QuickLogWidgetEntryView: View {
    var entry: QuickLogWidgetEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallQuickLogWidgetView(entry: entry)
        case .systemMedium:
            MediumQuickLogWidgetView(entry: entry)
        default:
            SmallQuickLogWidgetView(entry: entry)
        }
    }
}

/// Small widget view (2x2)
struct SmallQuickLogWidgetView: View {
    var entry: QuickLogWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Spacer()
                Text(entry.babyName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(entry.lastEvent)
                .font(.caption2)
                .foregroundColor(.secondary)

            HStack(spacing: 8) {
                QuickLogButton(eventType: .feed)
                QuickLogButton(eventType: .diaper)
            }
        }
        .padding(8)
    }
}

/// Medium widget view (2x4)
struct MediumQuickLogWidgetView: View {
    var entry: QuickLogWidgetEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(.red)
                    Text(entry.babyName)
                        .font(.headline)
                }

                Text(entry.lastEvent)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()
            }

            Spacer()

            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    QuickLogButton(eventType: .feed)
                    QuickLogButton(eventType: .diaper)
                }

                HStack(spacing: 8) {
                    QuickLogButton(eventType: .sleep)
                    QuickLogButton(eventType: .tummyTime)
                }
            }
        }
        .padding(12)
    }
}

/// Quick action button for logging events
struct QuickLogButton: View {
    let eventType: EventType

    var body: some View {
        Button(intent: LogEventIntent(eventType: eventType)) {
            VStack(spacing: 2) {
                Image(systemName: iconName(for: eventType))
                    .font(.system(size: 16))
                    .foregroundColor(iconColor(for: eventType))

                Text(title(for: eventType))
                    .font(.caption2)
                    .foregroundColor(.primary)
            }
            .frame(width: 44, height: 44)
            .background(Color.white.opacity(0.2))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }

    private func iconName(for eventType: EventType) -> String {
        switch eventType {
        case .feed: return "bottle.fill"
        case .diaper: return "arrow.triangle.2.circlepath.circle.fill"
        case .sleep: return "moon.fill"
        case .tummyTime: return "figure.play"
        }
    }

    private func iconColor(for eventType: EventType) -> Color {
        switch eventType {
        case .feed: return .blue
        case .diaper: return .green
        case .sleep: return .purple
        case .tummyTime: return .orange
        }
    }

    private func title(for eventType: EventType) -> String {
        switch eventType {
        case .feed: return "Feed"
        case .diaper: return "Diaper"
        case .sleep: return "Sleep"
        case .tummyTime: return "Tummy"
        }
    }
}

/// App Intent for logging events from widget
struct LogEventIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Event"

    @Parameter(title: "Event Type")
    var eventType: EventType

    init(eventType: EventType) {
        self.eventType = eventType
    }

    init() {}

    func perform() async throws -> some IntentResult {
        // In a real implementation, this would:
        // 1. Open the app if needed
        // 2. Log the event using shared data store
        // 3. Update widget timeline

        // For now, just return success
        return .result()
    }
}






