import XCTest
@testable import Nestling

final class NetworkMonitorTests: XCTestCase {
    var networkMonitor: NetworkMonitor!

    override func setUp() {
        super.setUp()
        networkMonitor = NetworkMonitor.shared
    }

    override func tearDown() {
        networkMonitor = nil
        super.tearDown()
    }

    func testNetworkMonitorInitializes() {
        // Test that NetworkMonitor can be initialized
        XCTAssertNotNil(networkMonitor)
    }

    func testConnectivityProperties() {
        // Test that connectivity properties are accessible
        _ = networkMonitor.isConnected
        _ = networkMonitor.connectionType
    }

    func testWaitForConnectivity() async {
        // Test that waitForConnectivity doesn't crash
        // Note: This is a basic smoke test - full connectivity testing
        // would require network mocking
        await networkMonitor.waitForConnectivity()
    }
}






