import XCTest
@testable import Nestling

final class AchievementServiceTests: XCTestCase {
    var achievementService: AchievementService!
    var mockDataStore: MockDataStore!

    override func setUp() {
        super.setUp()
        achievementService = AchievementService.shared
        mockDataStore = MockDataStore()
    }

    override func tearDown() {
        achievementService = nil
        mockDataStore = nil
        super.tearDown()
    }

    func testAchievementServiceInitialization() {
        XCTAssertNotNil(achievementService)
    }

    func testGetUnlockedAchievements() {
        // Initially no achievements should be unlocked
        let unlocked = achievementService.getUnlockedAchievements()
        XCTAssertTrue(unlocked.isEmpty)
    }

    func testCheckForNewAchievementsWithNoData() async {
        // Given
        let baby = Baby(name: "Test Baby", dateOfBirth: Date())

        // When
        let newAchievements = await achievementService.checkForNewAchievements(baby: baby, dataStore: mockDataStore)

        // Then
        XCTAssertTrue(newAchievements.isEmpty)
    }

    func testCheckForNewAchievementsWithEvents() async {
        // Given
        let baby = Baby(name: "Test Baby", dateOfBirth: Date())
        let events = (0..<5).map { _ in
            Event(babyId: baby.id, type: .feed, amount: 100, unit: "ml")
        }
        mockDataStore.mockEvents = events

        // When
        let newAchievements = await achievementService.checkForNewAchievements(baby: baby, dataStore: mockDataStore)

        // Then
        // Should unlock first_log achievement with 5 events
        XCTAssertFalse(newAchievements.isEmpty)
    }

    func testIsAchievementUnlocked() {
        // Test checking if specific achievement is unlocked
        let isUnlocked = achievementService.isAchievementUnlocked("first_log")
        XCTAssertFalse(isUnlocked)
    }

    func testAchievementProperties() {
        // Test that all achievements have required properties
        for achievement in Achievement.allAchievements {
            XCTAssertFalse(achievement.id.isEmpty)
            XCTAssertFalse(achievement.title.isEmpty)
            XCTAssertFalse(achievement.description.isEmpty)
            XCTAssertFalse(achievement.iconName.isEmpty)
            XCTAssertGreaterThan(achievement.unlockCondition.count, 0)
        }
    }

    func testAchievementRarities() {
        // Test that all rarity types are represented
        let rarities = Achievement.allAchievements.map { $0.rarity }
        XCTAssertTrue(rarities.contains(.common))
        XCTAssertTrue(rarities.contains(.rare))
        XCTAssertTrue(rarities.contains(.epic))
        XCTAssertTrue(rarities.contains(.legendary))
    }
}

// Enhanced MockDataStore for testing achievements
extension MockDataStore {
    var mockEvents: [Event] = []

    override func fetchEvents(for baby: Baby, from startDate: Date, to endDate: Date) async throws -> [Event] {
        return mockEvents.filter { event in
            event.startTime >= startDate && event.startTime <= endDate
        }
    }
}

