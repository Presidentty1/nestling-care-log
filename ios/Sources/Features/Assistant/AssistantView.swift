import SwiftUI

/// Main AI Assistant chat view
struct AssistantView: View {
    @EnvironmentObject var environment: AppEnvironment
    @StateObject private var viewModel: AssistantViewModel
    @FocusState private var isInputFocused: Bool
    
    init(baby: Baby?, environment: AppEnvironment) {
        // Create service with DataStore for baby context
        let service = AIAssistantService(dataStore: environment.dataStore)
        _viewModel = StateObject(
            wrappedValue: AssistantViewModel(
                service: service,
                baby: baby,
                settings: environment.appSettings
            )
        )
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // AI Consent Banner
                if !environment.appSettings.aiDataSharingEnabled {
                    AIConsentBanner()
                        .padding(.horizontal, .spacingMD)
                        .padding(.top, .spacingSM)
                }
                
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: .spacingMD) {
                            // Empty state
                            if viewModel.messages.isEmpty {
                                EmptyChatState()
                                    .padding(.top, .spacingXL)
                            }
                            
                            // Messages
                            ForEach(viewModel.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            
                            // Loading indicator
                            if viewModel.isSending {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                    Text("Thinking...")
                                        .font(.caption)
                                        .foregroundColor(.mutedForeground)
                                }
                                .padding(.spacingMD)
                            }
                        }
                        .padding(.horizontal, .spacingMD)
                        .padding(.vertical, .spacingLG)
                    }
                    .onChange(of: viewModel.messages.count) { oldValue, newValue in
                        if newValue > oldValue, let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Error message
                if let errorMessage = viewModel.errorMessage {
                    ErrorBanner(message: errorMessage) {
                        viewModel.clearError()
                    }
                    .padding(.horizontal, .spacingMD)
                }
                
                // Input Bar
                ChatInputBar(
                    text: $viewModel.inputText,
                    isSending: viewModel.isSending,
                    isEnabled: environment.appSettings.aiDataSharingEnabled,
                    onSend: {
                        Task {
                            await viewModel.send()
                        }
                    }
                )
                .padding(.spacingMD)
            }
            .navigationTitle("Ask Nestling")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color.background)
        }
    }
}

// MARK: - Subviews

/// Empty chat state with welcome message
private struct EmptyChatState: View {
    var body: some View {
        VStack(spacing: .spacingMD) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundColor(.primary)
            
            Text("Hi! I'm here to help")
                .font(.headline)
                .foregroundColor(.foreground)
            
            Text("Ask me anything about baby care, feeding schedules, sleep tips, or developmental milestones.")
                .font(.caption)
                .foregroundColor(.mutedForeground)
                .multilineTextAlignment(.center)
                .padding(.horizontal, .spacingLG)
        }
    }
}

/// Chat message bubble
private struct ChatBubble: View {
    let message: AIChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: .spacingSM) {
            if message.role == .assistant {
                Image(systemName: "brain.head.profile")
                    .font(.caption)
                    .foregroundColor(.primary)
                    .frame(width: 24, height: 24)
                    .background(Color.primary.opacity(0.1))
                    .clipShape(Circle())
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: .spacingXS) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.role == .user ? .white : .foreground)
                    .padding(.spacingMD)
                    .background(
                        message.role == .user
                            ? Color.primary
                            : Color.surface
                    )
                    .cornerRadius(.radiusMD)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.role == .user ? .trailing : .leading)
            
            if message.role == .user {
                Image(systemName: "person.circle.fill")
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
                    .frame(width: 24, height: 24)
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
        .accessibilityLabel(message.role == .user ? "You said: \(message.content)" : "Assistant said: \(message.content)")
    }
}

/// AI Consent Banner
private struct AIConsentBanner: View {
    var body: some View {
        CardView(variant: .warning) {
            HStack(spacing: .spacingMD) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.warning)
                
                VStack(alignment: .leading, spacing: .spacingXS) {
                    Text("AI Features Disabled")
                        .font(.headline)
                        .foregroundColor(.foreground)
                    
                    Text("To use AI features, turn on AI data sharing in Settings.")
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                }
            }
            .padding(.spacingMD)
        }
    }
}

/// Error Banner
private struct ErrorBanner: View {
    let message: String
    let onDismiss: () -> Void
    
    var body: some View {
        CardView(variant: .destructive) {
            HStack(spacing: .spacingMD) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.destructive)
                
                Text(message)
                    .font(.caption)
                    .foregroundColor(.foreground)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.mutedForeground)
                }
            }
            .padding(.spacingMD)
        }
    }
}

/// Chat input bar
private struct ChatInputBar: View {
    @Binding var text: String
    let isSending: Bool
    let isEnabled: Bool
    let onSend: () -> Void
    
    var body: some View {
        HStack(spacing: .spacingSM) {
            TextField(
                isEnabled ? "Ask Nestling..." : "Enable AI features to chat...",
                text: $text,
                axis: .vertical
            )
            .textFieldStyle(.roundedBorder)
            .lineLimit(1...4)
            .disabled(!isEnabled || isSending)
            .focused($isInputFocused)
            .onSubmit {
                if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && isEnabled {
                    onSend()
                }
            }
            
            Button(action: onSend) {
                if isSending {
                    ProgressView()
                        .scaleEffect(0.8)
                } else {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
            }
            .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSending || !isEnabled)
            .foregroundColor(.primary)
        }
    }
}

// MARK: - Entry View

/// Entry point for Assistant tab
struct AssistantEntryView: View {
    @EnvironmentObject var environment: AppEnvironment
    
    var body: some View {
        Group {
            if let baby = environment.currentBaby {
                AssistantView(baby: baby, environment: environment)
            } else {
                NoBabyState()
            }
        }
    }
}

/// State when no baby is configured
private struct NoBabyState: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: .spacingLG) {
                Spacer()
                
                Image(systemName: "person.crop.circle.badge.plus")
                    .font(.system(size: 64))
                    .foregroundColor(.mutedForeground)
                
                Text("Add a baby first")
                    .font(.headline)
                    .foregroundColor(.foreground)
                
                Text("Create a baby profile to start using the AI Assistant.")
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, .spacingXL)
                
                Spacer()
            }
            .navigationTitle("Ask Nestling")
            .background(Color.background)
        }
    }
}

