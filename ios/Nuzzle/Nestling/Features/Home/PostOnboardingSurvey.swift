import SwiftUI

/// Survey shown after 7 days to collect feedback (Phase 5)
struct PostOnboardingSurvey: View {
    @Binding var isPresented: Bool
    @State private var selectedRating: Int = 0
    @State private var feedback: String = ""
    @State private var hasSubmitted = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    dismiss()
                }
            
            VStack(spacing: .spacingXL) {
                VStack(spacing: .spacingMD) {
                    Text("Quick Question")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.foreground)
                    
                    Text("How was your onboarding experience?")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                }
                
                // Star rating
                HStack(spacing: .spacingMD) {
                    ForEach(1...5, id: \.self) { rating in
                        Button(action: {
                            selectedRating = rating
                            Haptics.selection()
                        }) {
                            Image(systemName: rating <= selectedRating ? "star.fill" : "star")
                                .font(.system(size: 32))
                                .foregroundColor(rating <= selectedRating ? Color.yellow : Color.mutedForeground)
                        }
                    }
                }
                
                // Feedback text
                VStack(alignment: .leading, spacing: .spacingSM) {
                    Text("What could be better? (Optional)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.mutedForeground)
                    
                    TextEditor(text: $feedback)
                        .frame(height: 100)
                        .padding(.spacingSM)
                        .background(Color.surface)
                        .cornerRadius(.radiusMD)
                        .overlay(
                            RoundedRectangle(cornerRadius: .radiusMD)
                                .stroke(Color.cardBorder, lineWidth: 1)
                        )
                }
                
                // Action buttons
                VStack(spacing: .spacingMD) {
                    Button(action: {
                        submitFeedback()
                    }) {
                        Text(hasSubmitted ? "Thank You!" : "Submit Feedback")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(hasSubmitted ? Color.green : Color.primary)
                            .cornerRadius(.radiusLG)
                    }
                    .disabled(selectedRating == 0 || hasSubmitted)
                    
                    Button("Skip") {
                        dismiss()
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.mutedForeground)
                }
            }
            .padding(.spacingXL)
            .background(Color.background)
            .cornerRadius(.radius2XL)
            .shadow(color: Color.black.opacity(0.2), radius: 20, x: 0, y: 10)
            .padding(.horizontal, .spacingLG)
        }
    }
    
    private func submitFeedback() {
        Task {
            // Log to analytics
            await Analytics.shared.log("onboarding_survey_completed", parameters: [
                "rating": selectedRating,
                "has_feedback": !feedback.isEmpty,
                "feedback_length": feedback.count
            ])
            
            // In a real app, send feedback to backend
            // For now, just mark as submitted
            hasSubmitted = true
            Haptics.success()
            
            // Auto-dismiss after brief delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                dismiss()
            }
        }
    }
    
    private func dismiss() {
        withAnimation(.easeInOut) {
            isPresented = false
        }
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboardingSurvey")
        Haptics.light()
    }
}

#Preview {
    @Previewable @State var isPresented = true
    return PostOnboardingSurvey(isPresented: $isPresented)
}

