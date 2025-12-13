import SwiftUI

/// A text field with voice input capability
struct VoiceInputView: View {
    @Binding var text: String
    let placeholder: String
    let axis: Axis = .vertical

    @StateObject private var speechService = SpeechRecognitionService.shared
    @State private var isListening = false
    @State private var showError = false
    @State private var showDictationHint = false

    private var shouldShowDictationHint: Bool {
        !UserDefaults.standard.bool(forKey: "hasDismissedDictationHint")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingSM) {
            // One-time dictation hint
            if shouldShowDictationHint {
                HStack(alignment: .top, spacing: .spacingSM) {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.primary)
                        .font(.caption)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Tip: Tap the mic to dictate notes")
                            .font(.caption)
                            .foregroundColor(.primary)

                        Button(action: dismissHint) {
                            Text("Got it")
                                .font(.caption2)
                                .foregroundColor(.primary.opacity(0.8))
                        }
                    }

                    Spacer()

                    Button(action: dismissHint) {
                        Image(systemName: "xmark")
                            .font(.caption2)
                            .foregroundColor(.mutedForeground)
                    }
                }
                .padding(.spacingSM)
                .background(Color.primary.opacity(0.05))
                .cornerRadius(.radiusSM)
                .transition(.opacity)
            }

            HStack(alignment: .top, spacing: .spacingSM) {
                ZStack(alignment: .topLeading) {
                    if text.isEmpty {
                        Text(placeholder)
                            .foregroundColor(.mutedForeground)
                            .padding(.top, 8)
                            .padding(.leading, 4)
                    }

                    TextEditor(text: $text)
                        .frame(minHeight: axis == .vertical ? 80 : 40, maxHeight: axis == .vertical ? 120 : 40)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .foregroundColor(.foreground)
                        .font(.body)
                        .lineLimit(axis == .vertical ? nil : 1)
                }

                // Voice input button
                Button(action: handleVoiceInput) {
                    ZStack {
                        Circle()
                            .fill(isListening ? Color.destructive : Color.primary)
                            .frame(width: 32, height: 32)

                        Image(systemName: isListening ? "stop.fill" : "mic.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 14))
                    }
                }
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(isListening ? "Stop voice input" : "Start voice input")
                .accessibilityHint("Tap to dictate notes using speech recognition")
            }

            // Recording indicator
            if isListening {
                HStack(spacing: .spacingXS) {
                    Circle()
                        .fill(Color.destructive)
                        .frame(width: 8, height: 8)
                        .opacity(speechService.isRecording ? 1 : 0.3)

                    Text("Listening...")
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                }
                .motionAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: speechService.isRecording)
            }

            // Error message
            if let error = speechService.errorMessage, showError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.destructive)
                    .padding(.vertical, .spacingXS)
            }
        }
        .onChange(of: speechService.recognizedText) { _, newText in
            if !newText.isEmpty && isListening {
                text = newText
            }
        }
        .onChange(of: speechService.errorMessage) { _, newError in
            showError = newError != nil
        }
        .onAppear {
            showDictationHint = shouldShowDictationHint
        }
        .onChange(of: speechService.isRecording) { _, isRecording in
            if !isRecording && isListening {
                isListening = false
                showError = speechService.errorMessage != nil
            }
        }
    }

    private func handleVoiceInput() {
        if isListening {
            // Stop recording
            speechService.stopRecording()
            isListening = false
        } else {
            // Start recording
            Task {
                speechService.reset()
                showError = false
                isListening = await speechService.startRecording()
                if !isListening && speechService.errorMessage == nil {
                    speechService.errorMessage = "Failed to start voice recognition"
                    showError = true
                }
            }
        }
    }

    private func dismissHint() {
        withAnimation {
            UserDefaults.standard.set(true, forKey: "hasDismissedDictationHint")
            showDictationHint = false
        }
    }
}

#Preview {
    VStack {
        VoiceInputView(text: .constant(""), placeholder: "Add optional notes...")
        VoiceInputView(text: .constant("This is a test note"), placeholder: "Add optional notes...")
    }
    .padding()
}

