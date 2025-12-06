import Foundation

struct Prediction: Identifiable, Codable, Equatable {
    let id: UUID
    let babyId: UUID
    let type: PredictionType
    let predictedTime: Date
    let confidence: Double // 0.0 - 1.0
    let explanation: String
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        babyId: UUID,
        type: PredictionType,
        predictedTime: Date,
        confidence: Double,
        explanation: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.babyId = babyId
        self.type = type
        self.predictedTime = predictedTime
        self.confidence = confidence
        self.explanation = explanation
        self.createdAt = createdAt
    }
    
    // MARK: - Mock Data
    
    static func mockNextNap(babyId: UUID, minutesFromNow: Int = 45) -> Prediction {
        Prediction(
            babyId: babyId,
            type: .nextNap,
            predictedTime: Date().addingTimeInterval(TimeInterval(minutesFromNow * 60)),
            confidence: 0.75,
            explanation: "Based on your baby's recent sleep patterns, the next nap window is approaching."
        )
    }
    
    static func mockNextFeed(babyId: UUID, minutesFromNow: Int = 90) -> Prediction {
        Prediction(
            babyId: babyId,
            type: .nextFeed,
            predictedTime: Date().addingTimeInterval(TimeInterval(minutesFromNow * 60)),
            confidence: 0.70,
            explanation: "Based on feeding frequency, your baby may be ready for the next feed soon."
        )
    }
}

enum PredictionType: String, Codable, CaseIterable {
    case nextFeed = "next_feed"
    case nextNap = "next_nap"
    
    var displayName: String {
        switch self {
        case .nextFeed: return "Next Feed"
        case .nextNap: return "Next Nap"
        }
    }
}

