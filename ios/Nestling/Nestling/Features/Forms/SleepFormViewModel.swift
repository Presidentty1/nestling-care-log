import Foundation
import Combine

@MainActor
class SleepFormViewModel: ObservableObject {
    @Published var subtype: SleepSubtype = .nap
    @Published var startTime: Date = Date()
    @Published var endTime: Date?
    @Published var note: String = ""
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
            checkActiveSleep()
        }
        
        validate()
    }
    
    private func loadFromEvent(_ event: Event) {
        if let subtype = event.subtype {
            self.subtype = subtype == "night" ? .night : .nap
        }
        startTime = event.startTime
        endTime = event.endTime
        note = event.note ?? ""
        isTimerMode = false
    }
    
    private func checkActiveSleep() {
        Task {
            if let activeSleep = try? await dataStore.getActiveSleep(for: baby) {
                await MainActor.run {
                    self.isTimerRunning = true
                    self.timerStartTime = activeSleep.startTime
                    self.startTime = activeSleep.startTime
                    startTimer()
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
        
        // Start Live Activity
        if #available(iOS 16.1, *) {
            LiveActivityManager.shared.startSleepActivity(for: baby, startTime: timerStartTime!)
        }
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
            
            // Stop Live Activity
            if #available(iOS 16.1, *) {
                LiveActivityManager.shared.stopSleepActivity()
            }
            
            // Show discard prompt
            showDiscardPrompt = true
            return
        }
        
        // Normal stop - save with minimum 1 minute
        endTime = Date()
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
        validate()
        
        // Stop Live Activity
        if #available(iOS 16.1, *) {
            LiveActivityManager.shared.stopSleepActivity()
        }
    }
    
    func discardTimer() {
        // Clear timer state without saving
        isTimerRunning = false
        timer?.invalidate()
        timer = nil
        timerStartTime = nil
        elapsedSeconds = 0
        endTime = nil
        startTime = Date()
        validate()
        
        // Stop Live Activity
        if #available(iOS 16.1, *) {
            LiveActivityManager.shared.stopSleepActivity()
        }
    }
    
    func keepTimer() {
        // Save with minimum 1 minute duration
        guard let startTime = timerStartTime else { return }
        let finalEndTime = startTime.addingTimeInterval(60) // Minimum 1 minute
        endTime = finalEndTime
        elapsedSeconds = 60
        validate()
    }
    
    private func startTimeUpdates() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let start = self.timerStartTime else { return }
                self.elapsedSeconds = Int(Date().timeIntervalSince(start))
                
                // Update Live Activity
                if #available(iOS 16.1, *) {
                    LiveActivityManager.shared.updateSleepActivity(elapsedSeconds: self.elapsedSeconds)
                }
            }
        }
    }
    
    @Published var validationError: String?
    
    func validate() {
        validationError = nil
        
        // Check for future dates
        let maxFutureDate = Date().addingTimeInterval(5 * 60) // 5 minutes for clock drift
        if startTime > maxFutureDate {
            validationError = "Start time cannot be in the future"
            isValid = false
            return
        }
        
        if let endTime = endTime, endTime > maxFutureDate {
            validationError = "End time cannot be in the future"
            isValid = false
            return
        }
        
        // Validate time relationships
        if isTimerMode {
            isValid = isTimerRunning && endTime != nil
        } else {
            if let endTime = endTime {
                if endTime <= startTime {
                    validationError = "End time must be after start time"
                    isValid = false
                    return
                }
            }
            isValid = endTime != nil && endTime! > startTime
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
        
        let finalEndTime = endTime ?? Date()
        let duration = Int(finalEndTime.timeIntervalSince(startTime) / 60)
        
        guard duration >= AppConstants.minimumSleepDurationMinutes else {
            throw FormError.validationFailed
        }
        
        // Domain-level validation
        try EventValidator.validateSleep(startTime: startTime, endTime: finalEndTime)
        
        // If starting a new sleep (not editing), auto-end any existing active sleep
        if editingEvent == nil {
            if let activeSleep = try? await dataStore.getActiveSleep(for: baby) {
                // Auto-end the previous active sleep when new one starts
                let autoEndTime = startTime // End previous sleep when new one starts
                let previousEvent = Event(
                    id: activeSleep.id,
                    babyId: activeSleep.babyId,
                    type: activeSleep.type,
                    subtype: activeSleep.subtype,
                    startTime: activeSleep.startTime,
                    endTime: autoEndTime,
                    amount: Double(DateUtils.durationMinutes(from: activeSleep.startTime, to: autoEndTime)),
                    unit: "min",
                    side: activeSleep.side,
                    note: activeSleep.note,
                    createdAt: activeSleep.createdAt,
                    updatedAt: Date()
                )
                try await dataStore.updateEvent(previousEvent)
            }
        }
        
        let eventData = Event(
            id: editingEvent?.id ?? IDGenerator.generate(),
            babyId: baby.id,
            type: .sleep,
            subtype: subtype.rawValue,
            startTime: startTime,
            endTime: finalEndTime,
            note: note.isEmpty ? nil : note,
            createdAt: editingEvent?.createdAt ?? Date(),
            updatedAt: Date()
        )
        
        // Final validation before save
        try EventValidator.validate(eventData)
        
        if editingEvent != nil {
            try await dataStore.updateEvent(eventData)
        } else {
            try await dataStore.addEvent(eventData)
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

enum SleepSubtype: String, CaseIterable {
    case nap
    case night
    
    var displayName: String {
        rawValue.capitalized
    }
}

