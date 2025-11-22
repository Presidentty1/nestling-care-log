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

