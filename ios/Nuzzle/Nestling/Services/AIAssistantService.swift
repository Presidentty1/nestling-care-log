import Foundation
import Supabase

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
        if !provider.isConfigured {
            // Demo Mode Fallback
            try? await Task.sleep(nanoseconds: 1_000_000_000) // Simulate delay
            
            let now = Date()
            let nextNapStart = now.addingTimeInterval(3600) // 1 hour from now
            let nextNapEnd = nextNapStart.addingTimeInterval(2700) // 45 min nap
            
            return PredictionResponse(
                predictionId: UUID().uuidString,
                predictionType: predictionType,
                confidence: 0.85,
                prediction: PredictionResponse.PredictionData(
                    nextNapWindow: PredictionResponse.NapWindow(
                        start: ISO8601DateFormatter().string(from: nextNapStart),
                        end: ISO8601DateFormatter().string(from: nextNapEnd),
                        confidence: 0.85
                    ),
                    feedingPattern: nil,
                    insights: ["Demo: Baby tends to nap around this time."]
                ),
                generatedAt: ISO8601DateFormatter().string(from: now)
            )
        }
        
        do {
            // Verify AI consent first
            let hasConsent = try await checkAIConsent()
            guard hasConsent else {
                throw AIError.consentRequired
            }
            
            guard let client = provider.client else {
                throw AIError.notConfigured
            }
            
            let requestBody = GeneratePredictionBody(
                babyId: babyId.uuidString,
                predictionType: predictionType,
                lookbackDays: String(lookbackDays)
            )
            
            let response: PredictionResponse = try await client.functions.invoke(
                "generate-predictions",
                options: FunctionInvokeOptions(body: requestBody)
            )
            
            return response
        } catch {
            if error is AIError {
                throw error
            }
            throw AIError.networkError(error)
        }
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
        if !provider.isConfigured {
            // Demo Mode Fallback
            try? await Task.sleep(nanoseconds: 2_000_000_000) // Simulate processing
            
            return CryAnalysisResponse(
                sessionId: UUID().uuidString,
                category: "hungry",
                confidence: 0.92,
                suggestions: ["Demo: Offer a feed", "Check for hunger cues"],
                detectedAt: ISO8601DateFormatter().string(from: Date())
            )
        }
        
        do {
            // Verify AI consent first
            let hasConsent = try await checkAIConsent()
            guard hasConsent else {
                throw AIError.consentRequired
            }
            
            guard let client = provider.client else {
                throw AIError.notConfigured
            }
            
            let contextBody: AnalyzeCryBody.CryContextBody? = context.map { ctx in
                AnalyzeCryBody.CryContextBody(
                    timeSinceLastFeed: ctx.timeSinceLastFeed.map { String($0) },
                    timeSinceLastSleep: ctx.timeSinceLastSleep.map { String($0) },
                    timeSinceLastDiaper: ctx.timeSinceLastDiaper.map { String($0) }
                )
            }
            
            let requestBody = AnalyzeCryBody(
                babyId: babyId.uuidString,
                audioBase64: audioBase64,
                duration: duration.map { String($0) },
                context: contextBody
            )
            
            let response: CryAnalysisResponse = try await client.functions.invoke(
                "analyze-cry-pattern",
                options: FunctionInvokeOptions(body: requestBody)
            )
            
            return response
        } catch {
            if error is AIError {
                throw error
            }
            throw AIError.networkError(error)
        }
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
        if !provider.isConfigured {
            // Demo Mode Fallback
            try? await Task.sleep(nanoseconds: 1_000_000_000) // Simulate delay
            
            return AIAssistantResponse(
                conversationId: conversationId ?? UUID().uuidString,
                message: "Demo: I'm Nuzzle's AI assistant. I can help with general baby care questions.",
                timestamp: ISO8601DateFormatter().string(from: Date()),
                disclaimer: "Demo Mode: This is a simulated response."
            )
        }
        
        do {
            // Verify AI consent first
            let hasConsent = try await checkAIConsent()
            guard hasConsent else {
                throw AIError.consentRequired
            }
            
            guard let client = provider.client else {
                throw AIError.notConfigured
            }
            
            let requestBody = AIAssistantBody(
                message: message,
                babyId: babyId?.uuidString,
                conversationId: conversationId
            )
            
            let response: AIAssistantResponse = try await client.functions.invoke(
                "ai-assistant",
                options: FunctionInvokeOptions(body: requestBody)
            )
            
            return response
        } catch {
            if error is AIError {
                throw error
            }
            throw AIError.networkError(error)
        }
    }
    
    // MARK: - Helper Methods
    
    /// Check if user has AI consent enabled
    private func checkAIConsent() async throws -> Bool {
        if !provider.isConfigured {
            return true // Allow in demo mode
        }
        
        guard let client = provider.client else {
            return true // Allow in demo mode if client not available
        }
        
        let session = try await client.auth.session
        
        let response: ProfileDTO = try await client
            .from("profiles")
            .select("ai_data_sharing_enabled")
            .eq("id", value: session.user.id.uuidString)
            .single()
            .execute()
            .value
        
        return response.aiDataSharingEnabled ?? false
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

// MARK: - Function Request Bodies (Encodable)

struct GeneratePredictionBody: Encodable {
    let babyId: String
    let predictionType: String
    let lookbackDays: String
}

struct AnalyzeCryBody: Encodable {
    let babyId: String
    let audioBase64: String?
    let duration: String?
    let context: CryContextBody?
    
    struct CryContextBody: Encodable {
        let timeSinceLastFeed: String?
        let timeSinceLastSleep: String?
        let timeSinceLastDiaper: String?
    }
}

struct AIAssistantBody: Encodable {
    let message: String
    let babyId: String?
    let conversationId: String?
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

