import Foundation

/// In-memory implementation of DataStore for development and previews.
/// Seeds itself with mock data and provides simple CRUD operations.
class InMemoryDataStore: DataStore {
    // MARK: - Private Storage
    
    private var babies: [Baby] = []
    private var events: [Event] = []
    private var predictions: [Prediction] = []
    private var appSettings: AppSettings = .default()
    private var activeSleep: [UUID: Event] = [:] // babyId -> active sleep event
    private var lastUsedValues: [EventType: LastUsedValues] = [:]
    
    private let queue = DispatchQueue(label: "com.nestling.datastore", attributes: .concurrent)
    
    // MARK: - Initialization
    
    init() {
        seedMockData()
    }
    
    // MARK: - Mock Data Seeding
    
    private func seedMockData() {
        let baby1 = Baby.mock()
        let baby2 = Baby.mock2()
        
        babies = [baby1, baby2]
        
        let now = Date()
        let calendar = Calendar.current
        
        // Seed events for today
        events = [
            // Baby 1 - Today's events
            Event.mockFeed(babyId: baby1.id, amount: 120, unit: "ml", subtype: "bottle"),
            Event.mockDiaper(babyId: baby1.id, subtype: "wet"),
            Event.mockSleep(babyId: baby1.id, durationMinutes: 45, subtype: "nap"),
            Event.mockFeed(babyId: baby1.id, amount: 150, unit: "ml", subtype: "bottle"),
            Event.mockDiaper(babyId: baby1.id, subtype: "both"),
            Event.mockTummyTime(babyId: baby1.id, durationMinutes: 5),
            
            // Baby 1 - Yesterday's events
            Event(
                babyId: baby1.id,
                type: .feed,
                subtype: "breast",
                startTime: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                amount: nil,
                unit: nil
            ),
            Event(
                babyId: baby1.id,
                type: .sleep,
                subtype: "night",
                startTime: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                endTime: calendar.date(byAdding: .hour, value: 8, to: calendar.date(byAdding: .day, value: -1, to: now) ?? now)
            ),
            
            // Baby 2 - Today's events
            Event.mockFeed(babyId: baby2.id, amount: 180, unit: "ml", subtype: "bottle"),
            Event.mockDiaper(babyId: baby2.id, subtype: "dirty"),
            Event.mockSleep(babyId: baby2.id, durationMinutes: 60, subtype: "nap"),
        ]
        
        // Seed predictions
        predictions = [
            Prediction.mockNextNap(babyId: baby1.id, minutesFromNow: 45),
            Prediction.mockNextFeed(babyId: baby1.id, minutesFromNow: 90)
        ]
    }
    
    // MARK: - Babies
    
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
                continuation.resume()
            }
        }
    }
    
    func updateBaby(_ baby: Baby) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                if let index = self.babies.firstIndex(where: { $0.id == baby.id }) {
                    self.babies[index] = baby
                }
                continuation.resume()
            }
        }
    }
    
    func deleteBaby(_ baby: Baby) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                self.babies.removeAll { $0.id == baby.id }
                // Also delete associated events
                self.events.removeAll { $0.babyId == baby.id }
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
        // In-memory store doesn't need syncing
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
                continuation.resume()
            }
        }
    }
    
    func updateEvent(_ event: Event) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                if let index = self.events.firstIndex(where: { $0.id == event.id }) {
                    self.events[index] = event
                }
                continuation.resume()
            }
        }
    }
    
    func deleteEvent(_ event: Event) async throws {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                self.events.removeAll { $0.id == event.id }
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
                // Simple heuristic: next nap in 45-60 min, next feed in 90-120 min
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
                
                // Update or add prediction
                if let index = self.predictions.firstIndex(where: { $0.babyId == baby.id && $0.type == type }) {
                    self.predictions[index] = prediction
                } else {
                    self.predictions.append(prediction)
                }
                
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
                continuation.resume()
            }
        }
    }
    
    // MARK: - Active Sleep Tracking
    
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
                continuation.resume(returning: sleepEvent)
            }
        }
    }
    
    func stopActiveSleep(for baby: Baby) async throws -> Event {
        return await withCheckedContinuation { continuation in
            queue.async(flags: .barrier) {
                guard var activeEvent = self.activeSleep[baby.id] else {
                    // If no active sleep, create a default one
                    let now = Date()
                    let startTime = now.addingTimeInterval(-600) // 10 min ago
                    let event = Event(
                        babyId: baby.id,
                        type: .sleep,
                        subtype: "nap",
                        startTime: startTime,
                        endTime: now,
                        note: "Quick log nap (10 min)"
                    )
                    self.events.append(event)
                    continuation.resume(returning: event)
                    return
                }
                
                activeEvent.endTime = Date()
                self.activeSleep.removeValue(forKey: baby.id)
                self.events.append(activeEvent)
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
                continuation.resume()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    /// Reset to default mock data (useful for testing)
    func reset() {
        queue.async(flags: .barrier) {
            self.seedMockData()
            self.activeSleep.removeAll()
            self.lastUsedValues.removeAll()
        }
    }
}

