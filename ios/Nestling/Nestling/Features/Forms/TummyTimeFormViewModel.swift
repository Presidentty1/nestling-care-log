import Foundation
import Combine

@MainActor
class TummyTimeFormViewModel: ObservableObject {
    @Published var durationMinutes: String = "5"
    @Published var note: String = ""
    @Published var startTime: Date = Date()
    @Published var isTimerMode: Bool = true
    @Published var isTimerRunning: Bool = false
    @Published var timerStartTime: Date?
    @Published var elapsedSeconds: Int = 0
    @Published var isValid: Bool = false
    @Published var isSaving: Bool = false
    
    private let dataStore: DataStore
    private let baby: Baby
    let editingEvent: Event?
    var timer: Timer?
    
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
        guard isTimerRunning else { return }
        let endTime = Date()
        let duration = Int(endTime.timeIntervalSince(timerStartTime ?? Date()) / 60)
        durationMinutes = String(max(1, duration))
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
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
        
        let eventData = Event(
            id: editingEvent?.id ?? IDGenerator.generate(),
            babyId: baby.id,
            type: .tummyTime,
            startTime: startTime,
            endTime: endTime,
            note: note.isEmpty ? nil : note,
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

