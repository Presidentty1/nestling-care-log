import SwiftUI

/// Progress indicator banner for early users (replaces "Example day" banner)
struct ExampleDataBanner: View {
    let eventCount: Int
    
    init(eventCount: Int = 0) {
        self.eventCount = eventCount
    }
    
    var body: some View {
        if eventCount < 6 {
            HStack(spacing: .spacingSM) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .foregroundColor(Color.primary)
                    .font(.caption)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(progressText)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.foreground)
                    
                    ProgressView(value: Double(eventCount), total: 6.0)
                        .tint(Color.primary)
                        .frame(height: 4)
                }
                
                Spacer()
            }
            .padding(.spacingMD)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.primary.opacity(0.08),
                        Color.primary.opacity(0.03)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusMD)
                    .stroke(Color.primary.opacity(0.15), lineWidth: 1)
            )
            .accessibilityLabel("Progress indicator")
            .accessibilityValue("\(eventCount) of 6 events logged")
        }
    }
    
    private var progressText: String {
        let remaining = max(0, 6 - eventCount)
        if remaining == 0 {
            return "Great! Now we can show you patterns 📊"
        } else if remaining == 1 {
            return "Track 1 more event to unlock patterns"
        } else {
            return "Track \(remaining) more events to unlock patterns"
        }
    }
}

#Preview {
    ExampleDataBanner()
        .padding()
}
