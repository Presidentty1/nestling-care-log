import Foundation
import CoreData

@objc(LastUsedValuesMO)
public class LastUsedValuesMO: NSManagedObject {
    func configure(with values: LastUsedValues, for eventType: EventType) {
        self.eventType = eventType.rawValue
        amount = values.amount != nil ? NSNumber(value: values.amount!) : nil
        unit = values.unit
        side = values.side
        subtype = values.subtype
        durationMinutes = values.durationMinutes != nil ? NSNumber(value: values.durationMinutes!) : nil
    }

    func toLastUsedValues() -> LastUsedValues {
        LastUsedValues(
            amount: amount?.doubleValue,
            unit: unit,
            side: side,
            subtype: subtype,
            durationMinutes: durationMinutes?.intValue
        )
    }
}

