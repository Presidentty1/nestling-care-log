import Foundation
import Combine
import UIKit

@MainActor
class DiaperFormViewModel: ObservableObject {
    @Published var subtype: DiaperSubtype = .wet
    @Published var note: String = ""
    @Published var photos: [UIImage] = []
    @Published var startTime: Date = Date()
    @Published var isValid: Bool = true
    @Published var isSaving: Bool = false
    
    private let dataStore: DataStore
    private let baby: Baby
    let editingEvent: Event?
    
    init(dataStore: DataStore, baby: Baby, editingEvent: Event? = nil) {
        self.dataStore = dataStore
        self.baby = baby
        self.editingEvent = editingEvent
        
        if let event = editingEvent {
            loadFromEvent(event)
        } else {
            loadLastUsedValues()
        }
    }
    
    private func loadFromEvent(_ event: Event) {
        if let subtype = event.subtype {
            self.subtype = DiaperSubtype(rawValue: subtype) ?? .wet
        }
        note = event.note ?? ""
        photos = PhotoStorageService.shared.loadPhotos(for: event.id)
        startTime = event.startTime
    }
    
    private func loadLastUsedValues() {
        Task {
            if let lastUsed = try? await dataStore.getLastUsedValues(for: .diaper),
               let subtype = lastUsed.subtype {
                await MainActor.run {
                    self.subtype = DiaperSubtype(rawValue: subtype) ?? .wet
                }
            }
        }
    }
    
    func save() async throws {
        guard !isSaving else { return }
        let saveStart = Date()
        
        isSaving = true
        defer { isSaving = false }
        
        let eventId = editingEvent?.id ?? IDGenerator.generate()

        // Save photos if any
        var photoUrls: [String]? = nil
        if !photos.isEmpty {
            photoUrls = try await PhotoStorageService.shared.savePhotos(photos, for: eventId)
        }

        let eventData = Event(
            id: eventId,
            babyId: baby.id,
            type: .diaper,
            subtype: subtype.rawValue,
            startTime: startTime,
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
        
        let durationMs = Int(Date().timeIntervalSince(saveStart) * 1000)
        AnalyticsService.shared.trackLogSaveLatency(eventType: "diaper", durationMs: durationMs)
        
        // Save last used values
        let lastUsed = LastUsedValues(subtype: subtype.rawValue)
        try await dataStore.saveLastUsedValues(for: .diaper, values: lastUsed)
    }
}

enum DiaperSubtype: String, CaseIterable {
    case wet
    case dirty
    case both
    
    var displayName: String {
        rawValue.capitalized
    }
}

