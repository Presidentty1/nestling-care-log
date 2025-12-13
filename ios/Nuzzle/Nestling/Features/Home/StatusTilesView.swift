import SwiftUI

/// Status tiles view showing Last Feed, Last Diaper, Sleep Status, and Next Nap
/// Matches North Star dashboard layout requirements
struct StatusTilesView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    let lastFeed: Event?
    let lastDiaper: Event?
    let activeSleep: Event?
    let nextNapWindow: NapWindow?
    let baby: Baby
    
    var body: some View {
        VStack(spacing: .spacingMD) {
            CurrentStateBadge(activeSleep: activeSleep)
            
            if isWideLayout {
                HStack(spacing: .spacingMD) {
                    heroCard
                    satelliteCards
                }
            } else {
                heroCard
                satelliteCards
            }
        }
        .padding(.horizontal, .spacingMD)
    }
    
    private var isWideLayout: Bool {
        horizontalSizeClass == .regular
    }
    
    @ViewBuilder
    private var heroCard: some View {
        if let napWindow = nextNapWindow {
            HeroNapCard(napWindow: napWindow, baby: baby)
                .onTapGesture {
                    logCardTap("nap")
                }
                .accessibilityHint("Shows the next suggested nap window.")
        } else if let sleep = activeSleep {
            ActiveSleepHeroCard(activeSleep: sleep)
                .onTapGesture {
                    logCardTap("sleep_active")
                }
                .accessibilityHint("Shows how long the current sleep has been running.")
        } else {
            EmptyView()
        }
    }
    
    private var satelliteCards: some View {
        HStack(spacing: .spacingMD) {
            SatelliteCard(
                icon: "drop.fill",
                iconColor: .eventFeed,
                title: "Last Feed",
                value: formatFeedValue(lastFeed),
                timeAgo: lastFeed.map { DateUtils.formatRelativeTime($0.startTime) }
            )
            .onTapGesture {
                logCardTap("feed")
            }
            .accessibilityHint("Shows when the last feed was logged.")
            
            SatelliteCard(
                icon: "drop.circle.fill",
                iconColor: .eventDiaper,
                title: "Last Diaper",
                value: formatDiaperValue(lastDiaper),
                timeAgo: lastDiaper.map { DateUtils.formatRelativeTime($0.startTime) }
            )
            .onTapGesture {
                logCardTap("diaper")
            }
            .accessibilityHint("Shows when the last diaper was logged.")
        }
    }

    private func logCardTap(_ type: String) {
        Task {
            await Analytics.shared.log("home_card_tap", parameters: ["card_type": type])
        }
    }
    
    private func formatFeedValue(_ event: Event?) -> String {
        guard let event = event else { return feedPrompt() }
        if let amount = event.amount, let unit = event.unit {
            // Amounts are stored in ml internally (from FeedFormViewModel.save())
            // The unit field indicates what the user entered, but amount is always in ml
            let displayAmount: Double
            let displayUnit: String
            
            // Validate amount is reasonable (prevent display of corrupted data)
            let maxML = AppConstants.maximumFeedAmountML
            if amount > maxML * 10 {
                // Likely corrupted data - show generic message
                return "See details"
            }
            
            if unit == "oz" {
                // User entered oz, but amount is stored in ml - convert back to oz for display
                displayAmount = amount / AppConstants.mlPerOz
                displayUnit = "oz"
                
                // Clamp to reasonable oz values
                let clampedAmount = min(displayAmount, AppConstants.maximumFeedAmountOZ)
                
                // Format appropriately
                if clampedAmount >= 10 {
                    return "\(Int(clampedAmount)) \(displayUnit)"
                } else if clampedAmount >= 1 {
                    return String(format: "%.1f \(displayUnit)", clampedAmount)
                } else {
                    return String(format: "%.2f \(displayUnit)", clampedAmount)
                }
            } else {
                // User entered ml, amount is already in ml
                displayAmount = amount
                displayUnit = "ml"
                
                // Clamp to reasonable ml values
                let clampedAmount = min(displayAmount, maxML)
                
                // Format appropriately
                if clampedAmount >= 100 {
                    return "\(Int(clampedAmount)) \(displayUnit)"
                } else if clampedAmount >= 10 {
                    return String(format: "%.1f \(displayUnit)", clampedAmount)
                } else {
                    return String(format: "%.2f \(displayUnit)", clampedAmount)
                }
            }
        } else if let subtype = event.subtype {
            return subtype.capitalized
        }
        return "Logged"
    }
    
    private func formatDiaperValue(_ event: Event?) -> String {
        guard let event = event else { return diaperPrompt() }
        return event.subtype?.capitalized ?? "Logged"
    }
    
    private func feedPrompt() -> String {
        return "Log feed"
    }
    
    private func diaperPrompt() -> String {
        return "Log diaper"
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
    @State private var feedbackSubmitted: Bool = false
    @State private var feedbackValue: Bool? = nil // true = helpful, false = not helpful
    
    private var shouldShowAILearningMessage: Bool {
        // Show learning message if baby is less than 7 days old or app was installed less than 7 days ago
        let daysSinceBirth = Calendar.current.dateComponents([.day], from: baby.dateOfBirth, to: Date()).day ?? 0
        let appInstallDate = UserDefaults.standard.object(forKey: "app_install_date") as? Date ?? Date()
        let daysSinceInstall = Calendar.current.dateComponents([.day], from: appInstallDate, to: Date()).day ?? 0
        return daysSinceBirth < 7 || daysSinceInstall < 7
    }
    
    private var isPro: Bool {
        ProSubscriptionService.shared.isProUser
    }
    
    private var predictionSource: String {
        if isPro {
            return "Based on \(baby.name)'s patterns"
        } else {
            return "Typical for \(ageDescription)"
        }
    }
    
    private var ageDescription: String {
        let months = Calendar.current.dateComponents([.month], from: baby.dateOfBirth, to: Date()).month ?? 0
        if months == 0 {
            return "newborns"
        } else if months == 1 {
            return "1-month-olds"
        } else {
            return "\(months)-month-olds"
        }
    }
    
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
                
                // Pro badge for personalized predictions (free users see age-based, Pro see personalized)
                if isPro {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                        Text("Pro")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.success)
                    .cornerRadius(8)
                }
            }
            
            Text(formatNapWindow(napWindow))
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.foreground)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(formatTimeUntil(napWindow))
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.foreground)
            
            // Source subtitle
            Text(predictionSource)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.mutedForeground)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
            
            // AI Learning Phase Message (show for first week)
            if shouldShowAILearningMessage {
                HStack(spacing: .spacingXS) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 12))
                        .foregroundColor(.mutedForeground)
                    Text("Nestling's AI will learn \(baby.name)'s unique patterns over the first week")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.mutedForeground)
                }
                .padding(.top, .spacingXS)
            }
            
            // UX-08: Add Thumb Up/Down feedback buttons for predictions
            if !feedbackSubmitted {
                HStack(spacing: .spacingMD) {
                    Text("Was this helpful?")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.mutedForeground)
                    
                    Button(action: {
                        Haptics.light()
                        feedbackValue = true
                        submitFeedback(helpful: true)
                    }) {
                        Image(systemName: "hand.thumbsup.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.mutedForeground)
                            .padding(.spacingXS)
                            .background(Color.surface)
                            .cornerRadius(.radiusSM)
                    }
                    
                    Button(action: {
                        Haptics.light()
                        feedbackValue = false
                        submitFeedback(helpful: false)
                    }) {
                        Image(systemName: "hand.thumbsdown.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.mutedForeground)
                            .padding(.spacingXS)
                            .background(Color.surface)
                            .cornerRadius(.radiusSM)
                    }
                }
                .padding(.top, .spacingXS)
            } else {
                HStack(spacing: .spacingXS) {
                    Image(systemName: feedbackValue == true ? "hand.thumbsup.fill" : "hand.thumbsdown.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.mutedForeground)
                    Text("Thanks for your feedback!")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.mutedForeground)
                }
                .padding(.top, .spacingXS)
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
    
    // UX-08: Submit feedback (stores locally for now, can be connected to backend later)
    private func submitFeedback(helpful: Bool) {
        feedbackSubmitted = true
        // Store feedback locally (can be synced to backend later)
        let key = "nap_prediction_feedback_\(napWindow.start.timeIntervalSince1970)"
        UserDefaults.standard.set(helpful, forKey: key)
        // TODO: Sync to analytics/backend
        logger.debug("📊 Nap prediction feedback: \(helpful ? "Helpful" : "Not helpful")")
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
        .shadow(color: Color.eventSleep.opacity(0.18), radius: 10, x: 0, y: 6)
        .overlay(
            RoundedRectangle(cornerRadius: .radiusLG)
                .fill(Color.eventSleep.opacity(0.05))
        )
    }
    
    private func formatSleepDuration(_ sleep: Event) -> String {
        // Use DateUtils for consistent formatting
        let durationMinutes = Int(Date().timeIntervalSince(sleep.startTime) / 60)
        return DateUtils.formatDuration(minutes: durationMinutes)
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
            
            // UX-02: Make relative time the PRIMARY display (bold, large)
            if let timeAgo = timeAgo {
                Text(timeAgo)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.foreground)
                    .lineLimit(1)
            } else {
                Text(value)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.foreground)
                    .lineLimit(1)
            }
            
            // UX-02: Show value (amount/type) as secondary info
            if timeAgo != nil {
                Text(value)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.mutedForeground.opacity(0.8))
                    .lineLimit(1)
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

/// UX-04: Current State Badge - Shows explicit "Awake / Asleep" status
struct CurrentStateBadge: View {
    let activeSleep: Event?
    
    var body: some View {
        HStack(spacing: .spacingSM) {
            Image(systemName: activeSleep != nil ? "moon.zzz.fill" : "sun.max.fill")
                .font(.system(size: 16))
                .foregroundColor(activeSleep != nil ? .eventSleep : .eventDiaper)
            
            Text(activeSleep != nil ? "Asleep" : "Awake")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.foreground)
            
            if let sleep = activeSleep {
                Text("• \(formatSleepDuration(sleep))")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.mutedForeground)
            }
        }
        .padding(.horizontal, .spacingMD)
        .padding(.vertical, .spacingSM)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface)
        .cornerRadius(.radiusSM)
        .overlay(
            RoundedRectangle(cornerRadius: .radiusSM)
                .stroke(activeSleep != nil ? Color.eventSleep.opacity(0.3) : Color.cardBorder, lineWidth: 1)
        )
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

