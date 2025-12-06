import SwiftUI

/// Wrapper for sheets with configurable detents and dismiss prevention
struct SheetDetentWrapper<Content: View>: View {
    let preferMedium: Bool
    let isSaving: Bool
    @ViewBuilder let content: Content
    @State private var selectedDetent: PresentationDetent = .medium
    
    var body: some View {
        content
            .presentationDetents([.medium, .large], selection: $selectedDetent)
            .presentationDragIndicator(.visible)
            .interactiveDismissDisabled(isSaving)
            .onAppear {
                selectedDetent = preferMedium ? .medium : .large
            }
    }
}

