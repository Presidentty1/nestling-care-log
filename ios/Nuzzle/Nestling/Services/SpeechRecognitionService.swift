import Foundation
import Speech
import AVFoundation
import Combine

/// Service for speech-to-text functionality in logging forms
@MainActor
class SpeechRecognitionService: ObservableObject {
    static let shared = SpeechRecognitionService()

    @Published var isRecording = false
    @Published var recognizedText = ""
    @Published var errorMessage: String?
    @Published var isAuthorized = false

    private var audioEngine = AVAudioEngine()
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    private init() {
        // Lazy initialization - don't setup speech recognizer until actually needed
        // This prevents crashes if Info.plist doesn't have speech recognition permission
    }

    private func setupSpeechRecognizer() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
        speechRecognizer?.supportsOnDeviceRecognition = true
    }

    private func checkPermissions() async -> Bool {
        return await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { authStatus in
                DispatchQueue.main.async {
                    switch authStatus {
                    case .authorized:
                        self.isAuthorized = true
                        continuation.resume(returning: true)
                    case .denied, .restricted, .notDetermined:
                        self.isAuthorized = false
                        continuation.resume(returning: false)
                    @unknown default:
                        self.isAuthorized = false
                        continuation.resume(returning: false)
                    }
                }
            }
        }
    }

    /// Start speech recognition recording
    func startRecording() async -> Bool {
        // Setup speech recognizer on first use (lazy initialization)
        if speechRecognizer == nil {
            setupSpeechRecognizer()
        }
        
        // Check permissions if not already authorized
        if !isAuthorized {
            let authorized = await checkPermissions()
            if !authorized {
                errorMessage = "Speech recognition not authorized. Please enable microphone access in Settings."
                return false
            }
        }

        guard !isRecording else { return false }

        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

            recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
            guard let recognitionRequest = recognitionRequest else {
                errorMessage = "Unable to create speech recognition request."
                return false
            }

            recognitionRequest.shouldReportPartialResults = true
            recognitionRequest.requiresOnDeviceRecognition = true

            recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
                if let result = result {
                    DispatchQueue.main.async {
                        self.recognizedText = result.bestTranscription.formattedString
                    }
                }

                if error != nil {
                    DispatchQueue.main.async {
                        self.stopRecording()
                        self.errorMessage = "Speech recognition failed. Please try again."
                    }
                }
            }

            let recordingFormat = audioEngine.inputNode.outputFormat(forBus: 0)
            audioEngine.inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
                recognitionRequest.append(buffer)
            }

            audioEngine.prepare()
            try audioEngine.start()

            isRecording = true
            errorMessage = nil

            return true
        } catch {
            errorMessage = "Failed to start recording: \(error.localizedDescription)"
            return false
        }
    }

    /// Stop speech recognition recording
    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        isRecording = false
    }

    /// Reset the service state
    func reset() {
        recognizedText = ""
        errorMessage = nil
    }
}

