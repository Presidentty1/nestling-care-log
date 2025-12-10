import Foundation
import AVFoundation

/// Result from cry analysis
struct CryAnalysisResult: Codable {
    let category: CryCategory
    let confidence: Double
    let reasoning: String
    let suggestions: [String]
    let contextInfo: ContextInfo?
    
    struct ContextInfo: Codable {
        let lastFeed: String?
        let lastNap: String?
        let lastDiaper: String?
    }
}

/// Category of cry
enum CryCategory: String, Codable, CaseIterable {
    case hungry
    case tired
    case discomfort
    case pain
    case unsure
    
    var displayName: String {
        switch self {
        case .hungry: return "Hungry"
        case .tired: return "Tired"
        case .discomfort: return "Discomfort"
        case .pain: return "Pain"
        case .unsure: return "Unsure"
        }
    }
    
    var icon: String {
        switch self {
        case .hungry: return "fork.knife"
        case .tired: return "moon.zzz.fill"
        case .discomfort: return "exclamationmark.triangle"
        case .pain: return "cross.case.fill"
        case .unsure: return "questionmark.circle"
        }
    }
    
    var color: String {
        switch self {
        case .hungry: return "eventFeed"
        case .tired: return "eventSleep"
        case .discomfort: return "warning"
        case .pain: return "destructive"
        case .unsure: return "mutedForeground"
        }
    }
}

/// Confidence level
enum ConfidenceLevel: String {
    case low
    case medium
    case high
    
    static func from(value: Double) -> ConfidenceLevel {
        if value >= 0.7 {
            return .high
        } else if value >= 0.4 {
            return .medium
        } else {
            return .low
        }
    }
    
    var displayName: String {
        switch self {
        case .low: return "Low"
        case .medium: return "Medium"
        case .high: return "High"
        }
    }
}

/// Service for analyzing baby cries using AI
@MainActor
class CryAnalysisService {
    static let shared = CryAnalysisService()
    
    private init() {}
    
    /// Analyze a recorded cry
    /// - Parameters:
    ///   - audioData: The recorded audio data
    ///   - baby: The baby being analyzed
    ///   - recentEvents: Recent events for context
    /// - Returns: Analysis result
    func analyzeCry(audioData: Data, baby: Baby, recentEvents: [Event]) async throws -> CryAnalysisResult {
        // Check network connectivity
        guard NetworkMonitor.shared.isConnected else {
            throw CryAnalysisError.offline
        }
        
        // Prepare context
        let context = buildContext(baby: baby, recentEvents: recentEvents)
        
        // Call edge function
        let result = try await callAnalyzeEdgeFunction(audioData: audioData, context: context)
        
        return result
    }
    
    /// Manually label a cry without AI analysis (offline fallback)
    func manualLabel(category: CryCategory, note: String? = nil) -> CryAnalysisResult {
        let suggestions = defaultSuggestions(for: category)
        
        return CryAnalysisResult(
            category: category,
            confidence: 0.5, // Medium confidence for manual labels
            reasoning: "Manually labeled by caregiver",
            suggestions: suggestions,
            contextInfo: nil
        )
    }
    
    // MARK: - Private Methods
    
    private func buildContext(baby: Baby, recentEvents: [Event]) -> [String: Any] {
        let now = Date()
        let calendar = Calendar.current
        
        // Find last feed
        let lastFeed = recentEvents.first { $0.type == .feed }
        let timeSinceLastFeed: Int? = {
            guard let feed = lastFeed else { return nil }
            return calendar.dateComponents([.hour], from: feed.startTime, to: now).hour
        }()
        
        // Find last sleep
        let lastSleep = recentEvents.first { $0.type == .sleep && $0.endTime != nil }
        let lastSleepDuration: Int? = {
            guard let sleep = lastSleep, let endTime = sleep.endTime else { return nil }
            return calendar.dateComponents([.minute], from: sleep.startTime, to: endTime).minute
        }()
        
        // Find last diaper
        let lastDiaper = recentEvents.first { $0.type == .diaper }
        let timeSinceLastDiaper: Int? = {
            guard let diaper = lastDiaper else { return nil }
            return calendar.dateComponents([.hour], from: diaper.startTime, to: now).hour
        }()
        
        // Time of day
        let timeOfDay = calendar.component(.hour, from: now)
        
        return [
            "babyId": baby.id.uuidString,
            "babyAgeInWeeks": calendar.dateComponents([.weekOfYear], from: baby.dateOfBirth, to: now).weekOfYear ?? 0,
            "timeOfDay": timeOfDay,
            "timeSinceLastFeedHours": timeSinceLastFeed as Any,
            "lastSleepDurationMinutes": lastSleepDuration as Any,
            "timeSinceLastDiaperHours": timeSinceLastDiaper as Any
        ]
    }
    
    private func callAnalyzeEdgeFunction(audioData: Data, context: [String: Any]) async throws -> CryAnalysisResult {
        // Construct request to Supabase edge function
        guard let url = URL(string: "\(SupabaseClient.supabaseURL)/functions/v1/analyze-cry-pattern") else {
            throw CryAnalysisError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(SupabaseClient.supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Encode audio as base64
        let base64Audio = audioData.base64EncodedString()
        
        let body: [String: Any] = [
            "audioBase64": base64Audio,
            "context": context
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        // Make request with timeout
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw CryAnalysisError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw CryAnalysisError.serverError(statusCode: httpResponse.statusCode)
        }
        
        // Parse response
        let result = try JSONDecoder().decode(CryAnalysisResult.self, from: data)
        return result
    }
    
    private func defaultSuggestions(for category: CryCategory) -> [String] {
        switch category {
        case .hungry:
            return [
                "Offer a feed - even if it's been less than 2 hours",
                "Check for hunger cues like rooting or sucking on hands",
                "Growth spurts can increase hunger temporarily"
            ]
        case .tired:
            return [
                "Try a nap - even a short 10-15 minute rest can help",
                "Look for sleep cues like yawning, eye rubbing, or staring",
                "Ensure a dark, quiet environment for sleep"
            ]
        case .discomfort:
            return [
                "Check diaper - wetness or tightness can cause discomfort",
                "Check clothing - tags, seams, or temperature",
                "Try gentle rocking, swaying, or white noise"
            ]
        case .pain:
            return [
                "Check for signs of illness: fever, rash, pulling ears",
                "Gently check for trapped gas - try bicycle legs",
                "Contact pediatrician if crying persists or seems severe"
            ]
        case .unsure:
            return [
                "Try the basics: check diaper, offer feed, try sleep",
                "Sometimes babies cry for no clear reason - that's normal",
                "Trust your instincts - contact pediatrician if worried"
            ]
        }
    }
}

// MARK: - Errors

enum CryAnalysisError: LocalizedError {
    case offline
    case invalidURL
    case invalidResponse
    case serverError(statusCode: Int)
    case decodingError
    
    var errorDescription: String? {
        switch self {
        case .offline:
            return "Cry analysis requires an internet connection. You can manually label the cry or try again when online."
        case .invalidURL:
            return "Configuration error. Please contact support."
        case .invalidResponse:
            return "Unexpected response from server. Please try again."
        case .serverError(let statusCode):
            return "Server error (\(statusCode)). Please try again later."
        case .decodingError:
            return "Could not understand server response. Please try again."
        }
    }
}



