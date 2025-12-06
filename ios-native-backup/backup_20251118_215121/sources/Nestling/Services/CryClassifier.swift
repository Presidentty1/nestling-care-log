import Foundation

/// Rule-based cry classifier (NO ML, NO medical claims).
/// Provides simple heuristics for educational purposes only.
/// 
/// NOTE: This is deprecated. Use MLCryClassifier instead, which includes rule-based fallback.
struct CryClassifier {
    /// Classify cry based on simple audio characteristics.
    /// This is a placeholder - real classification requires sophisticated audio analysis.
    /// 
    /// DEPRECATED: Use MLCryClassifier.classify() instead
    static func classify(duration: TimeInterval, averagePower: Float, peakPower: Float) -> (classification: CryClassification, confidence: Double, explanation: String) {
        // Rule-based heuristics (NOT medical advice)
        
        // Short, intense cries (< 5 seconds, high power)
        if duration < 5.0 && averagePower > -50.0 {
            return (
                .hungry,
                0.6,
                "Short, intense cry pattern often associated with hunger. This is a general observation, not a medical diagnosis."
            )
        }
        
        // Long, sustained cries (> 15 seconds)
        if duration > 15.0 {
            return (
                .tired,
                0.6,
                "Longer cry duration may indicate tiredness or overstimulation. This is a general observation, not a medical diagnosis."
            )
        }
        
        // High intensity cries
        if peakPower > -40.0 {
            return (
                .discomfort,
                0.5,
                "High intensity cry may indicate discomfort. Check for wet diaper, temperature, or other needs. This is not a medical diagnosis."
            )
        }
        
        // Default: unknown
        return (
            .unknown,
            0.3,
            "Unable to determine pattern. Consider checking basic needs: hunger, diaper, temperature, or comfort."
        )
    }
}

