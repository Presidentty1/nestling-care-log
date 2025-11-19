import Foundation
import CoreData

@objc(LastUsedValuesEntity)
public class LastUsedValuesEntity: NSManagedObject {
    func update(from values: LastUsedValues) {
        self.amount = values.amount.map { NSDecimalNumber(value: $0) }
        self.unit = values.unit
        self.side = values.side
        self.subtype = values.subtype
        self.durationMinutes = values.durationMinutes.map { Int16($0) }
    }
    
    func toLastUsedValues() -> LastUsedValues {
        LastUsedValues(
            amount: amount?.doubleValue,
            unit: unit,
            side: side,
            subtype: subtype,
            durationMinutes: durationMinutes.map { Int($0) }
        )
    }
}

