import SwiftUI

/// Simplified assistant view with preset prompts instead of full chat
struct GuidedAssistantView: View {
    @Environment(\.dismiss) var dismiss
    @State private var selectedPrompt: AssistantPrompt?
    @State private var isShowingResponse = false
    @State private var responseText = ""
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ZStack {
                NuzzleTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: .spacingLG) {
                        // Header
                        VStack(spacing: .spacingSM) {
                            Image(systemName: "bubble.left.and.bubble.right.fill")
                                .font(.system(size: 48))
                                .foregroundColor(NuzzleTheme.primary)

                            Text("Ask Nuzzle")
                                .font(.title.bold())
                                .foregroundColor(NuzzleTheme.textPrimary)

                            Text("Get guidance on sleep, feeding, and development")
                                .font(.body)
                                .foregroundColor(NuzzleTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, .spacingMD)
                        .padding(.top, .spacingLG)

                        // Disclaimer
                        VStack(spacing: .spacingXS) {
                            Text("⚠️ Medical Disclaimer")
                                .font(.caption.bold())
                                .foregroundColor(.orange)

                            Text("This is not medical advice. Always consult healthcare professionals for medical concerns.")
                                .font(.caption)
                                .foregroundColor(NuzzleTheme.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, .spacingMD)

                        // Preset prompts
                        VStack(alignment: .leading, spacing: .spacingMD) {
                            Text("Choose a question:")
                                .font(.headline)
                                .foregroundColor(NuzzleTheme.textPrimary)
                                .padding(.horizontal, .spacingMD)

                            ForEach(AssistantPrompt.allCases) { prompt in
                                PromptButton(prompt: prompt) {
                                    selectPrompt(prompt)
                                }
                            }
                        }

                        Spacer(minLength: .spacing2XL)
                    }
                }

                // Response overlay
                if isShowingResponse {
                    ResponseOverlay(
                        prompt: selectedPrompt!,
                        response: responseText,
                        onDismiss: {
                            isShowingResponse = false
                            selectedPrompt = nil
                            responseText = ""
                        }
                    )
                    .transition(.opacity)
                }
            }
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

    private func selectPrompt(_ prompt: AssistantPrompt) {
        selectedPrompt = prompt
        isLoading = true

        // Simulate AI response (in real implementation, this would call an AI service)
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 second delay

            await MainActor.run {
                responseText = generateResponse(for: prompt)
                isLoading = false
                withAnimation {
                    isShowingResponse = true
                }
            }
        }
    }

    private func generateResponse(for prompt: AssistantPrompt) -> String {
        switch prompt {
        case .wakeWindow:
            return """
            Based on typical sleep patterns for babies your age, it's common to see wake windows of 60-90 minutes between naps during the day. However, every baby is different!

            Signs your baby might be ready for a nap include:
            • Rubbing eyes
            • Yawning
            • Fussing or being less engaged
            • Quieter than usual

            Remember, these are general patterns. Your baby's individual needs may vary.
            """

        case .feedingSchedule:
            return """
            Feeding frequency varies by age and feeding method. Here's a general guide:

            **0-1 month:** Every 2-3 hours (8-12 feeds/day)
            **1-3 months:** Every 3-4 hours (6-8 feeds/day)
            **3-6 months:** Every 4-5 hours (5-6 feeds/day)

            Look for hunger cues like rooting, sucking on fists, or increased alertness. Trust your baby's signals over any schedule.

            If you're concerned about feeding patterns, consult your pediatrician.
            """

        case .napPatterns:
            return """
            Most babies follow predictable nap patterns based on their age:

            **Newborns (0-3 months):** 3-5 short naps totaling 14-17 hours sleep
            **3-6 months:** 3-4 naps, 13-15 hours total sleep
            **6-12 months:** 2-3 naps, 12-14 hours total sleep

            Your recent logs show [would analyze actual data here]. This looks [typical/atypical] for your baby's age.

            Sleep needs can vary widely between babies!
            """

        case .development:
            return """
            Every baby develops at their own pace. Common milestones around this age include:

            **Communication:** Cooing, babbling, responding to name
            **Motor skills:** Rolling over, reaching for objects
            **Social:** Smiling, recognizing familiar faces

            If you have concerns about development, discuss with your pediatrician. They can provide personalized guidance.
            """
        }
    }
}

/// Available assistant prompts
enum AssistantPrompt: String, CaseIterable, Identifiable {
    case wakeWindow = "Is this wake window okay?"
    case feedingSchedule = "How often should they be feeding?"
    case napPatterns = "Help me interpret today's naps"
    case development = "What should I expect developmentally?"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .wakeWindow: return "clock"
        case .feedingSchedule: return "drop.fill"
        case .napPatterns: return "moon.fill"
        case .development: return "figure.child"
        }
    }

    var color: Color {
        switch self {
        case .wakeWindow: return NuzzleTheme.accentSleep
        case .feedingSchedule: return NuzzleTheme.primary
        case .napPatterns: return NuzzleTheme.accentSleep
        case .development: return NuzzleTheme.accentTummy
        }
    }
}

/// Button for selecting a preset prompt
struct PromptButton: View {
    let prompt: AssistantPrompt
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: .spacingMD) {
                Image(systemName: prompt.icon)
                    .font(.system(size: 20))
                    .foregroundColor(prompt.color)
                    .frame(width: 24, height: 24)

                Text(prompt.rawValue)
                    .font(.body)
                    .foregroundColor(NuzzleTheme.textPrimary)
                    .multilineTextAlignment(.leading)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.spacingMD)
            .background(NuzzleTheme.surface)
            .cornerRadius(.radiusMD)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel("Ask: \(prompt.rawValue)")
    }
}

/// Overlay showing the AI response
struct ResponseOverlay: View {
    let prompt: AssistantPrompt
    let response: String
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }

            VStack(spacing: .spacingLG) {
                // Header
                VStack(spacing: .spacingSM) {
                    Image(systemName: prompt.icon)
                        .font(.system(size: 32))
                        .foregroundColor(prompt.color)

                    Text(prompt.rawValue)
                        .font(.headline)
                        .foregroundColor(NuzzleTheme.textPrimary)
                        .multilineTextAlignment(.center)
                }

                // Response
                ScrollView {
                    Text(response)
                        .font(.body)
                        .foregroundColor(NuzzleTheme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(4)
                }
                .frame(maxHeight: 300)
                .padding(.spacingMD)
                .background(NuzzleTheme.surface)
                .cornerRadius(.radiusMD)

                // Close button
                Button(action: onDismiss) {
                    Text("Got it")
                        .font(.body.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.spacingMD)
                        .background(NuzzleTheme.primary)
                        .cornerRadius(.radiusMD)
                }
                .padding(.horizontal, .spacingMD)
            }
            .padding(.spacingLG)
            .background(NuzzleTheme.background)
            .cornerRadius(.radiusLG)
            .shadow(radius: 20)
            .padding(.spacingLG)
        }
    }
}

#Preview {
    GuidedAssistantView()
}
