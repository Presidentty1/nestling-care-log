import Foundation
import Combine
import UIKit

@MainActor
class FeedFormViewModel: ObservableObject {
    @Published var feedType: FeedSubtype = .bottle
    @Published var amount: String = ""
    @Published var unit: UnitType = .ml {
        didSet {
            convertAmount(from: oldValue, to: unit)
        }
    }
    @Published var side: Side = .left
    @Published var note: String = ""
    @Published var photos: [UIImage] = []
    @Published var startTime: Date = Date()
    @Published var isValid: Bool = false
    @Published var errorMessage: String?
    @Published var isSaving: Bool = false
    @Published var hasChanges: Bool = false
    
    private let dataStore: DataStore
    private let baby: Baby
    let editingEvent: Event?
    private var initialSnapshot: Snapshot?
    
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
        captureInitialSnapshot()
    }
    
    private func loadFromEvent(_ event: Event) {
        if let subtype = event.subtype {
            if subtype == "breast" {
                feedType = .breast
            } else if subtype == "bottle" {
                feedType = .bottle
            } else if subtype == "pumping" {
                feedType = .pumping
            } else if subtype == "other" {
                feedType = .other
            }
        }
        
        if let amount = event.amount {
            self.amount = String(Int(amount))
        }
        
        if let unit = event.unit {
            self.unit = unit == "ml" ? .ml : .oz
        }
        
        if let sideStr = event.side {
            side = Side(rawValue: sideStr) ?? .left
        }
        
        note = event.note ?? ""
        startTime = event.startTime

        // Load photos
        photos = PhotoStorageService.shared.loadPhotos(for: event.id)
    }
    
    private func loadLastUsedValues() {
        // Load last used preferences from UserDefaults
        if let lastTypeRaw = UserDefaults.standard.string(forKey: "lastFeedType"),
           let lastType = FeedSubtype(rawValue: lastTypeRaw) {
            feedType = lastType
        }

        if let lastUnitRaw = UserDefaults.standard.string(forKey: "lastFeedUnit"),
           let lastUnit = UnitType(rawValue: lastUnitRaw) {
            unit = lastUnit
        }

        // Show last amount as placeholder
        if let lastAmount = UserDefaults.standard.string(forKey: "lastFeedAmount") {
            amount = lastAmount
        } else {
            // Use smart defaults
            let (defaultAmount, defaultUnit) = getSmartDefaults()
            amount = String(Int(defaultAmount))
            unit = defaultUnit
        }

        // Load other preferences from dataStore if available
        Task {
            do {
                if let lastUsed = try await dataStore.getLastUsedValues(for: .feed) {
                    if let sideStr = lastUsed.side {
                        side = Side(rawValue: sideStr) ?? .left
                    }
                }
            } catch {
                // Use defaults if dataStore fails
                logger.debug("Failed to load last used values from dataStore: \(error)")
            }
            validate()
        }
    }

    private func applySmartAdjustments(to amount: Double, unit: UnitType) -> Double {
        var adjustedAmount = amount

        // Time-of-day adjustments (slight bias)
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 6 && hour <= 10 { // Morning
            adjustedAmount *= 1.1 // Slightly more in morning
        } else if hour >= 18 && hour <= 22 { // Evening
            adjustedAmount *= 0.9 // Slightly less in evening
        }

        // Baby age adjustments (gradual increase)
        let babyAgeMonths = baby.ageInMonths
        let ageMultiplier = min(1.0 + (babyAgeMonths * 0.05), 2.0) // Max 2x increase
        adjustedAmount *= ageMultiplier

        // Ensure within reasonable bounds
        let minAmount = unit == .ml ? Double(AppConstants.minimumFeedAmountML) : Double(AppConstants.minimumFeedAmountML) / AppConstants.mlPerOz
        let maxAmount = unit == .ml ? Double(AppConstants.maximumFeedAmountML) : Double(AppConstants.maximumFeedAmountOZ)

        return max(minAmount, min(maxAmount, adjustedAmount))
    }

    private func getSmartDefaults() -> (amount: Double, unit: UnitType) {
        let babyAgeMonths = baby.ageInMonths
        let hour = Calendar.current.component(.hour, from: Date())

        // Age-based baseline amounts (in ml)
        var baselineML: Double
        switch babyAgeMonths {
        case 0..<1: baselineML = 60  // Newborn
        case 1..<3: baselineML = 90  // 1-3 months
        case 3..<6: baselineML = 120 // 3-6 months
        case 6..<12: baselineML = 180 // 6-12 months
        default: baselineML = 240     // 1+ years
        }

        // Time-of-day bias
        if hour >= 6 && hour <= 10 { // Morning
            baselineML *= 1.2
        } else if hour >= 18 && hour <= 22 { // Evening
            baselineML *= 0.8
        }

        return (baselineML, .ml)
    }
    
    private func convertAmount(from oldUnit: UnitType, to newUnit: UnitType) {
        guard oldUnit != newUnit else { return }
        guard let value = Double(amount) else { return }
        let amountInML = oldUnit == .ml ? value : value * AppConstants.mlPerOz
        let converted = newUnit == .ml ? amountInML : amountInML / AppConstants.mlPerOz
        amount = converted >= 10 ? String(format: "%.0f", converted) : String(format: "%.2f", converted)
    }
    
    func validate() {
        if feedType == .breast || feedType == .other {
            isValid = true
        } else {
            let amountValue = Double(amount) ?? 0
            let amountML = unit == .ml ? amountValue : amountValue * AppConstants.mlPerOz
            let maxML = unit == .ml ? AppConstants.maximumFeedAmountML : AppConstants.maximumFeedAmountOZ * AppConstants.mlPerOz
            // UX-01: Validate both minimum and maximum to prevent unrealistic values
            isValid = amountML >= AppConstants.minimumFeedAmountML && amountML <= maxML
        }
        
        updateHasChanges()
    }
    
    func save() async throws {
        guard !isSaving else {
            return // Prevent double-submission
        }
        
        let saveStart = Date()
        
        validate()
        guard isValid else {
            throw FormError.validationFailed
        }
        
        // Domain-level validation
        try EventValidator.validateFeed(amount: Double(amount), unit: unit.rawValue, subtype: feedType.rawValue)
        
        isSaving = true
        defer { isSaving = false }
        
        let eventId = editingEvent?.id ?? IDGenerator.generate()

        // Save photos if any
        var photoUrls: [String]? = nil
        if !photos.isEmpty {
            photoUrls = try await PhotoStorageService.shared.savePhotos(photos, for: eventId)
        }

        var eventData: Event

        if feedType == .breast {
            eventData = Event(
                id: eventId,
                babyId: baby.id,
                type: .feed,
                subtype: "breast",
                startTime: startTime,
                side: side.rawValue,
                note: note.isEmpty ? nil : note,
                photoUrls: photoUrls,
                createdAt: editingEvent?.createdAt ?? Date(),
                updatedAt: Date()
            )
        } else {
            let amountValue = Double(amount) ?? 0
            let amountML = unit == .ml ? amountValue : amountValue * AppConstants.mlPerOz

            eventData = Event(
                id: eventId,
                babyId: baby.id,
                type: .feed,
                subtype: feedType.rawValue,
                startTime: startTime,
                amount: amountML,
                unit: unit.rawValue,
                note: note.isEmpty ? nil : note,
                photoUrls: photoUrls,
                createdAt: editingEvent?.createdAt ?? Date(),
                updatedAt: Date()
            )
        }
        
        // Final validation before save
        try EventValidator.validate(eventData)
        
        if editingEvent != nil {
            try await dataStore.updateEvent(eventData)
        } else {
            try await dataStore.addEvent(eventData)
            
            // Check if this is the first event ever logged (Epic 1 bug fix)
            await checkAndCelebrateFirstEvent()
        }
        
        let durationMs = Int(Date().timeIntervalSince(saveStart) * 1000)
        AnalyticsService.shared.trackLogSaveLatency(eventType: "feed", durationMs: durationMs)
        
        // Save last used values
        let lastUsed = LastUsedValues(
            amount: eventData.amount,
            unit: eventData.unit,
            side: eventData.side,
            subtype: eventData.subtype
        )
        try await dataStore.saveLastUsedValues(for: .feed, values: lastUsed)

        // Remember preferences for next time
        UserDefaults.standard.set(feedType.rawValue, forKey: "lastFeedType")
        UserDefaults.standard.set(unit.rawValue, forKey: "lastFeedUnit")
        UserDefaults.standard.set(amount, forKey: "lastFeedAmount")
    }

    func getTodayFeedCount() async -> Int {
        do {
            let today = Calendar.current.startOfDay(for: Date())
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
            let todayEvents = try await dataStore.fetchEvents(for: baby, from: today, to: tomorrow)
            return todayEvents.filter { $0.type == .feed }.count
        } catch {
            return 0
        }
    }

    func predictNextFeedTime() -> Date? {
        // Simple prediction: next feed in 2-3 hours
        return Calendar.current.date(byAdding: .hour, value: 3, to: Date())
    }
    
    private func checkAndCelebrateFirstEvent() async {
        do {
            // Check if this baby has any events
            // Note: editingEvent is guaranteed to be nil when this function is called (only called for new events)
            let allEvents = try await dataStore.fetchEvents(for: baby, from: Date.distantPast, to: Date.distantFuture)
            
            // If total count is 1, this is the first event we just added
            // (The newly added event is already included in allEvents) - Bug fix from Epic 1
            if allEvents.count == 1 {
                await MainActor.run {
                    Haptics.success()
                    // Note: Toast notification would be shown here in a complete implementation
                    logger.debug("🎉 Great start! First event logged!")
                }
            }
        } catch {
            logger.debug("Failed to check first event: \(error.localizedDescription)")
        }
    }

    private func captureInitialSnapshot() {
        initialSnapshot = Snapshot(
            feedType: feedType,
            amount: amount,
            unit: unit,
            side: side,
            note: note,
            startTime: startTime,
            photosCount: photos.count
        )
        updateHasChanges()
    }

    private func updateHasChanges() {
        guard let initial = initialSnapshot else {
            hasChanges = true
            return
        }
        let changed = initial.feedType != feedType ||
            initial.amount != amount ||
            initial.unit != unit ||
            initial.side != side ||
            initial.note != note ||
            initial.startTime != startTime ||
            initial.photosCount != photos.count
        hasChanges = changed
    }

    private struct Snapshot {
        let feedType: FeedSubtype
        let amount: String
        let unit: UnitType
        let side: Side
        let note: String
        let startTime: Date
        let photosCount: Int
    }

    deinit {
        logger.debug("FeedFormViewModel.deinit: Cleaning up")
        // Any active Tasks will be cancelled by Swift's runtime
    }
}

enum FeedSubtype: String, CaseIterable {
    case breast
    case bottle
    case pumping
    case other
    
    var displayName: String {
        switch self {
        case .breast: return "Breast"
        case .bottle: return "Bottle"
        case .pumping: return "Pump"
        case .other: return "Other"
        }
    }
}

enum UnitType: String, CaseIterable {
    case ml
    case oz
    
    var displayName: String {
        rawValue.uppercased()
    }
}

enum Side: String, CaseIterable {
    case left
    case right
    case both
    
    var displayName: String {
        rawValue.capitalized
    }
}

enum FormError: LocalizedError {
    case validationFailed
    
    var errorDescription: String? {
        switch self {
        case .validationFailed:
            return "Please check your input and try again"
        }
    }
}

