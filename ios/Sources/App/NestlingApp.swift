import SwiftUI
import os.signpost

@main
struct NestlingApp: App {
    @StateObject private var environment: AppEnvironment
    @StateObject private var themeManager = ThemeManager()
    @State private var showAuth = false
    @State private var showOnboarding = false

    private let launchSignpostID: OSSignpostID
    
    init() {
        // Initialize crash reporter first
        _ = CrashReporter.shared

        // Configure Supabase client
        configureSupabase()

        // Use DataStoreSelector to choose implementation
        // Defaults to Core Data if available, falls back to JSON
        let dataStore = DataStoreSelector.create()
        _environment = StateObject(wrappedValue: AppEnvironment(dataStore: dataStore))

        // Start launch signpost
        launchSignpostID = SignpostLogger.beginInterval("AppLaunch", log: SignpostLogger.ui)

        // Add app launch breadcrumb
        CrashReporter.shared.addBreadcrumb("App launched", category: "app_lifecycle")
    }

    private func configureSupabase() {
        // Get Supabase credentials from environment variables or configuration
        // In production, these should be set in Xcode build settings or Info.plist

        #if DEBUG
        // For development, you can set these in your environment or Xcode scheme
        let supabaseURL = ProcessInfo.processInfo.environment["SUPABASE_URL"] ?? "https://your-project.supabase.co"
        let supabaseAnonKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"] ?? "your-anon-key-here"
        #else
        // For production, get from Info.plist or secure storage
        let supabaseURL = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String ?? "https://your-project.supabase.co"
        let supabaseAnonKey = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String ?? "your-anon-key-here"
        #endif

        // Configure the Supabase client
        SupabaseClient.shared.configure(url: supabaseURL, anonKey: supabaseAnonKey)

        Logger.info("Supabase client configured with URL: \(supabaseURL)")
    }
    
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            Group {
                if showAuth {
                    AuthView(dataStore: environment.dataStore)
                        .catchErrors()
                        .onDisappear {
                            showAuth = false
                            // Check if onboarding is needed after auth
                            Task {
                                await checkOnboardingStatus()
                            }
                        }
                } else if showOnboarding {
                    OnboardingView(dataStore: environment.dataStore) {
                        showOnboarding = false
                        environment.refreshBabies()
                        environment.refreshSettings()
                    }
                    .catchErrors()
                } else {
        ContentView()
            .environmentObject(environment)
            .environmentObject(themeManager)
            .appPrivacy(enabled: PrivacyManager.shared.isAppPrivacyEnabled)
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                // Check for system theme changes when app becomes active
                let currentSystemScheme = UITraitCollection.current.userInterfaceStyle == .dark ? ColorScheme.dark : .light
                if themeManager.themePreference == nil { // Only if following system
                    // Force UI update if system theme changed
                    themeManager.objectWillChange.send()
                }
            }
                        .catchErrors()
                        .onAppear {
                            // End launch signpost when ContentView appears
                            SignpostLogger.endInterval("AppLaunch", signpostID: launchSignpostID, log: SignpostLogger.ui)

                            // Process pending widget actions
                            processWidgetActions()
                        }
                        .onChange(of: scenePhase) { _, newPhase in
                            switch newPhase {
                            case .active:
                                Logger.info("App became active")
                                // Resume any paused operations
                                Task {
                                    await checkOnboardingStatus()
                                }
                            case .inactive:
                                Logger.info("App became inactive")
                                // Save any pending state
                            case .background:
                                Logger.info("App entered background")
                                // Critical: Save all data before backgrounding
                                Task {
                                    do {
                                        // Force save any pending changes
                                        try await environment.dataStore.forceSyncIfNeeded()
                                        Logger.info("Data saved before backgrounding")
                                    } catch {
                                        Logger.error("Failed to save data before backgrounding: \(error.localizedDescription)")
                                    }
                                }
                            @unknown default:
                                break
                            }
                        }
                        .onOpenURL { url in
                            let route = DeepLinkRouter.parse(url: url)
                            if let coordinator = environment.navigationCoordinator {
                                coordinator.handleDeepLink(route)
                            }
                        }
                        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                            // Handle Universal Links
                            if let url = userActivity.webpageURL {
                                let route = DeepLinkRouter.parse(url: url)
                                if let coordinator = environment.navigationCoordinator {
                                    coordinator.handleDeepLink(route)
                                }
                            }
                        }
                        .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
                            // Handle Spotlight search results
                            handleSpotlightActivity(userActivity)
                        }
                        .task {
                            // Check Face ID if enabled
                            if PrivacyManager.shared.isFaceIDEnabled {
                                let authenticated = await AuthenticationManager.shared.authenticate()
                                if !authenticated {
                                    // Handle authentication failure
                                }
                            }
                        }
                }
            }
            .preferredColorScheme(themeManager.effectiveTheme)
            .animation(.easeInOut(duration: 0.3), value: themeManager.effectiveTheme)
            .task {
                // Check auth and onboarding status on app launch
                await checkAuthAndOnboardingStatus()
            }
        }
    }
    
    /// Handle Spotlight search result tap
    private func handleSpotlightActivity(_ userActivity: NSUserActivity) {
        guard let identifier = userActivity.userInfo?[CSSearchableItemActivityIdentifier] as? String,
              identifier.hasPrefix("com.nestling.events.") else {
            return
        }
        
        // Extract event ID from identifier
        let eventId = String(identifier.dropFirst("com.nestling.events.".count))
        
        // Navigate to History tab and scroll to event
        Task {
            if let coordinator = environment.navigationCoordinator {
                coordinator.selectedTab = 1 // History tab
                
                // Find event and navigate to its date
                if let baby = environment.currentBaby {
                    let events = try? await environment.dataStore.fetchEvents(for: baby)
                    if let event = events?.first(where: { $0.id == eventId }) {
                        // Navigate to the date of the event
                        // This would be handled by HistoryViewModel
                        coordinator.navigateToEvent(event)
                    }
                }
            }
        }
    }
    
    /// Check both auth and onboarding status
    private func checkAuthAndOnboardingStatus() async {
        // Check if user has completed authentication
        let accountStatusRaw = UserDefaults.standard.string(forKey: AppConfig.userDefaultsAccountStatusKey) ?? AccountStatus.notSet.rawValue
        let accountStatus = AccountStatus(rawValue: accountStatusRaw) ?? .notSet

        if accountStatus == .notSet {
            // User needs to authenticate
            showAuth = true
            return
        }

        // User is authenticated, check onboarding
        await checkOnboardingStatus()
    }

    /// Check if onboarding is needed
    private func checkOnboardingStatus() async {
        let onboardingService = OnboardingService(dataStore: environment.dataStore)
        let completed = await onboardingService.isOnboardingCompleted()
        if !completed {
            showOnboarding = true
        }
    }

    /// Process widget actions queued from widgets
    private func processWidgetActions() {
        guard let (action, parameters) = WidgetActionService.shared.consumePendingAction() else {
            return
        }
        
        Task { @MainActor in
            // Actions are processed via deep links or direct DataStore calls
            // Widget actions trigger navigation or data operations
            switch action {
            case .logFeed120ml, .logFeed150ml:
                let amount = parameters["amount"] as? Double ?? 120
                let unit = parameters["unit"] as? String ?? "ml"
                // Trigger feed form with prefill
                if let coordinator = environment.navigationCoordinator {
                    coordinator.feedPrefillAmount = amount
                    coordinator.feedPrefillUnit = unit
                    coordinator.showFeedForm = true
                }
            case .startSleep:
                if let coordinator = environment.navigationCoordinator {
                    coordinator.showSleepForm = true
                }
            case .stopSleep:
                // Stop active sleep - handled by HomeViewModel
                break
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var environment: AppEnvironment
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        TabView(selection: Binding(
            get: { environment.navigationCoordinator.selectedTab },
            set: { environment.navigationCoordinator.selectedTab = $0 }
        )) {
            NowView()
                .tabItem {
                    Label("Now", systemImage: "bolt.fill")
                }
                .tag(0)
                .accessibilityLabel("Now tab")
                .accessibilityHint("What's happening now and what to do next")

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
                .tag(1)
                .accessibilityLabel("History tab")
                .accessibilityHint("View past events and daily summaries")

            SettingsRootView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
                .accessibilityLabel("Settings tab")
                .accessibilityHint("App settings and preferences")
        }
        .tint(NuzzleTheme.primary)
        .toolbar {
            // Quick theme toggle in top-right corner
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: {
                    Haptics.light()
                    themeManager.toggleTheme()
                }) {
                    Image(systemName: themeManager.effectiveTheme == .dark ? "sun.max.fill" : "moon.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Color.adaptiveSurface(themeManager.effectiveTheme == .dark ? .dark : .light).opacity(0.8))
                                .overlay(
                                    Circle()
                                        .stroke(Color.adaptiveBorder(themeManager.effectiveTheme == .dark ? .dark : .light), lineWidth: 0.5)
                                )
                        )
                }
                .accessibilityLabel("Toggle theme")
                .accessibilityHint("Switch between light and dark appearance")
            }
        }
        .commands {
            CommandMenu("Quick Actions") {
                Button("Log Feed") {
                    if let coordinator = environment.navigationCoordinator {
                        coordinator.showFeedForm = true
                    }
                }
                .keyboardShortcut("n", modifiers: .command)
                
                Button("Start/Stop Sleep") {
                    if let coordinator = environment.navigationCoordinator {
                        coordinator.showSleepForm = true
                    }
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Button("Log Diaper") {
                    if let coordinator = environment.navigationCoordinator {
                        coordinator.showDiaperForm = true
                    }
                }
                .keyboardShortcut("d", modifiers: .command)
                
                Button("Start Tummy Timer") {
                    if let coordinator = environment.navigationCoordinator {
                        coordinator.showTummyForm = true
                    }
                }
                .keyboardShortcut("t", modifiers: .command)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}

