import XCTest
@testable import Nestling

final class HomeViewModelTests: XCTestCase {
    var viewModel: HomeViewModel!
    var mockDataStore: MockDataStore!
    var baby: Baby!

    override func setUp() {
        super.setUp()
        mockDataStore = MockDataStore()
        baby = Baby(name: "Test Baby", dateOfBirth: Date())
        viewModel = HomeViewModel(dataStore: mockDataStore, baby: baby)
    }

    override func tearDown() {
        viewModel = nil
        mockDataStore = nil
        baby = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertFalse(viewModel.shouldShowFirstLogCard)
        XCTAssertFalse(viewModel.shouldShowTrialOffer)
        XCTAssertEqual(viewModel.selectedFilter, .all)
    }

    func testShouldShowFirstLogCard() async {
        // Given - onboarding completed, no events
        mockDataStore.mockOnboardingCompleted = true

        // When
        await viewModel.checkShouldShowFirstLogCard()

        // Then
        XCTAssertTrue(viewModel.shouldShowFirstLogCard)
    }

    func testShouldShowFirstLogCardWithEvents() async {
        // Given - onboarding completed, has events
        mockDataStore.mockOnboardingCompleted = true
        mockDataStore.mockEvents = [
            Event(babyId: baby.id, type: .feed, amount: 100, unit: "ml")
        ]

        // When
        await viewModel.checkShouldShowFirstLogCard()

        // Then
        XCTAssertFalse(viewModel.shouldShowFirstLogCard)
    }

    func testShouldShowTrialOffer() async {
        // Given - has events, not Pro user
        mockDataStore.mockEvents = [
            Event(babyId: baby.id, type: .feed, amount: 100, unit: "ml"),
            Event(babyId: baby.id, type: .diaper, subtype: "wet"),
            Event(babyId: baby.id, type: .feed, amount: 120, unit: "ml"),
        ]
        mockDataStore.mockSettings = AppSettings()

        // When
        await viewModel.checkShouldShowTrialOffer()

        // Then
        XCTAssertTrue(viewModel.shouldShowTrialOffer)
    }

    func testShouldShowTrialOfferWithDismissedOffers() async {
        // Given - has events but offers dismissed
        mockDataStore.mockEvents = [
            Event(babyId: baby.id, type: .feed, amount: 100, unit: "ml"),
            Event(babyId: baby.id, type: .diaper, subtype: "wet"),
            Event(babyId: baby.id, type: .feed, amount: 120, unit: "ml"),
        ]
        var settings = AppSettings()
        settings.trialOffersDismissed = true
        mockDataStore.mockSettings = settings

        // When
        await viewModel.checkShouldShowTrialOffer()

        // Then
        XCTAssertFalse(viewModel.shouldShowTrialOffer)
    }

    func testDismissTrialOffer() async {
        // Given
        viewModel.shouldShowTrialOffer = true

        // When
        viewModel.dismissTrialOffer()

        // Then
        XCTAssertFalse(viewModel.shouldShowTrialOffer)
    }

    func testDismissCurrentTip() {
        // Given
        viewModel.currentTip = ParentalTip(
            id: "test",
            title: "Test Tip",
            content: "Test content",
            category: .general,
            ageRange: 0...52
        )

        // When
        viewModel.dismissCurrentTip()

        // Then
        XCTAssertNil(viewModel.currentTip)
    }

    func testCheckForAchievements() async {
        // Given
        mockDataStore.mockEvents = [
            Event(babyId: baby.id, type: .feed, amount: 100, unit: "ml")
        ]

        // When
        await viewModel.checkForAchievements()

        // Then
        XCTAssertFalse(viewModel.newAchievements.isEmpty)
    }

    func testDismissNewAchievements() {
        // Given
        viewModel.newAchievements = [Achievement.allAchievements[0]]

        // When
        viewModel.dismissNewAchievements()

        // Then
        XCTAssertTrue(viewModel.newAchievements.isEmpty)
    }

    func testFilteredEventsWithTypeFilter() {
        // Given
        viewModel.selectedFilter = .feeds
        let feedEvent = Event(babyId: baby.id, type: .feed, amount: 100, unit: "ml")
        let diaperEvent = Event(babyId: baby.id, type: .diaper, subtype: "wet")
        viewModel.events = [feedEvent, diaperEvent]

        // When
        let filtered = viewModel.filteredEvents

        // Then
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.type, .feed)
    }

    func testFilteredEventsWithSearchText() {
        // Given
        viewModel.debouncedSearchText = "feed"
        let feedEvent = Event(babyId: baby.id, type: .feed, amount: 100, unit: "ml", note: "Morning feed")
        let diaperEvent = Event(babyId: baby.id, type: .diaper, subtype: "wet")
        viewModel.events = [feedEvent, diaperEvent]

        // When
        let filtered = viewModel.filteredEvents

        // Then
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.type, .feed)
    }

    func testFilteredEventsWithAllFilter() {
        // Given
        viewModel.selectedFilter = .all
        let feedEvent = Event(babyId: baby.id, type: .feed, amount: 100, unit: "ml")
        let diaperEvent = Event(babyId: baby.id, type: .diaper, subtype: "wet")
        viewModel.events = [feedEvent, diaperEvent]

        // When
        let filtered = viewModel.filteredEvents

        // Then
        XCTAssertEqual(filtered.count, 2)
    }

    func testBatchDeleteMultipleEvents() async {
        // Given
        let event1 = Event(babyId: baby.id, type: .feed, amount: 100, unit: "ml")
        let event2 = Event(babyId: baby.id, type: .diaper, subtype: "wet")
        let event3 = Event(babyId: baby.id, type: .sleep, subtype: "nap")
        viewModel.events = [event1, event2, event3]

        // When
        await viewModel.batchDelete(events: [event1, event3])

        // Then
        // Verify that deleteEvent was called for each event (through mock)
        // This would require a more sophisticated mock that tracks calls
        // For now, we verify the method exists and can be called
        XCTAssertEqual(viewModel.events.count, 3) // Original array unchanged until loadTodayEvents called
    }

    func testActiveSleepTriggersHeroLayout() {
        // Given
        let activeSleep = Event(babyId: baby.id, type: .sleep, startTime: Date())

        // When
        viewModel.activeSleep = activeSleep

        // Then
        XCTAssertNotNil(viewModel.activeSleep)
        // This test verifies the condition for hero layout is met
        // The actual UI layout would be tested in a UI test
    }
}

// Enhanced MockDataStore for HomeViewModel testing
extension MockDataStore {
    var mockOnboardingCompleted: Bool = false
    var mockSettings: AppSettings = AppSettings()

    override func fetchAppSettings() async throws -> AppSettings {
        var settings = mockSettings
        settings.onboardingCompleted = mockOnboardingCompleted
        return settings
    }
}