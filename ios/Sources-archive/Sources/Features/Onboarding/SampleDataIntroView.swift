import SwiftUI

/// View that explains and allows loading of sample data
struct SampleDataIntroView: View {
    @Environment(\.dismiss) var dismiss
    let onLoadSample: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingLG) {
                    // Header
                    VStack(spacing: .spacingSM) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 48))
                            .foregroundColor(NuzzleTheme.primary)

                        Text("Sample Data")
                            .font(.title.bold())
                            .foregroundColor(NuzzleTheme.textPrimary)

                        Text("See Nuzzle in action with realistic data")
                            .font(.body)
                            .foregroundColor(NuzzleTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, .spacingMD)

                    // Explanation
                    VStack(alignment: .leading, spacing: .spacingMD) {
                        VStack(alignment: .leading, spacing: .spacingSM) {
                            Text("What's included:")
                                .font(.headline)
                                .foregroundColor(NuzzleTheme.textPrimary)

                            VStack(alignment: .leading, spacing: .spacingXS) {
                                BulletPoint("24 hours of realistic feeding, sleep, and diaper patterns")
                                BulletPoint("Typical schedule for a 3-month-old baby")
                                BulletPoint("Nap predictions and insights")
                                BulletPoint("Complete timeline with time-since indicators")
                            }
                        }

                        VStack(alignment: .leading, spacing: .spacingSM) {
                            Text("Perfect for:")
                                .font(.headline)
                                .foregroundColor(NuzzleTheme.textPrimary)

                            VStack(alignment: .leading, spacing: .spacingXS) {
                                BulletPoint("Understanding how Nuzzle works")
                                BulletPoint("Testing features before entering real data")
                                BulletPoint("Learning the app's flow and capabilities")
                            }
                        }

                        VStack(alignment: .leading, spacing: .spacingSM) {
                            Text("You can always:")
                                .font(.headline)
                                .foregroundColor(NuzzleTheme.textPrimary)

                            VStack(alignment: .leading, spacing: .spacingXS) {
                                BulletPoint("Clear sample data and start fresh")
                                BulletPoint("Add your real baby data alongside or instead")
                                BulletPoint("Use the sample data as a reference")
                            }
                        }
                    }
                    .padding(.horizontal, .spacingMD)

                    Spacer(minLength: .spacing2XL)
                }
                .padding(.vertical, .spacingMD)
            }
            .background(NuzzleTheme.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        onLoadSample()
                    }) {
                        Text("Load Sample Data")
                            .font(.body.bold())
                    }
                }
            }
        }
    }
}

/// Bullet point component
struct BulletPoint: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: .spacingSM) {
            Text("•")
                .foregroundColor(NuzzleTheme.primary)
                .font(.body)

            Text(text)
                .font(.body)
                .foregroundColor(NuzzleTheme.textSecondary)
                .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    SampleDataIntroView(onLoadSample: {
        print("Sample data loaded")
    })
}



