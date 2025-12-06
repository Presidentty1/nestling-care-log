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
    @Environment(\.colorScheme) private var colorScheme
    
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
            .background(isSelected ? Color.adaptivePrimary(colorScheme).opacity(0.1) : Color.adaptiveSurface(colorScheme))
            .foregroundColor(isSelected ? Color.adaptivePrimary(colorScheme) : Color.adaptiveTextPrimary(colorScheme))
            .cornerRadius(.radiusMD)
            .overlay(
                RoundedRectangle(cornerRadius: .radiusMD)
                    .stroke(isSelected ? Color.adaptivePrimary(colorScheme) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    FilterChipsView(
        selectedFilter: .constant(.all),
        filters: EventTypeFilter.allCases
    )
    .padding()
}


