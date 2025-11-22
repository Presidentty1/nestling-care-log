import Foundation
import CoreData

@objc(PredictionCacheEntity)
public class PredictionCacheEntity: NSManagedObject {
    func update(from prediction: Prediction) {
        self.id = prediction.id
        self.babyId = prediction.babyId
        self.type = prediction.type.rawValue
        self.predictedTime = prediction.predictedTime
        self.confidence = prediction.confidence
        self.explanation = prediction.explanation
        self.createdAt = prediction.createdAt
    }
    
    func toPrediction() -> Prediction {
        Prediction(
            id: id ?? UUID(),
            babyId: babyId ?? UUID(),
            type: PredictionType(rawValue: type ?? "next_nap") ?? .nextNap,
            predictedTime: predictedTime ?? Date(),
            confidence: confidence,
            explanation: explanation ?? "",
            createdAt: createdAt ?? Date()
        )
    }
}

