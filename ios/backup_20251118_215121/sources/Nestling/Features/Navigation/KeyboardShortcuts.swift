import SwiftUI

/// Keyboard shortcuts for iPad and external keyboards
struct KeyboardShortcutsModifier: ViewModifier {
    @EnvironmentObject var environment: AppEnvironment
    @ObservedObject var navigationCoordinator: NavigationCoordinator
    
    func body(content: Content) -> some View {
        content
            .keyboardShortcut("n", modifiers: .command) {
                // ⌘N: Quick Log Feed
                if let baby = environment.currentBaby {
                    navigationCoordinator.showFeedForm = true
                }
            }
            .keyboardShortcut("s", modifiers: .command) {
                // ⌘S: Start/Stop Sleep
                if let baby = environment.currentBaby {
                    navigationCoordinator.showSleepForm = true
                }
            }
            .keyboardShortcut("d", modifiers: .command) {
                // ⌘D: Log Diaper
                if let baby = environment.currentBaby {
                    navigationCoordinator.showDiaperForm = true
                }
            }
            .keyboardShortcut("t", modifiers: .command) {
                // ⌘T: Start Tummy Timer
                if let baby = environment.currentBaby {
                    navigationCoordinator.showTummyForm = true
                }
            }
    }
}

extension View {
    /// Apply keyboard shortcuts for quick actions
    func keyboardShortcuts(navigationCoordinator: NavigationCoordinator) -> some View {
        modifier(KeyboardShortcutsModifier(navigationCoordinator: navigationCoordinator))
    }
}

/// Custom keyboard shortcut modifier (since SwiftUI's .keyboardShortcut doesn't support closures directly)
struct KeyboardShortcutModifier: ViewModifier {
    let key: KeyEquivalent
    let modifiers: EventModifiers
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onKeyPress(key, modifiers: modifiers) {
                action()
                return .handled
            }
    }
}

extension View {
    func keyboardShortcut(_ key: KeyEquivalent, modifiers: EventModifiers = .command, action: @escaping () -> Void) -> some View {
        modifier(KeyboardShortcutModifier(key: key, modifiers: modifiers, action: action))
    }
}

