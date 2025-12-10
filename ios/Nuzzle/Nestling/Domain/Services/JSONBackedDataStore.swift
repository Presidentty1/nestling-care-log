import Foundation

/// JSON-backed implementation of DataStore that persists to Documents directory.
/// On first run, seeds from mock data. On subsequent runs, loads from JSON.
class JSONBackedDataStore: DataStore {
    private var babies: [Baby] = []
    private var events: [Event] = []
    private var predictions: [Prediction] = []
    private var appSettings: AppSettings = .default()
    private var activeSleep: [UUID: Event] = [:]
    private var lastUsedValues: [EventType: LastUsedValues] = [:]
    
    // TODO: Update dispatch queue label from com.nestling.* to com.nuzzle.* when ready
    private let queue = DispatchQueue(label: "com.nestling.jsonstore", attributes: .concurrent)
    private let fileManager = FileManager.default
    
    private var documentsURL: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var dataFileURL: URL {
        documentsURL.appendingPathComponent(AppConstants.dataStoreFileName)
    }
    
    // MARK: - Initialization
    
    init() {
        loadFromDisk()
    }
    
    // MARK: - Persistence
    
    private func loadFromDisk() {
        guard let data = try? Data(contentsOf: dataFileURL),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let _ = json["version"] as? Int else {
            // First run - seed mock data
            seedMockData()
            saveToDisk()
            return
        }
        
        // Load from JSON
        if let babiesData = json["babies"] as? [[String: Any]] {
            babies = babiesData.compactMap { try? JSONDecoder().decode(Baby.self, from: JSONSerialization.data(withJSONObject: $0)) }
        }
        
        if let eventsData = json["events"] as? [[String: Any]] {
            events = eventsData.compactMap { try? JSONDecoder().decode(Event.self, from: JSONSerialization.data(withJSONObject: $0)) }
        }
        
        if let predictionsData = json["predictions"] as? [[String: Any]] {
            predictions = predictionsData.compactMap { try? JSONDecoder().decode(Prediction.self, from: JSONSerialization.data(withJSONObject: $0)) }
        }
        
        if let settingsData = json["settings"] as? [String: Any],
           let settings = try? JSONDecoder().decode(AppSettings.self, from: JSONSerialization.data(withJSONObject: settingsData)) {
            appSettings = settings
        }
        
        if let lastUsedData = json["lastUsedValues"] as? [String: [String: Any]] {
            for (key, value) in lastUsedData {
                if let eventType = EventType(rawValue: key),
                   let lastUsed = try? JSONDecoder().decode(LastUsedValues.self, from: JSONSerialization.data(withJSONObject: value)) {
                    lastUsedValues[eventType] = lastUsed
                }
            }
        }
    }
    
    private func saveToDisk() {
        queue.async(flags: .barrier) {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            var json: [String: Any] = [
                "version": AppConstants.dataStoreVersion
            ]
            
            if let babiesData = try? self.babies.map({ try encoder.encode($0) }).map({ try JSONSerialization.jsonObject(with: $0) as? [String: Any] }).compactMap({ $0 }) {
                json["babies"] = babiesData
            }
            
            if let eventsData = try? self.events.map({ try encoder.encode($0) }).map({ try JSONSerialization.jsonObject(with: $0) as? [String: Any] }).compactMap({ $0 }) {
                json["events"] = eventsData
            }
            
            if let predictionsData = try? self.predictions.map({ try encoder.encode($0) }).map({ try JSONSerialization.jsonObject(with: $0) as? [String: Any] }).compactMap({ $0 }) {
                json["predictions"] = predictionsData
            }
            
            if let settingsData = try? encoder.encode(self.appSettings),
               let settingsDict = try? JSONSerialization.jsonObject(with: settingsData) as? [String: Any] {
                json["settings"] = settingsDict
            }
            
            var lastUsedDict: [String: [String: Any]] = [:]
            for (eventType, values) in self.lastUsedValues {
                if let valuesData = try? encoder.encode(values),
                   let valuesDict = try? JSONSerialization.jsonObject(with: valuesData) as? [String: Any] {
                    lastUsedDict[eventType.rawValue] = valuesDict
                }
            }
            json["lastUsedValues"] = lastUsedDict
            
            if let jsonData = try? JSONSerialization.data(withJSONObject: json) {
                try? jsonData.write(to: self.dataFileURL)
            }
        }
    }
    
