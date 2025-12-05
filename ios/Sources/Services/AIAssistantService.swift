import Foundation
import Supabase

/// Protocol for AI Assistant service
protocol AIAssistantServiceProtocol {
    func sendMessage(
        messages: [AIChatMessage],
        baby: Baby?,
        conversationId: String?
    ) async throws -> [AIChatMessage]
}

/// Service for calling Supabase Edge Functions for AI Assistant chat
@MainActor
class AIAssistantService: AIAssistantServiceProtocol {
    static let shared = AIAssistantService()
    
    private let supabaseClient = SupabaseClient.shared
    private let session: URLSession
    private let dataStore: DataStore?
    
    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
        self.dataStore = nil // Will be injected if needed
    }
    
    /// Initialize with DataStore for building baby context
    init(dataStore: DataStore?) {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 60
        config.timeoutIntervalForResource = 120
        self.session = URLSession(configuration: config)
        self.dataStore = dataStore
    }
    
    /// Send message to AI assistant
    /// - Parameters:
    ///   - messages: Conversation history
    ///   - baby: Baby for context (optional)
    ///   - conversationId: Existing conversation ID (optional)
    /// - Returns: Updated messages array with assistant reply
    func sendMessage(
        messages: [AIChatMessage],
        baby: Baby?,
        conversationId: String?
    ) async throws -> [AIChatMessage] {
        guard supabaseClient.isConfigured else {
            throw AIAssistantError.notConfigured
        }
        
        // Build baby context if available
        let babyContext: BabyContext? = try await buildBabyContext(baby: baby)
        
        // Prepare request body matching web format
        var requestBody: [String: Any] = [
            "conversationId": conversationId as Any,
            "messages": messages.map { [
                "role": $0.role.rawValue,
                "content": $0.content
            ]}
        ]
        
        // Add baby context if available
        if let babyContext = babyContext {
            requestBody["babyContext"] = [
                "name": babyContext.name,
                "ageInMonths": babyContext.ageInMonths,
                "recentStats": [
                    "feedsPerDay": babyContext.recentStats.feedsPerDay,
                    "avgSleepHoursPerNight": babyContext.recentStats.avgSleepHoursPerNight,
                    "totalEventsTracked": babyContext.recentStats.totalEventsTracked
                ]
            ]
        }
        
        // Get Supabase URL and key
        guard let urlString = supabaseClient.url,
              let baseURL = URL(string: urlString),
              let functionURL = URL(string: "\(baseURL.absoluteString)/functions/v1/ai-assistant"),
              let anonKey = supabaseClient.anonKey else {
            throw AIAssistantError.notConfigured
        }
        
        // Create request
        var request = URLRequest(url: functionURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        
        // Try to get session token if available
        if let session = try? await supabaseClient.getCurrentSession(),
           let sessionToken = getSessionToken(from: session) {
            request.setValue("Bearer \(sessionToken)", forHTTPHeaderField: "Authorization")
        }
        
        // Encode body
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Make request
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIAssistantError.networkError(NSError(domain: "AIAssistantService", code: -1))
        }
        
        // Handle errors
        if httpResponse.statusCode == 401 {
            throw AIAssistantError.authenticationRequired
        } else if httpResponse.statusCode == 403 {
            throw AIAssistantError.consentRequired
        } else if httpResponse.statusCode == 429 {
            // Free tier limit reached (Epic 7 AC5)
            let errorData = try? JSONDecoder().decode([String: Any].self, from: data)
            let upgradeRequired = errorData?["upgradeRequired"] as? Bool ?? false
            throw AIAssistantError.upgradeRequired(errorData?["error"] as? String ?? "Free tier limit reached")
        } else if httpResponse.statusCode >= 400 {
            let errorData = try? JSONDecoder().decode([String: Any].self, from: data)
            let upgradeRequired = errorData?["upgradeRequired"] as? Bool ?? false
            if upgradeRequired {
                throw AIAssistantError.upgradeRequired(errorData?["error"] as? String ?? "Upgrade required")
            } else {
                throw AIAssistantError.apiError(errorData?["error"] as? String ?? "Unknown error")
            }
        }
        
        // Parse response
        let responseData = try JSONDecoder().decode(AIAssistantResponse.self, from: data)
        
        // Create assistant message
        let assistantMessage = AIChatMessage(
            role: .assistant,
            content: responseData.message,
            createdAt: Date()
        )
        
        // Return updated messages array
        return messages + [assistantMessage]
    }
    
    // MARK: - Helper Methods
    
    /// Build baby context for AI
    private func buildBabyContext(baby: Baby?) async throws -> BabyContext? {
        guard let baby = baby else { return nil }
        
        // Calculate age in months
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.month], from: baby.dateOfBirth, to: Date())
        let ageInMonths = ageComponents.month ?? 0
        
        // Fetch recent events from DataStore if available
        var feedCount = 0
        var sleepEvents: [Event] = []
        var totalEvents = 0
        
        if let dataStore = dataStore {
            do {
                // Get events from last 7 days
                let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                let recentEvents = try await dataStore.fetchEvents(for: baby, from: sevenDaysAgo, to: Date())
                totalEvents = recentEvents.count
                
                // Count feeds
                feedCount = recentEvents.filter { $0.type == .feed }.count
                
                // Get sleep events with end time
                sleepEvents = recentEvents.filter { $0.type == .sleep && $0.endTime != nil }
            } catch {
                // If fetching fails, continue with basic context
                Logger.dataError("Error fetching events for baby context: \(error.localizedDescription)")
            }
        }
        
        // Calculate average sleep hours
        var avgSleepHours: Double = 0
        if !sleepEvents.isEmpty {
            let totalSleepHours = sleepEvents.reduce(0.0) { total, event in
                guard let endTime = event.endTime else { return total }
                let duration = endTime.timeIntervalSince(event.startTime) / 3600.0
                return total + duration
            }
            avgSleepHours = totalSleepHours / Double(sleepEvents.count)
        }
        
        return BabyContext(
            name: baby.name,
            ageInMonths: ageInMonths,
            recentStats: BabyContext.RecentStats(
                feedsPerDay: String(format: "%.1f", Double(feedCount) / 7.0),
                avgSleepHoursPerNight: String(format: "%.1f", avgSleepHours),
                totalEventsTracked: totalEvents
            )
        )
    }
    
    /// Extract session token from session object
    private func getSessionToken(from session: Session) -> String? {
        return session.accessToken
    }
}

// MARK: - Response Models

struct AIAssistantResponse: Codable {
    let message: String
    let conversationId: String?
    let timestamp: String?
    
    enum CodingKeys: String, CodingKey {
        case message
        case conversationId
        case timestamp
    }
}

// MARK: - Errors

enum AIAssistantError: LocalizedError {
    case notConfigured
    case authenticationRequired
    case consentRequired
    case upgradeRequired(String) // Epic 7: Paywall trigger
    case networkError(Error)
    case apiError(String)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase is not configured. Please check your settings."
        case .authenticationRequired:
            return "Authentication required to use AI features"
        case .consentRequired:
            return "AI features are disabled. Enable in Settings → AI & Data Sharing."
        case .upgradeRequired(let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .apiError(let message):
            return message
        }
    }
}

