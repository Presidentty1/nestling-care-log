import SwiftUI

struct SettingsRootView: View {
    @EnvironmentObject var environment: AppEnvironment
    @ObservedObject private var themeManager = ThemeManager.shared
    @State private var showAIDataSharing = false
    @State private var showPrivacyData = false
    @State private var showManageBabies = false
    @State private var showManageCaregivers = false
    @State private var showAcceptInvite = false
    @State private var showAuth = false
    @State private var showProSubscription = false
    @State private var showPrivacyPolicy = false
    @State private var showTermsOfUse = false

    private func proStatusText() -> String {
        let proService = ProSubscriptionService.shared
        if proService.isProUser {
            if proService.trialDaysRemaining != nil && proService.trialDaysRemaining! > 0 {
                return "Pro Trial Active"
            } else {
                return "Pro Active"
            }
        } else {
            return "Free Plan"
        }
    }
    
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }
    
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        NavigationStack {
            List {
                // Guest/Account upgrade section
                if !SupabaseClientProvider.shared.isConfigured {
                    Section {
                        Button(action: { showAuth = true }) {
                            HStack(spacing: .spacingMD) {
                                Image(systemName: "person.badge.plus")
                                    .foregroundColor(.primary)
                                    .frame(width: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Create account to back up & share")
                                        .font(.headline)
                                        .foregroundColor(.foreground)
                                    Text("Sync your data across devices and share with caregivers")
                                        .font(.caption)
                                        .foregroundColor(.mutedForeground)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.mutedForeground)
                                    .font(.caption)
                            }
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                Section("Sync") {
                    SyncStatusView()
                    Button("Sync Now") {
                        Task { await CloudKitSyncService.shared.syncAll() }
                    }
                    .buttonStyle(.borderless)
                    .foregroundColor(.primary)
                }

                Section("Notifications & Reminders") {
                    NavigationLink("Notification Settings") {
                        NotificationSettingsView()
                    }
                }
                
                Section("Display") {
                    Toggle(isOn: $themeManager.nightModeEnabled) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Night Mode")
                                .font(.body)
                            Text("Red-tinted display for low-light logging")
                                .font(.caption2)
                                .foregroundColor(.mutedForeground)
                        }
                    }
                }
                
                Section("Feedback") {
                    Toggle(isOn: Binding(
                        get: { environment.appSettings.celebrationsEnabled },
                        set: { newValue in
                            Task {
                                var settings = environment.appSettings
                                settings.celebrationsEnabled = newValue
                                try? await environment.dataStore.saveAppSettings(settings)
                                await MainActor.run {
                                    environment.appSettings = settings
                                    UserDefaults.standard.set(newValue, forKey: "celebrationsEnabled")
                                }
                            }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Celebration Effects")
                                .font(.body)
                            Text("Toggle confetti and celebratory haptics")
                                .font(.caption2)
                                .foregroundColor(.mutedForeground)
                        }
                    }
                }
                
                Section("Subscription") {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Nestling Pro")
                                .font(.headline)
                                .foregroundColor(.foreground)

                            Text(proStatusText())
                                .font(.caption)
                                .foregroundColor(.mutedForeground)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundColor(.mutedForeground)
                            .font(.caption)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Task {
                            await Analytics.shared.logPaywallViewed(source: "settings")
                        }
                        showProSubscription = true
                    }
                }

                Section("AI & Smart Features") {
                    Button(action: { showAIDataSharing = true }) {
                        HStack {
                            Text("AI Data Sharing")
                            Spacer()
                            Text(environment.appSettings.aiDataSharingEnabled ? "On" : "Off")
                                .font(.caption)
                                .foregroundColor(.mutedForeground)
                            Image(systemName: "chevron.right")
                                .foregroundColor(.mutedForeground)
                                .font(.caption)
                        }
                    }
                    
                    #if DEBUG
                    Toggle("Use medium-sized popups", isOn: Binding(
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
                    #endif
                    
                    VStack(alignment: .leading, spacing: 4) {
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
                        
                        Text("Search your baby's logs from iOS Search")
                            .font(.caption2)
                            .foregroundColor(.mutedForeground)
                    }
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
                    
                    Toggle(isOn: Binding(
                        get: { environment.appSettings.analyticsEnabled },
                        set: { newValue in
                            Task {
                                var settings = environment.appSettings
                                settings.analyticsEnabled = newValue
                                try? await environment.dataStore.saveAppSettings(settings)
                                await MainActor.run {
                                    environment.appSettings = settings
                                    UserDefaults.standard.set(newValue, forKey: "analyticsEnabled")
                                    AnalyticsService.shared.setEnabled(newValue)
                                }
                            }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Allow Analytics")
                                .font(.body)
                            Text("Share anonymized usage data to improve the app")
                                .font(.caption2)
                                .foregroundColor(.mutedForeground)
                        }
                    }
                    
                    NavigationLink("Privacy & Security") {
                        PrivacySettingsView()
                    }
                    
                    // Caregiver Mode hidden for MVP
                    // NavigationLink("Caregiver Mode") {
                    //     CaregiverModeView()
                    // }
                    
                    #if DEBUG
                    // Data Migration hidden for MVP - migration happens automatically if needed
                    // NavigationLink("Data Migration") {
                    //     DataMigrationView()
                    // }
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
                            Text("Invite Caregiver")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.mutedForeground)
                                .font(.caption)
                        }
                    }
                    
                    Button(action: { showAcceptInvite = true }) {
                        HStack {
                            Text("Accept Invite")
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
                    Button(action: {
                        // Open support email
                        let email = "support@nestling.app"
                        let subject = "Nestling Support Request"
                        let body = """
                        Please describe your issue or feedback:

                        App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
                        iOS Version: \(UIDevice.current.systemVersion)
                        Device: \(UIDevice.current.model)

                        """
                        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                        let urlString = "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)"

                        if let url = URL(string: urlString) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        HStack {
                            Text("Get Help or Send Feedback")
                            Spacer()
                            Image(systemName: "envelope")
                                .foregroundColor(.mutedForeground)
                        }
                    }

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
                                    await environment.refreshBabies()
                                }
                            }
                        }
                    }
                }
                #endif
                
                // Legal & Version footer
                Section {
                    HStack(spacing: .spacingMD) {
                        Button("Privacy Policy") {
                            showPrivacyPolicy = true
                        }
                        .font(.caption)
                        .foregroundColor(.mutedForeground)

                        Text("•")
                            .font(.caption)
                            .foregroundColor(.mutedForeground)

                        Button("Terms of Use") {
                            showTermsOfUse = true
                        }
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    
                    Text("Nestling v\(appVersion) (\(buildNumber))")
                        .font(.caption2)
                        .foregroundColor(.mutedForeground)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showAIDataSharing) {
                AIDataSharingSettingsView()
            }
            .sheet(isPresented: $showPrivacyData) {
                PrivacyDataView()
            }
            .sheet(isPresented: $showManageCaregivers) {
                InviteCaregiverView()
            }
            .sheet(isPresented: $showAcceptInvite) {
                AcceptInviteView()
            }
            .sheet(isPresented: $showManageBabies) {
                ManageBabiesView()
            }
            .sheet(isPresented: $showManageCaregivers) {
                ManageCaregiversView()
            }
            .sheet(isPresented: $showAuth) {
                AuthView(viewModel: AuthViewModel()) {
                    // On successful authentication, dismiss and refresh
                    showAuth = false
                    Task {
                        await environment.refreshBabies()
                        environment.refreshSettings()
                    }
                }
            }
            .sheet(isPresented: $showProSubscription) {
                ProSubscriptionView()
            }
            .sheet(isPresented: $showPrivacyPolicy) {
                LegalDocumentView(documentType: .privacyPolicy)
            }
            .sheet(isPresented: $showTermsOfUse) {
                LegalDocumentView(documentType: .termsOfUse)
            }
        }
    }
}

#Preview {
    SettingsRootView()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}

