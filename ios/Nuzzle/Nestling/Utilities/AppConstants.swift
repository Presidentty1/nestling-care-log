import Foundation

struct AppConstants {
    // Feed defaults
    static let minimumFeedAmountML: Double = 10
    static let defaultFeedAmountML: Double = 120 // 4oz
    static let defaultFeedAmountOZ: Double = 4
    // Feed max limits (UX-01: Prevent unrealistic values like "118 oz")
    static let maximumFeedAmountML: Double = 500 // ~17oz
    static let maximumFeedAmountOZ: Double = 17
    
    // Sleep defaults
    static let minimumSleepDurationMinutes: Int = 1
    static let defaultQuickSleepDurationMinutes: Int = 10
    // Sleep max limit (UX-01: Prevent unrealistic durations)
    static let maximumSleepDurationMinutes: Int = 720 // 12 hours max
    
    // Tummy time defaults
    static let defaultTummyTimeDurationMinutes: Int = 5
    // Tummy time max limit (UX-01)
    static let maximumTummyTimeDurationMinutes: Int = 120 // 2 hours max
    
    // Units
    static let mlPerOz: Double = 29.5735
    
    // Storage
    static let dataStoreVersion = 1
    static let dataStoreFileName = "nestling_data.json"
}

