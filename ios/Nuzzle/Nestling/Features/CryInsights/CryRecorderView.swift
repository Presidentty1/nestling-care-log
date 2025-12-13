import SwiftUI
import AVFoundation

struct CryRecorderView: View {
    @StateObject private var viewModel: CryRecorderViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showSaveConfirmation = false
    @StateObject private var proService = ProSubscriptionService.shared
    @State private var showProSubscription = false
    @State private var showFirstUseExplainer = false
    
    init(dataStore: DataStore, baby: Baby) {
        _viewModel = StateObject(wrappedValue: CryRecorderViewModel(dataStore: dataStore, baby: baby))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingLG) {
                    if showFirstUseExplainer {
                        InfoBanner(
                            title: "How Cry Insights works",
                            message: "Record a short clip and we’ll suggest a likely need. Audio stays on-device and is deleted after analysis. This is guidance only, not medical advice."
                        )
                        .padding(.horizontal, .spacingMD)
                    }
                    
                    // Medical Disclaimer
                    MedicalDisclaimer(variant: .ai)
                        .padding(.horizontal, .spacingMD)
                    
                    // Summary text
                    Text("Record your baby's cry and get a rough sense of what they might need.")
                        .font(.body)
                        .foregroundColor(.mutedForeground)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, .spacingMD)
                    
                    // Privacy Info
                    InfoBanner(
                        title: "Privacy & Data",
                        message: "Audio is recorded locally and analyzed on-device. Recordings are automatically deleted after analysis. No audio data is stored or transmitted.",
                        variant: .info
                    )
                    .padding(.horizontal, .spacingMD)
                    
                    // Beta disclaimer
                    InfoBanner(
                        title: "Experimental Feature",
                        message: "This is an experimental tool and not a medical device. If you’re worried about your baby’s health or pain, contact a pediatric professional or urgent care.",
                        variant: .warning
                    )
                    .padding(.horizontal, .spacingMD)
                    
