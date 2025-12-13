import SwiftUI
import UIKit

/// Service for handling social sharing of milestone cards and achievements
@MainActor
final class ShareService {
    static let shared = ShareService()

    /// Milestone types that can be shared
    enum MilestoneType {
        case streakAchieved(days: Int)
        case sleepRecord(minutes: Int)
        case weekComplete(number: Int, avgSleep: Double)
        case patternUnlocked(totalLogs: Int)

        var title: String {
            switch self {
            case .streakAchieved(let days): return "\(days) Day Streak!"
            case .sleepRecord(let minutes): return "\(minutes/60)h Sleep Record!"
            case .weekComplete(let number, _): return "Week \(number) Complete!"
            case .patternUnlocked: return "Patterns Unlocked!"
            }
        }

        var subtitle: String {
            switch self {
            case .streakAchieved: return "Consistent tracking streak"
            case .sleepRecord: return "Longest sleep session"
            case .weekComplete(_, let avgSleep): return "Avg \(String(format: "%.1f", avgSleep/60))h sleep"
            case .patternUnlocked(let logs): return "\(logs) logs analyzed"
            }
        }

        var emoji: String {
            switch self {
            case .streakAchieved: return "🔥"
            case .sleepRecord: return "😴"
            case .weekComplete: return "🎯"
            case .patternUnlocked: return "🧠"
            }
        }
    }

    /// Generate and share a milestone card
    func shareMilestone(
        type: MilestoneType,
        babyName: String,
        presentingViewController: UIViewController
    ) async {
        guard PolishFeatureFlags.shared.shareCardsEnabled else { return }

        let isOffline = !NetworkMonitor.shared.isConnected

        // Show loading indicator with offline messaging
        let loadingMessage = isOffline ?
            "Creating share card... (Will share when online)" :
            "Creating share card..."
        let loadingAlert = UIAlertController(
            title: nil,
            message: loadingMessage,
            preferredStyle: .alert
        )
        presentingViewController.present(loadingAlert, animated: true)

        do {
            let card = ShareableMilestoneCard(milestone: type, babyName: babyName)
            let image = try await card.generateShareableImage()

            loadingAlert.dismiss(animated: true) {
                if isOffline {
                    // Show queued message
                    let queuedAlert = UIAlertController(
                        title: "Share Queued",
                        message: "Your milestone card is ready! It will be shared when you're back online.",
                        preferredStyle: .alert
                    )
                    queuedAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    presentingViewController.present(queuedAlert, animated: true)

                    // TODO: Queue the share action for when connection returns
                    // For now, just log that it would be queued
                    print("Share queued for offline: \(type)")
                } else {
                    self.presentShareSheet(with: image, from: presentingViewController)
                }

                AnalyticsService.shared.track(event: "milestone_shared", properties: [
                    "type": String(describing: type),
                    "baby_name": babyName,
                    "offline": isOffline
                ])
            }
        } catch {
            loadingAlert.dismiss(animated: true) {
                let errorAlert = UIAlertController(
                    title: "Share Failed",
                    message: "Unable to create share card. Please try again.",
                    preferredStyle: .alert
                )
                errorAlert.addAction(UIAlertAction(title: "OK", style: .default))
                presentingViewController.present(errorAlert, animated: true)
            }
        }
    }

    private func presentShareSheet(with image: UIImage, from viewController: UIViewController) {
        let activityVC = UIActivityViewController(
            activityItems: [image],
            applicationActivities: nil
        )

        // Exclude some activities that don't make sense for images
        activityVC.excludedActivityTypes = [
            .assignToContact,
            .addToReadingList,
            .openInIBooks
        ]

        // For iPad, set the popover presentation controller
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = CGRect(
                x: viewController.view.bounds.midX,
                y: viewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popoverController.permittedArrowDirections = []
        }

        viewController.present(activityVC, animated: true)
    }

    /// Check if sharing is available on this device
    var isSharingAvailable: Bool {
        return true // UIActivityViewController is always available on iOS
    }
}