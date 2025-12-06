import SwiftUI

/// Redesigned Status tiles with Hero-Satellite pattern
/// Hero card: Next Nap (most important)
/// Satellite cards: Last Feed, Last Diaper (quick reference)
struct StatusTilesViewNew: View {
    let lastFeed: Event?
    let lastDiaper: Event?
    let activeSleep: Event?
    let nextNapWindow: NapWindow?
    let baby: Baby
    
    var body: some View {
        VStack(spacing: .spacingMD) {
            // Hero Card: Next Nap Prediction
            if let napWindow = nextNapWindow {
                HeroNapCardNew(napWindow: napWindow, baby: baby)
            } else if activeSleep != nil {
                ActiveSleepHeroCardNew(activeSleep: activeSleep!)
            }
            
            // Satellite Cards: Feed & Diaper
            HStack(spacing: .spacingMD) {
                SatelliteCardNew(
                    icon: "drop.fill",
                    iconColor: .eventFeed,
                    title: "Last Feed",
                    value: formatFeedValue(lastFeed),
                    timeAgo: lastFeed.map { DateUtils.formatRelativeTime($0.startTime) }
                )
                
                SatelliteCardNew(
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
}

/// Hero card for Next Nap prediction (StatusTilesViewNew version)
private struct HeroNapCardNew: View {
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
            
            // Large time display
            Text(formatNapWindow(napWindow))
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.foreground)
            
            // Time until
            Text(formatTimeUntil(napWindow))
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.mutedForeground)
            
            // Optional: Set reminder button
            Button(action: {
                Haptics.light()
                // TODO: Implement reminder
            }) {
                HStack {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 14))
                    Text("Set Reminder")
                        .font(.system(size: 15, weight: .medium))
                }
                .foregroundColor(.primary)
                .padding(.vertical, .spacingSM)
                .padding(.horizontal, .spacingMD)
                .background(Color.primary.opacity(0.1))
                .cornerRadius(.radiusSM)
            }
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
            return "in \(minutesUntilStart) minutes"
        } else {
            let hours = minutesUntilStart / 60
            let minutes = minutesUntilStart % 60
            if minutes == 0 {
                return "in \(hours) hour\(hours == 1 ? "" : "s")"
            } else {
                return "in \(hours)h \(minutes)m"
            }
        }
    }
}

/// Hero card for active sleep (StatusTilesViewNew version)
private struct ActiveSleepHeroCardNew: View {
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
            
            // Duration display
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

/// Satellite card for quick reference info (StatusTilesViewNew version)
private struct SatelliteCardNew: View {
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

#Preview {
    StatusTilesViewNew(
        lastFeed: Event(
            babyId: UUID(),
            type: .feed,
            subtype: "bottle",
            startTime: Date().addingTimeInterval(-7200),
            amount: 120,
            unit: "ml"
        ),
        lastDiaper: Event(
            babyId: UUID(),
            type: .diaper,
            subtype: "wet",
            startTime: Date().addingTimeInterval(-3600)
        ),
        activeSleep: nil,
        nextNapWindow: NapWindow(
            start: Date().addingTimeInterval(2640),
            end: Date().addingTimeInterval(4440),
            confidence: 0.75,
            reason: "Based on typical patterns"
        ),
        baby: Baby.mock()
    )
    .padding()
    .background(Color.background)
}

