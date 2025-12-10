import SwiftUI

struct LabsView: View {
    @EnvironmentObject var environment: AppEnvironment
    @State private var showPredictions = false
    @State private var showProSubscription = false
    @State private var showCryInsightsOnboarding = false
    @State private var showCryInsights = false
    @State private var selectedComingSoon: ComingSoonFeature?
    
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
                            Task {
                                await Analytics.shared.logPaywallViewed(source: "labs_smart_predictions")
                            }
                            showProSubscription = true
                        }
                    }
                    .padding(.horizontal, .spacingMD)
                    
                    // Cry Insights Card
                    LabsCard(
                        title: "Cry Insights",
                        description: "Analyze baby's cry patterns",
                        icon: "waveform",
                        color: .primary,
                        badge: "Beta"
                    ) {
                        let onboardingShown = UserDefaults.standard.bool(forKey: "cryInsightsOnboardingShown")
                        if !onboardingShown {
                            showCryInsightsOnboarding = true
                        } else {
                            showCryInsights = true
                        }
                    }
                    .padding(.horizontal, .spacingMD)
                    
                    // Divider
                    Divider()
                        .padding(.vertical, .spacingSM)
                    
                    Text("Coming Soon")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.mutedForeground)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, .spacingMD)
                    
                    // Coming Soon Features
                    ForEach(ComingSoonFeature.allCases, id: \.self) { feature in
                        ComingSoonCard(feature: feature) {
                            selectedComingSoon = feature
                        }
                        .padding(.horizontal, .spacingMD)
                    }
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
            .sheet(isPresented: $showCryInsightsOnboarding) {
                AIFeatureOnboardingView(feature: .cryInsights)
                    .onDisappear {
                        // Show Cry Insights after onboarding
                        showCryInsights = true
                    }
            }
            .sheet(isPresented: $showCryInsights) {
                if let baby = environment.currentBaby ?? environment.babies.first {
                    CryRecorderView(dataStore: environment.dataStore, baby: baby)
                } else {
                    Text("No baby selected")
                }
            }
            .sheet(item: $selectedComingSoon) { feature in
                ComingSoonDetailView(feature: feature)
            }
            .sheet(isPresented: $showProSubscription) {
                ProSubscriptionView()
            }
        }
    }
}

// MARK: - Coming Soon Features

enum ComingSoonFeature: String, CaseIterable, Identifiable {
    case sleepConsultant = "Sleep Consultant AI"
    case growthCharts = "Growth & Development Charts"
    case smartPhotoMemories = "Smart Photo Memories"
    
    var id: String { rawValue }
    
    var description: String {
        switch self {
        case .sleepConsultant:
            return "Chat with an AI sleep consultant trained on pediatric sleep science"
        case .growthCharts:
            return "Track weight, height, and head circumference with WHO percentile charts"
        case .smartPhotoMemories:
            return "Automatically organize photos by milestone and create monthly recaps"
        }
    }
    
    var icon: String {
        switch self {
        case .sleepConsultant: return "message.fill"
        case .growthCharts: return "chart.line.uptrend.xyaxis"
        case .smartPhotoMemories: return "photo.on.rectangle.angled"
        }
    }
    
    var color: Color {
        switch self {
        case .sleepConsultant: return .eventSleep
        case .growthCharts: return .eventFeed
        case .smartPhotoMemories: return .eventTummy
        }
    }
}

struct ComingSoonCard: View {
    let feature: ComingSoonFeature
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacingMD) {
                Image(systemName: feature.icon)
                    .font(.title3)
                    .foregroundColor(feature.color)
                    .frame(width: 40)
                    .opacity(0.5)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: .spacingXS) {
                        Text(feature.rawValue)
                            .font(.headline)
                            .foregroundColor(.mutedForeground)
                        
                        Text("Soon")
                            .font(.caption2)
                            .fontWeight(.semibold)
                            .foregroundColor(.mutedForeground)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.surface)
                            .cornerRadius(6)
                            .opacity(0.7)
                    }
                    
                    Text(feature.description)
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                        .opacity(0.8)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.mutedForeground)
                    .opacity(0.5)
            }
            .padding(.spacingMD)
            .background(Color.surface.opacity(0.5))
            .cornerRadius(.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusMD)
                    .stroke(Color.cardBorder.opacity(0.5), lineWidth: 1)
                    .opacity(0.5)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ComingSoonDetailView: View {
    let feature: ComingSoonFeature
    @Environment(\.dismiss) var dismiss
    @State private var notifyMe = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: .spacingXL) {
                Spacer()
                
                Image(systemName: feature.icon)
                    .font(.system(size: 70))
                    .foregroundColor(feature.color)
                    .opacity(0.7)
                
                VStack(spacing: .spacingMD) {
                    Text(feature.rawValue)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.foreground)
                    
                    Text(feature.description)
                        .font(.body)
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, .spacingLG)
                }
                
                VStack(spacing: .spacingSM) {
                    Toggle("Notify me when available", isOn: $notifyMe)
                        .padding(.spacingMD)
                        .background(Color.surface)
                        .cornerRadius(.radiusMD)
                    
                    Text("We'll send you a notification when this feature launches")
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, .spacingLG)
                
                Spacer()
                
                PrimaryButton("Got it") {
                    dismiss()
                }
                .padding(.horizontal, .spacingLG)
                .padding(.bottom, .spacing2XL)
            }
            .background(Color.background)
            .navigationTitle("Coming Soon")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("✕") {
                        dismiss()
                    }
                    .foregroundColor(.mutedForeground)
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

