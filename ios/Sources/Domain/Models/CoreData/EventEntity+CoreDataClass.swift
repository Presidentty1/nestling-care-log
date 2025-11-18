import Foundation
import CoreData

@objc(EventEntity)
public class EventEntity: NSManagedObject {
    func update(from event: Event) {
        self.id = event.id
        self.babyId = event.babyId
        self.type = event.type.rawValue
        self.subtype = event.subtype
        self.startTime = event.startTime
        self.endTime = event.endTime
        self.amount = event.amount.map { NSDecimalNumber(value: $0) }
        self.unit = event.unit
        self.side = event.side
        self.note = event.note
        self.createdAt = event.createdAt
        self.updatedAt = event.updatedAt
    }
    
    func toEvent() -> Event {
        Event(
            id: id ?? UUID(),
            babyId: babyId ?? UUID(),
            type: EventType(rawValue: type ?? "feed") ?? .feed,
            subtype: subtype,
            startTime: startTime ?? Date(),
            endTime: endTime,
            amount: amount?.doubleValue,
            unit: unit,
            side: side,
            note: note,
            createdAt: createdAt ?? Date(),
            updatedAt: updatedAt ?? Date()
        )
    }
}


