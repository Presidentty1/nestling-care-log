import Foundation

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
    
    private let dataStore: DataStore
    private let baby: Baby
    private let editingEvent: Event?
    private var timer: Timer?
    
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
        guard isTimerRunning else { return }
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
    
    func validate() {
        if isTimerMode {
            isValid = isTimerRunning && endTime != nil
        } else {
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

