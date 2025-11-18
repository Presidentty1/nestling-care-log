import SwiftUI

struct SettingsRootView: View {
    @EnvironmentObject var environment: AppEnvironment
    @State private var showAIDataSharing = false
    @State private var showPrivacyData = false
    @State private var showManageBabies = false
    @State private var showManageCaregivers = false
    
    var body: some View {
        NavigationStack {
            List {
                Section("Notifications & Reminders") {
                    NavigationLink("Notification Settings") {
                        NotificationSettingsView()
                    }
                }
                
                Section("AI & Smart Features") {
                    Button(action: { showAIDataSharing = true }) {
                        HStack {
                            Text("AI Data Sharing")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.mutedForeground)
                                .font(.caption)
                        }
                    }
                    
                    Toggle("Prefer Medium Sheet", isOn: Binding(
                        get: { environment.appSettings.preferMediumSheet },
                        set: { newValue in
                            Task {
                                var settings = environment.appSettings
                                settings.preferMediumSheet = newValue
                                try? await environment.dataStore.saveAppSettings(settings)
                                await MainActor.run {
                                    environment.appSettings = settings
                                }
                            }
                        }
                    ))
                    
                    Toggle("Index Events in Spotlight", isOn: Binding(
                        get: { environment.appSettings.spotlightIndexingEnabled },
                        set: { newValue in
                            Task {
                                var settings = environment.appSettings
                                settings.spotlightIndexingEnabled = newValue
                                try? await environment.dataStore.saveAppSettings(settings)
                                await MainActor.run {
                                    environment.appSettings = settings
                                    
                                    // If disabling, remove all indexed events
                                    if !newValue {
                                        SpotlightIndexer.shared.removeAllIndexedEvents()
                                    }
                                }
                            }
                        }
                    ))
                }
                
                Section("Privacy & Data") {
                    Button(action: { showPrivacyData = true }) {
                        HStack {
                            Text("Export & Delete Data")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.mutedForeground)
                                .font(.caption)
                        }
                    }
                    
                    NavigationLink("Privacy & Security") {
                        PrivacySettingsView()
                    }
                    
                    NavigationLink("Caregiver Mode") {
                        CaregiverModeView()
                    }
                    
                    #if DEBUG
                    NavigationLink("Data Migration") {
                        DataMigrationView()
                    }
                    #endif
                }
                
                Section("Family & Caregivers") {
                    Button(action: { showManageBabies = true }) {
                        HStack {
                            Text("Manage Babies")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.mutedForeground)
                                .font(.caption)
                        }
                    }
                    
                    Button(action: { showManageCaregivers = true }) {
                        HStack {
                            Text("Manage Caregivers")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.mutedForeground)
                                .font(.caption)
                        }
                    }
                }
                
                Section("Shortcuts") {
                    NavigationLink("Keyboard Shortcuts") {
                        KeyboardShortcutsView()
                    }
                }
                
                Section("Support") {
                    Button(action: {
                        Task {
                            do {
                                let url = try await DiagnosticsService.shared.generateDiagnostics(dataStore: environment.dataStore)
                                let activityVC = UIActivityViewController(activityItems: [url], applicationActivities: nil)
                                
                                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let rootVC = windowScene.windows.first?.rootViewController {
                                    rootVC.present(activityVC, animated: true)
                                }
                            } catch {
                                print("Failed to generate diagnostics: \(error)")
                            }
                        }
                    }) {
                        HStack {
                            Text("Generate Diagnostics")
                            Spacer()
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.mutedForeground)
                        }
                    }
                }
                
                Section("Subscription") {
                    NavigationLink("Nestling Pro") {
                        ProSubscriptionView()
                    }
                }
                
                Section("About") {
                    NavigationLink("Achievements") {
                        AchievementsView()
                    }
                    
                    NavigationLink("About") {
                        AboutView()
                    }
                }
                
                #if DEBUG
                Section("Debug") {
                    NavigationLink("Developer Tools") {
                        DeveloperSettingsView()
                    }
                    
                    Button(action: {
                        Task {
                            let service = OnboardingService(dataStore: environment.dataStore)
                            try? await service.resetOnboarding()
                            // App will show onboarding on next launch
                        }
                    }) {
                        Text("Reset Onboarding")
                    }
                    
                    Toggle("RTL Preview", isOn: .constant(false))
                        .onChange(of: false) { _, enabled in
                            // In real implementation, this would set environment layout direction
                            // For now, this is a placeholder for RTL testing
                        }
                    
                    Menu("Load Scenario") {
                        ForEach(ScenarioType.allCases, id: \.self) { scenario in
                            Button(scenario.displayName) {
                                Task {
                                    let seeder = ScenarioSeeder(dataStore: environment.dataStore)
                                    try? await seeder.applyScenario(scenario)
                                    environment.refreshBabies()
                                }
                            }
                        }
                    }
                }
                #endif
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showAIDataSharing) {
                AIDataSharingSettingsView()
            }
            .sheet(isPresented: $showPrivacyData) {
                PrivacyDataView()
            }
            .sheet(isPresented: $showManageBabies) {
                ManageBabiesView()
            }
            .sheet(isPresented: $showManageCaregivers) {
                ManageCaregiversView()
            }
        }
    }
}

#Preview {
    SettingsRootView()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}

