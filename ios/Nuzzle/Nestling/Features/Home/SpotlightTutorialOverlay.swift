import SwiftUI

struct SpotlightTutorialOverlay: View {
    @Binding var isPresented: Bool
    @State private var currentStep: Int = 0
    let onDismiss: () -> Void
    
    private let tutorials: [(title: String, message: String, highlightArea: HighlightArea)] = [
        ("Quick Logging", "Tap the + button to log feeds, sleep, and diapers in seconds", .fab),
        ("Your Timeline", "All events appear here. Swipe to edit or delete", .timeline),
        ("Smart Insights", "Get AI-powered nap predictions and feeding suggestions", .insights)
    ]
    
    enum HighlightArea {
        case fab
        case timeline
        case insights
    }
    
    var body: some View {
        ZStack {
            // Dark overlay with spotlight effect
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    nextStep()
                }
            
            VStack {
                Spacer()
                
                // Tutorial card
                VStack(spacing: .spacingLG) {
                    // Title
                    Text(tutorials[currentStep].title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    // Message
                    Text(tutorials[currentStep].message)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, .spacingLG)
                    
                    // Progress dots
                    HStack(spacing: .spacingSM) {
                        ForEach(0..<tutorials.count, id: \.self) { index in
                            Circle()
                                .fill(index == currentStep ? Color.white : Color.white.opacity(0.3))
                                .frame(width: 8, height: 8)
                        }
                    }
                    .padding(.top, .spacingSM)
                    
                    // Action buttons
                    HStack(spacing: .spacingMD) {
                        if currentStep < tutorials.count - 1 {
                            Button("Next") {
                                nextStep()
                            }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(.radiusLG)
                        } else {
                            Button("Got it!") {
                                finish()
                            }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.white)
                            .cornerRadius(.radiusLG)
                        }
                        
                        Button("Skip") {
                            finish()
                        }
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.top, .spacingMD)
                }
                .padding(.spacingXL)
                .background(Color.primary)
                .cornerRadius(.radiusXL)
                .padding(.horizontal, .spacingLG)
                .padding(.bottom, 100)
            }
        }
        .transition(.opacity)
    }
    
    private func nextStep() {
        if currentStep < tutorials.count - 1 {
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep += 1
            }
            Haptics.light()
        } else {
            finish()
        }
    }
    
    private func finish() {
        withAnimation(.easeInOut(duration: 0.2)) {
            isPresented = false
        }
        Haptics.success()
        onDismiss()
    }
}

#Preview {
    @State var isPresented = true
    return SpotlightTutorialOverlay(isPresented: $isPresented) {
        print("Tutorial dismissed")
    }
}
