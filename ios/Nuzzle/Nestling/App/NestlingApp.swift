import SwiftUI
import os.signpost
import CoreSpotlight

@main
struct NestlingApp: App {
    @StateObject private var environment: AppEnvironment
    @StateObject private var authViewModel = AuthViewModel()
    @State private var showOnboarding = false
    @State private var showTrialCelebration = false
    @State private var isCheckingAuth = true
    @State private var isCheckingOnboarding = true
    
    private let launchSignpostID: OSSignpostID
    private let launchStartTime: Date
    
    init() {
        // Privacy-first: No third-party analytics (Firebase removed)
        // All analytics are first-party, privacy-respecting, and opt-outable
        
        // Initialize crash reporting (first-party only)
        _ = CrashReportingService.shared

        // Use DataStoreSelector to choose implementation
        // Defaults to Core Data if available, falls back to JSON
        let dataStore = DataStoreSelector.create()
        _environment = StateObject(wrappedValue: AppEnvironment(dataStore: dataStore))

        // Track app install date for AI learning messaging
        if UserDefaults.standard.object(forKey: "app_install_date") == nil {
            UserDefaults.standard.set(Date(), forKey: "app_install_date")
        }
        UserDefaults.standard.set(false, forKey: "voiceover_session_tracked")
        
        // Set up notification delegate for quiet hours filtering
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
        
        // Start launch signpost
        launchSignpostID = SignpostLogger.beginInterval("AppLaunch", log: SignpostLogger.ui)
        launchStartTime = Date()
    }
    
