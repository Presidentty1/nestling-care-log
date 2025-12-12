import SwiftUI

/// View showing recent activity feed with who logged what and when
struct ActivityFeedView: View {
    let events: [Event]
    let baby: Baby

    private var recentActivities: [ActivityItem] {
        // Convert events to activity items, showing most recent first
        events.prefix(20).map { event in
            ActivityItem(
                id: event.id.uuidString,
                caregiverName: "You", // In MVP, all activities are by current user
                action: activityDescription(for: event),
                timestamp: event.startTime,
                eventType: event.type
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingMD) {
            // Header
            Text("Recent Activity")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal, .spacingMD)

            if recentActivities.isEmpty {
                // Empty state
                VStack(spacing: .spacingMD) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.system(size: 48))
                        .foregroundColor(.mutedForeground)

                    Text("No recent activity")
                        .font(.headline)
                        .foregroundColor(.foreground)

                    Text("Activity from logging events will appear here")
                        .font(.body)
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, .spacingMD)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.top, .spacing2XL)
            } else {
                // Activity list
                ScrollView {
                    VStack(spacing: .spacingSM) {
                        ForEach(recentActivities) { activity in
                            ActivityRow(activity: activity)
                        }
                    }
                    .padding(.horizontal, .spacingMD)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }

    private func activityDescription(for event: Event) -> String {
        switch event.type {
        case .feed:
            if let amount = event.amount, let unit = event.unit {
                return "logged \(Int(amount))\(unit) feed"
            } else if event.subtype == "breast" {
                return "logged breast feed"
            } else {
                return "logged feed"
            }
        case .sleep:
            if let duration = event.durationMinutes {
                let hours = duration / 60
                let minutes = duration % 60
                if hours > 0 {
                    return "logged \(hours)h \(minutes)m sleep"
                } else {
                    return "logged \(minutes)m sleep"
                }
            } else {
                return "started sleep session"
            }
        case .diaper:
            return "logged diaper change"
        case .tummyTime:
            if let duration = event.durationMinutes {
                return "logged \(duration)m tummy time"
            } else {
                return "started tummy time"
            }
        case .cry:
            if let duration = event.durationMinutes {
                return "logged \(duration)s cry"
            }
            return "logged cry"
        }
    }
}

/// Individual activity item
struct ActivityItem: Identifiable {
    let id: String
    let caregiverName: String
    let action: String
    let timestamp: Date
    let eventType: EventType

    var relativeTime: String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: timestamp, to: now)

        if let days = components.day, days > 0 {
            return days == 1 ? "1 day ago" : "\(days) days ago"
        } else if let hours = components.hour, hours > 0 {
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        } else if let minutes = components.minute, minutes > 0 {
            return minutes == 1 ? "1 minute ago" : "\(minutes) minutes ago"
        } else {
            return "Just now"
        }
    }
}

/// Row displaying a single activity item
struct ActivityRow: View {
    let activity: ActivityItem

    var body: some View {
        HStack(alignment: .top, spacing: .spacingMD) {
            // Icon
            ZStack {
                Circle()
                    .fill(activity.eventType.color.opacity(0.1))
                    .frame(width: 32, height: 32)

                Image(systemName: activity.eventType.iconName)
                    .foregroundColor(activity.eventType.color)
                    .font(.system(size: 14))
            }

            // Content
            VStack(alignment: .leading, spacing: 2) {
                Text("\(activity.caregiverName) \(activity.action)")
                    .font(.body)
                    .foregroundColor(.foreground)
                    .lineLimit(2)

                Text(activity.relativeTime)
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
            }

            Spacer()
        }
        .padding(.vertical, .spacingSM)
        .padding(.horizontal, .spacingMD)
        .background(Color.surface)
        .cornerRadius(.radiusMD)
    }
}

#Preview {
    let sampleEvents = [
        Event(
            id: UUID(),
            babyId: UUID(),
            type: .feed,
            subtype: "bottle",
            startTime: Date().addingTimeInterval(-300), // 5 minutes ago
            amount: 120,
            unit: "ml",
            createdAt: Date().addingTimeInterval(-300)
        ),
        Event(
            id: UUID(),
            babyId: UUID(),
            type: .sleep,
            startTime: Date().addingTimeInterval(-3600), // 1 hour ago
            endTime: Date().addingTimeInterval(-1800), // 30 minutes ago
            createdAt: Date().addingTimeInterval(-3600)
        ),
        Event(
            id: UUID(),
            babyId: UUID(),
            type: .diaper,
            startTime: Date().addingTimeInterval(-7200), // 2 hours ago
            createdAt: Date().addingTimeInterval(-7200)
        )
    ]

    ActivityFeedView(events: sampleEvents, baby: Baby(id: UUID(), name: "Test Baby", dateOfBirth: Date()))
}
