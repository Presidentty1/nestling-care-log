import Foundation

/// Builder for AI assistant context from baby data and recent events
struct AIContextBuilder {
    /// Build context for AI assistant from baby and recent events
    /// - Parameters:
    ///   - baby: The baby to build context for
    ///   - recentEvents: Events from the last 24-48 hours
    /// - Returns: Dictionary of context data for AI prompt
    static func buildContext(baby: Baby, recentEvents: [Event]) -> [String: Any] {
        let calendar = Calendar.current
        let now = Date()
        
        // Baby age
        let ageComponents = calendar.dateComponents([.month, .weekOfYear], from: baby.dateOfBirth, to: now)
        let ageInMonths = ageComponents.month ?? 0
        let ageInWeeks = ageComponents.weekOfYear ?? 0
        
        // Last feed
        let lastFeed = recentEvents.first { $0.type == .feed }
        let lastFeedText: String? = {
            guard let feed = lastFeed else { return nil }
            let hoursAgo = calendar.dateComponents([.hour], from: feed.startTime, to: now).hour ?? 0
            let amount = feed.amount.map { "\(Int($0))\(feed.unit ?? "ml")" } ?? "unknown amount"
            return "\(hoursAgo) hours ago, \(amount)"
        }()
        
        // Recent sleep
        let recentSleeps = recentEvents.filter { $0.type == .sleep && $0.endTime != nil }
        let totalSleepMinutes = recentSleeps.reduce(0) { sum, event in
            guard let endTime = event.endTime else { return sum }
            let duration = calendar.dateComponents([.minute], from: event.startTime, to: endTime).minute ?? 0
            return sum + duration
        }
        
        let lastSleep = recentSleeps.first
        let lastSleepText: String? = {
            guard let sleep = lastSleep, let endTime = sleep.endTime else { return nil }
            let hoursAgo = calendar.dateComponents([.hour], from: endTime, to: now).hour ?? 0
            let duration = calendar.dateComponents([.minute], from: sleep.startTime, to: endTime).minute ?? 0
            return "\(hoursAgo) hours ago, duration \(duration) minutes"
        }()
        
        // Recent diapers
        let recentDiapers = recentEvents.filter { $0.type == .diaper }
        let lastDiaper = recentDiapers.first
        let lastDiaperText: String? = {
            guard let diaper = lastDiaper else { return nil }
            let hoursAgo = calendar.dateComponents([.hour], from: diaper.startTime, to: now).hour ?? 0
            return "\(hoursAgo) hours ago, \(diaper.subtype ?? "unknown type")"
        }()
        
        // Feed count today
        let todayStart = calendar.startOfDay(for: now)
        let feedsToday = recentEvents.filter { $0.type == .feed && $0.startTime >= todayStart }.count
        
        // Sleep count today
        let napsToday = recentEvents.filter { $0.type == .sleep && $0.startTime >= todayStart }.count
        
        // Diaper count today
        let diapersToday = recentEvents.filter { $0.type == .diaper && $0.startTime >= todayStart }.count
        
        var context: [String: Any] = [
            "babyName": baby.name,
            "babyAgeMonths": ageInMonths,
            "babyAgeWeeks": ageInWeeks,
            "feedsToday": feedsToday,
            "napsToday": napsToday,
            "diapersToday": diapersToday,
            "totalSleepMinutes": totalSleepMinutes,
            "eventCount": recentEvents.count
        ]
        
        if let lastFeedText = lastFeedText {
            context["lastFeed"] = lastFeedText
        }
        
        if let lastSleepText = lastSleepText {
            context["lastSleep"] = lastSleepText
        }
        
        if let lastDiaperText = lastDiaperText {
            context["lastDiaper"] = lastDiaperText
        }
        
        return context
    }
    
    /// Build prompt with context for AI
    static func buildPrompt(question: String, baby: Baby, recentEvents: [Event]) -> String {
        let context = buildContext(baby: baby, recentEvents: recentEvents)
        
        var prompt = """
        You are a supportive parenting assistant helping with baby care questions.
        
        Baby Profile:
        - Name: \(baby.name)
        - Age: \(context["babyAgeMonths"] as? Int ?? 0) months (\(context["babyAgeWeeks"] as? Int ?? 0) weeks)
        
        Today's Activity:
        - Feeds: \(context["feedsToday"] as? Int ?? 0)
        - Naps: \(context["napsToday"] as? Int ?? 0)
        - Diapers: \(context["diapersToday"] as? Int ?? 0)
        """
        
        if let lastFeed = context["lastFeed"] as? String {
            prompt += "\n- Last feed: \(lastFeed)"
        }
        
        if let lastSleep = context["lastSleep"] as? String {
            prompt += "\n- Last sleep: \(lastSleep)"
        }
        
        if let lastDiaper = context["lastDiaper"] as? String {
            prompt += "\n- Last diaper: \(lastDiaper)"
        }
        
        prompt += """
        
        
        User Question: \(question)
        
        Guidelines:
        - Provide short, readable responses (2-3 paragraphs max)
        - Reference specific data when relevant: "Based on the last 3 naps..."
        - For topics like fever, breathing difficulty, dehydration, lethargy, or pain, include: "This sounds serious. Please contact your pediatrician immediately."
        - Never diagnose or prescribe treatment
        - Use supportive, non-judgmental language
        - If unsure, admit it and suggest consulting a pediatrician
        """
        
        return prompt
    }
    
    /// Detect if a message contains red-flag topics requiring medical attention
    static func containsRedFlag(_ text: String) -> Bool {
        let redFlagKeywords = [
            "fever", "temperature", "breathing", "breath", "breathe",
            "dehydration", "dehydrated", "lethargic", "lethargy",
            "pain", "hurt", "ache", "blood", "vomit", "emergency",
            "rash", "seizure", "unresponsive", "unconscious"
        ]
        
        let lowercased = text.lowercased()
        return redFlagKeywords.contains { lowercased.contains($0) }
    }
}
