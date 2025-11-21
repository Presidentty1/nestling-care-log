import Foundation
import CoreData

@objc(PredictionMO)
public class PredictionMO: NSManagedObject {
    func configure(with prediction: Prediction) {
        id = prediction.id
        babyId = prediction.babyId
        type = prediction.type.rawValue
        predictedTime = prediction.predictedTime
        confidence = prediction.confidence
        explanation = prediction.explanation
        createdAt = prediction.createdAt
    }

    func toPrediction() -> Prediction {
        Prediction(
            id: id ?? UUID(),
            babyId: babyId ?? UUID(),
            type: PredictionType(rawValue: type ?? "") ?? .nextNap,
            predictedTime: predictedTime ?? Date(),
            confidence: confidence,
            explanation: explanation ?? "",
            createdAt: createdAt ?? Date()
        )
    }
}

