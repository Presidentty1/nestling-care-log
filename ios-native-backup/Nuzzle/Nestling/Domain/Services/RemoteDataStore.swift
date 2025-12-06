import Foundation
// TODO: Uncomment when Supabase Swift SDK is added via SPM
// import Supabase

/// Supabase-backed implementation of DataStore for cloud sync.
/// Requires Supabase Swift SDK and authentication.
///
/// Usage:
/// ```swift
/// let remoteStore = RemoteDataStore()
/// let environment = AppEnvironment(dataStore: remoteStore)
/// ```
///
/// Setup Steps:
/// 1. Add Supabase Swift SDK via SPM (see SUPABASE_SETUP.md)
/// 2. Configure SUPABASE_URL and SUPABASE_ANON_KEY environment variables
/// 3. Uncomment import Supabase and client initialization code
/// 4. Implement authentication flow (see Phase 1.2)
class RemoteDataStore: DataStore {
    // MARK: - Properties
    
    private let provider = SupabaseClientProvider.shared
    
    // TODO: Uncomment when Supabase Swift SDK is added
    // private var client: SupabaseClient {
    //     provider.client
    // }
    
    private var currentUserId: UUID? // Set after authentication
    private var currentFamilyId: UUID? // Set after authentication
    
    // MARK: - Initialization
    
