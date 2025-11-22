import SwiftUI

struct TimeSinceChipsView: View {
    let lastFeed: Event?
    let lastDiaper: Event?
    let lastSleep: Event?
    let onTapFeed: () -> Void
    let onTapDiaper: () -> Void
    let onTapSleep: () -> Void
    
    var body: some View {
        HStack(spacing: .spacingSM) {
            if let feed = lastFeed {
                TimeSinceChip(
                    icon: "drop.fill",
                    color: .eventFeed,
                    text: "Feed • \(DateUtils.formatDetailedRelativeTime(feed.startTime))",
                    onTap: onTapFeed
                )
            }
            
            if let diaper = lastDiaper {
                TimeSinceChip(
                    icon: "drop.circle.fill",
                    color: .eventDiaper,
                    text: "Diaper • \(DateUtils.formatDetailedRelativeTime(diaper.startTime))",
                    onTap: onTapDiaper
                )
            }
            
            if let sleep = lastSleep, let endTime = sleep.endTime {
                TimeSinceChip(
                    icon: "moon.fill",
                    color: .eventSleep,
                    text: "Nap ended • \(DateUtils.formatDetailedRelativeTime(endTime))",
                    onTap: onTapSleep
                )
            }
        }
    }
}

private struct TimeSinceChip: View {
    let icon: String
    let color: Color
    let text: String
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(color)
                    .accessibilityHidden(true) // Icon is decorative

                Text(text)
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.surface)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Tap to log a \(icon.contains("drop") ? "feed" : icon.contains("moon") ? "sleep" : icon.contains("drop.circle") ? "diaper" : "tummy time")")
        .accessibilityHint("Opens the logging form")
    }
}

#Preview {
    TimeSinceChipsView(
        lastFeed: Event(
            babyId: UUID(),
            type: .feed,
            startTime: Date().addingTimeInterval(-4800), // 1h 20m ago
            amount: 120,
            unit: "ml"
        ),
        lastDiaper: Event(
            babyId: UUID(),
            type: .diaper,
            subtype: "wet",
            startTime: Date().addingTimeInterval(-2400) // 40m ago
        ),
        lastSleep: Event(
            babyId: UUID(),
            type: .sleep,
            startTime: Date().addingTimeInterval(-7200),
            endTime: Date().addingTimeInterval(-3600) // Ended 1h ago
        ),
        onTapFeed: {},
        onTapDiaper: {},
        onTapSleep: {}
    )
    .padding()
    .background(Color.background)
}

