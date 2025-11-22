import SwiftUI

/// A wrapper view that observes an ObservableObject and rebuilds its content when the object changes.
/// This is useful when you have an ObservableObject stored in a @State property (which doesn't automatically observe changes)
/// and you want a part of your view hierarchy to update when the object changes.
struct ObservedViewModel<VM: ObservableObject, Content: View>: View {
    @ObservedObject var viewModel: VM
    let content: (VM) -> Content
    
    init(_ viewModel: VM, @ViewBuilder content: @escaping (VM) -> Content) {
        self.viewModel = viewModel
        self.content = content
    }
    
    var body: some View {
        content(viewModel)
    }
}