    var body: some Scene {
        WindowGroup {
            if isCheckingAuth {
                ZStack {
                    Color.background
                        .ignoresSafeArea()
                    VStack(spacing: .spacingMD) {
                        ProgressView()
                        Text("Loading...")
                            .font(.caption)
                            .foregroundColor(.mutedForeground)
                    }
                }
                .task {
                    let timeoutTask = Task {
                        try? await Task.sleep(nanoseconds: 5_000_000_000)
                        if isCheckingAuth {
                            await MainActor.run { isCheckingAuth = false }
                        }
                    }
                    
                    await authViewModel.restoreSession()
                    timeoutTask.cancel()
                    
                    await MainActor.run {
                        isCheckingAuth = false
                        if authViewModel.session != nil || authViewModel.hasSkippedAuth {
                            isCheckingOnboarding = true
                            checkOnboarding()
                        }
                    }
                }
                .onChange(of: authViewModel.hasSkippedAuth) { oldValue, newValue in
                    if newValue && !oldValue {
                        isCheckingOnboarding = true
                        checkOnboarding()
                    }
                }
            } else if authViewModel.session == nil && !authViewModel.hasSkippedAuth {
                AuthView(viewModel: authViewModel) {
                    isCheckingOnboarding = true
                    checkOnboarding()
                }
                .onChange(of: authViewModel.hasSkippedAuth) { oldValue, newValue in
                    if newValue && !oldValue {
                        isCheckingOnboarding = true
                        checkOnboarding()
                    }
                }
            } else if isCheckingOnboarding {
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
                        try? await Task.sleep(nanoseconds: 5_000_000_000)
                        if isCheckingOnboarding {
                            isCheckingOnboarding = false
                        }
                    }
            } else if showOnboarding {
                OnboardingView(dataStore: environment.dataStore) {
                    showOnboarding = false
                    showTrialCelebration = true
                    Task {
                        await environment.refreshBabies()
                        environment.refreshSettings()
                    }
                }
            } else {
                ContentView()
                    .environmentObject(environment)
                    .environmentObject(ThemeManager.shared)
                    .nightModeOverlay(themeManager: ThemeManager.shared)
                    .appPrivacy(enabled: PrivacyManager.shared.isAppPrivacyEnabled)
                    .sheet(isPresented: $showTrialCelebration) {
                        VStack(spacing: .spacing2XL) {
                            Spacer()
                            Image(systemName: "star.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.yellow)
                            Text("Welcome! 🎉")
                                .font(.system(size: 32, weight: .bold))
                            Text("Your 7-day free trial has started")
                                .font(.system(size: 18, weight: .regular))
                                .foregroundColor(.mutedForeground)
                            Spacer()
                            Button("Start Tracking") {
                                showTrialCelebration = false
                            }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.primary)
                            .cornerRadius(.radiusXL)
                            .padding(.horizontal, .spacingLG)
                            .padding(.bottom, .spacing2XL)
                        }
                        .background(Color.background)
                    }
                    .onAppear {
                        SignpostLogger.endInterval("AppLaunch", signpostID: launchSignpostID, log: SignpostLogger.ui)
                        let ttiMs = Date().timeIntervalSince(launchStartTime) * 1000
                        AnalyticsService.shared.trackTimeToInteractive(durationMs: Int(ttiMs))
                        let voiceOverRunning = UIAccessibility.isVoiceOverRunning
                        AnalyticsService.shared.track(event: "accessibility_enabled", properties: [
                            "voiceover_running": voiceOverRunning
                        ])
                        if voiceOverRunning && !UserDefaults.standard.bool(forKey: "voiceover_session_tracked") {
                            AnalyticsService.shared.track(event: "voiceover_session_started")
                            UserDefaults.standard.set(true, forKey: "voiceover_session_tracked")
                        }
                        processWidgetActions()
                    }
                    .onOpenURL { url in
                        let route = DeepLinkRouter.parse(url: url)
                        environment.navigationCoordinator.handleDeepLink(route)
                    }
                    .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                        if let url = userActivity.webpageURL {
                            let route = DeepLinkRouter.parse(url: url)
                            environment.navigationCoordinator.handleDeepLink(route)
                        }
                    }
                    .onContinueUserActivity(CSSearchableItemActionType) { userActivity in
                        handleSpotlightActivity(userActivity)
                    }
                    .task {
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
    
    // MARK: - Helper Methods
    
    private func checkOnboarding() {
        Task { @MainActor in
            print("🔍 Starting onboarding check...")
            
            // Add timeout to prevent infinite loading (declare early for guest mode)
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
                if isCheckingOnboarding {
                    print("⚠️ WARNING: checkOnboarding timed out after 1.5 seconds, proceeding anyway")
                    await MainActor.run {
                        isCheckingOnboarding = false
                        // On timeout, just show onboarding
                        showOnboarding = true
                    }
                }
            }
            
            // For guest mode (skipped auth), proceed immediately
            if authViewModel.hasSkippedAuth {
                print("✅ Guest mode: Proceeding immediately to onboarding check")
                timeoutTask.cancel()
                isCheckingOnboarding = false
                
                // Check babies in background, but don't wait - just show onboarding for now
                // User can skip onboarding if they already have data
                Task {
                    do {
                        let babies = try await environment.dataStore.fetchBabies()
                        if !babies.isEmpty {
                            await environment.refreshBabies()
                            // If we have babies, hide onboarding
                            showOnboarding = false
                        }
                    } catch {
                        print("⚠️ Error checking babies: \(error)")
                    }
                }
                
                // Always show onboarding for guest mode (they can skip if they want)
                showOnboarding = true
                return
            }
            
            // For authenticated users, check onboarding
            let onboardingService = OnboardingService(dataStore: environment.dataStore)
            let completedResult = await withTimeout(seconds: 0.5) {
                await onboardingService.isOnboardingCompleted()
            }
            
            // Also check if user has any babies - if not, force onboarding
            let babiesResult = await withTimeout(seconds: 0.5) {
                try await environment.dataStore.fetchBabies()
            }
            
            timeoutTask.cancel()
            isCheckingOnboarding = false
            
            switch (completedResult, babiesResult) {
            case (.success(let completed), .success(let babies)):
                let hasBabies = !babies.isEmpty
                // Show onboarding if:
                // 1. Onboarding was never completed, OR
                // 2. Onboarding was completed but no babies exist (data might have been cleared)
                if !completed || !hasBabies {
                    showOnboarding = true
                } else {
                    // Refresh babies list in environment
                    await environment.refreshBabies()
                }
            default:
                // On timeout or error, show onboarding
                print("⚠️ Timeout or error during onboarding check, showing onboarding")
                showOnboarding = true
            }
        }
    }
    
    // Helper to add timeout to async operations
    private func withTimeout<T>(seconds: Double, operation: @escaping () async throws -> T) async -> Result<T, Error> {
        await withTaskGroup(of: Result<T, Error>.self) { group in
            // Add the actual operation
            group.addTask {
                do {
                    let result = try await operation()
                    return .success(result)
                } catch {
                    return .failure(error)
                }
            }
            
            // Add timeout task
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                return .failure(TimeoutError())
            }
            
            // Get first result (either success or timeout)
            let result = await group.next()!
            group.cancelAll()
            return result
        }
    }
    
    private struct TimeoutError: Error {}
    
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
    @State private var previousTab: Int = 0

    var body: some View {
        TabView(selection: Binding(
            get: { environment.navigationCoordinator.selectedTab },
            set: { newValue in
                // Trigger haptic feedback on tab change
                if newValue != environment.navigationCoordinator.selectedTab {
                    Haptics.selection()
                }
                environment.navigationCoordinator.selectedTab = newValue
            }
        )) {
            HomeView()
                .tabItem {
                    Label("Today", systemImage: "sun.max")
                }
                .tag(0)

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "calendar")
                }
                .tag(1)

            MoreView()
                .tabItem {
                    Label("More", systemImage: "ellipsis.circle")
                }
                .tag(2)
        }
        .motionTransition(.opacity)
    }
}

#Preview {
    ContentView()
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}

