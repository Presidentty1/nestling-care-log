import Foundation
import UIKit
import SwiftUI

/// Service for handling milestone sharing and social media integration
class ShareService {
    static let shared = ShareService()

    enum MilestoneType {
        case streakAchieved(days: Int)
        case sleepRecord(minutes: Int)
        case weekComplete(number: Int, avgSleep: Double)
        case patternUnlocked(totalLogs: Int)

        var title: String {
            switch self {
            case .streakAchieved(let days):
                return "🎯 \(days)-Day Streak!"
            case .sleepRecord(let minutes):
                return "😴 \(minutes/60)h \(minutes%60)m Sleep!"
            case .weekComplete(let number, _):
                return "🏆 Week \(number) Complete!"
            case .patternUnlocked:
                return "📊 Patterns Unlocked!"
            }
        }

        var message: String {
            switch self {
            case .streakAchieved(let days):
                return "I've been tracking my baby's sleep for \(days) days straight! 📱"
            case .sleepRecord(let minutes):
                let hours = minutes / 60
                return "My baby just slept for \(hours)h \(minutes % 60)m! These patterns are amazing! 😴"
            case .weekComplete(let number, _):
                return "Just completed week \(number) of tracking! Seeing real patterns emerge. 📈"
            case .patternUnlocked:
                return "My baby's sleep patterns are becoming clear! Consistency is key! 🎯"
            }
        }

        var shareableText: String {
            return "\(title)\n\(message)\n\nTracked with Nestling app"
        }
    }

    private init() {}

    /// Share a milestone with native iOS share sheet
    func shareMilestone(
        type: MilestoneType,
        babyName: String,
        presentingViewController: UIViewController
    ) async {
        // Create the share text
        let shareText = type.shareableText

        // Create activity view controller
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        // Configure for iPad
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = presentingViewController.view
            popoverController.sourceRect = CGRect(
                x: presentingViewController.view.bounds.midX,
                y: presentingViewController.view.bounds.midY,
                width: 0,
                height: 0
            )
            popoverController.permittedArrowDirections = []
        }

        // Exclude certain activities that don't make sense for milestone sharing
        activityVC.excludedActivityTypes = [
            .addToReadingList,
            .assignToContact,
            .print,
            .saveToCameraRoll
        ]

        // Present the share sheet
        await MainActor.run {
            presentingViewController.present(activityVC, animated: true)
        }

        // Track the share attempt
        AnalyticsService.shared.track(event: "milestone_share_attempted", properties: [
            "milestone_type": String(describing: type),
            "baby_name_provided": !babyName.isEmpty
        ])
    }

    /// Get the top view controller for presenting share sheets
    private func topViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }

        var topController = window.rootViewController
        while let presented = topController?.presentedViewController {
            topController = presented
        }

        return topController
    }
}