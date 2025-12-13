import Foundation
import Combine

/// Success metrics dashboard for UX improvements
/// Tracks KPIs across all phases with weekly/monthly reporting
@MainActor
class SuccessMetricsService: ObservableObject {
    static let shared = SuccessMetricsService()

    // MARK: - Core Metrics

    @Published var weeklyMetrics: WeeklyMetrics = .zero
    @Published var monthlyMetrics: MonthlyMetrics = .zero

    // MARK: - Acquisition Metrics

    struct AcquisitionMetrics {
        var trialStarts: Int = 0
        var trialConversionRate: Double = 0.0  // Target: 45%
        var timeToFirstLog: TimeInterval = 0   // Target: <60 seconds
        var weekOverWeekTrialGrowth: Double = 0.0
    }

    // MARK: - Retention Metrics

    struct RetentionMetrics {
        var day1Retention: Double = 0.0   // Target: 35%+
        var day7Retention: Double = 0.0   // Target: 50%+
        var day30Retention: Double = 0.0  // Target: 30%+
        var monthlyChurn: Double = 0.0    // Target: <5%
    }

    // MARK: - Monetization Metrics

    struct MonetizationMetrics {
        var monthlyRecurringRevenue: Double = 0.0
        var annualVsMonthlySplit: Double = 0.0  // Target: 70% annual
        var cancellationFlowSaveRate: Double = 0.0  // Target: 35%+
        var averageRevenuePerUser: Double = 0.0
    }

    // MARK: - Engagement Metrics

    struct EngagementMetrics {
        var activeUsers: Int = 0
        var logsPerUserPerDay: Double = 0.0  // Target: 3+
        var featureAdoptionRate: Double = 0.0
        var sessionDuration: TimeInterval = 0
    }

    // MARK: - Weekly & Monthly Reports

    struct WeeklyMetrics {
        var acquisition: AcquisitionMetrics
        var retention: RetentionMetrics
        var monetization: MonetizationMetrics
        var engagement: EngagementMetrics
        var reportDate: Date

        static let zero = WeeklyMetrics(
            acquisition: .init(),
            retention: .init(),
            monetization: .init(),
            engagement: .init(),
            reportDate: Date()
        )
    }

    struct MonthlyMetrics {
        var revenueGrowth: Double = 0.0
        var userGrowth: Double = 0.0
        var churnRate: Double = 0.0
        var customerSatisfaction: Double = 0.0  // Target: 4.5+/5
        var netPromoterScore: Double = 0.0      // Target: 50+
        var appStoreRating: Double = 0.0        // Target: 4.7+
        var reportDate: Date

        static let zero = MonthlyMetrics(reportDate: Date())
    }

    // MARK: - Initialization

    private init() {
        loadLatestMetrics()
        startWeeklyReporting()
    }

    // MARK: - Data Loading

    private func loadLatestMetrics() {
        // Load from UserDefaults or local storage
        // This would integrate with analytics service
        weeklyMetrics = loadWeeklyMetrics()
        monthlyMetrics = loadMonthlyMetrics()
    }

    private func loadWeeklyMetrics() -> WeeklyMetrics {
        // TODO: Integrate with analytics to get real data
        // For now, return zero/placeholder data
        return .zero
    }

    private func loadMonthlyMetrics() -> MonthlyMetrics {
        // TODO: Integrate with analytics to get real data
        return .zero
    }

    // MARK: - Reporting

    private func startWeeklyReporting() {
        // Schedule weekly reports every Monday at 9 AM
        Timer.scheduledTimer(withTimeInterval: 7*24*60*60, repeats: true) { _ in
            Task { @MainActor in
                await self.generateWeeklyReport()
            }
        }
    }

    func generateWeeklyReport() async {
        // Generate comprehensive weekly report
        let report = await createWeeklyReport()

        // Log to analytics
        await Analytics.shared.log("weekly_metrics_report", parameters: [
            "trial_starts": report.acquisition.trialStarts,
            "trial_conversion": report.acquisition.trialConversionRate,
            "day1_retention": report.retention.day1Retention,
            "day7_retention": report.retention.day7Retention,
            "monthly_churn": report.retention.monthlyChurn,
            "mrr_growth": report.monetization.monthlyRecurringRevenue,
            "annual_split": report.monetization.annualVsMonthlySplit,
            "save_rate": report.monetization.cancellationFlowSaveRate
        ])

        // Save locally
        saveWeeklyMetrics(report)

        // Send to team (would integrate with Slack/Email)
        await sendWeeklyReportToTeam(report)
    }

    private func createWeeklyReport() async -> WeeklyMetrics {
        // This would gather data from various sources:
        // - Analytics service for user behavior
        // - Revenue tracking for monetization
        // - App Store Connect for ratings/downloads

        // Placeholder implementation
        return WeeklyMetrics(
            acquisition: AcquisitionMetrics(
                trialStarts: 150,  // This week
                trialConversionRate: 42.0,
                timeToFirstLog: 45.0,
                weekOverWeekTrialGrowth: 12.5
            ),
            retention: RetentionMetrics(
                day1Retention: 38.0,
                day7Retention: 52.0,
                day30Retention: 32.0,
                monthlyChurn: 4.2
            ),
            monetization: MonetizationMetrics(
                monthlyRecurringRevenue: 12500.0,
                annualVsMonthlySplit: 68.0,
                cancellationFlowSaveRate: 28.0,
                averageRevenuePerUser: 12.50
            ),
            engagement: EngagementMetrics(
                activeUsers: 1200,
                logsPerUserPerDay: 3.2,
                featureAdoptionRate: 45.0,
                sessionDuration: 180.0
            ),
            reportDate: Date()
        )
    }

