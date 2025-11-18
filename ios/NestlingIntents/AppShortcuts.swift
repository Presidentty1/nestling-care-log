import AppIntents

struct NestlingAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogFeedIntent(),
            phrases: [
                "Log a feed in \(.applicationName)",
                "Record a feed in \(.applicationName)",
                "Feed baby in \(.applicationName)"
            ]
        )
        
        AppShortcut(
            intent: StartSleepIntent(),
            phrases: [
                "Start sleep in \(.applicationName)",
                "Begin sleep tracking in \(.applicationName)"
            ]
        )
        
        AppShortcut(
            intent: StopSleepIntent(),
            phrases: [
                "Stop sleep in \(.applicationName)",
                "End sleep tracking in \(.applicationName)"
            ]
        )
        
        AppShortcut(
            intent: LogDiaperIntent(),
            phrases: [
                "Log diaper change in \(.applicationName)",
                "Record diaper in \(.applicationName)"
            ]
        )
        
        AppShortcut(
            intent: LogTummyTimeIntent(),
            phrases: [
                "Log tummy time in \(.applicationName)",
                "Record tummy time in \(.applicationName)"
            ]
        )
    }
    
    static var shortcutTileColor: ShortcutTileColor = .blue
}


