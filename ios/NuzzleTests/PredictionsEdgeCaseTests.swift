import XCTest
@testable import Nestling

final class PredictionsEdgeCaseTests: XCTestCase {
    func testOvertiredReasonIncludesGentleCopy() {
        let baby = Baby.mock()
        let pastWake = Calendar.current.date(byAdding: .hour, value: -5, to: Date())!
        let window = NapPredictorService.predictNextNapWindow(for: baby, lastWakeTime: pastWake)
        XCTAssertNotNil(window)
        XCTAssertTrue(window?.reason.contains("overtired") ?? false, "Reason should gently note overtired state when window passed.")
    }
    
    func testShortNapAdjustsNextWindowEarlier() {
        let baby = Baby.mock()
        let shortNap = Event(
            babyId: baby.id,
            type: .sleep,
            startTime: Calendar.current.date(byAdding: .minute, value: -50, to: Date())!,
            endTime: Calendar.current.date(byAdding: .minute, value: -20, to: Date())!,
            createdAt: Date().addingTimeInterval(-4000),
            updatedAt: Date()
        )
        let base = NapPredictorService.predictNextNapWindow(for: baby, lastWakeTime: Date().addingTimeInterval(-90*60))
        let adjusted = NapPredictorService.predictNextNapWindow(for: baby, lastSleep: shortNap, historicalSleepEvents: nil, isProUser: false)
        XCTAssertNotNil(base)
        XCTAssertNotNil(adjusted)
        if let base, let adjusted {
            XCTAssertLessThanOrEqual(adjusted.start, base.start, "Short nap should pull next window earlier.")
        }
    }
}