    // MARK: - Data Persistence

    private func saveWeeklyMetrics(_ metrics: WeeklyMetrics) {
        // Save to UserDefaults or Core Data
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(metrics) {
            UserDefaults.standard.set(data, forKey: "latest_weekly_metrics")
        }
    }

    private func sendWeeklyReportToTeam(_ metrics: WeeklyMetrics) async {
        // This would send the report via email/Slack
        // For now, just log it
        print("📊 Weekly Report Generated:")
        print("Trial Starts: \(metrics.acquisition.trialStarts)")
        print("Trial Conversion: \(String(format: "%.1f", metrics.acquisition.trialConversionRate))%")
        print("Day 1 Retention: \(String(format: "%.1f", metrics.retention.day1Retention))%")
        print("Day 7 Retention: \(String(format: "%.1f", metrics.retention.day7Retention))%")
        print("Monthly Churn: \(String(format: "%.1f", metrics.retention.monthlyChurn))%")
        print("MRR: $\(String(format: "%.0f", metrics.monetization.monthlyRecurringRevenue))")
        print("Annual Split: \(String(format: "%.1f", metrics.monetization.annualVsMonthlySplit))%")
        print("Save Rate: \(String(format: "%.1f", metrics.monetization.cancellationFlowSaveRate))%")
    }

    // MARK: - Phase Success Checklists

    func checkPhase1Success() -> Bool {
        // Phase 1: Foundation & Critical UX (Weeks 2-3)
        let metrics = weeklyMetrics
        return metrics.acquisition.timeToFirstLog < 60 &&
               metrics.retention.day1Retention >= 35 &&
               metrics.engagement.logsPerUserPerDay >= 2.5
    }

    func checkPhase2Success() -> Bool {
        // Phase 2: Delight & Conversion (Weeks 4-5)
        let metrics = weeklyMetrics
        return metrics.retention.day7Retention >= 50 &&
               metrics.monetization.cancellationFlowSaveRate >= 25 &&
               metrics.engagement.featureAdoptionRate >= 30
    }

    func checkPhase3Success() -> Bool {
        // Phase 3: Growth Mechanics (Weeks 6-8)
        let metrics = weeklyMetrics
        return metrics.acquisition.trialStarts > 100 && // Growing
               metrics.monetization.annualVsMonthlySplit >= 65 &&
               metrics.engagement.activeUsers > 1000
    }

    func checkPhase4Success() -> Bool {
        // Phase 4: Trust & Polish (Weeks 9-12)
        let metrics = weeklyMetrics
        return metrics.retention.monthlyChurn < 5 &&
               metrics.engagement.sessionDuration >= 180 &&
               metrics.monetization.averageRevenuePerUser >= 10
    }

    func checkPhase5Success() -> Bool {
        // Phase 5: Churn Prevention (Weeks 13-14)
        let metrics = weeklyMetrics
        return metrics.monetization.cancellationFlowSaveRate >= 35 &&
               metrics.retention.day30Retention >= 30 &&
               metrics.acquisition.trialConversionRate >= 40
    }

    // MARK: - Benchmark Comparison

    func compareToBenchmarks() -> BenchmarkComparison {
        let metrics = weeklyMetrics

        return BenchmarkComparison(
            trialConversion: BenchmarkResult(
                actual: metrics.acquisition.trialConversionRate,
                benchmark: 37.0,  // Industry median
                upperQuartile: 60.0,
                status: getStatus(metrics.acquisition.trialConversionRate, benchmark: 37.0)
            ),
            day1Retention: BenchmarkResult(
                actual: metrics.retention.day1Retention,
                benchmark: 25.0,
                upperQuartile: 40.0,
                status: getStatus(metrics.retention.day1Retention, benchmark: 25.0)
            ),
            monthlyChurn: BenchmarkResult(
                actual: metrics.retention.monthlyChurn,
                benchmark: 5.0,
                upperQuartile: 3.0,
                status: getStatus(metrics.retention.monthlyChurn, benchmark: 5.0, reverse: true)
            )
        )
    }

    private func getStatus(_ actual: Double, benchmark: Double, reverse: Bool = false) -> BenchmarkStatus {
        let difference = reverse ? benchmark - actual : actual - benchmark
        if difference > 10 { return .excellent }
        if difference > 0 { return .good }
        if difference > -5 { return .average }
        return .needsImprovement
    }
}

// MARK: - Benchmark Types

enum BenchmarkStatus {
    case excellent, good, average, needsImprovement

    var description: String {
        switch self {
        case .excellent: return "Excellent - Significantly above benchmark"
        case .good: return "Good - Above benchmark"
        case .average: return "Average - At benchmark level"
        case .needsImprovement: return "Needs Improvement - Below benchmark"
        }
    }
}

struct BenchmarkResult {
    let actual: Double
    let benchmark: Double
    let upperQuartile: Double
    let status: BenchmarkStatus
}

struct BenchmarkComparison {
    let trialConversion: BenchmarkResult
    let day1Retention: BenchmarkResult
    let monthlyChurn: BenchmarkResult
}