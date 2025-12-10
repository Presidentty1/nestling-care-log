import SwiftUI

/// Standard iOS alert for critical/destructive actions
/// Ensures consistent, accessible confirmation dialogs
struct ConfirmDialog: ViewModifier {
    let title: String
    let message: String
    let confirmTitle: String
    let confirmRole: ButtonRole
    @Binding var isPresented: Bool
    let onConfirm: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert(title, isPresented: $isPresented) {
                Button(confirmTitle, role: confirmRole) {
                    Haptics.warning()
                    onConfirm()
                }
                Button("Cancel", role: .cancel) {
                    Haptics.light()
                }
            } message: {
                Text(message)
            }
    }
}

extension View {
    /// Show a confirmation dialog for destructive actions
    /// - Parameters:
    ///   - title: Alert title
    ///   - message: Detailed explanation
    ///   - confirmTitle: Confirm button text (e.g., "Delete", "Remove")
    ///   - confirmRole: Button role (.destructive for dangerous actions)
    ///   - isPresented: Binding to show/hide
    ///   - onConfirm: Action to perform on confirmation
    func confirmDialog(
        title: String,
        message: String,
        confirmTitle: String,
        confirmRole: ButtonRole = .destructive,
        isPresented: Binding<Bool>,
        onConfirm: @escaping () -> Void
    ) -> some View {
        self.modifier(ConfirmDialog(
            title: title,
            message: message,
            confirmTitle: confirmTitle,
            confirmRole: confirmRole,
            isPresented: isPresented,
            onConfirm: onConfirm
        ))
    }
}

/// Pre-configured confirmation dialogs for common actions
extension View {
    /// Delete event confirmation
    func deleteEventConfirmation(
        eventType: EventType,
        isPresented: Binding<Bool>,
        onConfirm: @escaping () -> Void
    ) -> some View {
        self.confirmDialog(
            title: "Delete \(eventType.displayName)?",
            message: "This action cannot be undone.",
            confirmTitle: "Delete",
            confirmRole: .destructive,
            isPresented: isPresented,
            onConfirm: onConfirm
        )
    }
    
    /// Delete baby confirmation
    func deleteBabyConfirmation(
        babyName: String,
        isPresented: Binding<Bool>,
        onConfirm: @escaping () -> Void
    ) -> some View {
        self.confirmDialog(
            title: "Delete \(babyName)?",
            message: "This will permanently delete all data for \(babyName), including all logged events. This action cannot be undone.",
            confirmTitle: "Delete",
            confirmRole: .destructive,
            isPresented: isPresented,
            onConfirm: onConfirm
        )
    }
    
    /// Revoke caregiver confirmation
    func revokeCaregiverConfirmation(
        caregiverName: String,
        isPresented: Binding<Bool>,
        onConfirm: @escaping () -> Void
    ) -> some View {
        self.confirmDialog(
            title: "Revoke Access?",
            message: "\(caregiverName) will no longer be able to view or edit data. Their existing local data will remain on their device but will stop syncing.",
            confirmTitle: "Revoke",
            confirmRole: .destructive,
            isPresented: isPresented,
            onConfirm: onConfirm
        )
    }
    
    /// Delete all data confirmation
    func deleteAllDataConfirmation(
        isPresented: Binding<Bool>,
        onConfirm: @escaping () -> Void
    ) -> some View {
        self.confirmDialog(
            title: "Delete All Data?",
            message: "This will permanently delete ALL baby profiles, events, and settings from this device. This action cannot be undone. Your iCloud data (if synced) will remain until deleted separately.",
            confirmTitle: "Delete All",
            confirmRole: .destructive,
            isPresented: isPresented,
            onConfirm: onConfirm
        )
    }
}

#Preview {
    struct PreviewContainer: View {
        @State private var showConfirm = false
        
        var body: some View {
            VStack {
                PrimaryButton("Show Confirmation") {
                    showConfirm = true
                }
            }
            .deleteEventConfirmation(eventType: .feed, isPresented: $showConfirm) {
                print("Confirmed delete")
            }
        }
    }
    
    return PreviewContainer()
}