                    // Recording UI
                    recordingUI
                    .padding(.vertical, .spacingMD)
                }
            }
            .navigationTitle("Cry Insights")
            .background(Color.background)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Microphone Permission Required", isPresented: $viewModel.showPermissionAlert) {
                Button("Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Nestling needs microphone access to record cry analysis. Please enable it in Settings.")
            }
            .alert("Save Insight", isPresented: $showSaveConfirmation) {
                Button("Save") {
                    Task {
                        do {
                            try await viewModel.saveInsight()
                            Haptics.success()
                            dismiss()
                        } catch {
                            Haptics.error()
                        }
                    }
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This will save the analysis as a note in your event log. The audio recording will be deleted.")
            }
            .sheet(isPresented: $showProSubscription) {
                ProSubscriptionView()
            }
            .onAppear {
                let hasSeen = UserDefaults.standard.bool(forKey: "cry_insights_seen_explainer")
                if !hasSeen {
                    showFirstUseExplainer = true
                    UserDefaults.standard.set(true, forKey: "cry_insights_seen_explainer")
                }
            }
        }
    }
    
    @ViewBuilder
    private var recordingUI: some View {
        VStack(spacing: .spacingMD) {
            if case .recording = viewModel.state {
                            // Waveform visualization (simplified)
                            VStack(spacing: .spacingSM) {
                                Text("Recording...")
                                    .font(.headline)
                                    .foregroundColor(.foreground)
                                
                                Text(formatDuration(viewModel.recordingDuration))
                                    .font(.title)
                                    .fontWeight(.bold)
                                    .foregroundColor(.primary)
                                
                                // Power level indicator
                                HStack(spacing: 4) {
                                    ForEach(0..<20, id: \.self) { index in
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(powerColor(for: index))
                                            .frame(width: 4, height: CGFloat.random(in: 10...40))
                                    }
                                }
                                .frame(height: 50)
                            }
                            .padding(.spacing2XL)
                            .frame(maxWidth: .infinity)
                            .background(Color.surface)
                            .cornerRadius(.radiusLG)
                            
                            PrimaryButton("Stop Recording", icon: "stop.fill") {
                                viewModel.stopRecording()
                            }
                            .padding(.horizontal, .spacingMD)
                        } else if case .processing = viewModel.state {
                            // Processing state
                            VStack(spacing: .spacingMD) {
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .scaleEffect(1.5)
                                
                                Text("Analyzing...")
                                    .font(.headline)
                                    .foregroundColor(.foreground)
                                
                                Text("This may take a few seconds")
                                    .font(.caption)
                                    .foregroundColor(.mutedForeground)
                            }
                            .padding(.spacing2XL)
                            .frame(maxWidth: .infinity)
                            .background(Color.surface)
                            .cornerRadius(.radiusLG)
                            .padding(.horizontal, .spacingMD)
                        } else if case .error(let message) = viewModel.state {
                            // Error state
                            CardView(variant: .emphasis) {
                                VStack(spacing: .spacingMD) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.destructive)
                                    
                                    Text("Analysis Failed")
                                        .font(.headline)
                                        .foregroundColor(.foreground)
                                    
                                    Text(message)
                                        .font(.body)
                                        .foregroundColor(.mutedForeground)
                                        .multilineTextAlignment(.center)
                                    
                                    // Show upgrade button if quota exceeded
                                    if message.contains("weekly limit") || message.contains("quota") {
                                        PrimaryButton("Upgrade to Pro", icon: "star.fill") {
                                            Task {
                                                await Analytics.shared.logPaywallViewed(source: "cry_insights_quota_exceeded")
                                            }
                                            showProSubscription = true
                                        }
                                    } else {
                                        HStack(spacing: .spacingSM) {
                                            SecondaryButton("Discard", icon: "xmark.circle.fill") {
                                                viewModel.discardRecording()
                                            }
                                            
                                            PrimaryButton("Try Again", icon: "arrow.clockwise") {
                                                viewModel.retry()
                                            }
                                        }
                                    }
                                }
                                .padding(.spacingMD)
                            }
                            .padding(.horizontal, .spacingMD)
                        } else if let classification = viewModel.classification, case .result = viewModel.state {
                            // Analysis Result - Gate behind Pro
                            if proService.isProUser {
                                // Pro users see full results
                                CardView(variant: .emphasis) {
                                    VStack(alignment: .leading, spacing: .spacingMD) {
                                        HStack {
                                            Text("Analysis Result")
                                                .font(.headline)
                                                .foregroundColor(.foreground)
                                            
                                            Spacer()
                                            
                                            Text("\(Int(viewModel.confidence * 100))% confidence")
                                                .font(.caption)
                                                .foregroundColor(.mutedForeground)
                                        }
                                        
                                        // Category with icon and color
                                        HStack(spacing: .spacingSM) {
                                            Image(systemName: categoryIcon(for: classification))
                                                .foregroundColor(categoryColor(for: classification))
                                                .font(.title3)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Most likely: \(classification.displayName)")
                                                    .font(.title2)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.foreground)
                                                
                                                Text("\(Int(viewModel.confidence * 100))% confidence")
                                                    .font(.caption)
                                                    .foregroundColor(.mutedForeground)
                                            }
                                        }
                                        
                                        // Actionable tip
                                        CardView(variant: .default) {
                                            VStack(alignment: .leading, spacing: .spacingSM) {
                                                HStack(spacing: .spacingXS) {
                                                    Image(systemName: "lightbulb.fill")
                                                        .foregroundColor(.primary)
                                                        .font(.caption)
                                                    
                                                    Text("Try this:")
                                                        .font(.caption)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.mutedForeground)
                                                }
                                                
                                                Text(actionableTip(for: classification))
                                                    .font(.body)
                                                    .foregroundColor(.foreground)
                                            }
                                            .padding(.spacingSM)
                                        }
                                        
                                        // Safety disclaimer
                                        InfoBanner(
                                            title: "Important",
                                            message: "Nestling gives general guidance, not medical care. If your baby seems very unwell or you're worried, contact a pediatric professional.",
                                            variant: .warning
                                        )
                                        
                                        // Allow override of the label
                                        VStack(alignment: .leading, spacing: .spacingSM) {
                                            Text("Adjust the label if it doesn't look right")
                                                .font(.caption)
                                                .foregroundColor(.mutedForeground)
                                            Picker("Need", selection: Binding(
                                                get: { viewModel.overrideLabel ?? classification },
                                                set: { viewModel.overrideLabel = $0 }
                                            )) {
                                                ForEach(CryClassification.allCases, id: \.self) { label in
                                                    Text(label.displayName).tag(label)
                                                }
                                            }
                                            .pickerStyle(.segmented)
                                        }
                                        
                                        Text(viewModel.explanation)
                                            .font(.caption)
                                            .foregroundColor(.mutedForeground)
                                    }
                                }
                                .padding(.horizontal, .spacingMD)
                                
                                HStack(spacing: .spacingSM) {
                                    PrimaryButton("Save Insight", icon: "checkmark.circle.fill") {
                                        showSaveConfirmation = true
                                    }
                                    
                                    SecondaryButton("Discard", icon: "xmark.circle.fill") {
                                        viewModel.discardRecording()
                                    }
                                }
                                .padding(.horizontal, .spacingMD)
                            } else {
                                // Free users see blurred result with paywall
                                ZStack {
                                    // Blurred background
                                    CardView(variant: .emphasis) {
                                        VStack(alignment: .leading, spacing: .spacingMD) {
                                            HStack {
                                                Text("Analysis Result")
                                                    .font(.headline)
                                                    .foregroundColor(.foreground)
                                                
                                                Spacer()
                                                
                                                Text("\(Int(viewModel.confidence * 100))% confidence")
                                                    .font(.caption)
                                                    .foregroundColor(.mutedForeground)
                                            }
                                            
                                        // Category with icon and color
                                        HStack(spacing: .spacingSM) {
                                            Image(systemName: categoryIcon(for: classification))
                                                .foregroundColor(categoryColor(for: classification))
                                                .font(.title3)
                                            
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text("Most likely: \(classification.displayName)")
                                                    .font(.title2)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.foreground)
                                                
                                                Text("\(Int(viewModel.confidence * 100))% confidence")
                                                    .font(.caption)
                                                    .foregroundColor(.mutedForeground)
                                            }
                                        }
                                        
                                        // Actionable tip
                                        CardView(variant: .default) {
                                            VStack(alignment: .leading, spacing: .spacingSM) {
                                                HStack(spacing: .spacingXS) {
                                                    Image(systemName: "lightbulb.fill")
                                                        .foregroundColor(.primary)
                                                        .font(.caption)
                                                    
                                                    Text("Try this:")
                                                        .font(.caption)
                                                        .fontWeight(.semibold)
                                                        .foregroundColor(.mutedForeground)
                                                }
                                                
                                                Text(actionableTip(for: classification))
                                                    .font(.body)
                                                    .foregroundColor(.foreground)
                                            }
                                            .padding(.spacingSM)
                                        }
                                        
                                        // Safety disclaimer
                                        InfoBanner(
                                            title: "Important",
                                            message: "Nestling gives general guidance, not medical care. If your baby seems very unwell or you're worried, contact a pediatric professional.",
                                            variant: .warning
                                        )
                                        
                                        Text(viewModel.explanation)
                                            .font(.caption)
                                            .foregroundColor(.mutedForeground)
                                        }
                                    }
                                    .blur(radius: 8)
                                    .opacity(0.5)
                                    
                                    // Paywall overlay
                                    CardView(variant: .emphasis) {
                                        VStack(spacing: .spacingMD) {
                                            Image(systemName: "lock.fill")
                                                .font(.system(size: 40))
                                                .foregroundColor(.primary)
                                            
                                            Text("Unlock Cry Insights")
                                                .font(.headline)
                                                .foregroundColor(.foreground)
                                            
                                            Text("Get Pro to see detailed cry analysis and insights")
                                                .font(.body)
                                                .foregroundColor(.mutedForeground)
                                                .multilineTextAlignment(.center)
                                            
                                            PrimaryButton("Upgrade to Pro", icon: "star.fill") {
                                                Task {
                                                    await Analytics.shared.logPaywallViewed(source: "cry_insights_3_free_limit")
                                                }
                                                showProSubscription = true
                                            }
                                            
                                            Button("Maybe Later") {
                                                viewModel.discardRecording()
                                            }
                                            .font(.subheadline)
                                            .foregroundColor(.mutedForeground)
                                        }
                                        .padding(.spacingMD)
                                    }
                                }
                                .padding(.horizontal, .spacingMD)
                            }
                        } else if case .idle = viewModel.state {
                            // Start Recording
                            VStack(spacing: .spacingMD) {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 60))
                                    .foregroundColor(.primary)

                                Text("Record Cry Analysis")
                                    .font(.headline)
                                    .foregroundColor(.foreground)

                                Text("Record up to 20 seconds of audio. Analysis is done on-device and recordings are deleted immediately.")
                                    .font(.body)
                                    .foregroundColor(.mutedForeground)
                                    .multilineTextAlignment(.center)

                                // Quota info for free users
                                if !proService.isProUser, let remaining = viewModel.remainingQuota {
                                    Text("\(remaining) recording\(remaining == 1 ? "" : "s") left this week")
                                        .font(.caption)
                                        .foregroundColor(.mutedForeground)
                                        .padding(.top, .spacingXS)
                                } else if !proService.isProUser {
                                    Text("3 recordings per week (free)")
                                        .font(.caption)
                                        .foregroundColor(.mutedForeground)
                                        .padding(.top, .spacingXS)
                                }
                            }
                            .padding(.spacing2XL)
                            
                            if viewModel.quotaExceeded {
                                // Quota exceeded - show upgrade prompt
                                CardView(variant: .emphasis) {
                                    VStack(spacing: .spacingMD) {
                                        Image(systemName: "lock.fill")
                                            .font(.system(size: 40))
                                            .foregroundColor(.primary)

                                        Text("Weekly Limit Reached")
                                            .font(.headline)
                                            .foregroundColor(.foreground)

                                        Text("You've used all 3 free Cry Insights recordings this week. Upgrade to Pro for unlimited access.")
                                            .font(.body)
                                            .foregroundColor(.mutedForeground)
                                            .multilineTextAlignment(.center)

                                        PrimaryButton("Upgrade to Pro", icon: "star.fill") {
                                            Task {
                                                await Analytics.shared.logPaywallViewed(source: "cry_insights_weekly_limit")
                                            }
                                            showProSubscription = true
                                        }

                                        Text("Quota resets every Monday")
                                            .font(.caption)
                                            .foregroundColor(.mutedForeground)
                                    }
                                    .padding(.spacingMD)
                                }
                                .padding(.horizontal, .spacingMD)
                            } else {
                                PrimaryButton("Start Recording", icon: "mic.fill") {
                                    viewModel.startRecording()
                                }
                                .padding(.horizontal, .spacingMD)
                            }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func powerColor(for index: Int) -> Color {
        let threshold = Float(index) / 20.0 * -160.0
        if viewModel.averagePower > threshold {
            return .primary
        } else {
            return .mutedForeground.opacity(0.3)
        }
    }
    
    // MARK: - Helper Functions
    
    private func categoryIcon(for classification: CryClassification) -> String {
        switch classification {
        case .tired:
            return "moon.fill"
        case .hungry:
            return "drop.fill"
        case .discomfort:
            return "exclamationmark.triangle.fill"
        case .painPossible:
            return "cross.case.fill"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
    
    private func categoryColor(for classification: CryClassification) -> Color {
        switch classification {
        case .tired:
            return .eventSleep
        case .hungry:
            return .eventFeed
        case .discomfort:
            return .eventDiaper
        case .painPossible:
            return .destructive
        case .unknown:
            return .mutedForeground
        }
    }
    
    private func actionableTip(for classification: CryClassification) -> String {
        switch classification {
        case .tired:
            return "Try a quieter room with dim lights. Swaddle gently and see if they settle in 5-10 minutes. White noise or gentle rocking may help."
        case .hungry:
            return "Offer a feed. Look for hunger cues like rooting, hand-to-mouth movements, or smacking lips. If they just fed, try burping or a pacifier."
        case .discomfort:
            return "Check diaper, clothing tightness, and room temperature. Consider gas relief techniques like bicycle legs or tummy time. Ensure they're not too hot or cold."
        case .painPossible:
            return "If the cry is persistent and unusual, check for signs of pain (fever, unusual positions, refusal to feed). Consider contacting your pediatrician if concerned."
        case .unknown:
            return "Try a combination of comfort techniques: hold them, check basic needs (diaper, temperature), and offer gentle movement or sound."
        }
    }
}

#Preview {
    CryRecorderView(dataStore: InMemoryDataStore(), baby: .mock())
}

