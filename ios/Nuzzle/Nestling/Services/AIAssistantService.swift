import Foundation
// TODO: Uncomment when Supabase Swift SDK is added
// import Supabase

/// Service for calling Supabase Edge Functions for AI features.
/// 
/// Handles:
/// - generate-predictions: Nap and feeding predictions
/// - analyze-cry-pattern: Cry analysis
/// - ai-assistant: General Q&A
///
/// All functions respect AI consent (check `ai_data_sharing_enabled` flag).
@MainActor
class AIAssistantService {
    static let shared = AIAssistantService()
    
    private let provider = SupabaseClientProvider.shared
    
    private init() {}
    
    // MARK: - Predictions
    
    /// Generate AI prediction for baby care
    /// - Parameters:
    ///   - babyId: Baby UUID
    ///   - predictionType: Type of prediction (nap_window, feeding_pattern, etc.)
    ///   - lookbackDays: Number of days to look back (default: 7)
    /// - Returns: Prediction result with confidence and insights
    func generatePrediction(
        babyId: UUID,
        predictionType: String,
        lookbackDays: Int = 7
    ) async throws -> PredictionResponse {
        guard provider.isConfigured else {
            throw AIError.notConfigured
        }
        
        // TODO: Uncomment when Supabase Swift SDK is added
        // do {
        //     // Verify AI consent first
        //     let hasConsent = try await checkAIConsent()
        //     guard hasConsent else {
        //         throw AIError.consentRequired
        //     }
        //     
        //     let response = try await provider.client.functions.invoke(
        //         "generate-predictions",
        //         options: FunctionInvokeOptions(
        //             body: [
        //                 "babyId": babyId.uuidString,
        //                 "predictionType": predictionType,
        //                 "lookbackDays": lookbackDays
        //             ]
        //         )
        //     )
        //     
        //     return try JSONDecoder().decode(PredictionResponse.self, from: response.data)
        // } catch {
        //     if error is AIError {
        //         throw error
        //     }
        //     throw AIError.networkError(error)
        // }
        
        throw AIError.notImplemented("AI features require Supabase SDK - see SUPABASE_SETUP.md")
    }
    
    // MARK: - Cry Analysis
    
    /// Analyze baby cry pattern
    /// - Parameters:
    ///   - babyId: Baby UUID
    ///   - audioBase64: Base64 encoded audio (optional)
    ///   - duration: Cry duration in seconds (optional)
    ///   - context: Context information (time since last feed, sleep, etc.)
    /// - Returns: Analysis result with category, confidence, and suggestions
    func analyzeCry(
        babyId: UUID,
        audioBase64: String? = nil,
        duration: Int? = nil,
        context: CryAnalysisContext? = nil
    ) async throws -> CryAnalysisResponse {
        guard provider.isConfigured else {
            throw AIError.notConfigured
        }
        
        // TODO: Uncomment when Supabase Swift SDK is added
        // do {
        //     // Verify AI consent first
        //     let hasConsent = try await checkAIConsent()
        //     guard hasConsent else {
        //         throw AIError.consentRequired
        //     }
        //     
        //     var body: [String: Any] = ["babyId": babyId.uuidString]
        //     if let audioBase64 = audioBase64 {
        //         body["audioBase64"] = audioBase64
        //     }
        //     if let duration = duration {
        //         body["duration"] = duration
        //     }
        //     if let context = context {
        //         body["context"] = [
        //             "timeSinceLastFeed": context.timeSinceLastFeed,
        //             "timeSinceLastSleep": context.timeSinceLastSleep,
        //             "timeSinceLastDiaper": context.timeSinceLastDiaper
        //         ]
        //     }
        //     
        //     let response = try await provider.client.functions.invoke(
        //         "analyze-cry-pattern",
        //         options: FunctionInvokeOptions(body: body)
        //     )
        //     
        //     return try JSONDecoder().decode(CryAnalysisResponse.self, from: response.data)
        // } catch {
        //     if error is AIError {
        //         throw error
        //     }
        //     throw AIError.networkError(error)
        // }
        
        throw AIError.notImplemented("AI features require Supabase SDK - see SUPABASE_SETUP.md")
    }
    
    // MARK: - AI Assistant Chat
    
