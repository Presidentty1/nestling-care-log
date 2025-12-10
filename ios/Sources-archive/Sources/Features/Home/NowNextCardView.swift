import SwiftUI

struct NowNextCardView: View {
    @StateObject private var viewModel: NowNextViewModel
    @State private var hasBeenViewed = false
    @State private var showFeedbackPrompt = false

    init(dataStore: DataStore, baby: Baby) {
        _viewModel = StateObject(wrappedValue: NowNextViewModel(dataStore: dataStore, baby: baby))
    }

    var body: some View {
        VStack(spacing: .spacingMD) {
            CardView(variant: .elevated) {
                VStack(alignment: .leading, spacing: .spacingMD) {
                // Header
                Text("Now & next")
                    .font(.title)
                    .foregroundColor(.foreground)

                // Content rows
                VStack(alignment: .leading, spacing: .spacingSM) {
                    // Last feed
                    Text(viewModel.lastFeedSummary)
                        .font(.body)
                        .foregroundColor(.foreground)

                    // Wake duration
                    Text(viewModel.wakeDurationText)
                        .font(.body)
                        .foregroundColor(.foreground)

                    // Next nap window
                    Text(viewModel.nextNapWindowText)
                        .font(.body)
                        .foregroundColor(.foreground)

                    // Next feed window (optional)
                    if let nextFeedText = viewModel.nextFeedWindowText {
                        Text(nextFeedText)
                            .font(.body)
                            .foregroundColor(.foreground)
                    }
                }

                // Disclaimer
                Text(viewModel.disclaimerText)
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
                    .padding(.top, .spacingSM)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityLabel("Now and next information")
        .accessibilityHint("Shows last feed, current wake time, and next nap window suggestions")
        .onAppear {
            // Track when card is viewed (first time per session)
            if !hasBeenViewed {
                hasBeenViewed = true
                Task {
                    await Analytics.shared.log("now_next_card_viewed", parameters: [:])

                    // Show feedback prompt after 3 seconds if user is still viewing
                    try? await Task.sleep(nanoseconds: 3_000_000_000)
                    await MainActor.run {
                        // Only show if we haven't shown feedback recently
                        let lastFeedbackKey = "last_prediction_feedback"
                        let lastFeedback = UserDefaults.standard.object(forKey: lastFeedbackKey) as? Date
                        let shouldShow = lastFeedback == nil ||
                            Date().timeIntervalSince(lastFeedback!) > (24 * 60 * 60) // 24 hours

                        if shouldShow {
                            showFeedbackPrompt = true
                        }
                    }
                }
            }
        }

        // Feedback prompt
        if showFeedbackPrompt {
            FeedbackPrompt(
                feature: "nap predictions",
                onRating: { rating in
                    Task {
                        await Analytics.shared.log("prediction_feedback", parameters: [
                            "rating": rating.displayName,
                            "feature": "nap_predictions"
                        ])

                        // Mark feedback as given today
                        UserDefaults.standard.set(Date(), forKey: "last_prediction_feedback")
                    }
                    showFeedbackPrompt = false
                },
                onDismiss: {
                    showFeedbackPrompt = false
                }
            )
            .padding(.top, .spacingMD)
        }
    }
}

#Preview {
    NowNextCardView(dataStore: InMemoryDataStore(), baby: Baby.mock())
        .padding()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}
