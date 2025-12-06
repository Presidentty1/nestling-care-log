import SwiftUI

// NapWindow is defined in Domain/Models/NapWindow.swift

struct TodayStatusHeroCard: View {
    let lastFeed: Event?
    let lastDiaper: Event?
    let nextNapWindow: NapWindow?
    let baby: Baby?
    let isPro: Bool
    let onCTAAction: () -> Void
    let ctaTitle: String

    @State private var showNapGuideExplanation = false
    
    init(
        lastFeed: Event? = nil,
        lastDiaper: Event? = nil,
        nextNapWindow: NapWindow? = nil,
        baby: Baby? = nil,
        isPro: Bool = false,
        ctaTitle: String = "Log feed",
        onCTAAction: @escaping () -> Void
    ) {
        self.lastFeed = lastFeed
        self.lastDiaper = lastDiaper
        self.nextNapWindow = nextNapWindow
        self.baby = baby
        self.isPro = isPro
        self.ctaTitle = ctaTitle
        self.onCTAAction = onCTAAction
    }

    var body: some View {
        CardView(variant: .emphasis) {
            VStack(alignment: .leading, spacing: .spacingMD) {
                // Header
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Today Status")
                            .font(.headline)
                            .foregroundColor(.foreground)
                        
                        Spacer()
                    
                    // Settings menu
                    Menu {
                        if nextNapWindow != nil {
                            Button(action: onCTAAction) {
                                Label("Set nap reminder", systemImage: "bell.fill")
                            }
                            
                            Button(action: {
                                // TODO: Open nap settings or adjust nap settings
                            }) {
                                Label("Adjust nap settings", systemImage: "gearshape")
                            }
                            
                            Button(action: {
                                // TODO: Turn off nap suggestions
                            }) {
                                Label("Turn off nap suggestions", systemImage: "eye.slash")
                            }
                            
                            Button(action: {
                                // TODO: Show explanatory sheet
                            }) {
                                Label("Learn how this works", systemImage: "info.circle")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.mutedForeground)
                            .font(.title3)
                    }
                    }
                    
                    // Subtitle: Based on T's logs and age
                    if let baby = baby {
                        Text("Based on \(baby.name)'s logs and age")
                            .font(.caption)
                            .foregroundColor(.mutedForeground)
                        Text("We'll adjust suggestions as you log more days")
                            .font(.caption2)
                            .foregroundColor(.mutedForeground.opacity(0.8))
                            .padding(.top, 2)
                    } else {
                        Text("Based on your baby's logs and age")
                            .font(.caption)
                            .foregroundColor(.mutedForeground)
                        Text("We'll adjust suggestions as you log more days")
                            .font(.caption2)
                            .foregroundColor(.mutedForeground.opacity(0.8))
                            .padding(.top, 2)
                    }
                }
                
                // Status items
                VStack(alignment: .leading, spacing: .spacingSM) {
                    // Last Feed
                    if let feed = lastFeed {
                        StatusRow(
                            icon: "drop.fill",
                            iconColor: .eventFeed,
                            title: "Last feed",
                            detail: formatFeedDetail(feed),
                            timeAgo: DateUtils.formatRelativeTime(feed.startTime)
                        )
                    } else {
                        StatusRow(
                            icon: "drop.fill",
                            iconColor: .eventFeed.opacity(0.5),
                            title: "Last feed",
                            detail: "Not logged yet",
                            timeAgo: nil,
                            hint: "Log a feed to see patterns here"
                        )
                    }
                    
                    // Last Diaper
                    if let diaper = lastDiaper {
                        StatusRow(
                            icon: "drop.circle.fill",
                            iconColor: .eventDiaper,
                            title: "Last diaper",
                            detail: formatDiaperDetail(diaper),
                            timeAgo: DateUtils.formatRelativeTime(diaper.startTime)
                        )
                    } else {
                        StatusRow(
                            icon: "drop.circle.fill",
                            iconColor: .eventDiaper.opacity(0.5),
                            title: "Last diaper",
                            detail: "Not logged yet",
                            timeAgo: nil,
                            hint: "Log a diaper to see patterns here"
                        )
                    }
                    
                    // Next Nap Window
                    if let napWindow = nextNapWindow {
                        HStack(alignment: .top, spacing: .spacingXS) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Text("Next nap (Nap Guide)")
                                        .font(.caption)
                                        .foregroundColor(.mutedForeground)
                                    
                                    if isPro {
                                        Text("Pro")
                                            .font(.caption2)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                            .background(Color.primary)
                                            .cornerRadius(4)
                                    }
                                }
                                
                                Text(formatNapWindow(napWindow))
                                    .font(.body)
                                    .foregroundColor(.foreground)

                                // Personalized subtitle showing data sources
                                if let baby = baby {
                                    Text("Based on \(baby.name)'s recent naps and age")
                                        .font(.caption2)
                                        .foregroundColor(.mutedForeground.opacity(0.8))
                                        .padding(.top, 2)
                                } else {
                                    Text("Based on your baby's recent naps and age")
                                        .font(.caption2)
                                        .foregroundColor(.mutedForeground.opacity(0.8))
                                        .padding(.top, 2)
                                }
                            }
                            
                            Spacer()
                            
                            // Info icon to explain Nap Guide prediction
                            Button(action: {
                                showNapGuideExplanation = true
                            }) {
                                Image(systemName: "info.circle")
                                    .font(.caption2)
                                    .foregroundColor(.mutedForeground)
                            }
                            .padding(.top, 4) // Align with title text
                        }
                    } else {
                        StatusRow(
                            icon: "moon.fill",
                            iconColor: .eventSleep.opacity(0.5),
                            title: "Next nap",
                            detail: "Need more naps logged to suggest a window",
                            timeAgo: nil,
                            hint: "Log a nap to get a suggested window"
                        )
                    }
                }
                
                // CTA Button
                PrimaryButton(ctaTitle, icon: "plus") {
                    onCTAAction()
                }
            }
        }
            .onAppear {
                // Track prediction shown analytics
                if nextNapWindow != nil, let baby = baby {
                    Task {
                        await Analytics.shared.logPredictionShown(type: "nap", isPro: isPro, babyId: baby.id.uuidString)
                    }
                }
                // TODO: Also track feed predictions when implemented
            }
            .accessibilityElement(children: .contain)
            .accessibilityLabel("Today Status: \(formatAccessibilityLabel())")
            .accessibilityHint("Tap to view more details about your baby's status today")
            .sheet(isPresented: $showNapGuideExplanation) {
                NapGuideExplanationView(babyName: baby?.name)
            }
    }
    
    private func formatAccessibilityLabel() -> String {
        var parts: [String] = []
        
        if let feed = lastFeed {
            let detail = formatFeedDetail(feed)
            let timeAgo = DateUtils.formatRelativeTime(feed.startTime)
            parts.append("Last feed, \(detail), \(timeAgo)")
        } else {
            parts.append("Last feed, not logged yet")
        }
        
        if let diaper = lastDiaper {
            let detail = formatDiaperDetail(diaper)
            let timeAgo = DateUtils.formatRelativeTime(diaper.startTime)
            parts.append("Last diaper, \(detail), \(timeAgo)")
        } else {
            parts.append("Last diaper, not logged yet")
        }
        
        if let napWindow = nextNapWindow {
            parts.append("Next nap, \(formatNapWindow(napWindow))")
        } else {
            parts.append("Next nap, log a sleep to predict")
        }
        
        return parts.joined(separator: ". ")
    }
    
    private func formatFeedDetail(_ event: Event) -> String {
        var parts: [String] = []
        
        if let amount = event.amount, let unit = event.unit {
            let displayAmount: Double
            if unit == "oz" {
                displayAmount = amount / 30.0 // Convert ml to oz
                parts.append("\(Int(displayAmount)) oz")
            } else {
                displayAmount = amount
                parts.append("\(Int(displayAmount)) ml")
            }
        } else if let subtype = event.subtype {
            parts.append(subtype.capitalized)
        }
        
        return parts.joined(separator: " • ")
    }
    
    private func formatDiaperDetail(_ event: Event) -> String {
        return event.subtype?.capitalized ?? "Diaper"
    }
    
    private func formatNapWindow(_ window: NapWindow) -> String {
        let now = Date()
        let minutesUntilStart = Int(window.start.timeIntervalSince(now) / 60)
        let minutesUntilEnd = Int(window.end.timeIntervalSince(now) / 60)
        
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        let startTimeStr = timeFormatter.string(from: window.start)
        let endTimeStr = timeFormatter.string(from: window.end)
        
        if minutesUntilStart < 0 {
            // Window has started
            if minutesUntilEnd > 0 {
                return "\(startTimeStr)–\(endTimeStr) • Window ends in ~\(minutesUntilEnd) min"
            } else {
                return "Window has passed"
            }
        } else {
            // Window is in the future - show clock time + minutes
            return "\(startTimeStr)–\(endTimeStr) • in \(minutesUntilStart)–\(minutesUntilEnd) min"
        }
    }
}

