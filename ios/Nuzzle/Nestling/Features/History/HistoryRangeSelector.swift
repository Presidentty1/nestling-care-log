import SwiftUI

struct HistoryRangeSelector: View {
    @Binding var selectedRange: HistoryRange

    var body: some View {
        Picker("Range", selection: $selectedRange) {
            ForEach(HistoryRange.allCases) { range in
                Text(range.rawValue).tag(range)
            }
        }
        .pickerStyle(.segmented)
        .accessibilityLabel("History range")
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selection = HistoryRange.last24Hours
        var body: some View {
            HistoryRangeSelector(selectedRange: $selection)
                .padding()
        }
    }
    return PreviewWrapper()
}


