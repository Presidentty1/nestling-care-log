import SwiftUI

/// Hero card for displaying upcoming nap prediction
/// Large, colorful, attention-grabbing - the first thing users see on Home
///
/// Design: Per UX Polish plan Phase 1.2
/// - Prominent placement at top of Home
/// - Shows urgency/timing
/// - Clear call-to-action
struct NapWindowHeroCard: View {
    let prediction: NapPrediction
    let babyName: String
    let onTap: () -> Void
    
    @State private var pulseAnimation = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 16) {
                // Header with icon and urgency indicator
                HStack {
                    Image(systemName: "moon.zzz.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                        .scaleEffect(pulseAnimation ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: pulseAnimation)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(urgencyText)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                        
                        Text(windowTimeText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Confidence badge
                    if let confidence = prediction.confidence, PolishFeatureFlags.aiTransparency {
                        ConfidenceBadge(confidence: confidence)
                    }
                }
                
                // Main prediction text
                VStack(alignment: .leading, spacing: 8) {
                    Text(mainText)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(explanationText)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Call to action
                HStack {
                    Text(ctaText)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.blue)
                    
                    Spacer()
                }
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundGradient)
                    .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
        .onAppear {
            if isImminent {
                pulseAnimation = true
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var urgencyText: String {
        if isNow {
            return "NAP WINDOW OPEN NOW"
        } else if isImminent {
            return "NAP WINDOW SOON"
        } else {
            return "NEXT NAP PREDICTION"
        }
    }
    
    private var windowTimeText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        if let startTime = prediction.windowStart, let endTime = prediction.windowEnd {
            return "\(formatter.string(from: startTime)) - \(formatter.string(from: endTime))"
        }
        
        return ""
    }
    
    private var mainText: String {
        if isNow {
            return "\(babyName) is ready for sleep"
        } else if isImminent {
            return "Get ready for \(babyName)'s nap"
        } else {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            if let startTime = prediction.windowStart {
                return "Next nap around \(formatter.string(from: startTime))"
            }
            return "Nap coming up"
        }
    }
    
    private var explanationText: String {
        if isNow {
            return "Based on wake time and patterns, now's a great time to put \(babyName) down."
        } else if isImminent {
            let minutesUntil = Int((prediction.windowStart?.timeIntervalSinceNow ?? 0) / 60)
            return "\(babyName)'s nap window opens in about \(minutesUntil) minutes."
        } else {
            return prediction.reason ?? "Based on \(babyName)'s recent patterns"
        }
    }
    
    private var ctaText: String {
        if isNow {
            return "Log nap start"
        } else {
            return "View prediction details"
        }
    }
    
    private var isNow: Bool {
        guard let startTime = prediction.windowStart,
              let endTime = prediction.windowEnd else {
            return false
        }
        
        let now = Date()
        return now >= startTime && now <= endTime
    }
    
    private var isImminent: Bool {
        guard let startTime = prediction.windowStart else { return false }
        let minutesUntil = (startTime.timeIntervalSinceNow) / 60
        return minutesUntil > 0 && minutesUntil <= 15  // Within 15 minutes
    }
    
    private var backgroundGradient: LinearGradient {
        if isNow {
            // Active - use more vibrant colors
            return LinearGradient(
                colors: [
                    Color.blue.opacity(0.15),
                    Color.blue.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // Upcoming - subtle
            return LinearGradient(
                colors: [
                    Color(uiColor: .secondarySystemGroupedBackground),
                    Color(uiColor: .secondarySystemGroupedBackground)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
}

/// Confidence badge showing AI prediction confidence
struct ConfidenceBadge: View {
    let confidence: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: confidenceIcon)
                .font(.caption2)
            Text(confidenceText)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(confidenceColor.opacity(0.2))
        )
        .foregroundColor(confidenceColor)
    }
    
    private var confidenceIcon: String {
        if confidence >= 0.8 {
            return "checkmark.circle.fill"
        } else if confidence >= 0.6 {
            return "checkmark.circle"
        } else {
            return "questionmark.circle"
        }
    }
    
    private var confidenceText: String {
        let percentage = Int(confidence * 100)
        return "\(percentage)%"
    }
    
    private var confidenceColor: Color {
        if confidence >= 0.8 {
            return .green
        } else if confidence >= 0.6 {
            return .orange
        } else {
            return .gray
        }
    }
}

/// Nap prediction model for hero card
struct NapPrediction {
    let windowStart: Date?
    let windowEnd: Date?
    let confidence: Double?
    let reason: String?
}

// MARK: - Preview

#Preview("Active Now") {
    VStack {
        NapWindowHeroCard(
            prediction: NapPrediction(
                windowStart: Date(),
                windowEnd: Date().addingTimeInterval(30 * 60),
                confidence: 0.85,
                reason: "Based on Emma's wake time and age-appropriate wake windows"
            ),
            babyName: "Emma",
            onTap: { print("Hero card tapped") }
        )
        
        Spacer()
    }
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}

#Preview("Upcoming") {
    VStack {
        NapWindowHeroCard(
            prediction: NapPrediction(
                windowStart: Date().addingTimeInterval(90 * 60),
                windowEnd: Date().addingTimeInterval(120 * 60),
                confidence: 0.72,
                reason: "Based on Emma's recent sleep patterns"
            ),
            babyName: "Emma",
            onTap: { print("Hero card tapped") }
        )
        
        Spacer()
    }
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}

#Preview("Low Confidence") {
    VStack {
        NapWindowHeroCard(
            prediction: NapPrediction(
                windowStart: Date().addingTimeInterval(120 * 60),
                windowEnd: Date().addingTimeInterval(150 * 60),
                confidence: 0.45,
                reason: "Pattern still emerging - needs more data"
            ),
            babyName: "Emma",
            onTap: { print("Hero card tapped") }
        )
        
        Spacer()
    }
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}
