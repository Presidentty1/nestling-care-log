import Foundation
import BackgroundTasks

/// Service for handling background refresh tasks (iOS 13+)
@MainActor
class BackgroundRefreshService {
    static let shared = BackgroundRefreshService()

    private let backgroundTaskIdentifier = "com.nestling.app.refresh"
    private let dataStore: DataStore
    private let notificationScheduler: NotificationScheduler

    private init() {
        self.dataStore = DataStoreSelector.create()
        self.notificationScheduler = NotificationScheduler.shared

        registerBackgroundTasks()
        logger.debug("BackgroundRefreshService initialized")
    }

    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundTaskIdentifier, using: nil) { task in
            self.handleBackgroundRefresh(task as! BGAppRefreshTask)
        }

        logger.debug("Background refresh task registered")
    }

    func scheduleBackgroundRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: backgroundTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes from now

        do {
            try BGTaskScheduler.shared.submit(request)
            logger.debug("Background refresh task scheduled")
        } catch {
            logger.error("Failed to schedule background refresh: \(error)")
        }
    }

    private func handleBackgroundRefresh(_ task: BGAppRefreshTask) {
        logger.debug("Background refresh task started")

        // Create a task to perform the refresh
        let refreshTask = Task {
            do {
                // Refresh notifications based on latest data
                try await refreshNotifications()

                // Refresh any cached predictions if needed
                try await refreshPredictions()

                task.setTaskCompleted(success: true)
                logger.debug("Background refresh completed successfully")

            } catch {
                logger.error("Background refresh failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }

        // Handle task expiration
        task.expirationHandler = {
            logger.warning("Background refresh task expired")
            refreshTask.cancel()
        }

        // Schedule next refresh
        scheduleBackgroundRefresh()
    }

    private func refreshNotifications() async throws {
        // Refresh notification schedules based on latest baby data
        guard let baby = try await dataStore.fetchBabies().first else {
            logger.debug("No baby data available for notification refresh")
            return
        }

        // Update notification schedules
        await notificationScheduler.scheduleNotifications(for: baby)

        logger.debug("Notifications refreshed in background")
    }

    private func refreshPredictions() async throws {
        // Refresh cached predictions if they exist
        // This is a placeholder for more complex prediction refresh logic
        logger.debug("Predictions refreshed in background")
    }

    func cancelAllBackgroundTasks() {
        BGTaskScheduler.shared.cancelAllTaskRequests()
        logger.debug("All background tasks cancelled")
    }
}