private struct StatusRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let detail: String
    let timeAgo: String?
    var hint: String? = nil
    
    var body: some View {
        HStack(spacing: .spacingSM) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                    
                    if let timeAgo = timeAgo {
                        Text("•")
                            .font(.caption)
                            .foregroundColor(.mutedForeground)
                        Text(timeAgo)
                            .font(.caption)
                            .foregroundColor(.mutedForeground)
                    }
                }
                
                Text(detail)
                    .font(.body)
                    .foregroundColor(.foreground)
                
                if let hint = hint {
                    Text(hint)
                        .font(.caption2)
                        .foregroundColor(.mutedForeground.opacity(0.7))
                        .padding(.top, 2)
                }
            }
            
            Spacer()
        }
    }
}


#Preview {
    TodayStatusHeroCard(
        lastFeed: Event(
            babyId: UUID(),
            type: .feed,
            subtype: "bottle",
            startTime: Date().addingTimeInterval(-2700), // 45 min ago
            amount: 120,
            unit: "ml"
        ),
        lastDiaper: Event(
            babyId: UUID(),
            type: .diaper,
            subtype: "wet",
            startTime: Date().addingTimeInterval(-1200), // 20 min ago
            note: nil
        ),
        nextNapWindow: NapWindow(
            start: Date().addingTimeInterval(1500), // 25 min from now
            end: Date().addingTimeInterval(3300), // 55 min from now
            confidence: 0.7,
            reason: "Based on age and last wake"
        ),
        baby: Baby(
            id: UUID(),
            name: "T",
            dateOfBirth: Date().addingTimeInterval(-14 * 24 * 60 * 60), // 2 weeks ago
            sex: .male
        ),
        isPro: false,
        ctaTitle: "Set nap reminder",
        onCTAAction: {}
    )
    .padding()
    .background(Color.background)
}

