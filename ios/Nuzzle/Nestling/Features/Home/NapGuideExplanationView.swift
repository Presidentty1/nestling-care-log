import SwiftUI

struct NapGuideExplanationView: View {
    let babyName: String?
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacingLG) {
                    headerSection
                    explanationCards
                    if let babyName = babyName {
                        personalMessageSection(babyName: babyName)
                    }
                }
                .padding(.spacingMD)
            }
            .background(Color.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: .spacingSM) {
            Text("How Nestling Nap Guide Works")
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.foreground)

            Text("Personalized nap predictions based on age and patterns")
                .font(.subheadline)
                .foregroundColor(.mutedForeground)
        }
        .padding(.bottom, .spacingMD)
    }

    @ViewBuilder
    private var explanationCards: some View {
        VStack(alignment: .leading, spacing: .spacingLG) {
            smartNapWindowsCard
            getsSmarterCard
            freeVsProCard
            medicalDisclaimerCard
        }
    }

    @ViewBuilder
    private var smartNapWindowsCard: some View {
        CardView(variant: .default) {
            VStack(alignment: .leading, spacing: .spacingMD) {
                HStack {
                    Image(systemName: "moon.fill")
                        .foregroundColor(.eventSleep)
                        .font(.title2)
                    Text("Smart Nap Windows")
                        .font(.headline)
                        .foregroundColor(.foreground)
                }

                Text("Nestling predicts optimal nap times by analyzing:")
                    .font(.body)
                    .foregroundColor(.foreground)

                VStack(alignment: .leading, spacing: .spacingSM) {
                    BulletPoint("Age-appropriate wake windows (based on pediatric guidelines)")
                    BulletPoint("Your baby's recent sleep patterns")
                    BulletPoint("Last wake time and feeding schedule")
                }
            }
            .padding(.spacingMD)
        }
    }

    @ViewBuilder
    private var getsSmarterCard: some View {
        CardView(variant: .default) {
            VStack(alignment: .leading, spacing: .spacingMD) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(.primary)
                        .font(.title2)
                    Text("Gets Smarter Over Time")
                        .font(.headline)
                        .foregroundColor(.foreground)
                }

                Text("The more you log, the better the predictions become:")
                    .font(.body)
                    .foregroundColor(.foreground)

                VStack(alignment: .leading, spacing: .spacingSM) {
                    BulletPoint("Learns your baby's natural rhythm")
                    BulletPoint("Adapts to changes in schedule")
                    BulletPoint("Considers feeding timing")
                }
            }
            .padding(.spacingMD)
        }
    }

    @ViewBuilder
    private var freeVsProCard: some View {
        CardView(variant: .default) {
            VStack(alignment: .leading, spacing: .spacingMD) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.primary)
                        .font(.title2)
                    Text("Free vs Pro Predictions")
                        .font(.headline)
                        .foregroundColor(.foreground)
                }

                VStack(alignment: .leading, spacing: .spacingSM) {
                    HStack(alignment: .top, spacing: .spacingSM) {
                        Text("Free:")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.foreground)
                            .frame(width: 60, alignment: .leading)
                        Text("Age-based guidelines")
                            .font(.body)
                            .foregroundColor(.mutedForeground)
                    }

                    HStack(alignment: .top, spacing: .spacingSM) {
                        Text("Pro:")
                            .font(.body)
                            .fontWeight(.semibold)
                            .foregroundColor(.foreground)
                            .frame(width: 60, alignment: .leading)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Personalized patterns")
                            Text("Adapts to your baby")
                            Text("Smarter reminders")
                        }
                        .font(.body)
                        .foregroundColor(.mutedForeground)
                    }
                }
            }
            .padding(.spacingMD)
        }
    }

    @ViewBuilder
    private var medicalDisclaimerCard: some View {
        CardView(variant: .warning) {
            HStack(spacing: .spacingSM) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Medical Disclaimer")
                        .font(.headline)
                        .foregroundColor(.orange)
                    Text("Nestling gives general guidance, not medical care. If your baby seems very unwell or you're worried, contact a pediatric professional.")
                        .font(.caption)
                        .foregroundColor(.orange.opacity(0.8))
                }
            }
            .padding(.spacingMD)
        }
    }

    @ViewBuilder
    private func personalMessageSection(babyName: String) -> some View {
        CardView(variant: .default) {
            VStack(alignment: .leading, spacing: .spacingSM) {
                Text("About \(babyName)'s Predictions")
                    .font(.headline)
                    .foregroundColor(.foreground)

                Text("Predictions improve as \(babyName) develops and as you log more data. We'll adjust suggestions as you log more days.")
                    .font(.body)
                    .foregroundColor(.mutedForeground)
                    .multilineTextAlignment(.leading)
            }
            .padding(.spacingMD)
        }
    }
}

private struct BulletPoint: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: .spacingSM) {
            Text("•")
                .foregroundColor(.primary)
                .font(.body)
            Text(text)
                .foregroundColor(.foreground)
                .font(.body)
                .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    NapGuideExplanationView(babyName: "Emma")
}