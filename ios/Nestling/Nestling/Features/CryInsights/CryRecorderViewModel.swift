import Foundation
import AVFoundation
import Combine

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
            return await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
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
                print("Failed to start recording: \(error)")
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
            audioFeatures: nil, // TODO: Extract features from audio buffer
            duration: recordingDuration,
            averagePower: averagePower,
            peakPower: averagePower // Using average as proxy for peak
        )
        
        classification = result.classification
        confidence = result.confidence
        explanation = result.explanation
    }
    
    func saveInsight() async throws {
        guard let classification = classification else { return }
        
        // Create an event note with the classification
        // Note: Using .feed as placeholder since EventType doesn't have .other
        // The note field contains the actual cry insight information
        let event = Event(
            babyId: baby.id,
            type: .feed,
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
}

