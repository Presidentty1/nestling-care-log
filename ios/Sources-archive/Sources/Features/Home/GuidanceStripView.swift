import SwiftUI

/// Three-segment guidance strip showing "Now", "Next Nap", "Next Feed" (Epic 4 AC1)
struct GuidanceStripView: View {
    @StateObject private var viewModel: NowNextViewModel
    @State private var activeSleep: Event?
    
    let dataStore: DataStore
    let baby: Baby
    
    init(dataStore: DataStore, baby: Baby) {
        self.dataStore = dataStore
        self.baby = baby
        _viewModel = StateObject(wrappedValue: NowNextViewModel(dataStore: dataStore, baby: baby))
    }
    
    var body: some View {
        CardView(variant: .elevated) {
            HStack(spacing: 0) {
                // Segment 1: Now (Epic 4 AC2) - Epic 4 AC7: Tappable to navigate to timeline
                Button(action: {
                    // Navigate to today timeline (Epic 4 AC7)
                    Haptics.light()
                }) {
                    NowSegment(
                        activeSleep: activeSleep,
                        wakeDuration: viewModel.wakeDurationText
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 60)
                
                // Segment 2: Next Nap Window (Epic 4 AC3) - Epic 4 AC7: Tappable to nap detail
                Button(action: {
                    // Navigate to nap detail view (Epic 4 AC7)
                    Haptics.light()
                }) {
                    NextNapSegment(
                        napWindowText: viewModel.nextNapWindowText,
                        explanation: viewModel.nextNapWindowExplanation
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity)
                
                Divider()
                    .frame(height: 60)
                
                // Segment 3: Next Feed (Epic 4 AC4) - Epic 4 AC7: Tappable to feed history
                Button(action: {
                    // Navigate to feed history/patterns view (Epic 4 AC7)
                    Haptics.light()
                }) {
                    NextFeedSegment(
                        lastFeedText: viewModel.lastFeedSummary,
                        nextFeedText: viewModel.nextFeedWindowText,
                        typicalRange: viewModel.typicalFeedRange
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity)
            }
            .padding(.spacingMD)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Guidance strip: \(viewModel.nowStateText), \(viewModel.nextNapWindowText), \(viewModel.lastFeedSummary)")
        .task {
            // Check for active sleep to determine current state
            do {
                activeSleep = try await dataStore.getActiveSleep(for: baby)
            } catch {
                Logger.dataError("Failed to check active sleep: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Now Segment (Epic 4 AC2)

struct NowSegment: View {
    let activeSleep: Event?
    let wakeDuration: String
    
    var currentState: String {
        activeSleep != nil ? "Asleep" : "Awake"
    }
    
    var durationText: String {
        if activeSleep != nil {
            // Calculate sleep duration
            let duration = Date().timeIntervalSince(activeSleep!.startTime)
            let hours = Int(duration / 3600)
            let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        } else {
            // Extract duration from wakeDuration text
            return wakeDuration.replacingOccurrences(of: "Awake for: ", with: "").replacingOccurrences(of: "Awake time: we'll estimate after a sleep log.", with: "—")
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingXS) {
            Text("Now")
                .font(.caption)
                .foregroundColor(NuzzleTheme.textSecondary)
            
            Text(currentState)
                .font(.headline)
                .foregroundColor(NuzzleTheme.textPrimary)
            
            Text(durationText)
                .font(.caption)
                .foregroundColor(NuzzleTheme.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Now: \(currentState) for \(durationText)")
    }
}

// MARK: - Next Nap Segment (Epic 4 AC3)

struct NextNapSegment: View {
    let napWindowText: String
    let explanation: String?
    
    var windowRange: String {
        // Extract time range from napWindowText
        // Format: "Next nap window: 9:10–9:40" or "Next nap window: More sleep logs needed."
        if napWindowText.contains("More sleep logs") {
            return "—"
        }
        // Try to extract time range
        let components = napWindowText.components(separatedBy: ": ")
        if components.count > 1 {
            return String(components[1].split(separator: " ").first ?? "")
        }
        return "—"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingXS) {
            Text("Next nap")
                .font(.caption)
                .foregroundColor(NuzzleTheme.textSecondary)
            
            Text(windowRange)
                .font(.headline)
                .foregroundColor(NuzzleTheme.textPrimary)
            
            if let explanation = explanation {
                Text(explanation)
                    .font(.caption)
                    .foregroundColor(NuzzleTheme.textSecondary)
                    .lineLimit(2)
            } else {
                Text("Based on age + last wake")
                    .font(.caption)
                    .foregroundColor(NuzzleTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Next nap window: \(windowRange). \(explanation ?? "Based on age and last wake time")")
    }
}

// MARK: - Next Feed Segment (Epic 4 AC4)

struct NextFeedSegment: View {
    let lastFeedText: String
    let nextFeedText: String?
    let typicalRange: String?
    
    var timeSinceLastFeed: String {
        // Extract time from lastFeedText
        // Format: "Last feed: 120 ml at 2:30 PM" or "Last feed: none logged yet"
        if lastFeedText.contains("none logged") {
            return "—"
        }
        // Try to extract "at 2:30 PM" part
        if let atIndex = lastFeedText.range(of: " at ") {
            return String(lastFeedText[atIndex.upperBound...])
        }
        return "—"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingXS) {
            Text("Next feed")
                .font(.caption)
                .foregroundColor(NuzzleTheme.textSecondary)
            
            Text(timeSinceLastFeed)
                .font(.headline)
                .foregroundColor(NuzzleTheme.textPrimary)
            
            if let typicalRange = typicalRange {
                Text(typicalRange)
                    .font(.caption)
                    .foregroundColor(NuzzleTheme.textSecondary)
            } else {
                Text("Common range 2–3h")
                    .font(.caption)
                    .foregroundColor(NuzzleTheme.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Next feed: \(timeSinceLastFeed). \(typicalRange ?? "Common range 2-3 hours")")
    }
}

#Preview {
    GuidanceStripView(dataStore: InMemoryDataStore(), baby: Baby.mock())
        .padding()
}
