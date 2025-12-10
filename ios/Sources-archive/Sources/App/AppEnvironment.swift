import Foundation
import Combine

/// Central dependency container for the app.
/// Provides access to DataStore and shared view models.
@MainActor
class AppEnvironment: ObservableObject {
    let dataStore: DataStore
    let navigationCoordinator: NavigationCoordinator
    
    @Published var appSettings: AppSettings = .default()
    @Published var currentBaby: Baby?
    @Published var babies: [Baby] = []
    @Published var isCaregiverMode: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Check if AI features are enabled (requires both AI data sharing consent and Pro subscription)
    var isAIFeatureEnabled: Bool {
        appSettings.aiDataSharingEnabled && ProSubscriptionService.shared.isProUser
    }
    
    init(dataStore: DataStore) {
        self.dataStore = dataStore
        self.navigationCoordinator = NavigationCoordinator()
        loadInitialData()
        loadCaregiverMode()
    }
    
    private func loadCaregiverMode() {
        isCaregiverMode = UserDefaults.standard.bool(forKey: AppConfig.userDefaultsCaregiverModeKey)
    }
    
    func setCaregiverMode(_ enabled: Bool) {
        isCaregiverMode = enabled
        UserDefaults.standard.set(enabled, forKey: AppConfig.userDefaultsCaregiverModeKey)
    }
    
    private func loadInitialData() {
        Task {
            do {
                // Load babies
                let loadedBabies = try await dataStore.fetchBabies()
                await MainActor.run {
                    self.babies = loadedBabies
                    if currentBaby == nil, let firstBaby = loadedBabies.first {
                        self.currentBaby = firstBaby
                    }
                }
                
                // Load settings
                let settings = try await dataStore.fetchAppSettings()
                await MainActor.run {
                    self.appSettings = settings
                }
            } catch {
                Logger.dataError("Error loading initial data: \(error.localizedDescription)")
            }
        }
    }
    
    func refreshBabies() {
        Task {
            do {
                let loadedBabies = try await dataStore.fetchBabies()
                await MainActor.run {
                    self.babies = loadedBabies
                    // Update current baby if it still exists
                    if let currentId = currentBaby?.id,
                       let updatedBaby = loadedBabies.first(where: { $0.id == currentId }) {
                        self.currentBaby = updatedBaby
                    } else if currentBaby == nil, let firstBaby = loadedBabies.first {
                        self.currentBaby = firstBaby
                    }
                }
            } catch {
                Logger.dataError("Error refreshing babies: \(error.localizedDescription)")
            }
        }
    }
    
    func refreshSettings() {
        Task {
            do {
                let settings = try await dataStore.fetchAppSettings()
                await MainActor.run {
                    self.appSettings = settings
                }
            } catch {
                Logger.dataError("Error refreshing settings: \(error.localizedDescription)")
            }
        }
    }
}

