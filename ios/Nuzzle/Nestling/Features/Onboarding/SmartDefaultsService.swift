import Foundation

/// Service to provide smart defaults based on baby age and user context (Phase 4)
struct SmartDefaultsService {
    
    /// Suggests primary goal based on baby's age
    static func suggestGoalForBabyAge(dateOfBirth: Date) -> String {
        let ageInMonths = Calendar.current.dateComponents([.month], from: dateOfBirth, to: Date()).month ?? 0
        
        switch ageInMonths {
        case 0...1:
            return "Monitor Feeding" // Newborns: feeding is critical
        case 2...4:
            return "Track Sleep" // 2-4 months: sleep training age
        case 5...12:
            return "All of the Above" // Older babies: comprehensive tracking
        default:
            return "Just Survive" // Very young or error case
        }
    }
    
    /// Determines if baby is newborn (< 1 month) for extra guidance
    static func isNewborn(dateOfBirth: Date) -> Bool {
        let ageInDays = Calendar.current.dateComponents([.day], from: dateOfBirth, to: Date()).day ?? 0
        return ageInDays < 30
    }
    
    /// Determines if baby is in sleep training age window
    static func isInSleepTrainingWindow(dateOfBirth: Date) -> Bool {
        let ageInMonths = Calendar.current.dateComponents([.month], from: dateOfBirth, to: Date()).month ?? 0
        return ageInMonths >= 2 && ageInMonths <= 6
    }
    
    /// Gets personalized welcome message based on baby age
    static func getWelcomeMessage(babyName: String, dateOfBirth: Date) -> String {
        let ageInMonths = Calendar.current.dateComponents([.month], from: dateOfBirth, to: Date()).month ?? 0
        
        switch ageInMonths {
        case 0:
            return "Welcome! The first month is intense. We're here to help you track \(babyName)'s every need."
        case 1...2:
            return "Great job tracking \(babyName)! Let's help you understand their patterns as they grow."
        case 3...6:
            return "Welcome! \(babyName) is at a great age for sleep training. Let's track their progress together."
        default:
            return "Welcome! Ready to track \(babyName)'s day and get smart insights?"
        }
    }
}

