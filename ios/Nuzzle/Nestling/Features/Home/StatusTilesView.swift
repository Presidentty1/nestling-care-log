import SwiftUI

/// Status tiles view showing Last Feed, Last Diaper, Sleep Status, and Next Nap
/// Matches North Star dashboard layout requirements
struct StatusTilesView: View {
    let lastFeed: Event?
    let lastDiaper: Event?
    let activeSleep: Event?
    let nextNapWindow: NapWindow?
    let baby: Baby
    
    var body: some View {
        VStack(spacing: .spacingMD) {
            // Hero Card: Next Nap or Active Sleep
            if let napWindow = nextNapWindow {
                HeroNapCard(napWindow: napWindow, baby: baby)
            } else if let sleep = activeSleep {
                ActiveSleepHeroCard(activeSleep: sleep)
            }
            
            // Satellite Cards: Feed & Diaper (side by side)
            HStack(spacing: .spacingMD) {
                SatelliteCard(
                    icon: "drop.fill",
                    iconColor: .eventFeed,
                    title: "Last Feed",
                    value: formatFeedValue(lastFeed),
                    timeAgo: lastFeed.map { DateUtils.formatRelativeTime($0.startTime) }
                )
                
                SatelliteCard(
                    icon: "drop.circle.fill",
                    iconColor: .eventDiaper,
                    title: "Last Diaper",
                    value: formatDiaperValue(lastDiaper),
                    timeAgo: lastDiaper.map { DateUtils.formatRelativeTime($0.startTime) }
                )
            }
        }
        .padding(.horizontal, .spacingMD)
    }
    
    private func formatFeedValue(_ event: Event?) -> String {
        guard let event = event else { return timeBasedPrompt() }
        if let amount = event.amount, let unit = event.unit {
            let displayAmount: Double
            if unit == "oz" {
                displayAmount = amount / 30.0
                return "\(Int(displayAmount)) oz"
            } else {
                return "\(Int(amount)) ml"
            }
        } else if let subtype = event.subtype {
            return subtype.capitalized
        }
        return "Logged"
    }
    
    private func formatDiaperValue(_ event: Event?) -> String {
        guard let event = event else { return timeBasedPrompt() }
        return event.subtype?.capitalized ?? "Logged"
    }
    
    private func timeBasedPrompt() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 6..<11: return "Ready?"
        case 11..<15: return "Time to log?"
        case 15..<18: return "Track it?"
        case 18..<22: return "Log dinner?"
        default: return "Ready to track"
        }
    }
    
    private func formatSleepStatus(_ activeSleep: Event?) -> String {
        if activeSleep != nil {
            return "Asleep"
        } else {
            return "Awake"
        }
    }
    
    private func formatSleepDuration(_ sleep: Event) -> String {
        let duration = Date().timeIntervalSince(sleep.startTime)
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private func formatNapWindow(_ window: NapWindow?) -> String {
        guard let window = window else { return "Calculating..." }
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let startTime = timeFormatter.string(from: window.start)
        let endTime = timeFormatter.string(from: window.end)
        return "\(startTime)–\(endTime)"
    }
    
    private func formatNapTimeAgo(_ window: NapWindow) -> String {
        let now = Date()
        let minutesUntilStart = Int(window.start.timeIntervalSince(now) / 60)
        if minutesUntilStart < 0 {
            return "Window active"
        } else if minutesUntilStart < 60 {
            return "in \(minutesUntilStart) min"
        } else {
            let hours = minutesUntilStart / 60
            let minutes = minutesUntilStart % 60
            if minutes == 0 {
                return "in \(hours)h"
            } else {
                return "in \(hours)h \(minutes)m"
            }
        }
    }
}

