import SwiftUI

struct KeyboardShortcutsView: View {
    var body: some View {
        List {
            Section("Quick Actions") {
                ShortcutRow(title: "Log Feed", shortcut: "⌘N")
                ShortcutRow(title: "Start/Stop Sleep", shortcut: "⌘S")
                ShortcutRow(title: "Log Diaper", shortcut: "⌘D")
                ShortcutRow(title: "Start Tummy Timer", shortcut: "⌘T")
            }
            
            Section {
                Text("Keyboard shortcuts are available on iPad and when using an external keyboard.")
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
            }
        }
        .navigationTitle("Keyboard Shortcuts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ShortcutRow: View {
    let title: String
    let shortcut: String
    
    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(shortcut)
                .font(.system(.body, design: .monospaced))
                .foregroundColor(.mutedForeground)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(NuzzleTheme.surface)
                .cornerRadius(4)
        }
    }
}

#Preview {
    NavigationStack {
        KeyboardShortcutsView()
    }
}


