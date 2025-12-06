import Foundation

/// Protocol defining data access operations for the Nestling app.
/// Implementations can be swapped (InMemory, JSON-backed, Remote/Supabase) without changing view models.
///
/// All methods are async and can throw errors. Implementations should handle errors gracefully
/// and provide appropriate logging for debugging.
protocol DataStore {
    // MARK: - Babies
    
    /// Fetch all babies for the current user
    /// - Returns: Array of Baby objects
    /// - Throws: DataStoreError if fetch fails
    func fetchBabies() async throws -> [Baby]
    
    /// Add a new baby to the store
    /// - Parameter baby: Baby object to add
    /// - Throws: DataStoreError if add fails
    func addBaby(_ baby: Baby) async throws
    
    /// Update an existing baby
    /// - Parameter baby: Baby object with updated values
    /// - Throws: DataStoreError if update fails
    func updateBaby(_ baby: Baby) async throws
    
    /// Delete a baby and all associated events
    /// - Parameter baby: Baby object to delete
    /// - Throws: DataStoreError if delete fails
    func deleteBaby(_ baby: Baby) async throws
    
    // MARK: - Events
    
    /// Fetch events for a baby on a specific date
    /// - Parameters:
    ///   - baby: Baby to fetch events for
    ///   - date: Date to fetch events for
    /// - Returns: Array of Event objects sorted by startTime (newest first)
    /// - Throws: DataStoreError if fetch fails
    func fetchEvents(for baby: Baby, on date: Date) async throws -> [Event]
    
    /// Fetch events for a baby within a date range
    /// - Parameters:
    ///   - baby: Baby to fetch events for
    ///   - startDate: Start of date range (inclusive)
    ///   - endDate: End of date range (inclusive)
    /// - Returns: Array of Event objects sorted by startTime (newest first)
    /// - Throws: DataStoreError if fetch fails
    func fetchEvents(for baby: Baby, from startDate: Date, to endDate: Date) async throws -> [Event]
    
    /// Add a new event
    /// - Parameter event: Event object to add
    /// - Throws: DataStoreError or EventValidator errors if add fails
    func addEvent(_ event: Event) async throws
    
    /// Update an existing event
    /// - Parameter event: Event object with updated values
    /// - Throws: DataStoreError or EventValidator errors if update fails
    func updateEvent(_ event: Event) async throws
    
    /// Delete an event
    /// - Parameter event: Event object to delete
    /// - Throws: DataStoreError if delete fails
    func deleteEvent(_ event: Event) async throws
    
    // MARK: - Predictions
    
    /// Fetch a cached prediction for a baby
    /// - Parameters:
    ///   - baby: Baby to fetch prediction for
    ///   - type: Type of prediction (nextNap, nextFeed)
    /// - Returns: Prediction if found, nil otherwise
    /// - Throws: DataStoreError if fetch fails
    func fetchPredictions(for baby: Baby, type: PredictionType) async throws -> Prediction?
    
    /// Generate a new prediction for a baby
    /// - Parameters:
    ///   - baby: Baby to generate prediction for
    ///   - type: Type of prediction to generate
    /// - Returns: New Prediction object
    /// - Throws: DataStoreError if generation fails
    func generatePrediction(for baby: Baby, type: PredictionType) async throws -> Prediction
    
    // MARK: - Settings
    
    /// Fetch app settings
    /// - Returns: AppSettings object (defaults if none exist)
    /// - Throws: DataStoreError if fetch fails
    func fetchAppSettings() async throws -> AppSettings
    
    /// Save app settings
    /// - Parameter settings: AppSettings object to save
    /// - Throws: DataStoreError if save fails
    func saveAppSettings(_ settings: AppSettings) async throws
    
    // MARK: - Active Sleep Tracking
    
    /// Get the currently active sleep event for a baby (if any)
    /// - Parameter baby: Baby to check for active sleep
    /// - Returns: Active Event if found, nil otherwise
    /// - Throws: DataStoreError if fetch fails
    func getActiveSleep(for baby: Baby) async throws -> Event?
    
    /// Start tracking an active sleep session
    /// - Parameter baby: Baby to start sleep tracking for
    /// - Returns: New Event object representing the active sleep
    /// - Throws: DataStoreError if start fails
    func startActiveSleep(for baby: Baby) async throws -> Event
    
    /// Stop tracking an active sleep session
    /// - Parameter baby: Baby to stop sleep tracking for
    /// - Returns: Updated Event object with endTime set
    /// - Throws: DataStoreError if stop fails
    func stopActiveSleep(for baby: Baby) async throws -> Event
    
    // MARK: - Last Used Values
    
    /// Get last used values for an event type (for form pre-filling)
    /// - Parameter eventType: Type of event to get values for
    /// - Returns: LastUsedValues if found, nil otherwise
    /// - Throws: DataStoreError if fetch fails
    func getLastUsedValues(for eventType: EventType) async throws -> LastUsedValues?
    
    /// Save last used values for an event type
    /// - Parameters:
    ///   - eventType: Type of event
    ///   - values: LastUsedValues to save
    /// - Throws: DataStoreError if save fails
    func saveLastUsedValues(for eventType: EventType, values: LastUsedValues) async throws
    
    // MARK: - Data Persistence
    
    /// Force sync any pending changes to disk/remote storage.
    /// Critical for app backgrounding scenarios to ensure data is saved.
    /// - Throws: DataStoreError if sync fails
    func forceSyncIfNeeded() async throws
}

struct LastUsedValues: Codable {
    var amount: Double?
    var unit: String?
    var side: String?
    var subtype: String?
    var durationMinutes: Int?
}

