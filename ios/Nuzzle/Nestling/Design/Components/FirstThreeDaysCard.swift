import SwiftUI

/// Progress card for First 72 Hours Journey
/// Research: 10 logs in first 3 days = 3x retention
///
/// Displays on Home screen during first 3 days
/// Shows progress toward goals and encouragement
struct FirstThreeDaysCard: View {
    @StateObject private var journeyService = FirstThreeDaysJourneyService.shared
    @State private var showFullJourney = false
    
    var body: some View {
        Button(action: { showFullJourney = true }) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Image(systemName: "flag.checkered")
                        .font(.title3)
                        .foregroundColor(.orange)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your first 72 hours")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(dayText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                
                // Progress bar
                ProgressView(value: journeyService.journeyProgress)
                    .tint(.orange)
                
                // Current goal
                if let currentGoal = getCurrentGoal() {
                    HStack {
                        Image(systemName: "target")
                            .foregroundColor(.orange)
                            .font(.subheadline)
                        
                        Text(currentGoal)
                            .font(.subheadline)
                            .foregroundColor(.primary)
                    }
                }
                
                // Encouragement
                Text(encouragementText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.orange.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showFullJourney) {
            FirstThreeDaysDetailView()
        }
    }
    
    // MARK: - Computed Properties
    
    private var dayText: String {
        let day = journeyService.currentDay
        switch day {
        case 0: return "Day 1 of 3"
        case 1: return "Day 2 of 3"
        case 2: return "Day 3 of 3"
        default: return "Complete!"
        }
    }
    
    private func getCurrentGoal() -> String? {
        let completed = journeyService.getCompletedMilestones()
        
        // Return first incomplete goal
        if !completed.contains(.day0_firstLog) {
            return "Log your first event"
        }
        if !completed.contains(.day1_partnerInvite) && journeyService.currentDay >= 1 {
            return "Invite your partner to sync"
        }
        if !completed.contains(.day2_predictionAccuracy) && journeyService.currentDay >= 2 {
            return "Check your prediction accuracy"
        }
        if !completed.contains(.day3_completionCelebration) && journeyService.currentDay >= 3 {
            return "Celebrate 3 days!"
        }
        
        return nil
    }
    
    private var encouragementText: String {
        let progress = journeyService.journeyProgress
        
        if progress < 0.3 {
            return "You're off to a great start!"
        } else if progress < 0.6 {
            return "You're doing amazing! Keep it up."
        } else if progress < 0.9 {
            return "Almost there! One more push."
        } else {
            return "You've mastered the basics! 🎉"
        }
    }
}

/// Detailed view of First 72 Hours Journey
struct FirstThreeDaysDetailView: View {
    @StateObject private var journeyService = FirstThreeDaysJourneyService.shared
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "flag.checkered.2.crossed")
                                .font(.largeTitle)
                                .foregroundColor(.orange)
                            
                            Spacer()
                        }
                        
                        Text("Your First 72 Hours")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Build habits that lead to better sleep and less stress")
                            .font(.body)
                            .foregroundColor(.secondary)
                        
                        // Overall progress
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Overall Progress")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                Text("\(Int(journeyService.journeyProgress * 100))%")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.orange)
                            }
                            
                            ProgressView(value: journeyService.journeyProgress)
                                .tint(.orange)
                        }
                    }
                    .padding()
                    
                    // Day-by-day breakdown
                    ForEach(0..<3) { day in
                        DaySection(day: day)
                    }
                }
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("First 72 Hours")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

/// Day section showing goals and progress
struct DaySection: View {
    let day: Int
    @StateObject private var journeyService = FirstThreeDaysJourneyService.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Day header
            HStack {
                Text("Day \(day + 1)")
                    .font(.title3)
                    .fontWeight(.bold)
                
                Spacer()
                
                if isDayComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            .padding(.horizontal)
            
            // Goals for this day
            VStack(alignment: .leading, spacing: 12) {
                ForEach(getDayGoals(), id: \.rawValue) { milestone in
                    GoalRow(
                        milestone: milestone,
                        isCompleted: journeyService.isMilestoneCompleted(milestone)
                    )
                }
            }
        }
        .padding(.vertical)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
        .padding(.horizontal)
    }
    
    private func getDayGoals() -> [FirstThreeDaysJourneyService.DayMilestone] {
        return journeyService.getMilestones(for: day)
    }
    
    private var isDayComplete: Bool {
        let goals = getDayGoals()
        let completed = journeyService.getCompletedMilestones()
        return goals.allSatisfy { completed.contains($0) }
    }
}

/// Individual goal row
struct GoalRow: View {
    let milestone: FirstThreeDaysJourneyService.DayMilestone
    let isCompleted: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isCompleted ? .green : .gray)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(milestone.title)
                    .font(.body)
                    .fontWeight(isCompleted ? .medium : .regular)
                    .foregroundColor(.primary)
                    .strikethrough(isCompleted)
                
                Text(milestone.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview("Card") {
    VStack {
        FirstThreeDaysCard()
        Spacer()
    }
    .padding()
    .background(Color(uiColor: .systemGroupedBackground))
}

#Preview("Detail View") {
    FirstThreeDaysDetailView()
}