    private func seedMockData() {
        babies = [Baby.mock(), Baby.mock2()]
        let baby1 = babies[0]
        events = [
            Event.mockFeed(babyId: baby1.id, amount: 120, unit: "ml", subtype: "bottle"),
            Event.mockDiaper(babyId: baby1.id, subtype: "wet"),
            Event.mockSleep(babyId: baby1.id, durationMinutes: 45, subtype: "nap"),
            Event.mockFeed(babyId: baby1.id, amount: 150, unit: "ml", subtype: "bottle"),
        ]
    }
    
    // MARK: - Babies (delegate to InMemoryDataStore pattern)
    
    func fetchBabies() async throws -> [Baby] {
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.babies)
            }
        }
    }
    
    func addBaby(_ baby: Baby) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                self.babies.append(baby)
                self.saveToDisk()
                continuation.resume()
            }
        }
    }
    
    func updateBaby(_ baby: Baby) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                if let index = self.babies.firstIndex(where: { $0.id == baby.id }) {
                    self.babies[index] = baby
                    self.saveToDisk()
                }
                continuation.resume()
            }
        }
    }
    
    func deleteBaby(_ baby: Baby) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                self.babies.removeAll { $0.id == baby.id }
                self.events.removeAll { $0.babyId == baby.id }
                self.saveToDisk()
                continuation.resume()
            }
        }
    }
    
    // MARK: - Events
    
    func fetchEvents(for baby: Baby, on date: Date) async throws -> [Event] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date
                
                let dayEvents = self.events.filter { event in
                    event.babyId == baby.id &&
                    event.startTime >= startOfDay &&
                    event.startTime < endOfDay
                }
                continuation.resume(returning: dayEvents.sorted { $0.startTime > $1.startTime })
            }
        }
    }
    
    func fetchEvents(for baby: Baby, from startDate: Date, to endDate: Date) async throws -> [Event] {
        return await withCheckedContinuation { continuation in
            queue.async {
                let rangeEvents = self.events.filter { event in
                    event.babyId == baby.id &&
                    event.startTime >= startDate &&
                    event.startTime <= endDate
                }
                continuation.resume(returning: rangeEvents.sorted { $0.startTime > $1.startTime })
            }
        }
    }
    
    func addEvent(_ event: Event) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                self.events.append(event)
                self.saveToDisk()
                continuation.resume()
            }
        }
    }
    
    func updateEvent(_ event: Event) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                if let index = self.events.firstIndex(where: { $0.id == event.id }) {
                    self.events[index] = event
                    self.saveToDisk()
                }
                continuation.resume()
            }
        }
    }
    
    func deleteEvent(_ event: Event) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                self.events.removeAll { $0.id == event.id }
                self.saveToDisk()
                continuation.resume()
            }
        }
    }
    
    // MARK: - Predictions
    
    func fetchPredictions(for baby: Baby, type: PredictionType) async throws -> Prediction? {
        return await withCheckedContinuation { continuation in
            queue.async {
                let prediction = self.predictions.first { $0.babyId == baby.id && $0.type == type }
                continuation.resume(returning: prediction)
            }
        }
    }
    
    func generatePrediction(for baby: Baby, type: PredictionType) async throws -> Prediction {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                let minutesFromNow: Int
                let confidence: Double
                let explanation: String
                
                switch type {
                case .nextNap:
                    minutesFromNow = Int.random(in: 45...60)
                    confidence = 0.70 + Double.random(in: 0...0.10)
                    explanation = "Based on your baby's recent sleep patterns, the next nap window is approaching."
                case .nextFeed:
                    minutesFromNow = Int.random(in: 90...120)
                    confidence = 0.65 + Double.random(in: 0...0.10)
                    explanation = "Based on feeding frequency, your baby may be ready for the next feed soon."
                }
                
                let prediction = Prediction(
                    babyId: baby.id,
                    type: type,
                    predictedTime: Date().addingTimeInterval(TimeInterval(minutesFromNow * 60)),
                    confidence: confidence,
                    explanation: explanation
                )
                
                if let index = self.predictions.firstIndex(where: { $0.babyId == baby.id && $0.type == type }) {
                    self.predictions[index] = prediction
                } else {
                    self.predictions.append(prediction)
                }
                
                self.saveToDisk()
                continuation.resume(returning: prediction)
            }
        }
    }
    
    // MARK: - Settings
    
    func fetchAppSettings() async throws -> AppSettings {
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.appSettings)
            }
        }
    }
    
    func saveAppSettings(_ settings: AppSettings) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                self.appSettings = settings
                self.saveToDisk()
                
                // Also store quiet hours in UserDefaults for quick access by NotificationDelegate
                if let quietStart = settings.quietHoursStart {
                    UserDefaults.standard.set(quietStart, forKey: "quietHoursStart")
                } else {
                    UserDefaults.standard.removeObject(forKey: "quietHoursStart")
                }
                if let quietEnd = settings.quietHoursEnd {
                    UserDefaults.standard.set(quietEnd, forKey: "quietHoursEnd")
                } else {
                    UserDefaults.standard.removeObject(forKey: "quietHoursEnd")
                }
                UserDefaults.standard.set(settings.remindersPaused, forKey: "remindersPaused")
                
                // Notify that settings changed
                NotificationCenter.default.post(name: NSNotification.Name("AppSettingsDidChange"), object: nil)
                
                continuation.resume()
            }
        }
    }
    
    // MARK: - Active Sleep
    
    func getActiveSleep(for baby: Baby) async throws -> Event? {
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.activeSleep[baby.id])
            }
        }
    }
    
    func startActiveSleep(for baby: Baby) async throws -> Event {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                let sleepEvent = Event(
                    babyId: baby.id,
                    type: .sleep,
                    subtype: "nap",
                    startTime: Date(),
                    endTime: nil
                )
                self.activeSleep[baby.id] = sleepEvent
                self.saveToDisk()
                continuation.resume(returning: sleepEvent)
            }
        }
    }
    
    func stopActiveSleep(for baby: Baby) async throws -> Event {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                guard var activeEvent = self.activeSleep[baby.id] else {
                    let now = Date()
                    let startTime = now.addingTimeInterval(-600)
                    let event = Event(
                        babyId: baby.id,
                        type: .sleep,
                        subtype: "nap",
                        startTime: startTime,
                        endTime: now,
                        note: "Quick log nap (10 min)"
                    )
                    self.events.append(event)
                    self.saveToDisk()
                    continuation.resume(returning: event)
                    return
                }
                
                activeEvent.endTime = Date()
                self.activeSleep.removeValue(forKey: baby.id)
                self.events.append(activeEvent)
                self.saveToDisk()
                continuation.resume(returning: activeEvent)
            }
        }
    }
    
    // MARK: - Last Used Values
    
    func getLastUsedValues(for eventType: EventType) async throws -> LastUsedValues? {
        return await withCheckedContinuation { continuation in
            queue.async {
                continuation.resume(returning: self.lastUsedValues[eventType])
            }
        }
    }
    
    func saveLastUsedValues(for eventType: EventType, values: LastUsedValues) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                self.lastUsedValues[eventType] = values
                self.saveToDisk()
                continuation.resume()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func reset() {
        queue.async(flags: .barrier) {
            self.babies.removeAll()
            self.events.removeAll()
            self.predictions.removeAll()
            self.activeSleep.removeAll()
            self.lastUsedValues.removeAll()
            self.appSettings = .default()
            self.seedMockData()
            self.saveToDisk()
        }
    }
}

