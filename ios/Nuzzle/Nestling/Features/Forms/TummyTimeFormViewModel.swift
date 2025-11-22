import Foundation
import Combine
import UIKit

@MainActor
class TummyTimeFormViewModel: ObservableObject {
    @Published var durationMinutes: String = "5"
    @Published var note: String = ""
    @Published var photos: [UIImage] = []
    @Published var startTime: Date = Date()
    @Published var isTimerMode: Bool = true
    @Published var isTimerRunning: Bool = false
    @Published var timerStartTime: Date?
    @Published var elapsedSeconds: Int = 0
    @Published var isValid: Bool = false
    @Published var isSaving: Bool = false
    @Published var showDiscardPrompt: Bool = false
    
    private let dataStore: DataStore
    private let baby: Baby
    let editingEvent: Event?
    var timer: Timer?
    
    private let minimumTimerSeconds = 10 // Prompt to discard if stopped before this
    
    init(dataStore: DataStore, baby: Baby, editingEvent: Event? = nil) {
        self.dataStore = dataStore
        self.baby = baby
        self.editingEvent = editingEvent
        
        if let event = editingEvent {
            loadFromEvent(event)
        } else {
            loadLastUsedValues()
        }
        
        validate()
    }
    
    private func loadFromEvent(_ event: Event) {
        if let duration = event.durationMinutes {
            durationMinutes = String(duration)
        }
        note = event.note ?? ""
        photos = PhotoStorageService.shared.loadPhotos(for: event.id)
        startTime = event.startTime
        isTimerMode = false
    }
    
    private func loadLastUsedValues() {
        Task {
            if let lastUsed = try? await dataStore.getLastUsedValues(for: .tummyTime),
               let duration = lastUsed.durationMinutes {
                await MainActor.run {
                    self.durationMinutes = String(duration)
                }
            }
        }
    }
    
    func startTimer() {
        guard !isTimerRunning else { return }
        timerStartTime = Date()
        startTime = timerStartTime!
        isTimerRunning = true
        startTimeUpdates()
    }
    
    func stopTimer() {
        guard isTimerRunning, let startTime = timerStartTime else { return }
        
        let elapsedSeconds = Int(Date().timeIntervalSince(startTime))
        
        // If stopped before minimum duration, prompt to discard
        if elapsedSeconds < minimumTimerSeconds {
            // Pause timer but don't save yet
            isTimerRunning = false
            timer?.invalidate()
            timer = nil
            
            // Show discard prompt
            showDiscardPrompt = true
            return
        }
        
        // Normal stop - save with minimum 1 minute
        let duration = max(1, elapsedSeconds / 60)
        durationMinutes = String(duration)
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
        validate()
    }
    
    func discardTimer() {
        // Clear timer state without saving
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
        timerStartTime = nil
        elapsedSeconds = 0
        durationMinutes = "5" // Reset to default
        validate()
    }
    
    func keepTimer() {
        // Save with minimum 1 minute duration
        durationMinutes = "1"
        validate()
    }
    
    private func startTimeUpdates() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let start = self.timerStartTime else { return }
                self.elapsedSeconds = Int(Date().timeIntervalSince(start))
            }
        }
    }
    
    func validate() {
        if isTimerMode {
            isValid = isTimerRunning && elapsedSeconds > 0
        } else {
            let duration = Int(durationMinutes) ?? 0
            isValid = duration > 0
        }
    }
    
    func save() async throws {
        guard !isSaving else { return }
        
        validate()
        guard isValid else {
            throw FormError.validationFailed
        }
        
        isSaving = true
        defer { isSaving = false }
        
        let duration = isTimerMode ? (elapsedSeconds / 60) : (Int(durationMinutes) ?? AppConstants.defaultTummyTimeDurationMinutes)
        let endTime = startTime.addingTimeInterval(TimeInterval(duration * 60))
        
        let eventId = editingEvent?.id ?? IDGenerator.generate()

        // Save photos if any
        var photoUrls: [String]? = nil
        if !photos.isEmpty {
            photoUrls = try await PhotoStorageService.shared.savePhotos(photos, for: eventId)
        }

        let eventData = Event(
            id: eventId,
            babyId: baby.id,
            type: .tummyTime,
            startTime: startTime,
            endTime: endTime,
            note: note.isEmpty ? nil : note,
            photoUrls: photoUrls,
            createdAt: editingEvent?.createdAt ?? Date(),
            updatedAt: Date()
        )
        
        if editingEvent != nil {
            try await dataStore.updateEvent(eventData)
        } else {
            try await dataStore.addEvent(eventData)
        }
        
        // Save last used values
        let lastUsed = LastUsedValues(durationMinutes: duration)
        try await dataStore.saveLastUsedValues(for: .tummyTime, values: lastUsed)
    }
    
    deinit {
        timer?.invalidate()
    }
}

