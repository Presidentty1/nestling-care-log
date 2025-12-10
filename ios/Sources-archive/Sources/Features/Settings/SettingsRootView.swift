import SwiftUI
import SafariServices

struct SettingsRootView: View {
    @EnvironmentObject var environment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showAIDataSharing = false
    @State private var showPrivacyData = false
    @State private var showManageBabies = false
    @State private var showManageCaregivers = false
    @State private var showLabs = false
    @State private var showGuidedAssistant = false
    @State private var showDeleteConfirmation = false

    private var isSwiftDataAvailable: Bool {
        // Check if SwiftData is available (iOS 17+)
        if #available(iOS 17.0, *) {
            return true
        }
        return false
    }

    private var themeDescription: String {
        switch themeManager.themePreference {
        case "light":
            return "Always use light mode"
        case "dark":
            return "Always use dark mode"
        default:
            return "Match system setting"
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    VStack(spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 8) {
                                    Image(systemName: "circle.lefthalf.filled")
                                        .foregroundColor(.secondary)
                                        .font(.title2)
                                    Text("Appearance")
                                        .font(.headline)
                                }
                                Text("Choose how Nestling looks on your device")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }

                        VStack(spacing: 12) {
                            // Light Mode Option
                            Button(action: {
                                Haptics.medium()
                                themeManager.setLightMode()
                            }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white)
                                            .frame(width: 44, height: 44)
                                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                        Image(systemName: "sun.max.fill")
                                            .foregroundColor(.orange.opacity(0.8))
                                            .font(.title3)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Light")
                                            .font(.body)
                                            .fontWeight(.medium)
                                        Text("Bright and energetic")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if themeManager.themePreference == "light" {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.title3)
                                    }
                                }
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            // Dark Mode Option
                            Button(action: {
                                Haptics.medium()
                                themeManager.setDarkMode()
                            }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(red: 0.1, green: 0.1, blue: 0.15))
                                            .frame(width: 44, height: 44)
                                            .shadow(color: Color.black.opacity(0.3), radius: 4, x: 0, y: 2)
                                        Image(systemName: "moon.fill")
                                            .foregroundColor(.blue.opacity(0.8))
                                            .font(.title3)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Dark")
                                            .font(.body)
                                            .fontWeight(.medium)
                                        Text("Easy on the eyes")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if themeManager.themePreference == "dark" {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.title3)
                                    }
                                }
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            // System Option
                            Button(action: {
                                Haptics.medium()
                                themeManager.setSystemMode()
                            }) {
                                HStack(spacing: 16) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color.secondary.opacity(0.1))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "circle.lefthalf.filled")
                                            .foregroundColor(.secondary)
                                            .font(.title3)
                                    }
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("System")
                                            .font(.body)
                                            .fontWeight(.medium)
                                        Text("Matches your device")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    if themeManager.themePreference == nil {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.title3)
                                    }
                                }
                                .padding(.vertical, 8)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Display")
                } footer: {
                    Text("Choose a theme that feels right for you. Dark mode can be easier on your eyes during nighttime feedings, while light mode provides a bright, energetic feel for daytime use.")
                }

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

                Section("Cloud Sync & Family") {
                    NavigationLink("Cloud Sync") {
                        CloudSyncStatusView()
                    }
                    .disabled(!isSwiftDataAvailable) // Only show if SwiftData is available

                    NavigationLink("Manage Caregivers") {
                        ManageCaregiversView()
                    }
                }

                Section("Labs & Beta Features") {
                    Button(action: { showLabs = true }) {
                        HStack {
                            HStack(spacing: 12) {
                                Image(systemName: "flask.fill")
                                    .foregroundColor(.orange)
                                    .frame(width: 20, height: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text("Labs")
                                        Text("BETA")
                                            .font(.caption2.bold())
                                            .foregroundColor(.orange)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(Color.orange.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                    Text("Smart predictions & cry analysis")
                                        .font(.caption)
                                        .foregroundColor(.mutedForeground)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.mutedForeground)
                                .font(.caption)
                        }
                    }

                    Button(action: { showGuidedAssistant = true }) {
                        HStack {
                            HStack(spacing: 12) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .foregroundColor(NuzzleTheme.primary)
                                    .frame(width: 20, height: 20)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ask Nuzzle")
                                    Text("AI Guidance")
                                        .font(.caption)
                                        .foregroundColor(.mutedForeground)
                                }
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.mutedForeground)
                                .font(.caption)
                        }
                    }
                }

                Section("Privacy & Data") {
                    NavigationLink("Export Data") {
                        ExportDataView()
                    }

                    Button(action: { showPrivacyData = true }) {
                        HStack {
                            Text("Data & Privacy Settings")
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
                        openFeedbackEmail()
                    }) {
                        HStack {
                            Text("Send Feedback")
                            Spacer()
                            Image(systemName: "envelope")
                                .foregroundColor(.blue)
                        }
                    }
                    .accessibilityLabel("Send feedback")
                    .accessibilityHint("Open email to send feedback about the app")

                    Button(action: {
                        AppConfig.validateAndOpenURL(AppConfig.supportURL)
                    }) {
                        HStack {
                            Text("Support")
                            Spacer()
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.blue)
                        }
                    }
                    .accessibilityLabel("Open support website")
                    .accessibilityHint("Visit our support website for help and FAQs")

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
                                Logger.dataError("Failed to generate diagnostics: \(error.localizedDescription)")
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
                
                Section("Account") {
                    let accountStatusRaw = UserDefaults.standard.string(forKey: AppConfig.userDefaultsAccountStatusKey) ?? AccountStatus.notSet.rawValue
                    let accountTypeRaw = UserDefaults.standard.string(forKey: AppConfig.userDefaultsAccountTypeKey) ?? AccountType.localOnly.rawValue

                    let accountStatus = AccountStatus(rawValue: accountStatusRaw) ?? .notSet
                    let accountType = AccountType(rawValue: accountTypeRaw) ?? .localOnly

                    if accountType == .localOnly && accountStatus == .hasAccount {
                        // Show upgrade option for local accounts
                        Button(action: {
                            Task {
                                await upgradeToCloudKit()
                            }
                        }) {
                            HStack {
                                Text("Upgrade to CloudKit Sync")
                                Spacer()
                                Image(systemName: "icloud")
                                    .foregroundColor(.blue)
                            }
                        }
                        .accessibilityLabel("Upgrade to CloudKit sync")
                        .accessibilityHint("Migrate your data to iCloud for syncing across devices")
                    } else if accountType == .cloudKit {
                        HStack {
                            Text("Account Type")
                            Spacer()
                            Text("iCloud Sync")
                                .foregroundColor(.mutedForeground)
                        }
                    }

                    if accountStatus != .notSet {
                        Button(action: {
                            showDeleteConfirmation = true
                        }) {
                            HStack {
                                Text("Delete Account & Data")
                                    .foregroundColor(.red)
                                Spacer()
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                        .accessibilityLabel("Delete account and data")
                        .accessibilityHint("Permanently delete your account and all data")
                    }
                }

                Section("Legal") {
                    Button(action: {
                        AppConfig.validateAndOpenURL(AppConfig.privacyPolicyURL)
                    }) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.mutedForeground)
                                .font(.caption)
                        }
                    }
                    .accessibilityLabel("Privacy policy")
                    .accessibilityHint("Open privacy policy in browser")

                    Button(action: {
                        AppConfig.validateAndOpenURL(AppConfig.termsOfServiceURL)
                    }) {
                        HStack {
                            Text("Terms of Use")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .foregroundColor(.mutedForeground)
                                .font(.caption)
                        }
                    }
                    .accessibilityLabel("Terms of use")
                    .accessibilityHint("Open terms of use in browser")

                    NavigationLink("Send Feedback") {
                        FeedbackView()
                    }

                    NavigationLink("Safety & Disclaimers") {
                        SafetyDisclaimersView()
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
                
                Section("Demo & Sample Data") {
                    Button(action: {
                        Task {
                            await loadSampleData()
                        }
                    }) {
                        HStack {
                            Text("Load Sample Data")
                            Spacer()
                            Image(systemName: "person.fill.badge.plus")
                                .foregroundColor(.blue)
                        }
                    }
                    .accessibilityLabel("Load sample data")
                    .accessibilityHint("Create a sample baby with realistic activity data for demo purposes")

                    Button(action: {
                        Task {
                            await clearSampleData()
                        }
                    }) {
                        HStack {
                            Text("Clear Sample Data")
                            Spacer()
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .accessibilityLabel("Clear sample data")
                    .accessibilityHint("Remove sample baby and data, keeping only your real data")
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
            .sheet(isPresented: $showLabs) {
                LabsView()
            }
            .sheet(isPresented: $showGuidedAssistant) {
                GuidedAssistantView()
            }
            .alert("Delete Account & Data", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    Task {
                        await deleteAccountAndData()
                    }
                }
            } message: {
                Text("This will permanently delete all your data. For CloudKit accounts, your data will be removed from iCloud but you may need to contact support for complete account deletion. This action cannot be undone.")
            }
        }
    }

    private func loadSampleData() async {
        do {
            let seeder = ScenarioSeeder(dataStore: environment.dataStore)
            try await seeder.createSampleData()
            environment.refreshBabies()
            // Show success feedback
        } catch {
                    Logger.dataError("Failed to load sample data: \(error.localizedDescription)")
        }
    }

    private func clearSampleData() async {
        do {
            let seeder = ScenarioSeeder(dataStore: environment.dataStore)
            try await seeder.clearSampleData()
            environment.refreshBabies()
            // Show success feedback
        } catch {
                    Logger.dataError("Failed to clear sample data: \(error.localizedDescription)")
        }
    }

    private func deleteAccountAndData() async {
        do {
            let accountTypeRaw = UserDefaults.standard.string(forKey: AppConfig.userDefaultsAccountTypeKey) ?? AccountType.localOnly.rawValue
            let accountType = AccountType(rawValue: accountTypeRaw) ?? .localOnly

            if accountType == .cloudKit {
                // Delete CloudKit data (limited by CloudKit's capabilities)
                try await CloudKitAuthService.shared.deleteAccountData()
            }

            // Clear local data
            try await environment.dataStore.saveAppSettings(AppSettings.default())
            UserDefaults.standard.removeObject(forKey: AppConfig.userDefaultsAccountStatusKey)
            UserDefaults.standard.removeObject(forKey: AppConfig.userDefaultsAccountTypeKey)

            // Reset app state
            environment.refreshBabies()
            environment.refreshSettings()

            // Note: In a real app, you'd restart the onboarding flow here

        } catch {
                    Logger.authError("Account deletion failed: \(error.localizedDescription)")
        }
    }

    private func openFeedbackEmail() {
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let iosVersion = UIDevice.current.systemVersion

        let subject = "Nuzzle feedback"
        let body = """
        Hi Nestling Team,

        I have some feedback about the Nuzzle app:

        [Please describe your feedback here. Feel free to include screenshots or details about what you're experiencing.]

        App Version: \(appVersion)
        iOS Version: \(iosVersion)

        Thank you!
        """

        let email = "feedback@nestling.care" // Placeholder - replace with actual email
        let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? subject
        let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? body

        let mailtoURL = URL(string: "mailto:\(email)?subject=\(encodedSubject)&body=\(encodedBody)")

        if let url = mailtoURL, UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        } else {
            // Fallback: copy to clipboard or show message
                    Logger.uiError("Cannot open mailto URL")
        }
    }

    private func upgradeToCloudKit() async {
        do {
            // Check CloudKit account status
            let accountStatus = await CloudKitAuthService.shared.checkAccountStatus()

            switch accountStatus {
            case .available:
                // Migrate data
                let babies = environment.babies
                let events = try await environment.dataStore.fetchEvents(for: babies.first?.id ?? UUID(), from: Date.distantPast, to: Date.distantFuture)

                try await CloudKitAuthService.shared.migrateLocalData(babies: babies, events: events)

                // Update account status
                UserDefaults.standard.set(AccountStatus.signedIn.rawValue, forKey: AppConfig.userDefaultsAccountStatusKey)
                UserDefaults.standard.set(AccountType.cloudKit.rawValue, forKey: AppConfig.userDefaultsAccountTypeKey)

                // Show success message
                // Note: In a real app, you'd show a toast or alert here

            case .noAccount:
                // Show error - need iCloud account
                break

            case .restricted:
                // Show error - account restricted
                break

            case .couldNotDetermine:
                // Show error - couldn't determine status
                break

            @unknown default:
                break
            }

        } catch {
            // Handle migration error
                    Logger.dataError("Migration failed: \(error.localizedDescription)")
        }
    }

    private func openURL(_ urlString: String) {
        guard let url = URL(string: urlString) else { return }

        let safariViewController = SFSafariViewController(url: url)
        safariViewController.modalPresentationStyle = .pageSheet

        // Get the current window scene
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(safariViewController, animated: true)
        }
    }
}

#Preview {
    SettingsRootView()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}