    init() {
        // Verify Supabase is configured
        if !provider.isConfigured {
            print("⚠️ WARNING: SupabaseClientProvider is not configured. Please check SUPABASE_URL and SUPABASE_ANON_KEY environment variables")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Get current user ID from session
    private func getCurrentUserId() async throws -> UUID {
        guard let userId = currentUserId else {
            // TODO: Get from auth session when SDK is added
            // let session = try await provider.getCurrentSession()
            // guard let session = session as? Session else {
            //     throw DataStoreError.authenticationRequired
            // }
            // currentUserId = UUID(uuidString: session.user.id.uuidString)
            // return currentUserId!
            
            throw DataStoreError.authenticationRequired
        }
        return userId
    }
    
    /// Get current family ID (fetched once and cached)
    private func getCurrentFamilyId() async throws -> UUID {
        if let familyId = currentFamilyId {
            return familyId
        }
        
        // TODO: Query family_members table to get user's family_id when SDK is added
        // let userId = try await getCurrentUserId()
        // let response = try await client.database
        //     .from("family_members")
        //     .select("family_id")
        //     .eq("user_id", userId.uuidString)
        //     .single()
        //     .execute()
        // let familyMember = try JSONDecoder().decode(FamilyMemberDTO.self, from: response.data)
        // currentFamilyId = familyMember.familyId
        // return currentFamilyId!
        
        throw DataStoreError.authenticationRequired
    }
    
    /// JSON encoder configured for Supabase
    private var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
    
    /// JSON decoder configured for Supabase
    private var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
    
    // MARK: - Babies
    
    func fetchBabies() async throws -> [Baby] {
        guard provider.isConfigured else {
            throw DataStoreError.authenticationRequired
        }
        
        let familyId = try await getCurrentFamilyId()
        
        // TODO: Uncomment when Supabase Swift SDK is added
        // let response = try await client.database
        //     .from("babies")
        //     .select()
        //     .eq("family_id", value: familyId.uuidString)
        //     .order("created_at", ascending: false)
        //     .execute()
        // 
        // let babyDTOs = try jsonDecoder.decode([BabyDTO].self, from: response.data)
        // return babyDTOs.map { $0.toBaby() }
        
        throw DataStoreError.notImplemented("RemoteDataStore requires Supabase SDK - see SUPABASE_SETUP.md")
    }
    
    func addBaby(_ baby: Baby) async throws {
        guard provider.isConfigured else {
            throw DataStoreError.authenticationRequired
        }
        
        let familyId = try await getCurrentFamilyId()
        let babyDTO = BabyDTO.from(baby, familyId: familyId)
        let babyData = try jsonEncoder.encode(babyDTO)
        let babyDict = try JSONSerialization.jsonObject(with: babyData) as? [String: Any] ?? [:]
        
        // TODO: Uncomment when Supabase Swift SDK is added
        // try await client.database
        //     .from("babies")
        //     .insert(babyDict)
        //     .execute()
        
        throw DataStoreError.notImplemented("RemoteDataStore requires Supabase SDK - see SUPABASE_SETUP.md")
    }
    
    func updateBaby(_ baby: Baby) async throws {
        guard provider.isConfigured else {
            throw DataStoreError.authenticationRequired
        }
        
        let familyId = try await getCurrentFamilyId()
        var babyDTO = BabyDTO.from(baby, familyId: familyId)
        babyDTO = BabyDTO(
            id: babyDTO.id,
            familyId: babyDTO.familyId,
            name: babyDTO.name,
            dateOfBirth: babyDTO.dateOfBirth,
            dueDate: babyDTO.dueDate,
            sex: babyDTO.sex,
            timezone: babyDTO.timezone,
            primaryFeedingStyle: babyDTO.primaryFeedingStyle,
            createdAt: babyDTO.createdAt,
            updatedAt: Date() // Update timestamp
        )
        
        let babyData = try jsonEncoder.encode(babyDTO)
        let babyDict = try JSONSerialization.jsonObject(with: babyData) as? [String: Any] ?? [:]
        
        // TODO: Uncomment when Supabase Swift SDK is added
        // try await client.database
        //     .from("babies")
        //     .update(babyDict)
        //     .eq("id", value: baby.id.uuidString)
        //     .execute()
        
        throw DataStoreError.notImplemented("RemoteDataStore requires Supabase SDK - see SUPABASE_SETUP.md")
    }
    
    func deleteBaby(_ baby: Baby) async throws {
        guard provider.isConfigured else {
            throw DataStoreError.authenticationRequired
        }
        
        // TODO: Uncomment when Supabase Swift SDK is added
        // try await client.database
        //     .from("babies")
        //     .delete()
        //     .eq("id", value: baby.id.uuidString)
        //     .execute()
        
        throw DataStoreError.notImplemented("RemoteDataStore requires Supabase SDK - see SUPABASE_SETUP.md")
    }
    
    // MARK: - Events
    
    func fetchEvents(for baby: Baby, on date: Date) async throws -> [Event] {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        
        return try await fetchEvents(for: baby, from: startOfDay, to: endOfDay)
    }
    
    func fetchEvents(for baby: Baby, from startDate: Date, to endDate: Date) async throws -> [Event] {
        guard provider.isConfigured else {
            throw DataStoreError.authenticationRequired
        }
        
        let familyId = try await getCurrentFamilyId()
        let userId = try await getCurrentUserId()
        
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // TODO: Uncomment when Supabase Swift SDK is added
        // let response = try await client.database
        //     .from("events")
        //     .select()
        //     .eq("baby_id", value: baby.id.uuidString)
        //     .eq("family_id", value: familyId.uuidString)
        //     .gte("start_time", value: dateFormatter.string(from: startDate))
        //     .lt("start_time", value: dateFormatter.string(from: endDate))
        //     .order("start_time", ascending: false)
        //     .execute()
        // 
        // let eventDTOs = try jsonDecoder.decode([EventDTO].self, from: response.data)
        // return eventDTOs.map { $0.toEvent() }
        
        throw DataStoreError.notImplemented("RemoteDataStore requires Supabase SDK - see SUPABASE_SETUP.md")
    }
    
    func addEvent(_ event: Event) async throws {
        // Validate event before saving
        try EventValidator.validate(event)
        
        guard provider.isConfigured else {
            throw DataStoreError.authenticationRequired
        }
        
        let familyId = try await getCurrentFamilyId()
        let userId = try await getCurrentUserId()
        let eventDTO = EventDTO.from(event, familyId: familyId, userId: userId)
        let eventData = try jsonEncoder.encode(eventDTO)
        let eventDict = try JSONSerialization.jsonObject(with: eventData) as? [String: Any] ?? [:]
        
        // TODO: Uncomment when Supabase Swift SDK is added
        // try await client.database
        //     .from("events")
        //     .insert(eventDict)
        //     .execute()
        
        throw DataStoreError.notImplemented("RemoteDataStore requires Supabase SDK - see SUPABASE_SETUP.md")
    }
    
    func updateEvent(_ event: Event) async throws {
        // Validate event before saving
        try EventValidator.validate(event)
        
        guard provider.isConfigured else {
            throw DataStoreError.authenticationRequired
        }
        
        let familyId = try await getCurrentFamilyId()
        let userId = try await getCurrentUserId()
        var eventDTO = EventDTO.from(event, familyId: familyId, userId: userId)
        
        // Update timestamp
        eventDTO = EventDTO(
            id: eventDTO.id,
            familyId: eventDTO.familyId,
            babyId: eventDTO.babyId,
            type: eventDTO.type,
            subtype: eventDTO.subtype,
            startTime: eventDTO.startTime,
            endTime: eventDTO.endTime,
            amount: eventDTO.amount,
            unit: eventDTO.unit,
            side: eventDTO.side,
            note: eventDTO.note,
            createdBy: eventDTO.createdBy,
            createdAt: eventDTO.createdAt,
            updatedAt: Date()
        )
        
        let eventData = try jsonEncoder.encode(eventDTO)
        let eventDict = try JSONSerialization.jsonObject(with: eventData) as? [String: Any] ?? [:]
        
        // TODO: Uncomment when Supabase Swift SDK is added
        // try await client.database
        //     .from("events")
        //     .update(eventDict)
        //     .eq("id", value: event.id.uuidString)
        //     .execute()
        
        throw DataStoreError.notImplemented("RemoteDataStore requires Supabase SDK - see SUPABASE_SETUP.md")
    }
    
    func deleteEvent(_ event: Event) async throws {
        guard provider.isConfigured else {
            throw DataStoreError.authenticationRequired
        }
        
        // TODO: Uncomment when Supabase Swift SDK is added
        // try await client.database
        //     .from("events")
        //     .delete()
        //     .eq("id", value: event.id.uuidString)
        //     .execute()
        
        throw DataStoreError.notImplemented("RemoteDataStore requires Supabase SDK - see SUPABASE_SETUP.md")
    }
    
    // MARK: - Predictions
    
    func fetchPredictions(for baby: Baby, type: PredictionType) async throws -> Prediction? {
        // TODO: Query predictions table
        throw DataStoreError.notImplemented("RemoteDataStore requires Supabase SDK")
    }
    
    func generatePrediction(for baby: Baby, type: PredictionType) async throws -> Prediction {
        // Call Supabase edge function
        // Example:
        // let response = try await supabaseClient.functions
        //     .invoke("generate-predictions", body: [
        //         "babyId": baby.id.uuidString,
        //         "predictionType": type.rawValue
        //     ])
        // return try JSONDecoder().decode(Prediction.self, from: response.data)
        
        throw DataStoreError.notImplemented("RemoteDataStore requires Supabase SDK")
    }
    
    // MARK: - Settings
    
    func fetchAppSettings() async throws -> AppSettings {
        // TODO: Query app_settings table or profiles table
        // Example:
        // let response = try await supabaseClient.database
        //     .from("app_settings")
        //     .select()
        //     .eq("user_id", currentUserId)
        //     .single()
        //     .execute()
        // return try JSONDecoder().decode(AppSettings.self, from: response.data)
        
        throw DataStoreError.notImplemented("RemoteDataStore requires Supabase SDK")
    }
    
    func saveAppSettings(_ settings: AppSettings) async throws {
        // TODO: Upsert app_settings table
        throw DataStoreError.notImplemented("RemoteDataStore requires Supabase SDK")
    }
    
    // MARK: - Active Sleep Tracking
    
    func getActiveSleep(for baby: Baby) async throws -> Event? {
        // Query for active sleep event (no end_time)
        // Example:
        // let response = try await supabaseClient.database
        //     .from("events")
        //     .select()
        //     .eq("baby_id", baby.id.uuidString)
        //     .eq("type", "sleep")
        //     .is("end_time", value: nil)
        //     .single()
        //     .execute()
        // return try JSONDecoder().decode(Event.self, from: response.data)
        
        throw DataStoreError.notImplemented("RemoteDataStore requires Supabase SDK")
    }
    
    func startActiveSleep(for baby: Baby) async throws -> Event {
        let sleepEvent = Event(
            id: UUID(),
            babyId: baby.id,
            type: .sleep,
            subtype: "nap",
            startTime: Date(),
            endTime: nil,
            amount: nil,
            unit: nil,
            side: nil,
            note: nil,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        try await addEvent(sleepEvent)
        return sleepEvent
    }
    
    func stopActiveSleep(for baby: Baby) async throws -> Event {
        guard var activeSleep = try await getActiveSleep(for: baby) else {
            throw DataStoreError.notFound("No active sleep found")
        }
        
        // Update event with end time
        let updatedEvent = Event(
            id: activeSleep.id,
            babyId: activeSleep.babyId,
            type: activeSleep.type,
            subtype: activeSleep.subtype,
            startTime: activeSleep.startTime,
            endTime: Date(),
            amount: Date().timeIntervalSince(activeSleep.startTime) / 60, // Duration in minutes
            unit: "min",
            side: activeSleep.side,
            note: activeSleep.note,
            createdAt: activeSleep.createdAt,
            updatedAt: Date()
        )
        
        try await updateEvent(updatedEvent)
        return updatedEvent
    }
    
    // MARK: - Last Used Values
    
    func getLastUsedValues(for eventType: EventType) async throws -> LastUsedValues? {
        // TODO: Query last_used_values table
        throw DataStoreError.notImplemented("RemoteDataStore requires Supabase SDK")
    }
    
    func saveLastUsedValues(for eventType: EventType, values: LastUsedValues) async throws {
        // TODO: Upsert last_used_values table
        throw DataStoreError.notImplemented("RemoteDataStore requires Supabase SDK")
    }
}

// MARK: - DataStoreError

enum DataStoreError: LocalizedError {
    case notImplemented(String)
    case notFound(String)
    case networkError(Error)
    case authenticationRequired
    
    var errorDescription: String? {
        switch self {
        case .notImplemented(let message):
            return "Not implemented: \(message)"
        case .notFound(let message):
            return "Not found: \(message)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .authenticationRequired:
            return "Authentication required"
        }
    }
}

