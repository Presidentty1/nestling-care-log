import Foundation
import AVFoundation

@MainActor
class CryRecorderViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var averagePower: Float = -160.0
    @Published var classification: CryClassification?
    @Published var confidence: Double = 0.0
    @Published var explanation: String = ""
    @Published var showPermissionAlert = false
    @Published var permissionDenied = false
    
    private let audioService = AudioRecorderService()
    private let dataStore: DataStore
    private let baby: Baby
    
    init(dataStore: DataStore, baby: Baby) {
        self.dataStore = dataStore
        self.baby = baby
        
        // Observe audio service
        audioService.$isRecording.assign(to: &$isRecording)
        audioService.$recordingDuration.assign(to: &$recordingDuration)
        audioService.$averagePower.assign(to: &$averagePower)
    }
    
    func requestPermission() async -> Bool {
        let status = AVAudioSession.sharedInstance().recordPermission
        
        switch status {
        case .granted:
            return true
        case .denied:
            permissionDenied = true
            return false
        case .undetermined:
            return await AVAudioSession.sharedInstance().requestRecordPermission()
        @unknown default:
            return false
        }
    }
    
    func startRecording() {
        Task {
            let hasPermission = await requestPermission()
            
            if !hasPermission {
                showPermissionAlert = true
                return
            }
            
            do {
                try audioService.startRecording()
            } catch {
                Logger.dataError("Failed to start recording: \(error.localizedDescription)")
            }
        }
    }
    
    func stopRecording() {
        audioService.stopRecording()
        analyzeRecording()
    }
    
    private func analyzeRecording() {
        // Use ML classifier if available, fallback to rule-based
        let mlClassifier = MLCryClassifier()
        let result = mlClassifier.classify(
            audioFeatures: nil, // NOTE: Audio feature extraction not implemented in MVP
            duration: recordingDuration,
            averagePower: averagePower,
            peakPower: averagePower // Using average as proxy for peak
        )
        
        classification = result.classification
        confidence = result.confidence
        explanation = result.explanation

        // Analytics for cry analysis result viewed
        Task {
            await Analytics.shared.log("cry_analysis_result_viewed", parameters: [
                "label": result.classification?.rawValue ?? "unknown",
                "confidence_bucket": confidenceBucket(for: result.confidence)
            ])
        }
    }
    
    func saveInsight() async throws {
        guard let classification = classification else { return }

        // Analytics for cry analysis recording submitted
        Task {
            await Analytics.shared.log("cry_analysis_recording_submitted", parameters: [
                "label": classification.rawValue,
                "confidence_bucket": confidenceBucket(for: confidence)
            ])
        }

        // Create an event note with the classification
        let event = Event(
            babyId: baby.id,
            type: .other,
            subtype: "cry_insight",
            startTime: Date(),
            note: "Cry analysis: \(classification.displayName) (confidence: \(Int(confidence * 100))%). \(explanation)"
        )

        try await dataStore.addEvent(event)

        // Delete recording file
        audioService.deleteRecording()
    }
    
    func discardRecording() {
        audioService.deleteRecording()
        classification = nil
        confidence = 0.0
        explanation = ""
    }

    private func confidenceBucket(for confidence: Double) -> String {
        switch confidence {
        case 0.0..<0.3: return "low"
        case 0.3..<0.7: return "medium"
        case 0.7...1.0: return "high"
        default: return "unknown"
        }
    }
}

