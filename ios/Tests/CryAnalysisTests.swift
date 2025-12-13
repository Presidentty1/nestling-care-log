import XCTest
@testable import Nestling

final class CryAnalysisTests: XCTestCase {
    var classifier: MLCryClassifier!

    override func setUp() {
        super.setUp()
        classifier = MLCryClassifier()
    }

    override func tearDown() {
        classifier = nil
        super.tearDown()
    }

    func testClassifierInitialization() {
        XCTAssertNotNil(classifier)
    }

    func testClassifyShortDurationCry() {
        // Test cry classification for short duration (hungry)
        let result = classifier.classify(duration: 30, averagePower: -20, peakPower: -10)

        XCTAssertEqual(result.classification, .hungry)
        XCTAssertGreaterThan(result.confidence, 0.0)
        XCTAssertLessThanOrEqual(result.confidence, 1.0)
        XCTAssertFalse(result.explanation.isEmpty)
        XCTAssertGreaterThan(result.probabilities.count, 0)
    }

    func testClassifyLongDurationCry() {
        // Test cry classification for long duration (tired)
        let result = classifier.classify(duration: 120, averagePower: -15, peakPower: -5)

        XCTAssertEqual(result.classification, .tired)
        XCTAssertGreaterThan(result.confidence, 0.0)
        XCTAssertLessThanOrEqual(result.confidence, 1.0)
        XCTAssertFalse(result.explanation.isEmpty)
    }

    func testClassifyHighPowerCry() {
        // Test cry classification for high power (possible pain)
        let result = classifier.classify(duration: 45, averagePower: -5, peakPower: 0)

        XCTAssertEqual(result.classification, .painPossible)
        XCTAssertGreaterThan(result.confidence, 0.0)
        XCTAssertLessThanOrEqual(result.confidence, 1.0)
        XCTAssertFalse(result.explanation.isEmpty)
    }

    func testClassifyLowPowerCry() {
        // Test cry classification for low power (discomfort)
        let result = classifier.classify(duration: 60, averagePower: -35, peakPower: -25)

        XCTAssertEqual(result.classification, .discomfort)
        XCTAssertGreaterThan(result.confidence, 0.0)
        XCTAssertLessThanOrEqual(result.confidence, 1.0)
        XCTAssertFalse(result.explanation.isEmpty)
    }

    func testClassificationProbabilities() {
        // Test that probabilities are properly normalized
        let result = classifier.classify(duration: 90, averagePower: -20, peakPower: -15)

        let totalProbability = result.probabilities.values.reduce(0, +)
        XCTAssertEqual(totalProbability, 1.0, accuracy: 0.001)

        // Ensure all classifications have probabilities
        XCTAssertGreaterThan(result.probabilities[.hungry] ?? 0, 0)
        XCTAssertGreaterThan(result.probabilities[.tired] ?? 0, 0)
        XCTAssertGreaterThan(result.probabilities[.discomfort] ?? 0, 0)
        XCTAssertGreaterThan(result.probabilities[.painPossible] ?? 0, 0)
        XCTAssertGreaterThan(result.probabilities[.unknown] ?? 0, 0)
    }

    func testClassificationExplanations() {
        // Test that explanations are appropriate for each classification
        let testCases: [(duration: TimeInterval, power: Float, expectedClassification: CryClassification)] = [
            (30, -20, .hungry),
            (120, -15, .tired),
            (45, -5, .painPossible),
            (60, -35, .discomfort)
        ]

        for (duration, power, expected) in testCases {
            let result = classifier.classify(duration: duration, averagePower: power, peakPower: power)
            XCTAssertEqual(result.classification, expected)

            // Check explanation contains relevant keywords
            let explanation = result.explanation.lowercased()
            switch expected {
            case .hungry:
                XCTAssertTrue(explanation.contains("hungry") || explanation.contains("feed"))
            case .tired:
                XCTAssertTrue(explanation.contains("tired") || explanation.contains("nap") || explanation.contains("sleep"))
            case .painPossible:
                XCTAssertTrue(explanation.contains("pain") || explanation.contains("pediatrician"))
            case .discomfort:
                XCTAssertTrue(explanation.contains("discomfort") || explanation.contains("diaper") || explanation.contains("check"))
            case .unknown:
                XCTAssertTrue(explanation.contains("unknown") || explanation.contains("confidence"))
            }
        }
    }

    func testClassificationConfidenceRange() {
        // Test that confidence values are within valid range
        let testCases: [(duration: TimeInterval, power: Float)] = [
            (15, -40),
            (60, -20),
            (90, -10),
            (180, -30)
        ]

        for (duration, power) in testCases {
            let result = classifier.classify(duration: duration, averagePower: power, peakPower: power)
            XCTAssertGreaterThanOrEqual(result.confidence, 0.0)
            XCTAssertLessThanOrEqual(result.confidence, 1.0)
        }
    }

    func testExtractFeatures() {
        // Test feature extraction (currently returns empty array)
        // This test ensures the method doesn't crash and returns expected format

        let mockBuffer = MockAVAudioPCMBuffer()
        let features = classifier.extractFeatures(from: mockBuffer)

        XCTAssertTrue(features.isEmpty) // Current implementation returns empty array
    }

    func testCryClassificationDisplayNames() {
        // Test that all classifications have proper display names
        let classifications: [CryClassification] = [.hungry, .tired, .discomfort, .painPossible, .unknown]

        for classification in classifications {
            XCTAssertFalse(classification.displayName.isEmpty)
            XCTAssertNotEqual(classification.displayName, "_")
        }
    }
}

// Mock AVAudioPCMBuffer for testing
class MockAVAudioPCMBuffer: AVAudioPCMBuffer {
    override init?(pcmFormat: AVAudioFormat, frameCapacity: AVAudioFrameCount) {
        // Create a minimal buffer for testing
        super.init(pcmFormat: pcmFormat, frameCapacity: frameCapacity)
        self.frameLength = 1024
    }
}






