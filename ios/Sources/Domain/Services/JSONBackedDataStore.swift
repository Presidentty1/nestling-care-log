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
    
    private let queue = DispatchQueue(label: "com.nestling.jsonstore", attributes: .concurrent)
    private let fileManager = FileManager.default
    private var saveWorkItem: DispatchWorkItem?
    private let saveDebounceInterval: TimeInterval = 0.5 // 500ms debounce
    
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
              let version = json["version"] as? Int else {
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
        // Cancel previous save work item for debouncing
        saveWorkItem?.cancel()
        
        // Create new work item
        let workItem = DispatchWorkItem { [weak self] in
            guard let self = self else { return }
            
            self.queue.async(flags: .barrier) {
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                
                var json: [String: Any] = [
                    "version": AppConstants.dataStoreVersion
                ]
                
                // Encode babies
                do {
                    let babiesData = try self.babies.map { baby -> [String: Any]? in
                        let data = try encoder.encode(baby)
                        return try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    }.compactMap { $0 }
                    json["babies"] = babiesData
                } catch {
                    Logger.dataError("Failed to encode babies: \(error.localizedDescription)")
                }
                
                // Encode events
                do {
                    let eventsData = try self.events.map { event -> [String: Any]? in
                        let data = try encoder.encode(event)
                        return try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    }.compactMap { $0 }
                    json["events"] = eventsData
                } catch {
                    Logger.dataError("Failed to encode events: \(error.localizedDescription)")
                }
                
                // Encode predictions
                do {
                    let predictionsData = try self.predictions.map { prediction -> [String: Any]? in
                        let data = try encoder.encode(prediction)
                        return try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    }.compactMap { $0 }
                    json["predictions"] = predictionsData
                } catch {
                    Logger.dataError("Failed to encode predictions: \(error.localizedDescription)")
                }
                
                // Encode settings
                do {
                    let settingsData = try encoder.encode(self.appSettings)
                    if let settingsDict = try JSONSerialization.jsonObject(with: settingsData) as? [String: Any] {
                        json["settings"] = settingsDict
                    }
                } catch {
                    Logger.dataError("Failed to encode settings: \(error.localizedDescription)")
                }
                
                // Encode last used values
                var lastUsedDict: [String: [String: Any]] = [:]
                for (eventType, values) in self.lastUsedValues {
                    do {
                        let valuesData = try encoder.encode(values)
                        if let valuesDict = try JSONSerialization.jsonObject(with: valuesData) as? [String: Any] {
                            lastUsedDict[eventType.rawValue] = valuesDict
                        }
                    } catch {
                        Logger.dataError("Failed to encode last used values for \(eventType.rawValue): \(error.localizedDescription)")
                    }
                }
                json["lastUsedValues"] = lastUsedDict
                
                // Write to disk
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: json)
                    try jsonData.write(to: self.dataFileURL)
                    Logger.data("Successfully saved data to disk")
                } catch {
                    Logger.dataError("Failed to write data to disk: \(error.localizedDescription)")
                }
            }
        }
        
        saveWorkItem = workItem
        
        // Debounce: schedule save after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + saveDebounceInterval, execute: workItem)
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
    
    func forceSyncIfNeeded() async throws {
        // Cancel any pending debounced saves and perform immediate save
        // This is critical for app backgrounding scenarios
        saveWorkItem?.cancel()
        
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async(flags: .barrier) {
                // Perform the save synchronously within the barrier block
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                
                var json: [String: Any] = [
                    "version": AppConstants.dataStoreVersion
                ]
                
                // Encode babies with error logging
                do {
                    let babiesData = try self.babies.map { baby -> [String: Any]? in
                        let data = try encoder.encode(baby)
                        return try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    }.compactMap { $0 }
                    json["babies"] = babiesData
                } catch {
                    Logger.dataError("Failed to encode babies in forceSync: \(error.localizedDescription)")
                }
                
                // Encode events with error logging
                do {
                    let eventsData = try self.events.map { event -> [String: Any]? in
                        let data = try encoder.encode(event)
                        return try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    }.compactMap { $0 }
                    json["events"] = eventsData
                } catch {
                    Logger.dataError("Failed to encode events in forceSync: \(error.localizedDescription)")
                }
                
                // Encode predictions with error logging
                do {
                    let predictionsData = try self.predictions.map { prediction -> [String: Any]? in
                        let data = try encoder.encode(prediction)
                        return try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    }.compactMap { $0 }
                    json["predictions"] = predictionsData
                } catch {
                    Logger.dataError("Failed to encode predictions in forceSync: \(error.localizedDescription)")
                }
                
                // Encode settings with error logging
                do {
                    let settingsData = try encoder.encode(self.appSettings)
                    if let settingsDict = try JSONSerialization.jsonObject(with: settingsData) as? [String: Any] {
                        json["settings"] = settingsDict
                    }
                } catch {
                    Logger.dataError("Failed to encode settings in forceSync: \(error.localizedDescription)")
                }
                
                // Encode last used values with error logging
                var lastUsedDict: [String: [String: Any]] = [:]
                for (eventType, values) in self.lastUsedValues {
                    do {
                        let valuesData = try encoder.encode(values)
                        if let valuesDict = try JSONSerialization.jsonObject(with: valuesData) as? [String: Any] {
                            lastUsedDict[eventType.rawValue] = valuesDict
                        }
                    } catch {
                        Logger.dataError("Failed to encode last used values for \(eventType.rawValue) in forceSync: \(error.localizedDescription)")
                    }
                }
                json["lastUsedValues"] = lastUsedDict
                
                // Write to disk
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: json)
                    try jsonData.write(to: self.dataFileURL)
                    Logger.data("Successfully force-synced data to disk")
                    continuation.resume()
                } catch {
                    Logger.dataError("Failed to force-sync data to disk: \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }
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

