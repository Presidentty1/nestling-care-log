import Foundation
import CoreData

@objc(EventMO)
public class EventMO: NSManagedObject {
    func configure(with event: Event) {
        id = event.id
        babyId = event.babyId
        type = event.type.rawValue
        subtype = event.subtype
        startTime = event.startTime
        endTime = event.endTime
        amount = event.amount != nil ? NSNumber(value: event.amount!) : nil
        unit = event.unit
        side = event.side
        note = event.note
        createdAt = event.createdAt
        updatedAt = event.updatedAt
    }

    func toEvent() -> Event {
        Event(
            id: id ?? UUID(),
            babyId: babyId ?? UUID(),
            type: EventType(rawValue: type ?? "") ?? .feed,
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

