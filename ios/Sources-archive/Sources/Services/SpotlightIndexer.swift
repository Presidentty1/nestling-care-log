import Foundation
import CoreSpotlight
import MobileCoreServices

/// Service for indexing app content in Core Spotlight
@MainActor
class SpotlightIndexer {
    static let shared = SpotlightIndexer()
    
    private let maxIndexedEvents = 500
    private let indexDomainIdentifier = "com.nestling.events"
    
    private init() {}
    
    /// Index events for Spotlight search
    /// - Parameters:
    ///   - events: Array of events to index (will index latest up to maxIndexedEvents)
    ///   - baby: Baby associated with the events
    ///   - settings: AppSettings to check if indexing is enabled
    func indexEvents(_ events: [Event], for baby: Baby, settings: AppSettings) {
        guard settings.spotlightIndexingEnabled else {
            return
        }
        
        // Sort by date (newest first) and take latest events
        let sortedEvents = events.sorted { $0.startTime > $1.startTime }
        let eventsToIndex = Array(sortedEvents.prefix(maxIndexedEvents))
        
        var searchableItems: [CSSearchableItem] = []
        
        for event in eventsToIndex {
            let item = createSearchableItem(for: event, baby: baby)
            searchableItems.append(item)
        }
        
        // Index items
        CSSearchableIndex.default().indexSearchableItems(searchableItems) { error in
            if let error = error {
                Logger.dataError("Failed to index events in Spotlight: \(error.localizedDescription)")
            } else {
                Logger.data("Indexed \(searchableItems.count) events in Spotlight")
            }
        }
    }
    
    /// Create a searchable item for an event
    private func createSearchableItem(for event: Event, baby: Baby) -> CSSearchableItem {
        let attributeSet = CSSearchableItemAttributeSet(itemContentType: kUTTypeText as String)
        
        // Title
        attributeSet.title = eventTypeDisplayName(event.type)
        
        // Content description
        var contentDescription = "\(baby.name) - \(formatEventSummary(event))"
        if let note = event.note, !note.isEmpty {
            contentDescription += " - \(note)"
        }
        attributeSet.contentDescription = contentDescription
        
        // Keywords for search
        var keywords: [String] = [
            baby.name,
            event.type.rawValue,
            eventTypeDisplayName(event.type)
        ]
        
        if let subtype = event.subtype {
            keywords.append(subtype)
        }
        
        if let note = event.note, !note.isEmpty {
            // Add individual words from note as keywords
            keywords.append(contentsOf: note.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty })
        }
        
        attributeSet.keywords = keywords
        
        // Date
        attributeSet.contentCreationDate = event.startTime
        attributeSet.contentModificationDate = event.updatedAt
        
        // Unique identifier
        let identifier = "\(indexDomainIdentifier).\(event.id)"
        
        return CSSearchableItem(uniqueIdentifier: identifier, domainIdentifier: indexDomainIdentifier, attributeSet: attributeSet)
    }
    
    /// Remove all indexed events
    func removeAllIndexedEvents() {
        CSSearchableIndex.default().deleteSearchableItems(withDomainIdentifiers: [indexDomainIdentifier]) { error in
            if let error = error {
                Logger.dataError("Failed to remove indexed events: \(error.localizedDescription)")
            } else {
                Logger.data("Removed all indexed events from Spotlight")
            }
        }
    }
    
    /// Remove specific event from index
    func removeEvent(_ event: Event) {
        let identifier = "\(indexDomainIdentifier).\(event.id)"
        CSSearchableIndex.default().deleteSearchableItems(withIdentifiers: [identifier]) { error in
            if let error = error {
                Logger.dataError("Failed to remove event from Spotlight: \(error.localizedDescription)")
            }
        }
    }
    
    /// Update index when event is modified
    func updateEvent(_ event: Event, baby: Baby, settings: AppSettings) {
        guard settings.spotlightIndexingEnabled else {
            return
        }
        
        let item = createSearchableItem(for: event, baby: baby)
        CSSearchableIndex.default().indexSearchableItems([item]) { error in
            if let error = error {
                Logger.dataError("Failed to update event in Spotlight: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Helpers
    
    private func eventTypeDisplayName(_ type: Event.EventType) -> String {
        switch type {
        case .feed: return "Feed"
        case .diaper: return "Diaper Change"
        case .sleep: return "Sleep"
        case .tummyTime: return "Tummy Time"
        }
    }
    
    private func formatEventSummary(_ event: Event) -> String {
        switch event.type {
        case .feed:
            if let amount = event.amount, let unit = event.unit {
                return "\(Int(amount)) \(unit)"
            }
            return "Feed"
        case .diaper:
            if let subtype = event.subtype {
                return subtype.capitalized
            }
            return "Diaper Change"
        case .sleep:
            if let duration = event.durationMinutes {
                return DateUtils.formatDuration(minutes: duration)
            }
            return "Sleep"
        case .tummyTime:
            if let duration = event.durationMinutes {
                return "\(duration) minutes"
            }
            return "Tummy Time"
        }
    }
}


