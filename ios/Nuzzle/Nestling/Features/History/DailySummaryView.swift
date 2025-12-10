import SwiftUI

/// Summary view showing daily totals
struct DailySummaryView: View {
    let date: Date
    let events: [Event]
    
    var body: some View {
        CardView(variant: .elevated) {
            VStack(spacing: .spacingMD) {
                // Header
                HStack {
                    Text("Daily Summary")
                        .font(.headline)
                        .foregroundColor(.foreground)
                    
                    Spacer()
                    
                    Text(formattedDate)
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                }
                
                // Stats grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: .spacingMD) {
                    summaryItem(
                        icon: "fork.knife",
                        color: .eventFeed,
                        value: "\(feedCount)",
                        label: feedCount == 1 ? "Feed" : "Feeds"
                    )
                    
                    summaryItem(
                        icon: "moon.zzz.fill",
                        color: .eventSleep,
                        value: totalSleepFormatted,
                        label: "Sleep"
                    )
                    
                    summaryItem(
                        icon: "drop.fill",
                        color: .eventDiaper,
                        value: "\(diaperCount)",
                        label: diaperCount == 1 ? "Diaper" : "Diapers"
                    )
                }
                
                // Total feed amount (if applicable)
                if totalFeedAmount > 0 {
                    Divider()
                    
                    HStack {
                        Image(systemName: "drop.fill")
                            .font(.caption)
                            .foregroundColor(.eventFeed)
                        
                        Text("Total intake:")
                            .font(.caption)
                            .foregroundColor(.mutedForeground)
                        
                        Spacer()
                        
                        Text("\(Int(totalFeedAmount)) ml")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.foreground)
                    }
                }
            }
            .padding(.spacingMD)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily summary for \(formattedDate). \(feedCount) feeds, \(totalSleepFormatted) of sleep, \(diaperCount) diapers")
    }
    
    @ViewBuilder
    private func summaryItem(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: .spacingSM) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.foreground)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.mutedForeground)
        }
        .frame(maxWidth: .infinity)
        .padding(.spacingSM)
        .background(color.opacity(0.05))
        .cornerRadius(.radiusSM)
    }
    
    // MARK: - Calculated Properties
    
    private var feedCount: Int {
        events.filter { $0.type == .feed }.count
    }
    
    private var totalFeedAmount: Double {
        events
            .filter { $0.type == .feed }
            .compactMap { $0.amount }
            .reduce(0, +)
    }
    
    private var sleepEvents: [Event] {
        events.filter { $0.type == .sleep && $0.endTime != nil }
    }
    
    private var totalSleepMinutes: Int {
        sleepEvents.reduce(0) { sum, event in
            guard let endTime = event.endTime else { return sum }
            let minutes = Calendar.current.dateComponents([.minute], from: event.startTime, to: endTime).minute ?? 0
            return sum + minutes
        }
    }
    
    private var totalSleepFormatted: String {
        let hours = totalSleepMinutes / 60
        let minutes = totalSleepMinutes % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    private var diaperCount: Int {
        events.filter { $0.type == .diaper }.count
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        
        if Calendar.current.isDateInToday(date) {
            return "Today"
        } else if Calendar.current.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
    }
}

#Preview {
    let sampleEvents = [
        Event(id: UUID(), babyId: UUID(), type: .feed, subtype: "bottle", amount: 120, unit: "ml", side: nil, startTime: Date(), endTime: nil, durationMinutes: nil, note: nil, createdAt: Date(), updatedAt: Date()),
        Event(id: UUID(), babyId: UUID(), type: .feed, subtype: "bottle", amount: 150, unit: "ml", side: nil, startTime: Date().addingTimeInterval(-3600), endTime: nil, durationMinutes: nil, note: nil, createdAt: Date(), updatedAt: Date()),
        Event(id: UUID(), babyId: UUID(), type: .sleep, subtype: nil, amount: nil, unit: nil, side: nil, startTime: Date().addingTimeInterval(-7200), endTime: Date().addingTimeInterval(-5400), durationMinutes: 30, note: nil, createdAt: Date(), updatedAt: Date()),
        Event(id: UUID(), babyId: UUID(), type: .diaper, subtype: "wet", amount: nil, unit: nil, side: nil, startTime: Date().addingTimeInterval(-1800), endTime: nil, durationMinutes: nil, note: nil, createdAt: Date(), updatedAt: Date())
    ]
    
    DailySummaryView(date: Date(), events: sampleEvents)
        .padding()
        .background(Color.background)
}
