import Foundation

/// Protocol defining data access operations for the Nestling app.
/// Implementations can be swapped (InMemory, JSON-backed, Remote/Supabase) without changing view models.
protocol DataStore {
    // MARK: - Babies
    
    func fetchBabies() async throws -> [Baby]
    func addBaby(_ baby: Baby) async throws
    func updateBaby(_ baby: Baby) async throws
    func deleteBaby(_ baby: Baby) async throws
    
    // MARK: - Events
    
    func fetchEvents(for baby: Baby, on date: Date) async throws -> [Event]
    func fetchEvents(for baby: Baby, from startDate: Date, to endDate: Date) async throws -> [Event]
    func addEvent(_ event: Event) async throws
    func updateEvent(_ event: Event) async throws
    func deleteEvent(_ event: Event) async throws
    
    // MARK: - Predictions
    
    func fetchPredictions(for baby: Baby, type: PredictionType) async throws -> Prediction?
    func generatePrediction(for baby: Baby, type: PredictionType) async throws -> Prediction
    
    // MARK: - Settings
    
    func fetchAppSettings() async throws -> AppSettings
    func saveAppSettings(_ settings: AppSettings) async throws
    
    // MARK: - Active Sleep Tracking
    
    func getActiveSleep(for baby: Baby) async throws -> Event?
    func startActiveSleep(for baby: Baby) async throws -> Event
    func stopActiveSleep(for baby: Baby) async throws -> Event
    
    // MARK: - Last Used Values
    
    func getLastUsedValues(for eventType: EventType) async throws -> LastUsedValues?
    func saveLastUsedValues(for eventType: EventType, values: LastUsedValues) async throws
}

struct LastUsedValues: Codable {
    var amount: Double?
    var unit: String?
    var side: String?
    var subtype: String?
    var durationMinutes: Int?
}

extension DataStore {
    /// Remove all locally persisted domain data. Useful when access is revoked or during logout.
    /// Default implementation wipes babies, their events, and resets settings to defaults.
    func clearSharedData() async throws {
        let babies = try await fetchBabies()
        for baby in babies {
            let events = try await fetchEvents(
                for: baby,
                from: .distantPast,
                to: Date()
            )
            for event in events {
                try? await deleteEvent(event)
            }
            try? await deleteBaby(baby)
        }
        
        // Reset settings to defaults after data removal
        try? await saveAppSettings(AppSettings.default())
    }
}

