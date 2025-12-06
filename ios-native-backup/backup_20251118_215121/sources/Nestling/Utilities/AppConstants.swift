import Foundation

struct AppConstants {
    // Feed defaults
    static let minimumFeedAmountML: Double = 10
    static let defaultFeedAmountML: Double = 120 // 4oz
    static let defaultFeedAmountOZ: Double = 4
    
    // Sleep defaults
    static let minimumSleepDurationMinutes: Int = 1
    static let defaultQuickSleepDurationMinutes: Int = 10
    
    // Tummy time defaults
    static let defaultTummyTimeDurationMinutes: Int = 5
    
    // Units
    static let mlPerOz: Double = 29.5735
    
    // Storage
    static let dataStoreVersion = 1
    static let dataStoreFileName = "nestling_data.json"
}

