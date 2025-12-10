import SwiftUI

struct LabsView: View {
    @EnvironmentObject var environment: AppEnvironment
    @State private var showPredictions = false
    @State private var showPaywall = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingLG) {
                    Text("Experimental Features")
                        .font(.headline)
                        .foregroundColor(.foreground)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, .spacingMD)
                    
                    // Smart Predictions Card
                    LabsCard(
                        title: "Smart Predictions",
                        description: "AI-powered predictions for next feed and nap times. These features are for general guidance only and are not medical advice. If you're worried about your baby's health, contact a pediatric professional.",
                        disclaimer: nil,
                        icon: "brain.head.profile",
                        color: NuzzleTheme.primary
                    ) {
                        showPredictions = true
                    }
                    .padding(.horizontal, .spacingMD)
                    
                    // Cry Insights Card
                    if FeatureAccess.canUseCryAnalysis {
                        NavigationLink(destination: {
                            if let baby = environment.currentBaby ?? environment.babies.first {
                                CryRecorderView(dataStore: environment.dataStore, baby: baby)
                            } else {
                                Text("No baby selected")
                            }
                        }) {
                            LabsCard(
                                title: "Cry Insights (Beta)",
                                description: "Record a cry and we'll try to label it as hungry, tired, discomfort, or pain. Experimental feature — suggestions are not medical advice. These features are for general guidance only and are not medical advice. If you're worried about your baby's health, contact a pediatric professional.",
                                disclaimer: nil,
                                icon: "waveform",
                                color: NuzzleTheme.primary
                            ) { }
                        }
                        .padding(.horizontal, .spacingMD)
                    } else {
                        Button(action: {
                            // Show paywall
                            showPaywall = true
                        }) {
                            LabsCard(
                                title: "Cry Insights (Beta)",
                                description: "Record a cry and we'll try to label it as hungry, tired, discomfort, or pain. \(FeatureAccess.proMessage(for: .cryAnalysis))",
                                disclaimer: nil,
                                icon: "waveform",
                                color: .gray
                            ) { }
                        }
                        .padding(.horizontal, .spacingMD)
                    }
                }
                .padding(.vertical, .spacingMD)
            }
            .navigationTitle("Labs")
            .background(NuzzleTheme.background)
            .onChange(of: environment.navigationCoordinator.showPredictions) { _, newValue in
                if newValue {
                    showPredictions = true
                }
            }
            .sheet(isPresented: $showPredictions) {
                PredictionsView()
                    .onDisappear {
                        environment.navigationCoordinator.showPredictions = false
                    }
            }
            .sheet(isPresented: $showPaywall) {
                ProSubscriptionView()
            }
        }
    }
}

struct LabsCard: View {
    let title: String
    let description: String
    let disclaimer: String?
    let icon: String
    let color: Color
    let action: () -> Void

    init(title: String, description: String, disclaimer: String? = nil, icon: String, color: Color, action: @escaping () -> Void) {
        self.title = title
        self.description = description
        self.disclaimer = disclaimer
        self.icon = icon
        self.color = color
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacingMD) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.title)
                        .foregroundColor(.foreground)

                    Text(description)
                        .font(.caption)
                        .foregroundColor(.mutedForeground)

                    if let disclaimer = disclaimer {
                        Text(disclaimer)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, 2)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.mutedForeground)
            }
            .padding(.spacingMD)
            .background(NuzzleTheme.surface)
            .cornerRadius(.radiusMD)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ComingSoonSheet: View {
    let title: String
    let description: String
    @EnvironmentObject var environment: AppEnvironment
    @Environment(\.dismiss) var dismiss
    @State private var notifyMe: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingLG) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.mutedForeground)
                    
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.foreground)
                    
                    Text(description)
                        .font(.body)
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, .spacingMD)
                    
                    Toggle("Notify me when available", isOn: $notifyMe)
                        .padding(.spacingMD)
                        .background(NuzzleTheme.surface)
                        .cornerRadius(.radiusMD)
                        .onChange(of: notifyMe) { _, newValue in
                            Task {
                                var settings = environment.appSettings
                                settings.cryInsightsNotifyMe = newValue
                                try? await environment.dataStore.saveAppSettings(settings)
                                await MainActor.run {
                                    environment.appSettings = settings
                                }
                            }
                        }
                        .onAppear {
                            notifyMe = environment.appSettings.cryInsightsNotifyMe
                        }
                    
                    PrimaryButton("Got it") {
                        dismiss()
                    }
                    .padding(.horizontal, .spacingMD)
                }
                .padding(.spacing2XL)
            }
            .background(NuzzleTheme.background)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LabsView()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}

