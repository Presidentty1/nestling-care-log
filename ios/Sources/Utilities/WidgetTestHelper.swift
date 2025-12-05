import Foundation
import WidgetKit

/// Helper utilities for testing widgets on device.
/// 
/// Provides methods to:
/// - Reload widget timelines
/// - Test widget configurations
/// - Debug widget data
///
/// Usage in Settings → Developer:
/// ```swift
/// WidgetTestHelper.reloadAllWidgets()
/// WidgetTestHelper.testWidgetData()
/// ```

class WidgetTestHelper {
    /// Reload all widget timelines
    static func reloadAllWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
        Logger.info("[Widget] Reloaded all widget timelines")
    }
    
    /// Reload specific widget timeline
    /// - Parameter kind: Widget kind identifier
    static func reloadWidget(kind: String) {
        WidgetCenter.shared.reloadTimelines(ofKind: kind)
        Logger.info("[Widget] Reloaded widget: \(kind)")
    }
    
    /// Get widget configuration info
    /// - Returns: Array of widget configuration details
    static func getWidgetInfo() -> [String: Any] {
        // Note: WidgetCenter doesn't expose active widgets directly
        // This is a placeholder for future API support
        
        return [
            "availableWidgets": [
                "NextFeedWidget",
                "NextNapWidget",
                "TodaySummaryWidget",
                "SleepActivityWidget"
            ],
            "appGroup": "group.com.nestling.app",
            "note": "Use WidgetCenter.shared.reloadAllTimelines() to refresh widgets"
        ]
    }
    
    /// Test widget data generation
    /// - Returns: Sample data for testing widgets
    static func generateTestData() -> [String: Any] {
        let testBaby = Baby.mock()
        let testEvents = [
            Event.mockFeed(babyId: testBaby.id),
            Event.mockSleep(babyId: testBaby.id),
            Event.mockDiaper(babyId: testBaby.id)
        ]
        
        return [
            "baby": [
                "id": testBaby.id.uuidString,
                "name": testBaby.name,
                "age_days": Calendar.current.dateComponents([.day], from: testBaby.dateOfBirth, to: Date()).day ?? 0
            ],
            "events_today": testEvents.count,
            "next_feed_minutes": 90,
            "next_nap_minutes": 45,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
    }
    
    /// Verify App Groups configuration
    /// - Returns: True if App Groups is properly configured
    static func verifyAppGroups() -> Bool {
        let fileManager = FileManager.default
        guard let appGroupURL = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.com.nestling.app") else {
            Logger.warning("[Widget] ❌ App Groups not configured")
            return false
        }
        
        Logger.info("[Widget] ✅ App Groups configured: \(appGroupURL.path)")
        return true
    }
    
    /// Test widget data persistence
    /// - Parameter data: Data to persist
    static func testDataPersistence(data: [String: Any]) {
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.nestling.app") else {
            Logger.warning("[Widget] ❌ Cannot test persistence: App Groups not configured")
            return
        }
        
        let testFileURL = appGroupURL.appendingPathComponent("widget_test.json")
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: data, options: .prettyPrinted)
            try jsonData.write(to: testFileURL)
            Logger.info("[Widget] ✅ Test data persisted to: \(testFileURL.path)")
        } catch {
            Logger.error("[Widget] ❌ Failed to persist test data: \(error.localizedDescription)")
        }
    }
    
    /// Clear widget test data
    static func clearTestData() {
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.com.nestling.app") else {
            return
        }
        
        let testFileURL = appGroupURL.appendingPathComponent("widget_test.json")
        
        try? FileManager.default.removeItem(at: testFileURL)
        Logger.info("[Widget] Cleared test data")
    }
}

// MARK: - Widget Testing Checklist

/*
 Widget Testing Checklist:
 
 ✅ Setup:
 - [ ] App Groups configured in Xcode (group.com.nestling.app)
 - [ ] Widget extension target created
 - [ ] Widgets added to app target
 
 ✅ Functionality:
 - [ ] Widgets display correct data
 - [ ] Widgets update when data changes
 - [ ] Widget actions work (if interactive)
 - [ ] Widgets handle empty states
 - [ ] Widgets handle errors gracefully
 
 ✅ Performance:
 - [ ] Widgets load quickly (< 1 second)
 - [ ] No memory leaks
 - [ ] Efficient data fetching
 
 ✅ Design:
 - [ ] Widgets match app design
 - [ ] Text is readable
 - [ ] Icons are clear
 - [ ] Dark mode support
 
 ✅ Device Testing:
 - [ ] Test on iPhone (all sizes)
 - [ ] Test on iPad
 - [ ] Test lock screen widgets
 - [ ] Test Dynamic Island (if applicable)
 
 ✅ Edge Cases:
 - [ ] No baby selected
 - [ ] No events today
 - [ ] Very long event lists
 - [ ] Network errors
 - [ ] App Groups unavailable
 */


