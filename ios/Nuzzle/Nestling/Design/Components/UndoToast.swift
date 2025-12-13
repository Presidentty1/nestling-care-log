import SwiftUI
import Logger
/// Toast component for undo operations.
/// Appears at the bottom of the screen when an undoable action is performed.
struct UndoToast: View {
    @ObservedObject private var undoService = UndoService.shared
    @State private var isVisible = false

    var body: some View {
        if let undoAction = undoService.currentUndo {
            VStack {
                Spacer()

                HStack(spacing: .spacingMD) {
                    Text(undoAction.message)
                        .font(.body)
                        .foregroundColor(.foreground)

                    Spacer()

                    Button("Undo") {
                        Task {
                            await undoService.executeUndo()
                        }
                    }
                    .font(.body.weight(.semibold))
                    .foregroundColor(.accentColor)

                    Button(action: {
                        undoService.dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundColor(.mutedForeground)
                    }
                    .accessibilityLabel("Dismiss undo")
                }
                .padding(.horizontal, .spacingLG)
                .padding(.vertical, .spacingMD)
                .background(
                    RoundedRectangle(cornerRadius: .radiusLG)
                        .fill(Color.surface.opacity(0.95))
                        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal, .spacingMD)
                .padding(.bottom, .spacingXL) // Account for safe area
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .accessibilityAddTraits(.isButton)
                .accessibilityLabel("\(undoAction.message). Double tap to undo")
            }
            .onAppear {
                withAnimation(AnimationManager.gentleSpring) {
                    isVisible = true
                }
            }
            .onDisappear {
                isVisible = false
            }
            .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - Integration Helper

/// View modifier to add undo toast overlay to any view
struct UndoToastModifier: ViewModifier {
    func body(content: Content) -> some View {
        ZStack {
            content
            UndoToast()
        }
    }
}

extension View {
    /// Add undo toast capability to any view
    func withUndoToast() -> some View {
        modifier(UndoToastModifier())
    }
}

#Preview {
    ZStack {
        Color.gray.opacity(0.1)
            .edgesIgnoringSafeArea(.all)

        VStack {
            Text("Demo View")
                .font(.title)

            Button("Simulate Undo Action") {
                UndoService.shared.offerUndo(message: "Event deleted") {
                    logger.debug("Undo executed!")
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
    }
    .withUndoToast()
}
