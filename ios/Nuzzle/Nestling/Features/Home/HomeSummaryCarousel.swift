import SwiftUI

/// Horizontal summary cards for quick glance status on Home.
struct HomeSummaryCarousel: View {
    let lastFeed: Event?
    let lastDiaper: Event?
    let activeSleep: Event?
    let lastSleep: Event?
    let nextNapWindow: NapWindow?
    let baby: Baby?
    
    var onFeedTapped: (() -> Void)?
    var onDiaperTapped: (() -> Void)?
    var onSleepTapped: (() -> Void)?
    var onNapTapped: (() -> Void)?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacingMD) {
                feedCard
                diaperCard
                sleepCard
                nextNapCard
            }
            .padding(.horizontal, .spacingMD)
            .padding(.vertical, .spacingSM)
        }
    }
    
    private var feedCard: some View {
        HomeSummaryCard(
            icon: "baby.bottle.fill",
            iconColor: .eventFeed,
            title: "Last Feed",
            primaryText: lastFeed.map { DateUtils.formatDetailedRelativeTime($0.startTime) } ?? "No feeds yet",
            secondaryText: formatFeedDetail(lastFeed),
            onTap: onFeedTapped
        )
        .accessibilityLabel(lastFeedAccessibilityLabel)
        .accessibilityHint("Double tap to view feed details")
    }
    
    private var lastFeedAccessibilityLabel: String {
        if let event = lastFeed {
            let time = DateUtils.formatDetailedRelativeTime(event.startTime)
            let detail = formatFeedDetail(event)
            return "Last feed, \(time). \(detail)"
        }
        return "No feeds logged yet"
    }
    
    private var diaperCard: some View {
        HomeSummaryCard(
            icon: "drop.circle.fill",
            iconColor: .eventDiaper,
            title: "Last Diaper",
            primaryText: lastDiaper.map { DateUtils.formatDetailedRelativeTime($0.startTime) } ?? "No diapers yet",
            secondaryText: lastDiaper?.subtype?.capitalized ?? "Try logging one",
            onTap: onDiaperTapped
        )
        .accessibilityLabel(lastDiaperAccessibilityLabel)
        .accessibilityHint("Double tap to view diaper history")
    }
    
    private var lastDiaperAccessibilityLabel: String {
        if let event = lastDiaper {
            let time = DateUtils.formatDetailedRelativeTime(event.startTime)
            let detail = event.subtype?.capitalized ?? "Diaper"
            return "Last diaper, \(time). \(detail)"
        }
        return "No diapers logged yet"
    }
    
    private var sleepCard: some View {
        if let active = activeSleep {
            return HomeSummaryCard(
                icon: "moon.zzz.fill",
                iconColor: .eventSleep,
                title: "Sleeping",
                primaryText: formatActiveDuration(active),
                secondaryText: "Started \(DateUtils.formatDetailedRelativeTime(active.startTime))",
                isEmphasized: true,
                onTap: onSleepTapped
            )
        }
        
        return HomeSummaryCard(
            icon: "moon.zzz.fill",
            iconColor: .eventSleep,
            title: "Last Nap",
            primaryText: lastSleep.flatMap { $0.endTime }.map { DateUtils.formatDetailedRelativeTime($0) } ?? "No naps yet",
            secondaryText: formatSleepDetail(lastSleep),
            onTap: onSleepTapped
        )
        .accessibilityLabel(lastSleepAccessibilityLabel)
        .accessibilityHint("Double tap to open sleep details")
    }
    
    private var lastSleepAccessibilityLabel: String {
        if let active = activeSleep {
            return "Sleeping, \(formatActiveDuration(active)) so far"
        }
        if let sleep = lastSleep, let end = sleep.endTime {
            return "Last nap ended \(DateUtils.formatDetailedRelativeTime(end))"
        }
        return "No sleep logged yet"
    }
    
    private var nextNapCard: some View {
        HomeSummaryCard(
            icon: "alarm.fill",
            iconColor: .eventSleep,
            title: "Next Nap",
            primaryText: formatNextNapPrimary(nextNapWindow),
            secondaryText: nextNapWindow?.reason ?? "Learning your baby’s rhythm",
            onTap: onNapTapped
        )
        .accessibilityLabel(nextNapAccessibilityLabel)
        .accessibilityHint("Double tap to view nap prediction details")
    }
    
    private var nextNapAccessibilityLabel: String {
        if let window = nextNapWindow {
            return "Next nap around \(formatWindowRange(window))"
        }
        return "Next nap prediction unavailable yet"
    }
    
    // MARK: - Formatting Helpers
    
    private func formatFeedDetail(_ event: Event?) -> String {
        guard let event else { return "Tap to log a feed" }
        if let amount = event.amount, let unit = event.unit {
            let roundedAmount: String
            if amount >= 100 {
                roundedAmount = "\(Int(amount))"
            } else if amount >= 10 {
                roundedAmount = String(format: "%.1f", amount)
            } else {
                roundedAmount = String(format: "%.2f", amount)
            }
            return "\(roundedAmount) \(unit)"
        }
        if let subtype = event.subtype {
            return subtype.capitalized
        }
        return "Logged"
    }
    
    private func formatSleepDetail(_ event: Event?) -> String {
        guard let event, let duration = event.durationMinutes else { return "Tap to log sleep" }
        return "Nap • \(DateUtils.formatDuration(minutes: duration))"
    }
    
    private func formatActiveDuration(_ event: Event) -> String {
        let minutes = Int(Date().timeIntervalSince(event.startTime) / 60)
        return DateUtils.formatDuration(minutes: max(minutes, 1))
    }
    
    private func formatNextNapPrimary(_ window: NapWindow?) -> String {
        guard let window else { return "Learning schedule" }
        let now = Date()
        if window.start > now {
            let minutes = Int(window.start.timeIntervalSince(now) / 60)
            if minutes <= 0 {
                return "Soon"
            } else if minutes < 90 {
                return "in ~\(minutes)m"
            } else {
                let hours = minutes / 60
                let mins = minutes % 60
                return mins == 0 ? "in ~\(hours)h" : "in ~\(hours)h \(mins)m"
            }
        } else if window.end > now {
            return "Window open"
        } else {
            return "Try winding down"
        }
    }
    
    private func formatWindowRange(_ window: NapWindow) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: window.start)) – \(formatter.string(from: window.end))"
    }
}

