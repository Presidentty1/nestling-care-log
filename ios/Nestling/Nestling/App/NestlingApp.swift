import SwiftUI
import os.signpost
import CoreSpotlight

@main
struct NestlingApp: App {
    @StateObject private var environment: AppEnvironment
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showOnboarding = false
    @State private var isCheckingAuth = true
    @State private var isCheckingOnboarding = true
    
    private let launchSignpostID: OSSignpostID
    
    init() {
        // Initialize crash reporting
        _ = CrashReportingService.shared

        // Use DataStoreSelector to choose implementation
        // Defaults to Core Data if available, falls back to JSON
        let dataStore = DataStoreSelector.create()
        _environment = StateObject(wrappedValue: AppEnvironment(dataStore: dataStore))

        // Start launch signpost
        launchSignpostID = SignpostLogger.beginInterval("AppLaunch", log: SignpostLogger.ui)
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                if isCheckingAuth {
                    // Show loading screen while checking auth status
                    Color.background
                        .ignoresSafeArea()
                        .overlay {
                            ProgressView()
                        }
                        .task {
                            // Check for existing session
                            await authViewModel.restoreSession()
                            await MainActor.run {
                                isCheckingAuth = false
                                // If no session, we'll show AuthView
                                // If session exists, check onboarding
                                if authViewModel.session != nil {
                                    isCheckingOnboarding = true
                                    checkOnboarding()
                                }
                            }
                        }
                } else if authViewModel.session == nil {
                    // No session - show Auth
                    AuthView(viewModel: authViewModel) {
                        // On authenticated, check onboarding
                        Task { @MainActor in
                            // Small delay to ensure session state propagates
                            try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
                            isCheckingOnboarding = true
                            checkOnboarding()
                        }
                    }
                } else if isCheckingOnboarding {
                    // Show loading screen while checking onboarding status
                    Color.background
                        .ignoresSafeArea()
                        .overlay {
                            VStack(spacing: .spacingMD) {
                                ProgressView()
                                Text("Checking setup...")
                                    .font(.caption)
                                    .foregroundColor(.mutedForeground)
                            }
                        }
                        .task {
                            // Fallback timeout - if checkOnboarding doesn't complete in 5 seconds, proceed anyway
                            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                            if isCheckingOnboarding {
                                print("⚠️ WARNING: Onboarding check timed out, proceeding to app")
                                isCheckingOnboarding = false
                            }
                        }
                } else if showOnboarding {
                    OnboardingView(dataStore: environment.dataStore) {
                        showOnboarding = false
                        // Refresh babies and settings after onboarding completes
                        Task {
                            await environment.refreshBabies()
                            await environment.refreshSettings()
                        }
                    }
                } else {
                    ContentView()
                        .environmentObject(environment)
                        .appPrivacy(enabled: PrivacyManager.shared.isAppPrivacyEnabled)
                        .onAppear {
                            // End launch signpost when ContentView appears
                            SignpostLogger.endInterval("AppLaunch", signpostID: launchSignpostID, log: SignpostLogger.ui)
                            
                            // Process pending widget actions
                            processWidgetActions()
                        }
                        .onOpenURL { url in
                            let route = DeepLinkRouter.parse(url: url)
                            environment.navigationCoordinator.handleDeepLink(route)
                        }
                        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                            // Handle Universal Links
                            if let url = userActivity.webpageURL {
                                let route = DeepLinkRouter.parse(url: url)
                                environment.navigationCoordinator.handleDeepLink(route)
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
        }
    }
    
    // MARK: - Helper Methods
    
    private func checkOnboarding() {
        Task { @MainActor in
            // Add timeout to prevent infinite loading
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
                if isCheckingOnboarding {
                    print("⚠️ WARNING: checkOnboarding timed out after 3 seconds, proceeding anyway")
                    isCheckingOnboarding = false
                }
            }
            
            // Check if onboarding is needed
            do {
                let onboardingService = OnboardingService(dataStore: environment.dataStore)
                let completed = await onboardingService.isOnboardingCompleted()
                
                // Also check if user has any babies - if not, force onboarding
                let babies = try await environment.dataStore.fetchBabies()
                let hasBabies = !babies.isEmpty
                
                timeoutTask.cancel()
                isCheckingOnboarding = false
                
                // Show onboarding if:
                // 1. Onboarding was never completed, OR
                // 2. Onboarding was completed but no babies exist (data might have been cleared)
                if !completed || !hasBabies {
                    showOnboarding = true
                } else {
                    // Refresh babies list in environment
                    await environment.refreshBabies()
                }
            } catch {
                print("⚠️ ERROR: Failed to check onboarding status: \(error)")
                timeoutTask.cancel()
                isCheckingOnboarding = false
                // On error, assume onboarding is needed to be safe
                showOnboarding = true
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
        let eventIdString = String(identifier.dropFirst("com.nestling.events.".count))
        guard let eventId = UUID(uuidString: eventIdString) else {
            return
        }
        
        // Navigate to History tab and scroll to event
        Task {
            environment.navigationCoordinator.selectedTab = 1 // History tab
            
            // Find event and navigate to its date
            if let baby = environment.currentBaby {
                let startDate = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
                let events = try? await environment.dataStore.fetchEvents(for: baby, from: startDate, to: Date())
                if let event = events?.first(where: { $0.id == eventId }) {
                    // Navigate to the date of the event
                    // This would be handled by HistoryViewModel
                    environment.navigationCoordinator.navigateToEvent(event)
                }
            }
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
                environment.navigationCoordinator.feedPrefillAmount = amount
                environment.navigationCoordinator.feedPrefillUnit = unit
                environment.navigationCoordinator.showFeedForm = true
            case .startSleep:
                environment.navigationCoordinator.showSleepForm = true
            case .stopSleep:
                // Stop active sleep - handled by HomeViewModel
                break
            }
        }
    }
}

struct ContentView: View {
    @EnvironmentObject var environment: AppEnvironment
    
    var body: some View {
        TabView(selection: Binding(
            get: { environment.navigationCoordinator.selectedTab },
            set: { environment.navigationCoordinator.selectedTab = $0 }
        )) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
                .tag(1)
            
            LabsView()
                .tabItem {
                    Label("Labs", systemImage: "flask.fill")
                }
                .tag(2)
            
            SettingsRootView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}

