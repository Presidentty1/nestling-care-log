import SwiftUI

/// Strategic cancellation flow UI
/// Research: Can save 42-58% of canceling users
///
/// Designed to be presented as a modal sheet from subscription settings
struct CancellationFlowView: View {
    @StateObject private var coordinator = CancellationFlowCoordinator.shared
    @Environment(\.dismiss) private var dismiss
    
    let currentPlan: String
    let source: String
    
    var body: some View {
        NavigationView {
            Group {
                switch coordinator.currentStep {
                case .valueReminder:
                    ValueReminderStep(
                        stats: coordinator.userStats,
                        onContinue: {
                            coordinator.moveToReasonSelection()
                        },
                        onKeepSubscription: {
                            dismiss()
                        }
                    )
                    
                case .reasonSelection:
                    ReasonSelectionStep(
                        onReasonSelected: { reason in
                            Task {
                                await coordinator.reasonSelected(reason)
                            }
                        }
                    )
                    
                case .retentionOffer:
                    if let offer = coordinator.retentionOffer {
                        RetentionOfferStep(
                            offer: offer,
                            onAccept: {
                                Task {
                                    await coordinator.acceptedRetentionOffer()
                                    dismiss()
                                }
                            },
                            onDecline: {
                                coordinator.declinedRetentionOffer()
                            }
                        )
                    }
                    
                case .lossAversion:
                    LossAversionStep(
                        stats: coordinator.userStats,
                        onKeepSubscription: {
                            dismiss()
                        },
                        onContinueCancellation: {
                            Task {
                                await coordinator.confirmCancellation()
                                dismiss()
                            }
                        }
                    )
                    
                case .none:
                    // Flow not started yet
                    ProgressView()
                        .onAppear {
                            Task {
                                await coordinator.startCancellationFlow(
                                    currentPlan: currentPlan,
                                    source: source
                                )
                            }
                        }
                }
            }
            .navigationTitle("Cancel Subscription")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Step 1: Value Reminder

struct ValueReminderStep: View {
    let stats: CancellationUserStats?
    let onContinue: () -> Void
    let onKeepSubscription: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 12) {
                    Text("Before you go...")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Here's what you'll lose access to:")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Value items
                if let stats = stats {
                    VStack(spacing: 16) {
                        ValueLossCard(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "\(stats.totalLogs) events tracked",
                            description: "All your tracking history for \(stats.babyName)"
                        )
                        
                        ValueLossCard(
                            icon: "sparkles",
                            title: "\(stats.accuratePredictions) accurate predictions",
                            description: "AI-powered nap and feed windows this month"
                        )
                        
                        if let partnerName = stats.partnerName {
                            ValueLossCard(
                                icon: "person.2.fill",
                                title: "Partner sync with \(partnerName)",
                                description: "Real-time collaboration with your co-parent"
                            )
                        }
                        
                        ValueLossCard(
                            icon: "clock.arrow.circlepath",
                            title: "Complete feeding history",
                            description: "Never wonder 'when did they last eat?' again"
                        )
                        
                        ValueLossCard(
                            icon: "brain",
                            title: "Pattern insights",
                            description: "Correlations and trends you'd miss otherwise"
                        )
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 32)
                
                // Actions
                VStack(spacing: 12) {
                    Button(action: onKeepSubscription) {
                        Text("Keep My Subscription")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: onContinue) {
                        Text("Continue Canceling")
                            .font(.body)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

struct ValueLossCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.orange)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(uiColor: .secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Step 2: Reason Selection

struct ReasonSelectionStep: View {
    let onReasonSelected: (CancellationReason) -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("We're sorry to see you go")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("What's the main reason you're canceling?")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Reason buttons
                VStack(spacing: 12) {
                    ForEach(CancellationReason.allCases) { reason in
                        Button(action: { onReasonSelected(reason) }) {
                            HStack {
                                Text(reason.displayText)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(uiColor: .secondarySystemGroupedBackground))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

// MARK: - Step 3: Retention Offer

struct RetentionOfferStep: View {
    let offer: RetentionOffer
    let onAccept: () -> Void
    let onDecline: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Offer details
                VStack(alignment: .leading, spacing: 16) {
                    Image(systemName: "gift.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    
                    Text(offer.title)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(offer.description)
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    Text(offer.terms)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green.opacity(0.1))
                        )
                }
                .padding(.horizontal)
                .padding(.top)
                
                Spacer(minLength: 32)
                
                // Actions
                VStack(spacing: 12) {
                    Button(action: onAccept) {
                        Text(offer.cta)
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: onDecline) {
                        Text("No thanks, cancel anyway")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

// MARK: - Step 4: Loss Aversion

struct LossAversionStep: View {
    let stats: CancellationUserStats?
    let onKeepSubscription: () -> Void
    let onContinueCancellation: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Are you sure?")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("If you cancel, you'll lose:")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.top)
                
                // Loss items with strikethrough effect
                VStack(alignment: .leading, spacing: 12) {
                    LossItem(text: "AI nap predictions")
                    LossItem(text: "Feed & sleep insights")
                    LossItem(text: "Cry analysis (Beta)")
                    LossItem(text: "Pattern correlations")
                    LossItem(text: "Weekly summary emails")
                    
                    if stats?.partnerName != nil {
                        LossItem(text: "Real-time partner sync")
                    }
                }
                .padding(.horizontal)
                
                // What you keep
                VStack(alignment: .leading, spacing: 12) {
                    Text("You'll keep:")
                        .font(.headline)
                    
                    KeepItem(text: "Basic tracking (free forever)")
                    KeepItem(text: "Your complete history")
                    KeepItem(text: "Manual predictions")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.05))
                )
                .padding(.horizontal)
                
                Spacer(minLength: 32)
                
                // Final actions
                VStack(spacing: 12) {
                    Button(action: onKeepSubscription) {
                        Text("Keep Pro")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: onContinueCancellation) {
                        Text("Yes, cancel my subscription")
                            .font(.body)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
        }
        .background(Color(uiColor: .systemGroupedBackground))
    }
}

struct LossItem: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
            Text(text)
                .strikethrough()
                .foregroundColor(.secondary)
        }
    }
}

struct KeepItem: View {
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            Text(text)
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Preview

#Preview("Value Reminder") {
    NavigationView {
        ValueReminderStep(
            stats: CancellationUserStats(
                totalLogs: 847,
                daysUsed: 42,
                accuratePredictions: 23,
                partnerName: "James"
            ),
            onContinue: { print("Continue") },
            onKeepSubscription: { print("Keep") }
        )
    }
}

#Preview("Reason Selection") {
    NavigationView {
        ReasonSelectionStep(
            onReasonSelected: { reason in
                print("Selected: \(reason.displayText)")
            }
        )
    }
}

#Preview("Retention Offer") {
    NavigationView {
        RetentionOfferStep(
            offer: RetentionOffer(
                type: .discount,
                title: "50% off for 3 months",
                description: "We'd love to keep you. Here's 50% off your next 3 months—just $4.99/month.",
                cta: "Accept Offer",
                terms: "Discount applies to next 3 renewals. Regular price resumes after."
            ),
            onAccept: { print("Accepted") },
            onDecline: { print("Declined") }
        )
    }
}

#Preview("Loss Aversion") {
    NavigationView {
        LossAversionStep(
            stats: CancellationUserStats(
                totalLogs: 847,
                daysUsed: 42,
                accuratePredictions: 23,
                partnerName: "James"
            ),
            onKeepSubscription: { print("Keep") },
            onContinueCancellation: { print("Cancel") }
        )
    }
}
