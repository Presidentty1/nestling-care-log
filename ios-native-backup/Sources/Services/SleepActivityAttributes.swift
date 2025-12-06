import Foundation
import ActivityKit

/// Attributes for Sleep Live Activity and Dynamic Island
struct SleepActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var startTime: Date
        var elapsedSeconds: Int
        var babyName: String
    }
    
    var babyName: String
}


