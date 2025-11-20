import Foundation
import AVFoundation
import Combine

enum CryRecorderState: Equatable {
    case idle
    case recording
    case processing
    case result
    case error(String)
}

@MainActor
class CryRecorderViewModel: ObservableObject {
    @Published var state: CryRecorderState = .idle
    @Published var recordingDuration: TimeInterval = 0
    @Published var averagePower: Float = -160.0
    @Published var classification: CryClassification?
    @Published var confidence: Double = 0.0
    @Published var explanation: String = ""
    @Published var showPermissionAlert = false
    @Published var permissionDenied = false
    @Published var errorMessage: String?
    @Published var quotaExceeded = false
    @Published var remainingQuota: Int?

    private let audioService = AudioRecorderService()
    private let dataStore: DataStore
    private let baby: Baby
    private let minimumRecordingDuration: TimeInterval = 2.0 // Minimum 2 seconds
    private let proService = ProSubscriptionService.shared
    private let quotaManager = CryInsightsQuotaManager()
    
    init(dataStore: DataStore, baby: Baby) {
        self.dataStore = dataStore
        self.baby = baby

        // Check quota on init
        Task { @MainActor in
            await checkQuota()
        }

        // Observe audio service - update state when recording starts
        Task { @MainActor in
            for await isRecording in audioService.$isRecording.values {
                if isRecording && state == .idle {
                    state = .recording
                }
            }
        }
        audioService.$recordingDuration.assign(to: &$recordingDuration)
        audioService.$averagePower.assign(to: &$averagePower)
    }

    func checkQuota() async {
        guard let settings = try? await dataStore.fetchAppSettings() else {
            remainingQuota = nil
            return
        }

        let isPro = proService.isProUser
        remainingQuota = CryInsightsQuotaManager.getRemainingQuota(
            isPro: isPro,
            weeklyCount: settings.cryInsightsWeeklyCount,
            weekStart: settings.cryInsightsWeekStart
        )

        quotaExceeded = !CryInsightsQuotaManager.canRecord(
            isPro: isPro,
            weeklyCount: settings.cryInsightsWeeklyCount,
            weekStart: settings.cryInsightsWeekStart
        )
    }
    
    var isRecording: Bool {
        if case .recording = state {
            return true
        }
        return false
    }
    
    var isProcessing: Bool {
        if case .processing = state {
            return true
        }
        return false
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
            // Check quota first
            await checkQuota()
            if quotaExceeded {
                state = .error("You've reached your weekly limit of 3 Cry Insights recordings. Upgrade to Pro for unlimited access.")
                return
            }

            // Check AI Data Sharing
            guard let settings = try? await dataStore.fetchAppSettings(), settings.aiDataSharingEnabled else {
                state = .error("Turn on AI data sharing to use Cry Insights")
                return
            }

            let hasPermission = await requestPermission()

            if !hasPermission {
                showPermissionAlert = true
                permissionDenied = true
                return
            }

            // Reset state
            state = .idle
            classification = nil
            confidence = 0.0
            explanation = ""
            errorMessage = nil
            recordingDuration = 0

            do {
                try audioService.startRecording()
                state = .recording
            } catch {
                state = .error("Failed to start recording: \(error.localizedDescription)")
                print("Failed to start recording: \(error)")
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioService.stopRecording()
        
        // Check minimum duration
        if recordingDuration < minimumRecordingDuration {
            state = .error("Recording too short. Please record at least 2 seconds.")
            audioService.deleteRecording()
            return
        }
        
        // Start processing
        state = .processing
        analyzeRecording()
    }
    
    private func analyzeRecording() {
        Task {
            do {
                // Check AI Data Sharing again (in case it was disabled during recording)
                guard let settings = try? await dataStore.fetchAppSettings(), settings.aiDataSharingEnabled else {
                    await MainActor.run {
                        state = .error("AI data sharing is disabled. Enable it in Settings to use Cry Insights.")
                    }
                    audioService.deleteRecording()
                    return
                }
                
                // Use ML classifier if available, fallback to rule-based
                // Note: For MVP, using local classifier. In production, this would call the edge function
                let mlClassifier = MLCryClassifier()
                let result = mlClassifier.classify(
                    audioFeatures: nil, // TODO: Extract features from audio buffer
                    duration: recordingDuration,
                    averagePower: averagePower,
                    peakPower: averagePower // Using average as proxy for peak
                )
                
                // Increment quota after successful analysis
                if let settings = try? await dataStore.fetchAppSettings(), !proService.isProUser {
                    var updatedSettings = settings
                    let quotaUpdate = CryInsightsQuotaManager.incrementQuota(
                        currentCount: settings.cryInsightsWeeklyCount,
                        currentWeekStart: settings.cryInsightsWeekStart
                    )
                    updatedSettings.cryInsightsWeeklyCount = quotaUpdate.count
                    updatedSettings.cryInsightsWeekStart = quotaUpdate.weekStart
                    try? await dataStore.saveAppSettings(updatedSettings)

                    await MainActor.run {
                        remainingQuota = CryInsightsQuotaManager.getRemainingQuota(
                            isPro: false,
                            weeklyCount: quotaUpdate.count,
                            weekStart: quotaUpdate.weekStart
                        )
                    }
                }
                
                await MainActor.run {
                    classification = result.classification
                    confidence = result.confidence
                    explanation = result.explanation
                    state = .result
                }
            } catch {
                await MainActor.run {
                    // Check if it's a network error
                    if let nsError = error as NSError?, nsError.domain == NSURLErrorDomain {
                        state = .error("We couldn't analyze that cry. Check your connection and try again.")
                    } else {
                        state = .error("We couldn't analyze that cry. Please try again.")
                    }
                    errorMessage = error.localizedDescription
                }
                audioService.deleteRecording()
            }
        }
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
        errorMessage = nil
        state = .idle
        recordingDuration = 0
    }
    
    func retry() {
        discardRecording()
        startRecording()
    }
}

