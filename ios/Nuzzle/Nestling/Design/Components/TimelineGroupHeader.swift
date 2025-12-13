import SwiftUI

/// Header component for grouped timeline events
/// Shows time block name, event count, and expandable icon row
struct TimelineGroupHeader: View {
    let timeBlock: TimeBlock
    let events: [Event]
    @Binding var isExpanded: Bool

    enum TimeBlock {
        case morning, afternoon, evening, night

        var name: String {
            switch self {
            case .morning: return "Morning"
            case .afternoon: return "Afternoon"
            case .evening: return "Evening"
            case .night: return "Night"
            }
        }

        var icon: String {
            switch self {
            case .morning: return "sunrise.fill"
            case .afternoon: return "sun.max.fill"
            case .evening: return "sunset.fill"
            case .night: return "moon.stars.fill"
            }
        }

        var color: Color {
            switch self {
            case .morning: return .orange.opacity(0.7)
            case .afternoon: return .yellow.opacity(0.7)
            case .evening: return .purple.opacity(0.7)
            case .night: return .blue.opacity(0.7)
            }
        }

        static func from(hour: Int) -> TimeBlock {
            switch hour {
            case 6..<12: return .morning
            case 12..<18: return .afternoon
            case 18..<22: return .evening
            default: return .night
            }
        }
    }

    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                isExpanded.toggle()
            }
            Haptics.light()
        }) {
            HStack(spacing: .spacingMD) {
                // Time block icon
                Image(systemName: timeBlock.icon)
                    .font(.title3)
                    .foregroundColor(timeBlock.color)
                    .frame(width: 32, height: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(timeBlock.name)
                        .font(.headline)
                        .foregroundColor(.foreground)

                    Text("\(events.count) \(events.count == 1 ? "event" : "events")")
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                }

                Spacer()

                // Icon row when collapsed
                if !isExpanded && events.count > 1 {
                    HStack(spacing: 4) {
                        ForEach(events.prefix(5)) { event in
                            Image(systemName: event.type.iconName)
                                .font(.caption)
                                .foregroundColor(event.type.color)
                                .frame(width: 20, height: 20)
                        }

                        if events.count > 5 {
                            Text("+\(events.count - 5)")
                                .font(.caption2)
                                .foregroundColor(.mutedForeground)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                                .background(Color.surface.opacity(0.8))
                                .cornerRadius(4)
                        }
                    }
                }

                // Expand/collapse indicator
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
            }
            .padding(.vertical, .spacingSM)
            .padding(.horizontal, .spacingMD)
            .background(Color.surface.opacity(0.5))
            .cornerRadius(.radiusMD)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(timeBlock.name) time block with \(events.count) events. \(isExpanded ? "Expanded" : "Collapsed")")
        .accessibilityHint("Double tap to \(isExpanded ? "collapse" : "expand") this time block")
    }
}

#Preview {
    VStack(spacing: .spacingMD) {
        TimelineGroupHeader(
            timeBlock: .morning,
            events: [
                Event(type: .feed, timestamp: Date(), amount: 4, unit: "oz"),
                Event(type: .diaper, timestamp: Date(), diaperType: .wet),
                Event(type: .sleep, timestamp: Date(), duration: 45)
            ],
            isExpanded: .constant(false)
        )

        TimelineGroupHeader(
            timeBlock: .afternoon,
            events: [
                Event(type: .feed, timestamp: Date(), amount: 4, unit: "oz"),
                Event(type: .tummyTime, timestamp: Date(), duration: 10),
                Event(type: .feed, timestamp: Date(), amount: 4, unit: "oz"),
                Event(type: .diaper, timestamp: Date(), diaperType: .wet),
                Event(type: .feed, timestamp: Date(), amount: 4, unit: "oz"),
                Event(type: .sleep, timestamp: Date(), duration: 30),
                Event(type: .diaper, timestamp: Date(), diaperType: .dirty)
            ],
            isExpanded: .constant(true)
        )
    }
    .padding()
}

