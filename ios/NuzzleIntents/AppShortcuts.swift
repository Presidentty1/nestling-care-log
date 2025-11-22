import AppIntents

struct NuzzleAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        // Logging shortcuts
        AppShortcut(
            intent: LogFeedIntent(),
            phrases: [
                "Log a feed in \(.applicationName)",
                "Record a feed in \(.applicationName)",
                "Feed baby in \(.applicationName)",
                "Log feeding in \(.applicationName)"
            ],
            shortTitle: "Log Feed",
            systemImageName: "drop.fill"
        )

        AppShortcut(
            intent: StartSleepIntent(),
            phrases: [
                "Start sleep timer in \(.applicationName)",
                "Begin nap in \(.applicationName)",
                "Put baby to sleep in \(.applicationName)",
                "Start sleep tracking in \(.applicationName)"
            ],
            shortTitle: "Start Sleep",
            systemImageName: "moon.fill"
        )

        AppShortcut(
            intent: StopSleepIntent(),
            phrases: [
                "Stop sleep timer in \(.applicationName)",
                "End nap in \(.applicationName)",
                "Wake baby in \(.applicationName)",
                "Stop sleep tracking in \(.applicationName)"
            ],
            shortTitle: "Stop Sleep",
            systemImageName: "moon.zzz.fill"
        )

        AppShortcut(
            intent: LogDiaperIntent(),
            phrases: [
                "Log diaper change in \(.applicationName)",
                "Change diaper in \(.applicationName)",
                "Record diaper in \(.applicationName)",
                "Diaper change in \(.applicationName)"
            ],
            shortTitle: "Log Diaper",
            systemImageName: "drop.circle.fill"
        )

        AppShortcut(
            intent: LogTummyTimeIntent(),
            phrases: [
                "Log tummy time in \(.applicationName)",
                "Start tummy time in \(.applicationName)",
                "Record tummy time in \(.applicationName)"
            ],
            shortTitle: "Log Tummy Time",
            systemImageName: "figure.child"
        )

        // Query shortcuts
        AppShortcut(
            intent: QueryLastFeedIntent(),
            phrases: [
                "When was last feed in \(.applicationName)",
                "How long since last feed in \(.applicationName)",
                "Time since last feeding in \(.applicationName)",
                "When did baby last eat in \(.applicationName)"
            ],
            shortTitle: "Last Feed Time",
            systemImageName: "clock.fill"
        )

        AppShortcut(
            intent: QueryLastDiaperIntent(),
            phrases: [
                "When was last diaper change in \(.applicationName)",
                "How long since last diaper in \(.applicationName)",
                "Time since last diaper change in \(.applicationName)",
                "When did baby last get changed in \(.applicationName)"
            ],
            shortTitle: "Last Diaper Time",
            systemImageName: "arrow.clockwise"
        )

        AppShortcut(
            intent: QueryLastSleepIntent(),
            phrases: [
                "When was last nap in \(.applicationName)",
                "How long since last sleep in \(.applicationName)",
                "Time since last nap in \(.applicationName)",
                "When did baby wake up in \(.applicationName)"
            ],
            shortTitle: "Last Nap Time",
            systemImageName: "moon.zzz.fill"
        )
    }
    
    static var shortcutTileColor: ShortcutTileColor = .blue
}


