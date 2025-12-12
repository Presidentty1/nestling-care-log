import SwiftUI

struct FilterChipsView: View {
    @Binding var selectedFilter: EventTypeFilter
    let filters: [EventTypeFilter]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: .spacingSM) {
                ForEach(filters, id: \.self) { filter in
                    FilterChip(
                        filter: filter,
                        isSelected: selectedFilter == filter
                    ) {
                        withAnimation {
                            selectedFilter = filter
                        }
                        Haptics.selection()
                    }
                }
            }
            .padding(.horizontal, .spacingMD)
        }
    }
}

struct FilterChip: View {
    let filter: EventTypeFilter
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: filter.iconName)
                    .font(.caption)
                Text(filter.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, .spacingMD)
            .padding(.vertical, .spacingSM)
            .background(isSelected ? Color.primary.opacity(0.1) : Color.surface)
            .foregroundColor(isSelected ? .primary : .foreground)
            .cornerRadius(.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusMD)
                    .stroke(isSelected ? Color.primary : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("\(filter.displayName) filter")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    FilterChipsView(
        selectedFilter: .constant(.all),
        filters: EventTypeFilter.allCases
    )
    .padding()
}

