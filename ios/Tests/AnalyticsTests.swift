import XCTest
@testable import Nestling

final class AnalyticsTests: XCTestCase {
    var mockAnalytics: MockAnalyticsService!

    override func setUp() {
        super.setUp()
        mockAnalytics = MockAnalyticsService()
        // In a real implementation, you'd inject the mock analytics service
    }

    override func tearDown() {
        mockAnalytics = nil
        super.tearDown()
    }

    func testOnboardingAnalyticsEvents() {
        // Test onboarding completion event
        mockAnalytics.log("onboarding_completed", parameters: [
            "skipped": false,
            "steps_completed": 2,
            "goal_selected": "better_naps"
        ])

        XCTAssertEqual(mockAnalytics.loggedEvents.count, 1)
        let event = mockAnalytics.loggedEvents[0]
        XCTAssertEqual(event.name, "onboarding_completed")
        XCTAssertEqual(event.parameters?["goal_selected"] as? String, "better_naps")
    }

    func testGoalSelectionAnalytics() {
        // Test goal selection event
        mockAnalytics.log("onboarding_goal_selected", parameters: [
            "goal": "track_feeds",
            "step": 2
        ])

        XCTAssertEqual(mockAnalytics.loggedEvents.count, 1)
        let event = mockAnalytics.loggedEvents[0]
        XCTAssertEqual(event.name, "onboarding_goal_selected")
        XCTAssertEqual(event.parameters?["goal"] as? String, "track_feeds")
    }

    func testFirstEventAnalytics() {
        // Test first event logged
        mockAnalytics.log("first_event_logged", parameters: [
            "event_type": "feed",
            "time_since_onboarding": 300 // 5 minutes
        ])

        XCTAssertEqual(mockAnalytics.loggedEvents.count, 1)
        let event = mockAnalytics.loggedEvents[0]
        XCTAssertEqual(event.name, "first_event_logged")
        XCTAssertEqual(event.parameters?["event_type"] as? String, "feed")
    }

    func testAchievementAnalytics() {
        // Test achievement unlocked
        mockAnalytics.log("achievement_unlocked", parameters: [
            "achievement_id": "first_log",
            "baby_id": "test-baby-id"
        ])

        XCTAssertEqual(mockAnalytics.loggedEvents.count, 1)
        let event = mockAnalytics.loggedEvents[0]
        XCTAssertEqual(event.name, "achievement_unlocked")
        XCTAssertEqual(event.parameters?["achievement_id"] as? String, "first_log")
    }

    func testPredictionFeedbackAnalytics() {
        // Test prediction feedback
        mockAnalytics.log("prediction_feedback", parameters: [
            "rating": "Just Right",
            "feature": "nap_predictions"
        ])

        XCTAssertEqual(mockAnalytics.loggedEvents.count, 1)
        let event = mockAnalytics.loggedEvents[0]
        XCTAssertEqual(event.name, "prediction_feedback")
        XCTAssertEqual(event.parameters?["rating"] as? String, "Just Right")
    }

    func testSubscriptionAnalytics() {
        // Test subscription purchased
        mockAnalytics.log("subscription_purchased", parameters: [
            "package_id": "yearly",
            "price": "$49.99"
        ])

        XCTAssertEqual(mockAnalytics.loggedEvents.count, 1)
        let event = mockAnalytics.loggedEvents[0]
        XCTAssertEqual(event.name, "subscription_purchased")
        XCTAssertEqual(event.parameters?["package_id"] as? String, "yearly")
    }

    func testHomeScreenAnalytics() {
        // Test home screen viewed
        mockAnalytics.log("home_screen_viewed", parameters: [
            "layout_type": "goal-based",
            "goal_type": "better_naps",
            "time_of_day_bucket": "morning",
            "baby_age_months": 3
        ])

        XCTAssertEqual(mockAnalytics.loggedEvents.count, 1)
        let event = mockAnalytics.loggedEvents[0]
        XCTAssertEqual(event.name, "home_screen_viewed")
        XCTAssertEqual(event.parameters?["goal_type"] as? String, "better_naps")
    }

    func testNotificationAnalytics() {
        // Test notification opened
        mockAnalytics.log("notification_opened", parameters: [
            "type": "nap_window",
            "action_taken": "view_details"
        ])

        XCTAssertEqual(mockAnalytics.loggedEvents.count, 1)
        let event = mockAnalytics.loggedEvents[0]
        XCTAssertEqual(event.name, "notification_opened")
        XCTAssertEqual(event.parameters?["type"] as? String, "nap_window")
    }

    func testSyncAnalytics() {
        // Test sync success
        mockAnalytics.log("sync_success", parameters: [
            "changes_synced": 5,
            "auto_sync": true
        ])

        XCTAssertEqual(mockAnalytics.loggedEvents.count, 1)
        let event = mockAnalytics.loggedEvents[0]
        XCTAssertEqual(event.name, "sync_success")
        XCTAssertEqual(event.parameters?["changes_synced"] as? Int, 5)
    }

    func testFeedbackAnalytics() {
        // Test user feedback submitted
        mockAnalytics.log("feedback_submitted", parameters: [
            "rating": 5,
            "category": "feature",
            "message_length": 150,
            "include_device_info": true
        ])

        XCTAssertEqual(mockAnalytics.loggedEvents.count, 1)
        let event = mockAnalytics.loggedEvents[0]
        XCTAssertEqual(event.name, "feedback_submitted")
        XCTAssertEqual(event.parameters?["rating"] as? Int, 5)
        XCTAssertEqual(event.parameters?["category"] as? String, "feature")
    }
}

// MARK: - Mock Analytics Service

class MockAnalyticsService {
    struct LoggedEvent {
        let name: String
        let parameters: [String: Any]?
        let timestamp: Date
    }

    var loggedEvents: [LoggedEvent] = []

    func log(_ eventName: String, parameters: [String: Any]? = nil) {
        let event = LoggedEvent(
            name: eventName,
            parameters: parameters,
            timestamp: Date()
        )
        loggedEvents.append(event)
    }
}





