import SwiftUI

struct SafetyDisclaimersView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacingLG) {
                    // Main disclaimer
                    CardView(variant: .warning) {
                        VStack(alignment: .leading, spacing: .spacingSM) {
                            Text("Medical Disclaimer")
                                .font(.headline)
                                .foregroundColor(.foreground)

                            Text("Nuzzle does not provide medical advice, diagnosis, or treatment.")
                                .font(.body)
                                .foregroundColor(.foreground)
                        }
                    }

                    // Emergency guidance
                    CardView(variant: .info) {
                        VStack(alignment: .leading, spacing: .spacingSM) {
                            Text("When to Contact a Professional")
                                .font(.headline)
                                .foregroundColor(.foreground)

                            Text("If your baby has a fever, difficulty breathing, signs of dehydration, unusual lethargy, or severe pain, contact a pediatric professional or emergency services.")
                                .font(.body)
                                .foregroundColor(.foreground)
                        }
                    }

                    // AI features disclaimer
                    CardView(variant: .elevated) {
                        VStack(alignment: .leading, spacing: .spacingSM) {
                            Text("AI Features")
                                .font(.headline)
                                .foregroundColor(.foreground)

                            Text("AI-powered features like nap predictions and cry analysis provide general information only. They are not medical advice and should not replace professional medical judgment.")
                                .font(.body)
                                .foregroundColor(.foreground)
                        }
                    }

                    // Data privacy
                    CardView(variant: .elevated) {
                        VStack(alignment: .leading, spacing: .spacingSM) {
                            Text("Data & Privacy")
                                .font(.headline)
                                .foregroundColor(.foreground)

                            Text("Your baby's data is stored locally on your device. When you choose to sync with caregivers or use cloud features, data is encrypted and transmitted securely.")
                                .font(.body)
                                .foregroundColor(.foreground)
                        }
                    }

                    Spacer()
                }
                .padding(.spacingMD)
            }
            .background(NuzzleTheme.background)
            .navigationTitle("Safety & Disclaimers")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SafetyDisclaimersView()
}
