import SwiftUI

struct NextFeedSuggestionCard: View {
    let nextFeedTime: Date
    let lastFeed: Event
    let isPro: Bool
    
    var body: some View {
        CardView(variant: .default) {
            HStack(spacing: .spacingMD) {
                Image(systemName: "drop.fill")
                    .foregroundColor(.eventFeed)
                    .font(.title3)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Next feed")
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                    
                    if isPro {
                        HStack(spacing: 4) {
                            Text(formatFeedSuggestion())
                                .font(.body)
                                .foregroundColor(.foreground)
                            
                            Text("Pro")
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Color.primary)
                                .cornerRadius(4)
                        }
                    } else {
                        Text("Around \(formatTime(nextFeedTime)) • based on age")
                            .font(.body)
                            .foregroundColor(.foreground)
                    }
                }
                
                Spacer()
            }
        }
    }
    
    private func formatFeedSuggestion() -> String {
        let now = Date()
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        let timeSinceLastFeed = now.timeIntervalSince(lastFeed.startTime) / 3600.0 // hours
        let hoursUntilFeed = max(0, (nextFeedTime.timeIntervalSinceNow) / 3600.0)
        
        if hoursUntilFeed <= 0 {
            return "Feed due now • based on last feeds"
        } else if hoursUntilFeed < 1 {
            let minutes = Int(hoursUntilFeed * 60)
            return "Around \(timeFormatter.string(from: nextFeedTime)) • in ~\(minutes) min"
        } else {
            return "Around \(timeFormatter.string(from: nextFeedTime)) • based on last feeds"
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NextFeedSuggestionCard(
        nextFeedTime: Date().addingTimeInterval(2 * 60 * 60), // 2 hours from now
        lastFeed: Event(
            babyId: UUID(),
            type: .feed,
            subtype: "bottle",
            startTime: Date().addingTimeInterval(-2 * 60 * 60),
            amount: 120,
            unit: "ml"
        ),
        isPro: false
    )
    .padding()
    .background(Color.background)
}

