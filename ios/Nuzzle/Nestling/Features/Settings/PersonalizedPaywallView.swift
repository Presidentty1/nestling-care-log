import SwiftUI

/// Personalized paywall that contextualizes value based on user behavior
/// Research: Personalization can increase trial-to-paid conversion from 40% → 60%
///
/// Design: Per UX Polish plan Phase 2.3
/// - Calculate user stats in real-time
/// - Show only 3 most relevant features
/// - Contextualize copy based on usage and goals
struct PersonalizedPaywallView: View {
    let source: String
    let userStats: UserStats
    let userGoal: String?
    let onSubscribe: (String) -> Void
    let onDismiss: () -> Void
    
    @StateObject private var subscriptionService = ProSubscriptionService.shared
    @State private var selectedPlan: SubscriptionPlan = .annual
    @State private var isLoading = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header with personalized headline
                VStack(alignment: .leading, spacing: 8) {
                    Text(personalizedHeadline)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(personalizedSubheadline)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // User value summary
                if userStats.daysUsed > 0 {
                    UserValueCard(stats: userStats)
                        .padding(.horizontal)
                }
                
                // Plan selector - Annual first (67% choose annual)
                VStack(spacing: 12) {
                    // Annual plan (FEATURED)
                    PlanSelectionCard(
                        plan: .annual,
                        isSelected: selectedPlan == .annual,
                        isFeatured: true,
                        onSelect: { selectedPlan = .annual }
                    )
                    
                    // Monthly plan
                    PlanSelectionCard(
                        plan: .monthly,
                        isSelected: selectedPlan == .monthly,
                        isFeatured: false,
                        onSelect: { selectedPlan = .monthly }
                    )
                }
                .padding(.horizontal)
                
                // Relevant features (only show 3 most relevant)
                VStack(alignment: .leading, spacing: 16) {
                    Text("What's included:")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    ForEach(relevantFeatures, id: \.title) { feature in
                        FeatureRow(
                            icon: feature.icon,
                            title: feature.title,
                            description: feature.description
                        )
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(uiColor: .secondarySystemGroupedBackground))
                )
                .padding(.horizontal)
                
                // Privacy badge
                if PolishFeatureFlags.privacyMessaging {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                        Text("HIPAA-aligned privacy practices")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                }
                
                // Subscribe button
                Button(action: subscribe) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text(ctaText)
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(isLoading)
                .padding(.horizontal)
                
                // Terms and restore
                VStack(spacing: 8) {
                    Button("Restore Purchase") {
                        Task {
                            // Handle restore
                        }
                    }
                    .font(.footnote)
                    .foregroundColor(.secondary)
                    
                    Text("Auto-renews. Cancel anytime.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        Button("Terms") { /* Show terms */ }
                        Button("Privacy") { /* Show privacy */ }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
        .navigationTitle("Unlock Pro")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Not Now") {
                    onDismiss()
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
        }
        .onAppear {
            // Track paywall view with variant
            Task {
                await Analytics.shared.logPaywallViewed(source: source, variant: "personalized")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var personalizedHeadline: String {
        if let goal = userGoal {
            if goal.lowercased().contains("sleep") || goal.lowercased().contains("nap") {
                return "Get AI nap predictions that actually work"
            } else if goal.lowercased().contains("feed") {
                return "Never wonder 'when did they last eat?'"
            } else if goal.lowercased().contains("cry") {
                return "Understand what your baby needs"
            }
        }
        
        // Default based on usage
        if userStats.totalLogs > 0 {
            return "\(userStats.babyName)'s patterns are emerging"
        }
        
        return "Track smarter, worry less"
    }
    
    private var personalizedSubheadline: String {
        if userStats.daysUsed > 0 {
            return "Keep the momentum going with Pro insights"
        }
        return "Get AI-powered predictions and insights"
    }
    
    private var relevantFeatures: [Feature] {
        // Show only 3 most relevant features based on goal
        if let goal = userGoal {
            if goal.lowercased().contains("sleep") {
                return [
                    Feature(
                        icon: "moon.stars.fill",
                        title: "AI nap predictions",
                        description: "Know when \(userStats.babyName) needs to nap—before the meltdown"
                    ),
                    Feature(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Sleep pattern insights",
                        description: "See patterns you'd miss on your own"
                    ),
                    Feature(
                        icon: "waveform",
                        title: "Cry analysis (Beta)",
                        description: "Understand what different cries might mean"
                    )
                ]
            } else if goal.lowercased().contains("feed") {
                return [
                    Feature(
                        icon: "clock.arrow.circlepath",
                        title: "Feed tracking made simple",
                        description: "Never wonder 'when did they last eat?'"
                    ),
                    Feature(
                        icon: "chart.bar.fill",
                        title: "Feeding insights",
                        description: "Track intake and spot patterns early"
                    ),
                    Feature(
                        icon: "person.2.fill",
                        title: "Partner sync",
                        description: "Keep everyone on the same page automatically"
                    )
                ]
            }
        }
        
        // Default feature set
        return [
            Feature(
                icon: "moon.stars.fill",
                title: "AI nap & feed predictions",
                description: "Know what's next before your baby tells you"
            ),
            Feature(
                icon: "chart.line.uptrend.xyaxis",
                title: "Pattern insights",
                description: "See trends and correlations you'd otherwise miss"
            ),
            Feature(
                icon: "person.2.fill",
                title: "Partner sync",
                description: "Real-time sync with co-parents and caregivers"
            )
        ]
    }
    
    private var ctaText: String {
        switch selectedPlan {
        case .monthly:
            return "Start Free Trial"
        case .annual:
            return "Start Free Trial (14 Days)"
        }
    }
    
    // MARK: - Actions
    
    private func subscribe() {
        isLoading = true
        onSubscribe(selectedPlan == .annual ? "annual" : "monthly")
        // isLoading will be reset by parent view
    }
}

/// User stats for personalization
struct UserStats {
    let babyName: String
    let totalLogs: Int
    let daysUsed: Int
    let timeSavedMinutes: Int
    
    var formattedTimeSaved: String {
        if timeSavedMinutes < 60 {
            return "\(timeSavedMinutes) minutes"
        } else {
            let hours = timeSavedMinutes / 60
            return "\(hours) hour\(hours == 1 ? "" : "s")"
        }
    }
}

/// User value card showing personal achievements
struct UserValueCard: View {
    let stats: UserStats
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your progress so far:")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            VStack(alignment: .leading, spacing: 8) {
                StatRow(
                    icon: "checkmark.circle.fill",
                    text: "\(stats.totalLogs) events tracked for \(stats.babyName)",
                    color: .green
                )
                
                StatRow(
                    icon: "calendar",
                    text: "\(stats.daysUsed) days of insights",
                    color: .blue
                )
                
                StatRow(
                    icon: "clock.fill",
                    text: "\(stats.formattedTimeSaved) saved vs. paper notes",
                    color: .orange
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.1))
        )
    }
}

/// Stat row for user value card
struct StatRow: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.body)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}

