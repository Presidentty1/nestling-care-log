import SwiftUI

/// Visual indicator showing bottle fill level for feed amounts
struct BottleLevelIndicator: View {
    let amount: Double
    let maxAmount: Double = 8.0 // Standard 8oz bottle
    let unit: UnitType

    private var fillPercentage: Double {
        let amountInOz = unit == .oz ? amount : amount / AppConstants.mlPerOz
        return min(amountInOz / maxAmount, 1.0)
    }

    private var filledBars: Int {
        Int(fillPercentage * 8) // 8 bars total
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<8, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(index < filledBars ? Color.eventFeed : Color.eventFeed.opacity(0.2))
                    .frame(width: 8, height: 24)
            }
        }
        .padding(.vertical, .spacingXS)
        .accessibilityLabel("Bottle fill level: \(filledBars) of 8 segments filled")
        .accessibilityValue("\(Int(fillPercentage * 100))% full")
    }
}

#Preview {
    VStack(spacing: .spacingMD) {
        Text("4 oz bottle").font(.caption)
        BottleLevelIndicator(amount: 4.0, unit: .oz)

        Text("120 ml bottle").font(.caption)
        BottleLevelIndicator(amount: 120.0, unit: .ml)

        Text("Empty bottle").font(.caption)
        BottleLevelIndicator(amount: 0, unit: .oz)
    }
    .padding()
}
