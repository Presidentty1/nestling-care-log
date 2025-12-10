import Foundation
import CoreML
import AVFoundation

/// ML-based cry classifier using Core ML.
/// 
/// This is a placeholder structure for ML model integration.
/// To use:
/// 1. Train a Core ML model (using Create ML or TensorFlow Lite converter)
/// 2. Add the .mlmodel file to the Xcode project
/// 3. Update this class to load and use the model
///
/// Example model input:
/// - Audio features: MFCC coefficients, spectral features
/// - Duration: Recording duration in seconds
/// - Power levels: Average and peak power
///
/// Example model output:
/// - Classification probabilities: [hungry: 0.7, tired: 0.2, discomfort: 0.1]
/// - Confidence: Overall confidence score

enum CryClassification: String, Codable {
    case hungry
    case tired
    case discomfort
    case painPossible = "pain_possible"
    case unknown
    
    var displayName: String {
        switch self {
        case .hungry: return "Hungry"
        case .tired: return "Tired"
        case .discomfort: return "Discomfort"
        case .painPossible: return "Possible Pain"
        case .unknown: return "Unknown"
        }
    }
}

struct CryClassificationResult {
    let classification: CryClassification
    let confidence: Double
    let probabilities: [CryClassification: Double]
    let explanation: String
}

class MLCryClassifier {
        // NOTE: ML model loading deferred - using rule-based classification for MVP
    // private var model: MLModel?
    
    /// Initialize ML classifier
    init() {
        // NOTE: ML model not loaded in MVP - rule-based approach used
        // guard let modelURL = Bundle.main.url(forResource: "CryClassifier", withExtension: "mlmodelc") else {
        //     print("Warning: CryClassifier model not found")
        //     return
        // }
        // model = try? MLModel(contentsOf: modelURL)
    }
    
    /// Classify cry from audio features
    /// - Parameters:
    ///   - audioFeatures: Extracted audio features (MFCC, spectral, etc.)
    ///   - duration: Recording duration in seconds
    ///   - averagePower: Average audio power
    ///   - peakPower: Peak audio power
    /// - Returns: Classification result
    func classify(
        audioFeatures: [Float]? = nil,
        duration: TimeInterval,
        averagePower: Float,
        peakPower: Float
    ) -> CryClassificationResult {
        // NOTE: Using rule-based classification instead of ML model for MVP
        // For now, fallback to rule-based classifier
        
        // If model is available, use it
        // if let model = model, let features = audioFeatures {
        //     return classifyWithModel(model: model, features: features, duration: duration)
        // }
        
        // Fallback to rule-based classification
        return classifyRuleBased(duration: duration, averagePower: averagePower, peakPower: peakPower)
    }
    
    /// Classify using Core ML model
    private func classifyWithModel(
        model: MLModel,
        features: [Float],
        duration: TimeInterval
    ) -> CryClassificationResult {
        // NOTE: ML inference not implemented - rule-based approach provides basic functionality
        // Example:
        // let input = try MLMultiArray(shape: [features.count], dataType: .float32)
        // for (index, value) in features.enumerated() {
        //     input[index] = NSNumber(value: value)
        // }
        // let prediction = try model.prediction(from: MLModelInput(features: input))
        // let probabilities = extractProbabilities(from: prediction)
        // let (classification, confidence) = getTopClassification(probabilities)
        
        // Placeholder
        return CryClassificationResult(
            classification: .unknown,
            confidence: 0.5,
            probabilities: [:],
            explanation: "ML model not yet integrated"
        )
    }
    
    /// Rule-based fallback classifier
    private func classifyRuleBased(
        duration: TimeInterval,
        averagePower: Float,
        peakPower: Float
    ) -> CryClassificationResult {
        // Simple heuristics (same as existing CryClassifier)
        var probabilities: [CryClassification: Double] = [
            .hungry: 0.25,
            .tired: 0.25,
            .discomfort: 0.25,
            .painPossible: 0.10,
            .unknown: 0.15
        ]
        
        // Adjust based on duration
        if duration < 5 {
            probabilities[.hungry] = 0.40
            probabilities[.tired] = 0.20
        } else if duration > 30 {
            probabilities[.tired] = 0.40
            probabilities[.discomfort] = 0.30
        }
        
        // Adjust based on power
        if averagePower > -40 {
            probabilities[.painPossible] = 0.30
            probabilities[.discomfort] = 0.35
        }
        
        // Normalize probabilities
        let total = probabilities.values.reduce(0, +)
        probabilities = probabilities.mapValues { $0 / total }
        
        // Get top classification
        let sorted = probabilities.sorted { $0.value > $1.value }
        guard let (classification, confidence) = sorted.first else {
            return ("unknown", 0.0)
        }
        
        let explanation = generateExplanation(classification: classification, confidence: confidence)
        
        return CryClassificationResult(
            classification: classification,
            confidence: confidence,
            probabilities: probabilities,
            explanation: explanation
        )
    }
    
    private func generateExplanation(classification: CryClassification, confidence: Double) -> String {
        let confidencePercent = Int(confidence * 100)
        
        switch classification {
        case .hungry:
            return "The cry pattern suggests your baby may be hungry (\(confidencePercent)% confidence). Consider checking when they last fed."
        case .tired:
            return "The cry pattern suggests your baby may be tired (\(confidencePercent)% confidence). They might be ready for a nap."
        case .discomfort:
            return "The cry pattern suggests possible discomfort (\(confidencePercent)% confidence). Check diaper, clothing, or temperature."
        case .painPossible:
            return "The cry pattern may indicate pain (\(confidencePercent)% confidence). If persistent, consult your pediatrician."
        case .unknown:
            return "Unable to classify cry pattern with high confidence (\(confidencePercent)% confidence). This is normal - babies cry for many reasons."
        }
    }
    
    /// Extract audio features from audio buffer
    /// - Parameter audioBuffer: AVAudioPCMBuffer
    /// - Returns: Feature vector (MFCC coefficients, spectral features, etc.)
    func extractFeatures(from audioBuffer: AVAudioPCMBuffer) -> [Float] {
        // NOTE: Audio feature extraction not implemented - using basic amplitude analysis
        // This would extract:
        // - MFCC (Mel-frequency cepstral coefficients)
        // - Spectral features (centroid, rolloff, flux)
        // - Zero-crossing rate
        // - Energy features
        
        // Placeholder: return empty array
        // In production, use Accelerate framework or vDSP for feature extraction
        return []
    }
}

// MARK: - Model Training Notes

/*
 To train a Core ML model for cry classification:
 
 1. Collect training data:
    - Record cries labeled with ground truth (hungry, tired, etc.)
    - Aim for 100+ samples per class
    - Ensure diversity (different babies, ages, environments)
 
 2. Extract features:
    - Use librosa or similar for MFCC extraction
    - Normalize features
    - Create feature vectors (e.g., 13 MFCC coefficients × 10 frames = 130 features)
 
 3. Train model:
    - Use Create ML (macOS) or TensorFlow/PyTorch
    - Try different architectures: Random Forest, Neural Network, SVM
    - Validate with cross-validation
    - Export as .mlmodel
 
 4. Optimize for Core ML:
    - Quantize model if needed (reduce size)
    - Test on device for performance
    - Ensure model runs in < 100ms
 
 5. Add to Xcode:
    - Drag .mlmodel file into project
    - Xcode will generate Swift interface
    - Update MLCryClassifier to use generated model class
 */