/// Plan selection card (annual vs monthly)
struct PlanSelectionCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let isFeatured: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(plan.priceDescription)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    
                    Spacer()
                    
                    // Selection indicator
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .accentColor : .gray)
                        .font(.title3)
                }
                
                if plan == .annual {
                    Text("Save $69 vs monthly")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.green)
                }
                
                Text(plan.billingCycle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(
                        isSelected ? Color.accentColor : Color.gray.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isFeatured ? Color.accentColor.opacity(0.05) : Color.clear)
                    )
            )
            .overlay(alignment: .topTrailing) {
                if isFeatured {
                    Text("MOST POPULAR")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.accentColor)
                        )
                        .offset(x: -8, y: -8)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

/// Subscription plan enum
enum SubscriptionPlan {
    case monthly
    case annual
    
    var displayName: String {
        switch self {
        case .monthly: return "Monthly"
        case .annual: return "Annual"
        }
    }
    
    var priceDescription: String {
        switch self {
        case .monthly: return "$9.99/month"
        case .annual: return "$49.99/year"
        }
    }
    
    var perMonthPrice: String? {
        switch self {
        case .monthly: return nil
        case .annual: return "Just $4.17/month"
        }
    }
    
    var billingCycle: String {
        switch self {
        case .monthly: return "Billed monthly • Cancel anytime"
        case .annual: return "Billed annually • Cancel anytime"
        }
    }
}

/// Feature row for feature list
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

/// Feature model
struct Feature {
    let icon: String
    let title: String
    let description: String
}

// MARK: - Preview

#Preview("Sleep Goal") {
    NavigationView {
        PersonalizedPaywallView(
            source: "home_prediction",
            userStats: UserStats(
                babyName: "Emma",
                totalLogs: 47,
                daysUsed: 5,
                timeSavedMinutes: 85
            ),
            userGoal: "Better sleep tracking",
            onSubscribe: { plan in
                print("Subscribe to: \(plan)")
            },
            onDismiss: {
                print("Dismissed")
            }
        )
    }
}

#Preview("Feed Goal") {
    NavigationView {
        PersonalizedPaywallView(
            source: "feed_tracking",
            userStats: UserStats(
                babyName: "Oliver",
                totalLogs: 23,
                daysUsed: 3,
                timeSavedMinutes: 42
            ),
            userGoal: "Feeding tracking",
            onSubscribe: { plan in
                print("Subscribe to: \(plan)")
            },
            onDismiss: {
                print("Dismissed")
            }
        )
    }
}

#Preview("New User") {
    NavigationView {
        PersonalizedPaywallView(
            source: "onboarding",
            userStats: UserStats(
                babyName: "Liam",
                totalLogs: 0,
                daysUsed: 0,
                timeSavedMinutes: 0
            ),
            userGoal: nil,
            onSubscribe: { plan in
                print("Subscribe to: \(plan)")
            },
            onDismiss: {
                print("Dismissed")
            }
        )
    }
}
