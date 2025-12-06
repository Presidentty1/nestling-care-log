import SwiftUI

struct Last7DaysTrendsView: View {
    @EnvironmentObject var environment: AppEnvironment
    let babyId: UUID
    @Environment(\.dismiss) var dismiss

    @State private var weeklyData: WeeklyTrendsData?
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    LoadingStateView(message: "Loading your baby's patterns...")
                } else if let data = weeklyData {
                    ScrollView {
                        VStack(alignment: .leading, spacing: .spacingLG) {
                            // Header
                            VStack(alignment: .leading, spacing: .spacingSM) {
                                Text("Last 7 Days")
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.foreground)

                                Text("Your baby's patterns at a glance")
                                    .font(.body)
                                    .foregroundColor(.mutedForeground)
                            }

                            // Daily Sleep Summary
                            CardView(variant: .default) {
                                VStack(alignment: .leading, spacing: .spacingMD) {
                                    HStack(spacing: .spacingSM) {
                                        Image(systemName: "moon.fill")
                                            .foregroundColor(.eventSleep)
                                            .font(.title3)
                                        Text("Daily Sleep")
                                            .font(.headline)
                                            .foregroundColor(.foreground)
                                    }

                                    Text("Total sleep hours per day")
                                        .font(.subheadline)
                                        .foregroundColor(.mutedForeground)

                                    // Simple sleep bars
                                    VStack(spacing: .spacingSM) {
                                        ForEach(data.dailySleep.sorted(by: { $0.date < $1.date }), id: \.date) { day in
                                            HStack(spacing: .spacingSM) {
                                                Text(formatDayName(day.date))
                                                    .font(.caption)
                                                    .foregroundColor(.mutedForeground)
                                                    .frame(width: 40, alignment: .leading)

                                                GeometryReader { geometry in
                                                    ZStack(alignment: .leading) {
                                                        // Background bar
                                                        RoundedRectangle(cornerRadius: 2)
                                                            .fill(Color.eventSleep.opacity(0.2))
                                                            .frame(height: 20)

                                                        // Sleep bar
                                                        RoundedRectangle(cornerRadius: 2)
                                                            .fill(Color.eventSleep)
                                                            .frame(width: max(4, (day.totalHours / 16.0) * geometry.size.width), height: 20)
                                                    }
                                                }
                                                .frame(height: 20)

                                                Text(String(format: "%.1f", day.totalHours))
                                                    .font(.caption)
                                                    .foregroundColor(.foreground)
                                                    .frame(width: 35, alignment: .trailing)
                                            }
                                        }
                                    }

                                    Divider()

                                    // Summary stats
                                    HStack(spacing: .spacingLG) {
                                        VStack(alignment: .leading) {
                                            Text("Average")
                                                .font(.caption)
                                                .foregroundColor(.mutedForeground)
                                            Text(String(format: "%.1f hrs", data.averageSleepPerDay))
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.foreground)
                                        }

                                        VStack(alignment: .leading) {
                                            Text("Most Sleep")
                                                .font(.caption)
                                                .foregroundColor(.mutedForeground)
                                            Text(String(format: "%.1f hrs", data.maxSleepDay))
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.foreground)
                                        }
                                    }
                                }
                                .padding(.spacingMD)
                            }

                            // First Nap Times
                            CardView(variant: .default) {
                                VStack(alignment: .leading, spacing: .spacingMD) {
                                    HStack(spacing: .spacingSM) {
                                        Image(systemName: "sunrise.fill")
                                            .foregroundColor(.orange)
                                            .font(.title3)
                                        Text("First Nap Times")
                                            .font(.headline)
                                            .foregroundColor(.foreground)
                                    }

                                    if data.firstNapTimes.isEmpty {
                                        Text("No nap data for this period")
                                            .font(.body)
                                            .foregroundColor(.mutedForeground)
                                    } else {
                                        VStack(spacing: .spacingSM) {
                                            ForEach(data.firstNapTimes.sorted(by: { $0.date < $1.date }), id: \.date) { nap in
                                                HStack {
                                                    Text(formatDayName(nap.date))
                                                        .font(.caption)
                                                        .foregroundColor(.mutedForeground)
                                                        .frame(width: 40, alignment: .leading)

                                                    Spacer()

                                                    Text(formatTime(nap.time))
                                                        .font(.body)
                                                        .foregroundColor(.foreground)
                                                }
                                            }
                                        }

                                        Divider()

                                        Text("Average: \(formatTime(data.averageFirstNapTime))")
                                            .font(.subheadline)
                                            .foregroundColor(.foreground)
                                    }
                                }
                                .padding(.spacingMD)
                            }

                            // Feeding Summary
                            CardView(variant: .default) {
                                VStack(alignment: .leading, spacing: .spacingMD) {
                                    HStack(spacing: .spacingSM) {
                                        Image(systemName: "drop.fill")
                                            .foregroundColor(.eventFeed)
                                            .font(.title3)
                                        Text("Feeding")
                                            .font(.headline)
                                            .foregroundColor(.foreground)
                                    }

                                    HStack(spacing: .spacingLG) {
                                        VStack(alignment: .leading) {
                                            Text("Total Feeds")
                                                .font(.caption)
                                                .foregroundColor(.mutedForeground)
                                            Text("\(data.totalFeeds)")
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.foreground)
                                        }

                                        VStack(alignment: .leading) {
                                            Text("Avg per Day")
                                                .font(.caption)
                                                .foregroundColor(.mutedForeground)
                                            Text(String(format: "%.1f", data.averageFeedsPerDay))
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.foreground)
                                        }
                                    }
                                }
                                .padding(.spacingMD)
                            }

                            // Diaper Summary
                            CardView(variant: .default) {
                                VStack(alignment: .leading, spacing: .spacingMD) {
                                    HStack(spacing: .spacingSM) {
                                        Image(systemName: "drop.circle.fill")
                                            .foregroundColor(.eventDiaper)
                                            .font(.title3)
                                        Text("Diapers")
                                            .font(.headline)
                                            .foregroundColor(.foreground)
                                    }

                                    HStack(spacing: .spacingLG) {
                                        VStack(alignment: .leading) {
                                            Text("Total Changes")
                                                .font(.caption)
                                                .foregroundColor(.mutedForeground)
                                            Text("\(data.totalDiapers)")
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.foreground)
                                        }

                                        VStack(alignment: .leading) {
                                            Text("Avg per Day")
                                                .font(.caption)
                                                .foregroundColor(.mutedForeground)
                                            Text(String(format: "%.1f", data.averageDiapersPerDay))
                                                .font(.title3)
                                                .fontWeight(.semibold)
                                                .foregroundColor(.foreground)
                                        }
                                    }
                                }
                                .padding(.spacingMD)
                            }
                        }
                        .padding(.spacingMD)
                    }
                } else {
                    EmptyStateView(
                        icon: "chart.bar.fill",
                        title: "No data yet",
                        message: "Log more feeds, sleep, and diapers to see your baby's patterns."
                    )
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .fontWeight(.semibold)
                    }
                }
            }
            .task {
                await loadWeeklyData()
            }
        }
    }

    private func loadWeeklyData() async {
        isLoading = true
        defer { isLoading = false }

        do {
            // Calculate date range (last 7 days)
            let endDate = Date()
            let startDate = Calendar.current.date(byAdding: .day, value: -6, to: endDate) ?? endDate

            let events = try await environment.dataStore.fetchEvents(for: environment.currentBaby ?? Baby.mock(), from: startDate, to: endDate)

            // Process data
            let calendar = Calendar.current
            var dailySleep: [Date: Double] = [:]
            var firstNapTimes: [Date: Date] = [:]
            var dailyFeeds: [Date: Int] = [:]
            var dailyDiapers: [Date: Int] = [:]

            for event in events {
                let day = calendar.startOfDay(for: event.startTime)

                switch event.type {
                case .sleep:
                    if let endTime = event.endTime {
                        let duration = endTime.timeIntervalSince(event.startTime) / 3600.0 // hours
                        dailySleep[day, default: 0] += duration

                        // Track first nap time
                        if firstNapTimes[day] == nil || event.startTime < firstNapTimes[day]! {
                            firstNapTimes[day] = event.startTime
                        }
                    }

                case .feed:
                    dailyFeeds[day, default: 0] += 1

                case .diaper:
                    dailyDiapers[day, default: 0] += 1

                default:
                    break
                }
            }

            // Convert to display format
            let dailySleepData = dailySleep.map { DailySleepData(date: $0.key, totalHours: $0.value) }
            let firstNapData = firstNapTimes.map { FirstNapData(date: $0.key, time: $0.value) }

            let totalSleep = dailySleepData.reduce(0) { $0 + $1.totalHours }
            let averageSleep = dailySleepData.isEmpty ? 0 : totalSleep / Double(dailySleepData.count)
            let maxSleep = dailySleepData.map { $0.totalHours }.max() ?? 0

            let totalFeeds = dailyFeeds.values.reduce(0, +)
            let averageFeeds = dailyFeeds.isEmpty ? 0 : Double(totalFeeds) / Double(dailyFeeds.count)

            let totalDiapers = dailyDiapers.values.reduce(0, +)
            let averageDiapers = dailyDiapers.isEmpty ? 0 : Double(totalDiapers) / Double(dailyDiapers.count)

            let avgFirstNapTime = firstNapData.isEmpty ? Date() :
                Date(timeIntervalSince1970: firstNapData.map { $0.time.timeIntervalSince1970 }.reduce(0, +) / Double(firstNapData.count))

            weeklyData = WeeklyTrendsData(
                dailySleep: dailySleepData,
                firstNapTimes: firstNapData,
                averageSleepPerDay: averageSleep,
                maxSleepDay: maxSleep,
                totalFeeds: totalFeeds,
                averageFeedsPerDay: averageFeeds,
                totalDiapers: totalDiapers,
                averageDiapersPerDay: averageDiapers,
                averageFirstNapTime: avgFirstNapTime
            )

        } catch {
            print("Failed to load weekly data: \(error)")
            weeklyData = nil
        }
    }

    private func formatDayName(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Data Structures

struct WeeklyTrendsData {
    let dailySleep: [DailySleepData]
    let firstNapTimes: [FirstNapData]
    let averageSleepPerDay: Double
    let maxSleepDay: Double
    let totalFeeds: Int
    let averageFeedsPerDay: Double
    let totalDiapers: Int
    let averageDiapersPerDay: Double
    let averageFirstNapTime: Date
}

struct DailySleepData {
    let date: Date
    let totalHours: Double
}

struct FirstNapData {
    let date: Date
    let time: Date
}

#Preview {
    Last7DaysTrendsView(babyId: UUID())
        .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
}
