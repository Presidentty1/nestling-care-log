import SwiftUI

/// Interactive tutorial overlay shown on first Home screen visit
/// Part of Phase 3: Conversion & Advanced Tutorial
struct HomeTutorialOverlay: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var currentStep: TutorialStep = .quickActions
    @State private var showSpotlight = false
    let onComplete: () -> Void
    
    enum TutorialStep {
        case quickActions
        case timeline
        case predictions
        
        var title: String {
            switch self {
            case .quickActions:
                return "Quick Actions"
            case .timeline:
                return "Your Timeline"
            case .predictions:
                return "AI Predictions"
            }
        }
        
        var message: String {
            switch self {
            case .quickActions:
                return "Tap these buttons to log feeds, sleep, and diapers in seconds"
            case .timeline:
                return "All your events appear here. Swipe to edit or delete."
            case .predictions:
                return "Get AI-powered nap predictions to plan your day"
            }
        }
        
        var icon: String {
            switch self {
            case .quickActions:
                return "hand.tap.fill"
            case .timeline:
                return "clock.fill"
            case .predictions:
                return "sparkles"
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    nextStep()
                }
            
            VStack {
                Spacer()
                
                // Tutorial card
                VStack(spacing: .spacingLG) {
                    // Icon
                    Image(systemName: currentStep.icon)
                        .font(.system(size: 50))
                        .foregroundColor(Color.adaptivePrimary(colorScheme))
                    
                    // Title
                    Text(currentStep.title)
                        .font(.title2.bold())
                        .foregroundColor(Color.adaptiveForeground(colorScheme))
                        .multilineTextAlignment(.center)
                    
                    // Message
                    Text(currentStep.message)
                        .font(.body)
                        .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, .spacingMD)
                    
                    // Progress dots
                    HStack(spacing: .spacingSM) {
                        ForEach([TutorialStep.quickActions, .timeline, .predictions], id: \.self) { step in
                            Circle()
                                .fill(currentStep == step ? Color.adaptivePrimary(colorScheme) : Color.adaptiveTextTertiary(colorScheme))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top, .spacingSM)
                    
                    // Actions
                    VStack(spacing: .spacingSM) {
                        Button(action: nextStep) {
                            Text(currentStep == .predictions ? "Get Started" : "Next")
                                .font(.headline)
                                .foregroundColor(Color.adaptivePrimaryForeground(colorScheme))
                                .frame(maxWidth: .infinity)
                                .padding(.spacingMD)
                                .background(Color.adaptivePrimary(colorScheme))
                                .cornerRadius(.radiusMD)
                        }
                        
                        Button(action: skip) {
                            Text("Skip Tutorial")
                                .font(.body)
                                .foregroundColor(Color.adaptiveTextSecondary(colorScheme))
                        }
                    }
                    .padding(.top, .spacingSM)
                }
                .padding(.spacingXL)
                .background(Color.adaptiveSurface(colorScheme))
                .cornerRadius(.radiusLG)
                .padding(.spacingXL)
                .shadow(color: Color.black.opacity(0.3), radius: 20, x: 0, y: 10)
                
                Spacer()
            }
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.3)) {
                showSpotlight = true
            }
        }
    }
    
    private func nextStep() {
        switch currentStep {
        case .quickActions:
            withAnimation {
                currentStep = .timeline
            }
            Haptics.light()
        case .timeline:
            withAnimation {
                currentStep = .predictions
            }
            Haptics.light()
        case .predictions:
            complete()
        }
    }
    
    private func skip() {
        // Track skip in analytics
        Task {
            await Analytics.shared.log("home_tutorial_skipped", parameters: [
                "step": currentStep.title
            ])
        }
        complete()
    }
    
    private func complete() {
        // Track completion
        Task {
            await Analytics.shared.log("home_tutorial_completed", parameters: [
                "completed": currentStep == .predictions
            ])
        }
        
        withAnimation {
            onComplete()
        }
        Haptics.success()
    }
}

#Preview {
    ZStack {
        // Mock home screen background
        VStack {
            Text("Home Screen Content")
            Spacer()
        }
        
        HomeTutorialOverlay {
            print("Tutorial completed")
        }
    }
}