    /// Send message to AI assistant
    /// - Parameters:
    ///   - message: User's question
    ///   - babyId: Baby UUID for context
    ///   - conversationId: Optional conversation ID to continue thread
    /// - Returns: AI response with message and conversation ID
    func askAssistant(
        message: String,
        babyId: UUID?,
        conversationId: String? = nil
    ) async throws -> AIAssistantResponse {
        guard provider.isConfigured else {
            throw AIError.notConfigured
        }
        
        // TODO: Uncomment when Supabase Swift SDK is added
        // do {
        //     // Verify AI consent first
        //     let hasConsent = try await checkAIConsent()
        //     guard hasConsent else {
        //         throw AIError.consentRequired
        //     }
        //     
        //     var body: [String: Any] = ["message": message]
        //     if let babyId = babyId {
        //         body["babyId"] = babyId.uuidString
        //     }
        //     if let conversationId = conversationId {
        //         body["conversationId"] = conversationId
        //     }
        //     
        //     let response = try await provider.client.functions.invoke(
        //         "ai-assistant",
        //         options: FunctionInvokeOptions(body: body)
        //     )
        //     
        //     return try JSONDecoder().decode(AIAssistantResponse.self, from: response.data)
        // } catch {
        //     if error is AIError {
        //         throw error
        //     }
        //     throw AIError.networkError(error)
        // }
        
        throw AIError.notImplemented("AI features require Supabase SDK - see SUPABASE_SETUP.md")
    }
    
    // MARK: - Helper Methods
    
    /// Check if user has AI consent enabled
    private func checkAIConsent() async throws -> Bool {
        // TODO: Uncomment when Supabase Swift SDK is added
        // let session = try await provider.getCurrentSession()
        // guard let session = session else {
        //     throw AIError.authenticationRequired
        // }
        // 
        // let response = try await provider.client.database
        //     .from("profiles")
        //     .select("ai_data_sharing_enabled")
        //     .eq("id", value: session.userId.uuidString)
        //     .single()
        //     .execute()
        // 
        // let profile = try JSONDecoder().decode(ProfileDTO.self, from: response.data)
        // return profile.aiDataSharingEnabled ?? false
        
        return false
    }
}

// MARK: - Response Models

struct PredictionResponse: Codable {
    let predictionId: String
    let predictionType: String
    let confidence: Double
    let prediction: PredictionData
    let generatedAt: String
    
    struct PredictionData: Codable {
        let nextNapWindow: NapWindow?
        let feedingPattern: FeedingPattern?
        let insights: [String]
        
        enum CodingKeys: String, CodingKey {
            case nextNapWindow = "next_nap_window"
            case feedingPattern = "feeding_pattern"
            case insights
        }
    }
    
    struct NapWindow: Codable {
        let start: String // ISO timestamp
        let end: String // ISO timestamp
        let confidence: Double
    }
    
    struct FeedingPattern: Codable {
        let averageInterval: Int // minutes
        let nextFeedTime: String // ISO timestamp
        let confidence: Double
    }
}

struct CryAnalysisResponse: Codable {
    let sessionId: String
    let category: String // hungry, tired, discomfort, pain, unknown
    let confidence: Double
    let suggestions: [String]
    let detectedAt: String
}

struct AIAssistantResponse: Codable {
    let conversationId: String
    let message: String
    let timestamp: String
    let disclaimer: String?
}

struct CryAnalysisContext {
    let timeSinceLastFeed: Int? // minutes
    let timeSinceLastSleep: Int? // minutes
    let timeSinceLastDiaper: Int? // minutes
}

struct ProfileDTO: Codable {
    let aiDataSharingEnabled: Bool?
    
    enum CodingKeys: String, CodingKey {
        case aiDataSharingEnabled = "ai_data_sharing_enabled"
    }
}

// MARK: - Errors

enum AIError: LocalizedError {
    case notConfigured
    case consentRequired
    case authenticationRequired
    case notImplemented(String)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase is not configured. Please check SUPABASE_URL and SUPABASE_ANON_KEY environment variables"
        case .consentRequired:
            return "AI features are disabled. Enable in Settings → AI & Data Sharing."
        case .authenticationRequired:
            return "Authentication required to use AI features"
        case .notImplemented(let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

