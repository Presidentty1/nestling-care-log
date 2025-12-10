import SwiftUI

/// Card displaying next nap prediction with reasoning
struct NapPredictionCard: View {
    let napWindow: NapWindow?
    let baby: Baby?
    let onTap: () -> Void
    
    @State private var isPulsing = false
    @State private var showInfo = false
    
    var body: some View {
        CardView(variant: .default) {
            if let window = napWindow, let baby = baby {
                napPredictionContent(window: window, baby: baby)
            } else {
                emptyStateContent
            }
        }
        .onAppear {
            // Gentle pulse animation when prediction appears
            if napWindow != nil && !UIAccessibility.isReduceMotionEnabled {
                withAnimation(.gentleSpring.delay(0.3)) {
                    isPulsing = true
                }
            }
        }
    }
    
    @ViewBuilder
    private func napPredictionContent(window: NapWindow, baby: Baby) -> some View {
        VStack(alignment: .leading, spacing: .spacingMD) {
            // Header
            HStack(spacing: .spacingSM) {
                Image(systemName: "moon.zzz.fill")
                    .font(.title2)
                    .foregroundColor(.eventSleep)
                    .symbolPulse(value: isPulsing)
                
                Text("Next Nap")
                    .font(.headline)
                    .foregroundColor(.foreground)
                
                Spacer()
                
                Button {
                    showInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(.mutedForeground)
                }
                .accessibilityLabel("How predictions work")
                .buttonStyle(.plain)
                
                // Suggestion badge
                Text("Suggestion")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.eventSleep)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.eventSleep.opacity(0.1))
                    .cornerRadius(8)
            }
            
            // Time window
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("Around")
                    .font(.body)
                    .foregroundColor(.mutedForeground)
                
                Text(timeWindowText(window))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.foreground)
            }
            
            // Time until nap (if in future)
            if window.start > Date() {
                let minutesUntil = Calendar.current.dateComponents([.minute], from: Date(), to: window.start).minute ?? 0
                if minutesUntil > 0 {
                    Text("In about \(minutesUntil) minutes")
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                }
            } else if window.end > Date() {
                Text("Nap window is open now")
                    .font(.caption)
                    .foregroundColor(.eventSleep)
                    .fontWeight(.medium)
            }
            
            // Reasoning
            Text(window.reason)
                .font(.caption)
                .foregroundColor(.mutedForeground)
                .lineLimit(2)
                .padding(.top, .spacingXS)
            
            // Confidence indicator (subtle)
            HStack(spacing: 4) {
                confidenceBars(confidence: window.confidence)
                    .foregroundColor(.eventSleep.opacity(0.4))
                
                Text(confidenceText(window.confidence))
                    .font(.caption2)
                    .foregroundColor(.mutedForeground)
            }
            .padding(.top, .spacingXS)
        }
        .padding(.spacingMD)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Next nap suggestion: \(timeWindowText(window)). \(window.reason)")
        .accessibilityHint("Tap for more details about nap predictions")
        .sheet(isPresented: $showInfo) {
            VStack(alignment: .leading, spacing: .spacingMD) {
                Text("How nap predictions work")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("We look at age-based wake windows and your recent sleep logs. Short naps can shorten the next wake window. Suggestions are gentle guidance, not medical advice.")
                    .font(.body)
                Text("If the window has passed, we’ll gently note that baby may be overtired and suggest winding down soon.")
                    .font(.body)
                Button("Close") {
                    showInfo = false
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .presentationDetents([.medium])
        }
    }
    
    @ViewBuilder
    private var emptyStateContent: some View {
        VStack(alignment: .leading, spacing: .spacingMD) {
            HStack(spacing: .spacingSM) {
                Image(systemName: "moon.zzz")
                    .font(.title2)
                    .foregroundColor(.mutedForeground)
                
                Text("Next Nap")
                    .font(.headline)
                    .foregroundColor(.foreground)
            }
            
            Text("Log a sleep to see nap predictions")
                .font(.body)
                .foregroundColor(.mutedForeground)
            
            Text("Predictions are based on age and recent sleep patterns")
                .font(.caption)
                .foregroundColor(.mutedForeground)
        }
        .padding(.spacingMD)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Next nap prediction unavailable. Log a sleep to see nap predictions.")
    }
    
    private func timeWindowText(_ window: NapWindow) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        
        let startTime = formatter.string(from: window.start)
        let endTime = formatter.string(from: window.end)
        
        return "\(startTime) – \(endTime)"
    }
    
    private func confidenceText(_ confidence: Double) -> String {
        if confidence >= 0.8 {
            return "High confidence"
        } else if confidence >= 0.6 {
            return "Medium confidence"
        } else {
            return "Low confidence"
        }
    }
    
    @ViewBuilder
    private func confidenceBars(confidence: Double) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < Int(confidence * 3) ? Color.eventSleep : Color.eventSleep.opacity(0.2))
                    .frame(width: 12, height: 4)
            }
        }
    }
}

#Preview {
    VStack(spacing: .spacingLG) {
        // With prediction
        NapPredictionCard(
            napWindow: NapWindow(
                start: Date().addingTimeInterval(45 * 60),
                end: Date().addingTimeInterval(90 * 60),
                confidence: 0.75,
                reason: "Based on age (3 months) and last wake at 9:15 AM"
            ),
            baby: Baby(
                id: UUID(),
                name: "Test Baby",
                dateOfBirth: Calendar.current.date(byAdding: .month, value: -3, to: Date())!,
                sex: "f",
                primaryFeedingStyle: "breast",
                timezone: "America/Los_Angeles",
                createdAt: Date(),
                updatedAt: Date()
            ),
            onTap: {}
        )
        
        // Empty state
        NapPredictionCard(
            napWindow: nil,
            baby: nil,
            onTap: {}
        )
    }
    .padding()
    .background(Color.background)
}


