import Foundation
import Combine

@MainActor
class NowNextViewModel: ObservableObject {
    @Published var lastFeedSummary: String = "Last feed: none logged yet"
    @Published var wakeDurationText: String = "Awake time: we'll estimate after a sleep log."
    @Published var nextNapWindowText: String = "Next nap window: More sleep logs needed."
    @Published var nextFeedWindowText: String?
    @Published var disclaimerText: String = "Suggestions are informational and not medical advice."
    
    // Epic 4: Additional properties for three-segment strip
    @Published var nowStateText: String = "Awake"
    @Published var nextNapWindowExplanation: String?
    @Published var typicalFeedRange: String?

    private let dataStore: DataStore
    private let baby: Baby
    private var cancellables = Set<AnyCancellable>()

    init(dataStore: DataStore, baby: Baby) {
        self.dataStore = dataStore
        self.baby = baby
        loadData()
    }

    func loadData() {
        Task {
            await loadLastFeed()
            await loadWakeDuration()
            await loadNextNapWindow()
            await loadNextFeedWindow()
            await loadCurrentState()
        }
    }
    
    private func loadCurrentState() async {
        do {
            if try await dataStore.getActiveSleep(for: baby) {
                await MainActor.run {
                    nowStateText = "Asleep"
                }
            } else {
                await MainActor.run {
                    nowStateText = "Awake"
                }
            }
        } catch {
            await MainActor.run {
                nowStateText = "Awake"
            }
        }
    }

    private func loadLastFeed() async {
        do {
            let events = try await dataStore.fetchEvents(for: baby, from: Date().startOfDay, to: Date().endOfDay)
            let lastFeed = events
                .filter { $0.type == .feed }
                .sorted { $0.startTime > $1.startTime }
                .first

            if let feed = lastFeed {
                let amount = feed.amount ?? 0
                let unit = feed.unit ?? "ml"
                let timeString = DateUtils.formatTime(feed.startTime)
                lastFeedSummary = "Last feed: \(Int(amount)) \(unit) at \(timeString)"
            } else {
                lastFeedSummary = "Last feed: none logged yet"
            }
        } catch {
            lastFeedSummary = "Last feed: none logged yet"
        }
    }

    private func loadWakeDuration() async {
        do {
            let events = try await dataStore.fetchEvents(for: baby, from: Date().startOfDay, to: Date().endOfDay)
            let lastSleep = events
                .filter { $0.type == .sleep }
                .sorted { $0.endTime ?? $0.startTime > $1.endTime ?? $1.startTime }
                .first

            if let sleep = lastSleep, let endTime = sleep.endTime {
                let now = Date()
                let wakeDuration = now.timeIntervalSince(endTime)

                if wakeDuration > 0 {
                    let hours = Int(wakeDuration / 3600)
                    let minutes = Int((wakeDuration.truncatingRemainder(dividingBy: 3600)) / 60)

                    if hours > 0 {
                        wakeDurationText = "Awake for: \(hours)h \(minutes)m"
                    } else {
                        wakeDurationText = "Awake for: \(minutes)m"
                    }
                } else {
                    wakeDurationText = "Awake time: we'll estimate after a sleep log."
                }
            } else {
                wakeDurationText = "Awake time: we'll estimate after a sleep log."
            }
        } catch {
            wakeDurationText = "Awake time: we'll estimate after a sleep log."
        }
    }

    private func loadNextNapWindow() async {
        do {
            if let prediction = try await dataStore.fetchPredictions(for: baby, type: .nextNap) {
                let timeString = DateUtils.formatTime(prediction.predictedTime)
                let babyName = baby.name.isEmpty ? "your baby" : baby.name
                nextNapWindowText = "Next nap window: \(timeString)"
                nextNapWindowExplanation = "Based on \(babyName)'s age and last wake time"
            } else {
                nextNapWindowText = "Next nap window: More sleep logs needed."
                nextNapWindowExplanation = "Using typical patterns for this age until we learn more"
            }
            } catch {
                nextNapWindowText = "Next nap window: More sleep logs needed."
                nextNapWindowExplanation = "Using typical patterns for this age until we learn more"
            }

            // Analytics for nap suggestion viewed
            if let prediction = try? await dataStore.fetchPredictions(for: baby, type: .nextNap), prediction.predictedTime > Date() {
                let ageDays = Calendar.current.dateComponents([.day], from: baby.dateOfBirth, to: Date()).day ?? 0
                Task {
                    await Analytics.shared.log("nap_suggestion_viewed", parameters: [
                        "age_days": ageDays,
                        "wake_duration_minutes": 0 // Could calculate this if needed
                    ])
                }
            }
    }

    private func loadNextFeedWindow() async {
        do {
            // Calculate typical feed range based on baby age
            let ageInMonths = Calendar.current.dateComponents([.month], from: baby.dateOfBirth, to: Date()).month ?? 0
            if ageInMonths < 1 {
                typicalFeedRange = "Common range 1.5–2h"
            } else if ageInMonths < 3 {
                typicalFeedRange = "Common range 2–3h"
            } else if ageInMonths < 6 {
                typicalFeedRange = "Common range 3–4h"
            } else {
                typicalFeedRange = "Common range 3–4h"
            }
            
            if let prediction = try await dataStore.fetchPredictions(for: baby, type: .nextFeed) {
                let timeString = DateUtils.formatTime(prediction.predictedTime)
                nextFeedWindowText = "Next feed window: around \(timeString)"
            } else {
                nextFeedWindowText = nil
            }
        } catch {
            nextFeedWindowText = nil
        }
    }
}

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: self) ?? self
    }
}
