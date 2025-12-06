import SwiftUI
import AVFoundation

struct CryRecorderView: View {
    @StateObject private var viewModel: CryRecorderViewModel
    @Environment(\.dismiss) var dismiss
    @State private var showSaveConfirmation = false
    
    init(dataStore: DataStore, baby: Baby) {
        _viewModel = StateObject(wrappedValue: CryRecorderViewModel(dataStore: dataStore, baby: baby))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: .spacingLG) {
                    // Medical Disclaimer
                    MedicalDisclaimer(variant: .ai)
                        .padding(.horizontal, .spacingMD)
                    
                    // Privacy Info
                    InfoBanner(
                        title: "Privacy & Data",
                        message: "Audio is recorded locally and analyzed on-device. Recordings are automatically deleted after analysis. No audio data is stored or transmitted.",
                        variant: .info
                    )
                    .padding(.horizontal, .spacingMD)
                    
                    // Recording UI
                    VStack(spacing: .spacingMD) {
                        if viewModel.isRecording {
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
                            .background(NuzzleTheme.surface)
                            .cornerRadius(.radiusLG)
                            
                            PrimaryButton("Stop Recording", icon: "stop.fill") {
                                viewModel.stopRecording()
                            }
                            .padding(.horizontal, .spacingMD)
                        } else if let classification = viewModel.classification {
                            // Analysis Result
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
                                    
                                    Text(classification.displayName)
                                        .font(.title2)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.primary)
                                    
                                    Text(viewModel.explanation)
                                        .font(.body)
                                        .foregroundColor(.mutedForeground)

                                    Text("If you're worried or your baby seems very unwell, contact a pediatric professional.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.top, .spacingSM)
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
                            }
                            .padding(.spacing2XL)
                            
                            PrimaryButton("Start Recording", icon: "mic.fill") {
                                viewModel.startRecording()
                            }
                            .padding(.horizontal, .spacingMD)
                        }
                    }
                    .padding(.vertical, .spacingMD)
                }
            }
            .navigationTitle("Cry Insights")
            .background(NuzzleTheme.background)
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
}

#Preview {
    CryRecorderView(dataStore: InMemoryDataStore(), baby: .mock())
}


