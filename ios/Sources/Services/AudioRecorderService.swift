import Foundation
import AVFoundation

// Note: CryClassification enum is now defined in MLCryClassifier.swift
// This file only handles audio recording, not classification

class AudioRecorderService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var averagePower: Float = -160.0
    
    private var audioRecorder: AVAudioRecorder?
    private var recordingTimer: Timer?
    private var recordingURL: URL?
    private let maxRecordingDuration: TimeInterval = 20.0 // 20 seconds max
    
    override init() {
        super.init()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .default, options: [.duckOthers])
            try session.setActive(true)
            
            // Register for interruption notifications
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleInterruption),
                name: AVAudioSession.interruptionNotification,
                object: session
            )
            
            // Register for route change notifications
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(handleRouteChange),
                name: AVAudioSession.routeChangeNotification,
                object: session
            )
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    @objc private func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: typeValue) else {
            return
        }
        
        switch type {
        case .began:
            // Interruption began - pause recording gracefully
            if isRecording {
                stopRecording()
            }
        case .ended:
            // Interruption ended - could resume if needed
            // For cry recording, we don't auto-resume
            break
        @unknown default:
            break
        }
    }
    
    @objc private func handleRouteChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let reasonValue = userInfo[AVAudioSessionRouteChangeReasonKey] as? UInt,
              let reason = AVAudioSession.RouteChangeReason(rawValue: reasonValue) else {
            return
        }
        
        switch reason {
        case .oldDeviceUnavailable:
            // Headphones unplugged, etc. - stop recording
            if isRecording {
                stopRecording()
            }
        default:
            break
        }
    }
    
    func startRecording() throws {
        guard !isRecording else { return }
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "cry_recording_\(Date().timeIntervalSince1970).m4a"
        recordingURL = tempDir.appendingPathComponent(fileName)
        
        guard let url = recordingURL else {
            throw NSError(domain: "AudioRecorder", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create recording URL"])
        }
        
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]
        
        audioRecorder = try AVAudioRecorder(url: url, settings: settings)
        audioRecorder?.delegate = self
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.record()
        
        isRecording = true
        recordingDuration = 0
        
        // Start timer for duration tracking
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.recordingDuration += 0.1
            
            // Update power level
            self.audioRecorder?.updateMeters()
            if let power = self.audioRecorder?.averagePower(forChannel: 0) {
                self.averagePower = power
            }
            
            // Auto-stop at max duration
            if self.recordingDuration >= self.maxRecordingDuration {
                self.stopRecording()
            }
        }
    }
    
    func stopRecording() {
        guard isRecording else { return }
        
        audioRecorder?.stop()
        recordingTimer?.invalidate()
        recordingTimer = nil
        isRecording = false
    }
    
    func analyzeRecording() -> (classification: CryClassification, confidence: Double) {
        // Rule-based classification (NO ML, NO medical claims)
        // This is a placeholder heuristic - real analysis would require audio processing
        
        // Simple heuristic based on duration and power
        if recordingDuration < 5.0 {
            return (.hungry, 0.5) // Short bursts often indicate hunger
        } else if recordingDuration > 15.0 {
            return (.tired, 0.5) // Longer cries often indicate tiredness
        } else if averagePower > -40.0 {
            return (.discomfort, 0.5) // High intensity might indicate discomfort
        } else {
            return (.unknown, 0.3) // Default to unknown
        }
    }
    
    func deleteRecording() {
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
        recordingURL = nil
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        deleteRecording()
    }
}

extension AudioRecorderService: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
    }
    
    func audioRecorderEncodeErrorDidOccur(_ recorder: AVAudioRecorder, error: Error?) {
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        print("Audio recording error: \(error?.localizedDescription ?? "Unknown")")
    }
}

