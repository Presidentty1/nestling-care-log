import Foundation

/// Service for generating nap predictions based on baby's sleep patterns and age
class NapPredictionService {
    private let dataStore: DataStore

    init(dataStore: DataStore) {
        self.dataStore = dataStore
    }

    /// Generate a nap suggestion for the given baby
    /// - Parameter baby: The baby to generate a suggestion for
    /// - Returns: A NapSuggestion if enough data is available, nil otherwise
    func generateSuggestion(for baby: Baby) async throws -> NapSuggestion? {
        // Check if we have enough recent sleep data (last 3 days)
        let hasEnoughData = try await hasRecentSleepData(for: baby)
        if !hasEnoughData {
            return nil
        }

        // Analyze recent wake patterns
        let wakeTime = try await findLastWakeTime(for: baby)
        guard let wakeTime = wakeTime else {
            return nil
        }

        // Calculate suggested nap window based on baby's age
        let suggestedWindow = calculateNapWindow(from: wakeTime, babyAge: baby.ageInMonths)

        return NapSuggestion(
            startTime: suggestedWindow.start,
            endTime: suggestedWindow.end,
            explanation: generateExplanation(for: baby, wakeTime: wakeTime)
        )
    }

    /// Check if we have enough recent sleep data to make predictions
    private func hasRecentSleepData(for baby: Baby) async throws -> Bool {
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        let recentEvents = try await dataStore.fetchEvents(for: baby, from: threeDaysAgo, to: Date())

        let sleepEvents = recentEvents.filter { $0.type == .sleep }
        return sleepEvents.count >= 3 // At least 3 sleep sessions in last 3 days
    }

    /// Find the most recent wake time (end of last sleep)
    private func findLastWakeTime(for baby: Baby) async throws -> Date? {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let recentEvents = try await dataStore.fetchEvents(for: baby, from: yesterday, to: Date())

        let sleepEvents = recentEvents
            .filter { $0.type == .sleep && $0.endTime != nil }
            .sorted(by: { $0.endTime! > $1.endTime! })

        return sleepEvents.first?.endTime
    }

    /// Calculate nap window based on wake time and baby age
    private func calculateNapWindow(from wakeTime: Date, babyAge: Int) -> (start: Date, end: Date) {
        let calendar = Calendar.current

        // Base wake-to-nap interval on baby age (in months)
        let wakeToNapHours: Double
        if babyAge <= 2 {
            wakeToNapHours = 1.5 // 90 minutes for very young babies
        } else if babyAge <= 6 {
            wakeToNapHours = 2.0 // 2 hours for 3-6 months
        } else if babyAge <= 12 {
            wakeToNapHours = 2.5 // 2.5 hours for 6-12 months
        } else {
            wakeToNapHours = 3.0 // 3 hours for toddlers
        }

        // Suggested nap duration based on age
        let napDurationHours: Double
        if babyAge <= 3 {
            napDurationHours = 1.0 // 1 hour naps for 0-3 months
        } else if babyAge <= 9 {
            napDurationHours = 1.5 // 1.5 hour naps for 3-9 months
        } else {
            napDurationHours = 2.0 // 2 hour naps for 9+ months
        }

        let napStart = calendar.date(byAdding: .hour, value: Int(wakeToNapHours), to: wakeTime) ?? wakeTime
        let napEnd = calendar.date(byAdding: .hour, value: Int(napDurationHours), to: napStart) ?? napStart

        return (napStart, napEnd)
    }

    /// Generate a human-readable explanation for the nap suggestion
    private func generateExplanation(for baby: Baby, wakeTime: Date) -> String {
        let age = baby.ageInMonths

        if age <= 2 {
            return "Based on wake time and age (\(age) months). Many babies this age nap 90-120 minutes after waking."
        } else if age <= 6 {
            return "Based on wake time and age (\(age) months). Most babies nap well 2 hours after waking up."
        } else {
            return "Based on wake time and age (\(age) months). Suggested nap window for optimal rest."
        }
    }
}

/// Represents a nap time suggestion
struct NapSuggestion {
    let startTime: Date
    let endTime: Date
    let explanation: String

    var displayText: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        let start = formatter.string(from: startTime)
        let end = formatter.string(from: endTime)
        return "Suggested nap: \(start) – \(end)"
    }

    var fullDisplayText: String {
        return displayText + "\n\n" + explanation
    }
}

// MARK: - Helper Extension

private extension Baby {
    /// Calculate age in months (rough approximation)
    var ageInMonths: Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.month], from: dateOfBirth, to: Date())
        return components.month ?? 0
    }
}