/// Hero card for Next Nap prediction
struct HeroNapCard: View {
    let napWindow: NapWindow
    let baby: Baby
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingMD) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.eventSleep)
                
                Text("Next Nap")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.mutedForeground)
                
                Spacer()
            }
            
            Text(formatNapWindow(napWindow))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.foreground)
            
            Text(formatTimeUntil(napWindow))
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.mutedForeground)
        }
        .padding(.spacingLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.elevated)
        .cornerRadius(.radiusLG)
        .overlay(
            RoundedRectangle(cornerRadius: .radiusLG)
                .stroke(Color.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
    
    private func formatNapWindow(_ window: NapWindow) -> String {
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        let startTime = timeFormatter.string(from: window.start)
        let endTime = timeFormatter.string(from: window.end)
        return "\(startTime)–\(endTime)"
    }
    
    private func formatTimeUntil(_ window: NapWindow) -> String {
        let now = Date()
        let minutesUntilStart = Int(window.start.timeIntervalSince(now) / 60)
        if minutesUntilStart < 0 {
            return "Window is active now"
        } else if minutesUntilStart < 60 {
            return "in \(minutesUntilStart) min"
        } else {
            let hours = minutesUntilStart / 60
            let minutes = minutesUntilStart % 60
            if minutes == 0 {
                return "in \(hours)h"
            } else {
                return "in \(hours)h \(minutes)m"
            }
        }
    }
}

/// Hero card for active sleep
struct ActiveSleepHeroCard: View {
    let activeSleep: Event
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingMD) {
            HStack {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.eventSleep)
                
                Text("Currently Sleeping")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.mutedForeground)
                
                Spacer()
            }
            
            Text(formatSleepDuration(activeSleep))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.foreground)
            
            Text("Started \(DateUtils.formatRelativeTime(activeSleep.startTime))")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.mutedForeground)
        }
        .padding(.spacingLG)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.eventSleep.opacity(0.15),
                    Color.eventSleep.opacity(0.08)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(.radiusLG)
        .overlay(
            RoundedRectangle(cornerRadius: .radiusLG)
                .stroke(Color.eventSleep.opacity(0.3), lineWidth: 1.5)
        )
        .shadow(color: Color.eventSleep.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    private func formatSleepDuration(_ sleep: Event) -> String {
        let duration = Date().timeIntervalSince(sleep.startTime)
        let hours = Int(duration / 3600)
        let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes) min"
        }
    }
}

/// Satellite card for quick reference info
struct SatelliteCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let timeAgo: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingSM) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(iconColor)
            
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.mutedForeground)
            
            Text(value)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.foreground)
                .lineLimit(1)
            
            if let timeAgo = timeAgo {
                Text(timeAgo)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.mutedForeground.opacity(0.8))
            }
        }
        .padding(.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 120)
        .background(Color.surface)
        .cornerRadius(.radiusMD)
        .overlay(
            RoundedRectangle(cornerRadius: .radiusMD)
                .stroke(Color.cardBorder, lineWidth: 1)
        )
    }
}

/// Individual status tile component (legacy, kept for compatibility)
struct StatusTile: View {
    let title: String
    let icon: String
    let iconColor: Color
    let value: String
    let timeAgo: String?
    
    var body: some View {
        CardView(variant: .elevated) {
            VStack(alignment: .leading, spacing: .spacingXS) {
                HStack {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.title3)
                    
                    Spacer()
                }
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
                
                Text(value)
                    .font(.headline)
                    .foregroundColor(.foreground)
                    .lineLimit(2)
                
                if let timeAgo = timeAgo {
                    Text(timeAgo)
                        .font(.caption2)
                        .foregroundColor(.mutedForeground)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.spacingSM)
        }
    }
}

#Preview {
    StatusTilesView(
        lastFeed: Event(
            babyId: UUID(),
            type: .feed,
            subtype: "bottle",
            startTime: Date().addingTimeInterval(-2700),
            amount: 120,
            unit: "ml"
        ),
        lastDiaper: Event(
            babyId: UUID(),
            type: .diaper,
            subtype: "wet",
            startTime: Date().addingTimeInterval(-1200)
        ),
        activeSleep: nil,
        nextNapWindow: NapWindow(
            start: Date().addingTimeInterval(1500),
            end: Date().addingTimeInterval(3300),
            confidence: 0.7,
            reason: "Based on age"
        ),
        baby: Baby.mock()
    )
    .padding()
    .background(Color.background)
}
