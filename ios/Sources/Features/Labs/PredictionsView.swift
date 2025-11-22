import SwiftUI

struct PredictionsView: View {
    @EnvironmentObject var environment: AppEnvironment
    @State private var viewModel: PredictionsViewModel?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Group {
                if let viewModel = viewModel {
                    ScrollView {
                        VStack(spacing: .spacingLG) {
                            // Medical Disclaimer
                            MedicalDisclaimer(variant: .predictions)
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel("Medical disclaimer: This information is not medical advice. Consult your healthcare provider for medical decisions.")
                            
                            if !viewModel.aiEnabled {
                                InfoBanner(
                                    title: "AI Features Disabled",
                                    message: "Enable AI Data Sharing in Settings to use predictions",
                                    variant: .warning,
                                    actionTitle: "Go to Settings",
                                    action: {
                                        dismiss()
                                        // Navigate to settings - would need navigation coordinator
                                    }
                                )
                                .padding(.horizontal, .spacingMD)
                            } else {
                                // Info about local predictions
                                InfoBanner(
                                    title: "Local Predictions",
                                    message: "Predictions use on-device heuristics based on your baby's age and recent patterns. No data is sent to external servers.",
                                    variant: .info
                                )
                                .padding(.horizontal, .spacingMD)
                                
                                // Generate Buttons
                                HStack(spacing: .spacingSM) {
                                    PrimaryButton(
                                        "Predict Next Feed",
                                        icon: "drop.fill",
                                        isDisabled: viewModel.isLoading
                                    ) {
                                        viewModel.generatePrediction(type: .nextFeed)
                                    }
                                    
                                    PrimaryButton(
                                        "Predict Next Nap",
                                        icon: "moon.fill",
                                        isDisabled: viewModel.isLoading
                                    ) {
                                        viewModel.generatePrediction(type: .nextNap)
                                    }
                                }
                                .padding(.horizontal, .spacingMD)
                                
                                // Predictions
                                if viewModel.isLoading {
                                    LoadingStateView(message: "Generating prediction...")
                                        .frame(height: 100)
                                } else {
                                    if let feedPrediction = viewModel.nextFeedPrediction {
                                        PredictionCard(prediction: feedPrediction)
                                            .padding(.horizontal, .spacingMD)
                                    }
                                    
                                    if let napPrediction = viewModel.nextNapPrediction {
                                        PredictionCard(prediction: napPrediction)
                                            .padding(.horizontal, .spacingMD)
                                    }
                                    
                                    if viewModel.nextFeedPrediction == nil && viewModel.nextNapPrediction == nil {
                                        EmptyStateView(
                                            icon: "brain.head.profile",
                                            title: "No predictions yet",
                                            message: "Tap the buttons above to generate predictions"
                                        )
                                        .frame(height: 200)
                                    }
                                }
                                
                                if let error = viewModel.errorMessage {
                                    ErrorStateView(message: error)
                                        .frame(height: 150)
                                }
                            }
                        }
                        .padding(.vertical, .spacingMD)
                    }
                } else {
                    LoadingStateView()
                }
            }
            .navigationTitle("Smart Predictions")
            .background(Color.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                if let baby = environment.currentBaby {
                    updateViewModel(for: baby)
                }
            }
        }
    }
    
    private func updateViewModel(for baby: Baby) {
        viewModel = PredictionsViewModel(
            dataStore: environment.dataStore,
            baby: baby,
            aiEnabled: environment.appSettings.aiDataSharingEnabled,
            appSettings: environment.appSettings
        )
    }
}

// AIDisabledCard removed - using InfoBanner instead

struct PredictionCard: View {
    let prediction: Prediction
    
    var body: some View {
        VStack(alignment: .leading, spacing: .spacingSM) {
            HStack {
                Text(prediction.type.displayName)
                    .font(.headline)
                    .foregroundColor(.foreground)
                
                Spacer()
                
                Text("\(Int(prediction.confidence * 100))% confidence")
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
            }
            
            Text(formatTime(prediction.predictedTime))
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(prediction.explanation)
                .font(.body)
                .foregroundColor(.mutedForeground)
        }
        .padding(.spacingMD)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.surface)
        .cornerRadius(.radiusMD)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}

#Preview {
    PredictionsView()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}

