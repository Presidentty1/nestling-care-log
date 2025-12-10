import XCTest
@testable import Nestling

final class RevenueCatServiceTests: XCTestCase {
    var revenueCatService: RevenueCatService!

    override func setUp() {
        super.setUp()
        revenueCatService = RevenueCatService.shared
    }

    override func tearDown() {
        revenueCatService = nil
        super.tearDown()
    }

    func testRevenueCatServiceInitialization() {
        XCTAssertNotNil(revenueCatService)
    }

    func testInitialSubscriptionStatus() {
        XCTAssertEqual(revenueCatService.subscriptionStatus, .notSubscribed)
        XCTAssertFalse(revenueCatService.isProUser)
    }

    func testLoadOfferings() async {
        // When
        await revenueCatService.loadOfferings()

        // Then
        XCTAssertFalse(revenueCatService.offerings.isEmpty)
        XCTAssertEqual(revenueCatService.offerings.count, 2) // Monthly and yearly
    }

    func testOfferingProperties() {
        // Given
        let offerings = revenueCatService.offerings

        // Then
        XCTAssertFalse(offerings.isEmpty)
        for offering in offerings {
            XCTAssertFalse(offering.id.isEmpty)
            XCTAssertFalse(offering.title.isEmpty)
            XCTAssertFalse(offering.price.isEmpty)
        }
    }

    func testMonthlyOffering() {
        // When
        let monthlyOffering = revenueCatService.offerings.first { $0.id.contains("monthly") }

        // Then
        XCTAssertNotNil(monthlyOffering)
        XCTAssertEqual(monthlyOffering?.title, "Monthly")
        XCTAssertEqual(monthlyOffering?.trialDays, 3)
    }

    func testYearlyOffering() {
        // When
        let yearlyOffering = revenueCatService.offerings.first { $0.id.contains("yearly") }

        // Then
        XCTAssertNotNil(yearlyOffering)
        XCTAssertEqual(yearlyOffering?.title, "Yearly")
        XCTAssertTrue(yearlyOffering?.isPopular ?? false)
        XCTAssertEqual(yearlyOffering?.trialDays, 7)
    }

    func testPurchaseFlow() async {
        // Given
        let offeringId = "monthly"

        // When
        let success = await revenueCatService.purchase(packageId: offeringId)

        // Then
        // Note: This would normally integrate with RevenueCat,
        // but for testing we expect mock success
        XCTAssertTrue(success)
        XCTAssertEqual(revenueCatService.subscriptionStatus, .subscribed)
        XCTAssertTrue(revenueCatService.isProUser)
    }

    func testRestorePurchases() async {
        // When
        let success = await revenueCatService.restorePurchases()

        // Then
        // Note: This would normally check with RevenueCat,
        // but for testing we expect mock success
        XCTAssertTrue(success)
    }

    func testCheckSubscriptionStatus() async {
        // When
        await revenueCatService.checkSubscriptionStatus()

        // Then
        // Should not crash and update properties
        // In real implementation, this would check RevenueCat status
    }
}


