import SwiftUI

struct TodayPatternsCard: View {
    let events: [Event]
    let isPro: Bool
    let onUpgrade: () -> Void
    
    private var todayStats: (feeds: Int, naps: Int, diapers: Int, avgFeedAmount: Double?, avgNapDuration: TimeInterval?, diaperTypes: (wet: Int, dirty: Int)) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        let todayEvents = events.filter { calendar.isDate($0.startTime, inSameDayAs: today) }
        
        let feeds = todayEvents.filter { $0.type == .feed }
        let naps = todayEvents.filter { $0.type == .sleep && $0.endTime != nil }
        let diapers = todayEvents.filter { $0.type == .diaper }
        
        // Calculate average feed amount
        let feedAmounts = feeds.compactMap { event -> Double? in
            guard let amount = event.amount else { return nil }
            return event.unit == "oz" ? amount * 30.0 : amount // Convert to ml for consistency
        }
        let avgFeedAmount = feedAmounts.isEmpty ? nil : feedAmounts.reduce(0, +) / Double(feedAmounts.count)
        
        // Calculate average nap duration
        let napDurations = naps.compactMap { event -> TimeInterval? in
            guard let endTime = event.endTime else { return nil }
            return endTime.timeIntervalSince(event.startTime)
        }
        let avgNapDuration = napDurations.isEmpty ? nil : napDurations.reduce(0, +) / Double(napDurations.count)
        
        // Count diaper types
        let wetCount = diapers.filter { $0.subtype?.lowercased() == "wet" }.count
        let dirtyCount = diapers.filter { $0.subtype?.lowercased() == "dirty" }.count
        
        return (
            feeds: feeds.count,
            naps: naps.count,
            diapers: diapers.count,
            avgFeedAmount: avgFeedAmount,
            avgNapDuration: avgNapDuration,
            diaperTypes: (wet: wetCount, dirty: dirtyCount)
        )
    }
    
    var body: some View {
        if isPro {
            // Pro users see full stats
            CardView(variant: .default) {
                VStack(alignment: .leading, spacing: .spacingSM) {
                    Text("Today so far")
                        .font(.headline)
                        .foregroundColor(.foreground)
                    
                    let stats = todayStats
                    
                    if stats.feeds > 0 || stats.naps > 0 || stats.diapers > 0 {
                        VStack(alignment: .leading, spacing: .spacingXS) {
                            if stats.feeds > 0 {
                                PatternRow(
                                    icon: "drop.fill",
                                    iconColor: .eventFeed,
                                    label: "Feeds",
                                    value: "\(stats.feeds)",
                                    detail: stats.avgFeedAmount.map { "avg \(Int($0)) ml" }
                                )
                            }
                            
                            if stats.naps > 0 {
                                PatternRow(
                                    icon: "moon.fill",
                                    iconColor: .eventSleep,
                                    label: "Naps",
                                    value: "\(stats.naps)",
                                    detail: stats.avgNapDuration.map { "avg \(Int($0 / 60)) min" }
                                )
                            }
                            
                            if stats.diapers > 0 {
                                PatternRow(
                                    icon: "drop.circle.fill",
                                    iconColor: .eventDiaper,
                                    label: "Diapers",
                                    value: "\(stats.diapers)",
                                    detail: "\(stats.diaperTypes.wet) wet, \(stats.diaperTypes.dirty) dirty"
                                )
                            }
                        }
                    } else {
                        Text("No events logged today yet")
                            .font(.caption)
                            .foregroundColor(.mutedForeground)
                    }
                }
                .padding(.spacingMD)
            }
        } else {
            // Free users see blurred teaser
            ZStack {
                // Blurred background
                CardView(variant: .default) {
                    VStack(alignment: .leading, spacing: .spacingSM) {
                        Text("Today so far")
                            .font(.headline)
                            .foregroundColor(.foreground)
                        
                        let stats = todayStats
                        if stats.feeds > 0 || stats.naps > 0 || stats.diapers > 0 {
                            VStack(alignment: .leading, spacing: .spacingXS) {
                                if stats.feeds > 0 {
                                    PatternRow(
                                        icon: "drop.fill",
                                        iconColor: .eventFeed,
                                        label: "Feeds",
                                        value: "\(stats.feeds)",
                                        detail: stats.avgFeedAmount.map { "avg \(Int($0)) ml" }
                                    )
                                }
                                
                                if stats.naps > 0 {
                                    PatternRow(
                                        icon: "moon.fill",
                                        iconColor: .eventSleep,
                                        label: "Naps",
                                        value: "\(stats.naps)",
                                        detail: stats.avgNapDuration.map { "avg \(Int($0 / 60)) min" }
                                    )
                                }
                                
                                if stats.diapers > 0 {
                                    PatternRow(
                                        icon: "drop.circle.fill",
                                        iconColor: .eventDiaper,
                                        label: "Diapers",
                                        value: "\(stats.diapers)",
                                        detail: "\(stats.diaperTypes.wet) wet, \(stats.diaperTypes.dirty) dirty"
                                    )
                                }
                            }
                        } else {
                            Text("No events logged today yet")
                                .font(.caption)
                                .foregroundColor(.mutedForeground)
                        }
                    }
                    .padding(.spacingMD)
                }
                .blur(radius: 8)
                .opacity(0.5)
                
                // Lock overlay
                CardView(variant: .default) {
                    VStack(spacing: .spacingSM) {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.primary)
                        
                        Text("Unlock Pro to see daily patterns and insights")
                            .font(.subheadline)
                            .foregroundColor(.foreground)
                            .multilineTextAlignment(.center)
                        
                        Button(action: onUpgrade) {
                            Text("Upgrade to Pro")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, .spacingMD)
                                .padding(.vertical, 6)
                                .background(Color.primary)
                                .cornerRadius(6)
                        }
                    }
                    .padding(.spacingMD)
                }
            }
        }
    }
}

private struct PatternRow: View {
    let icon: String
    let iconColor: Color
    let label: String
    let value: String
    let detail: String?
    
    var body: some View {
        HStack(spacing: .spacingSM) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.mutedForeground)
            
            Text(value)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(.foreground)
            
            if let detail = detail {
                Text("(\(detail))")
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
            }
            
            Spacer()
        }
    }
}

#Preview {
    VStack(spacing: .spacingMD) {
        TodayPatternsCard(
            events: [
                Event(babyId: UUID(), type: .feed, startTime: Date(), amount: 120, unit: "ml"),
                Event(babyId: UUID(), type: .feed, startTime: Date(), amount: 150, unit: "ml"),
                Event(babyId: UUID(), type: .sleep, startTime: Date().addingTimeInterval(-3600), endTime: Date().addingTimeInterval(-3300)),
                Event(babyId: UUID(), type: .diaper, subtype: "wet", startTime: Date())
            ],
            isPro: true,
            onUpgrade: {}
        )
        
        TodayPatternsCard(
            events: [
                Event(babyId: UUID(), type: .feed, startTime: Date(), amount: 120, unit: "ml")
            ],
            isPro: false,
            onUpgrade: {}
        )
    }
    .padding()
    .background(Color.background)
}

