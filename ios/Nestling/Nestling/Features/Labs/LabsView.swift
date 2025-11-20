import SwiftUI

struct LabsView: View {
    @EnvironmentObject var environment: AppEnvironment
    @State private var showPredictions = false
    @State private var showProSubscription = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingLG) {
                    // Disclaimer text
                    Text("Experimental features. These may change as we learn from feedback.")
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, .spacingMD)
                        .padding(.top, .spacingSM)
                    
                    // Smart Predictions Card
                    LabsCard(
                        title: "Smart Predictions",
                        description: "Get suggested nap and feed times based on your baby's logs",
                        icon: "brain.head.profile",
                        color: .primary,
                        badge: !ProSubscriptionService.shared.isProUser ? "Pro" : nil
                    ) {
                        if ProSubscriptionService.shared.isProUser {
                            showPredictions = true
                        } else {
                            showProSubscription = true
                        }
                    }
                    .padding(.horizontal, .spacingMD)
                    
                    // Cry Insights Card
                    NavigationLink(destination: {
                        if let baby = environment.currentBaby ?? environment.babies.first {
                            CryRecorderView(dataStore: environment.dataStore, baby: baby)
                        } else {
                            Text("No baby selected")
                        }
                    }) {
                        LabsCard(
                            title: "Cry Insights",
                            description: "Analyze baby's cry patterns",
                            icon: "waveform",
                            color: .primary,
                            badge: "Beta"
                        ) { }
                    }
                    .padding(.horizontal, .spacingMD)
                }
                .padding(.vertical, .spacingMD)
            }
            .navigationTitle("Labs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack {
                        Text("Labs")
                            .font(.headline)
                        Text("AI & Experimental Features")
                            .font(.caption2)
                            .foregroundColor(.mutedForeground)
                    }
                }
            }
            .background(Color.background)
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
        }
    }
}

struct LabsCard: View {
    let title: String
    let description: String
    let icon: String
    let color: Color
    let badge: String?
    let action: () -> Void
    
    init(
        title: String,
        description: String,
        icon: String,
        color: Color,
        badge: String? = nil,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.description = description
        self.icon = icon
        self.color = color
        self.badge = badge
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
                    HStack(spacing: .spacingXS) {
                        Text(title)
                            .font(.title)
                            .foregroundColor(.foreground)
                        
                        if let badge = badge {
                            Text(badge)
                                .font(.caption2)
                                .fontWeight(.semibold)
                                .foregroundColor(badge == "Pro" ? .white : .mutedForeground)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(badge == "Pro" ? Color.primary : Color.surface)
                                .cornerRadius(8)
                        }
                    }
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.mutedForeground)
            }
            .padding(.spacingMD)
            .background(Color.surface)
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
                        .background(Color.surface)
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
            .background(Color.background)
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