private struct HomeSummaryCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let primaryText: String
    let secondaryText: String?
    var isEmphasized: Bool = false
    var onTap: (() -> Void)?
    
    var body: some View {
        Button(action: {
            onTap?()
            Haptics.selection()
        }) {
            VStack(alignment: .leading, spacing: .spacingSM) {
                HStack(spacing: .spacingXS) {
                    Image(systemName: icon)
                        .font(.headline)
                        .foregroundColor(iconColor)
                        .accessibilityHidden(true)
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.mutedForeground)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer(minLength: 0)
                }
                
                Text(primaryText)
                    .font(isEmphasized ? .title3.weight(.bold) : .title3.weight(.semibold))
                    .foregroundColor(.foreground)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                if let secondaryText, !secondaryText.isEmpty {
                    Text(secondaryText)
                        .font(.footnote)
                        .foregroundColor(.mutedForeground)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
            }
            .padding(.spacingMD)
            .frame(width: 220, alignment: .leading)
            .background(Color.surface)
            .cornerRadius(.radiusLG)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusLG)
                    .stroke(Color.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HomeSummaryCarousel(
        lastFeed: Event.mockFeed(babyId: Baby.mock().id),
        lastDiaper: Event.mockDiaper(babyId: Baby.mock().id),
        activeSleep: nil,
        lastSleep: Event.mockSleep(babyId: Baby.mock().id),
        nextNapWindow: NapWindow(
            start: Date().addingTimeInterval(45 * 60),
            end: Date().addingTimeInterval(90 * 60),
            confidence: 0.7,
            reason: "Based on age + last wake"
        ),
        baby: Baby.mock()
    )
    .background(Color.background)
}

