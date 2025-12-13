import SwiftUI

/// AI Assistant chat view
struct AssistantView: View {
    @EnvironmentObject var environment: AppEnvironment
    @StateObject private var viewModel: AssistantViewModel
    @State private var inputText = ""
    @State private var isComposing = false
    @FocusState private var isInputFocused: Bool
    @State private var showClearConfirm = false
    
    init() {
        _viewModel = StateObject(wrappedValue: AssistantViewModel())
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Consolidated disclaimer banner
            DisclosureGroup {
                Text("No diagnoses. If anything feels urgent or serious, contact a pediatric professional immediately.")
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
            } label: {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.info)
                    Text("General guidance only - not medical advice")
                        .font(.caption)
                        .foregroundColor(.mutedForeground)
                }
            }
            .padding(.horizontal, .spacingMD)
            .padding(.vertical, .spacingSM)
            .background(Color.surface)
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: .spacingMD) {
                        // Welcome message
                        if viewModel.messages.isEmpty {
                            welcomeContent
                        }
                        
                        // Message bubbles
                        ForEach(viewModel.messages) { message in
                            messageBubble(message)
                                .id(message.id)
                        }
                        
                        // Loading indicator
                        if viewModel.isLoading {
                            HStack(spacing: .spacingSM) {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                Text("Thinking...")
                                    .font(.caption)
                                    .foregroundColor(.mutedForeground)
                            }
                            .padding(.spacingMD)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(.spacingMD)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Input bar
            HStack(spacing: .spacingSM) {
                TextField("Ask a question...", text: $inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.spacingSM)
                    .background(Color.surface)
                    .cornerRadius(.radiusSM)
                    .focused($isInputFocused)
                    .disabled(!NetworkMonitor.shared.isConnected)
                    .accessibilityLabel("Question input")
                    .accessibilityHint(NetworkMonitor.shared.isConnected ? "Type your question about baby care" : "AI Assistant requires internet connection")
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(canSend ? .primary : .mutedForeground)
                }
                .disabled(!canSend)
                .accessibilityLabel("Send message")
                .accessibilityHint("Send your question to the AI assistant")
            }
            .padding(.spacingMD)
            .background(Color.background)
            
            // Offline indicator
            if !NetworkMonitor.shared.isConnected {
                HStack(spacing: .spacingSM) {
                    Image(systemName: "wifi.slash")
                        .font(.caption)
                    Text("AI Assistant requires internet connection")
                        .font(.caption)
                }
                .foregroundColor(.mutedForeground)
                .padding(.spacingSM)
                .frame(maxWidth: .infinity)
                .background(Color.warning.opacity(0.1))
            }
        }
        .navigationTitle("AI Assistant")
        .background(Color.background)
        .onAppear {
            viewModel.setBaby(environment.currentBaby)
            
            // Track feature first used
            let hasUsedAI = UserDefaults.standard.bool(forKey: "feature_ai_assistant_used")
            if !hasUsedAI {
                let onboardingDate = UserDefaults.standard.object(forKey: "onboardingCompletedDate") as? Date ?? Date()
                let daysSinceOnboarding = Calendar.current.dateComponents([.day], from: onboardingDate, to: Date()).day ?? 0
                AnalyticsService.shared.trackFeatureFirstUsed(
                    featureName: "ai_assistant",
                    daysSinceOnboarding: daysSinceOnboarding
                )
                UserDefaults.standard.set(true, forKey: "feature_ai_assistant_used")
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Clear") {
                    showClearConfirm = true
                }
                .disabled(viewModel.messages.isEmpty)
            }
        }
        .alert("Clear this conversation?", isPresented: $showClearConfirm) {
            Button("Clear", role: .destructive) {
                viewModel.clearConversation()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This removes the current chat history on this device.")
        }
    }
    
    private var babyName: String {
        environment.currentBaby?.name ?? "your baby"
    }

    @ViewBuilder
    private var welcomeContent: some View {
        VStack(spacing: .spacingLG) {
            // Icon
            Circle()
                .fill(Color.primary.opacity(0.1))
                .frame(width: 80, height: 80)
                .overlay(
                    Image(systemName: "sparkles")
                        .font(.system(size: 36))
                        .foregroundColor(.primary)
                )
            
            // Welcome text
            VStack(spacing: .spacingSM) {
                Text("Hi! I'm Nuzzle")  // Give it a name
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.foreground)

                Text("I'm here to help you understand \(babyName)'s patterns. Parenting is hard - you're doing great!")
                    .font(.body)
                    .foregroundColor(.mutedForeground)
                    .multilineTextAlignment(.center)
            }
            
            // Quick questions
            VStack(alignment: .leading, spacing: .spacingSM) {
                Text("Quick questions:")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.mutedForeground)
                
                quickQuestionButton("Why is my baby crying?")
                quickQuestionButton("How much should they eat?")
                quickQuestionButton("Is this sleep pattern normal?")
            }
        }
        .padding(.spacing2XL)
    }
    
    @ViewBuilder
    private func quickQuestionButton(_ question: String) -> some View {
        Button(action: {
            inputText = question
            sendMessage()
        }) {
            HStack {
                Text(question)
                    .font(.body)
                    .foregroundColor(.foreground)
                Spacer()
                Image(systemName: "arrow.up.circle")
                    .foregroundColor(.primary)
            }
            .padding(.spacingMD)
            .background(Color.surface)
            .cornerRadius(.radiusMD)
        }
    }
    
    @ViewBuilder
    private func messageBubble(_ message: AIMessage) -> some View {
        HStack(alignment: .top, spacing: .spacingSM) {
            if message.role == .assistant {
                // Avatar
                Circle()
                    .fill(Color.primary.opacity(0.1))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "sparkles")
                            .font(.caption)
                            .foregroundColor(.primary)
                    )
            }
            
            // Message content
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: .spacingSM) {
                Text(message.content)
                    .font(.body)
                    .foregroundColor(message.role == .user ? .white : .foreground)
                    .padding(.spacingMD)
                    .background(message.role == .user ? Color.primary : Color.surface)
                    .cornerRadius(.radiusMD)
                    .frame(maxWidth: message.role == .user ? .infinity : nil, alignment: message.role == .user ? .trailing : .leading)
                
                // Red flag warning
                if message.role == .assistant && message.containsRedFlag {
                    HStack(spacing: .spacingSM) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundColor(.warning)
                        
                        Text("This sounds serious. Please contact your pediatrician immediately.")
                            .font(.caption)
                            .foregroundColor(.warning)
                            .fontWeight(.medium)
                    }
                    .padding(.spacingSM)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.warning.opacity(0.1))
                    .cornerRadius(.radiusSM)
                }
                    
                    if message.role == .assistant {
                        Text("Not medical advice. Contact your pediatrician for medical concerns.")
                            .font(.caption2)
                            .foregroundColor(.mutedForeground)
                            .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: .spacingSM) {
                        Button {
                            viewModel.recordFeedback(for: message.id, helpful: true)
                        } label: {
                            Label("Helpful", systemImage: "hand.thumbsup")
                        }
                        Button {
                            viewModel.recordFeedback(for: message.id, helpful: false)
                        } label: {
                            Label("Not helpful", systemImage: "hand.thumbsdown")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.mutedForeground)
                    }
            }
            
            if message.role == .user {
                // User avatar
                Circle()
                    .fill(Color.mutedForeground.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.caption)
                            .foregroundColor(.mutedForeground)
                    )
            }
        }
        .frame(maxWidth: .infinity, alignment: message.role == .user ? .trailing : .leading)
    }
    
    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !viewModel.isLoading &&
        NetworkMonitor.shared.isConnected
    }
    
    private func sendMessage() {
        let message = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !message.isEmpty else { return }
        
        inputText = ""
        isInputFocused = false
        Haptics.light()
        
        Task {
            await viewModel.sendMessage(message, baby: environment.currentBaby, recentEvents: await getRecentEvents())
        }
    }
    
    private func getRecentEvents() async -> [Event] {
        guard let baby = environment.currentBaby else { return [] }
        
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        
        do {
            return try await environment.dataStore.fetchEvents(for: baby, from: twoDaysAgo, to: Date())
        } catch {
            Logger.dataError("Failed to fetch recent events for AI context: \(error.localizedDescription)")
            return []
        }
    }
}

/// ViewModel for AI Assistant
@MainActor
class AssistantViewModel: ObservableObject {
    @Published var messages: [AIMessage] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private var currentBaby: Baby?
    private var conversationId: String?
    private let storage = UserDefaults.standard
    private let sensitiveKeywords = ["fever", "vaccine", "medicine", "dosage", "sids", "pain", "emergency", "911"]
    
    func setBaby(_ baby: Baby?) {
        self.currentBaby = baby
        
        // Load conversation history for this baby
        if let baby = baby {
            Task {
                await loadConversationHistory(for: baby)
            }
        }
    }
    
    func sendMessage(_ text: String, baby: Baby?, recentEvents: [Event]) async {
        guard let baby = baby else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        // Add user message
        let userMessage = AIMessage(role: .user, content: trimmed)
        messages.append(userMessage)
        
        // Lightweight moderation before sending to backend
        if containsSensitiveContent(trimmed) {
            let caution = AIMessage(
                role: .assistant,
                content: "I’m here for general guidance and can’t provide medical advice. For urgent or sensitive health questions, please contact a pediatric professional.",
                containsRedFlag: true
            )
            messages.append(caution)
            await saveConversation(baby: baby)
            return
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Call AI service with the user's question
            // The edge function will handle context building server-side
            let response = try await AIAssistantService.shared.askAssistant(
                message: trimmed,
                babyId: baby.id,
                conversationId: conversationId
            )
            var responseContent = response.message
            
            // Store conversation ID for continuity
            conversationId = response.conversationId
            
            // Check for red flags
            let containsRedFlag = AIContextBuilder.containsRedFlag(trimmed) || AIContextBuilder.containsRedFlag(response)
            
            // Add light citation to recent logs if available
            if let recent = recentEvents.first {
                let formatter = DateFormatter()
                formatter.timeStyle = .short
                formatter.dateStyle = .short
                let type = recent.type.displayName
                let timeString = formatter.string(from: recent.startTime)
                responseContent += "\n\nBased on recent logs, last \(type.lowercased()) was \(timeString)."
            }
            
            // Add assistant message
            let assistantMessage = AIMessage(role: .assistant, content: responseContent, containsRedFlag: containsRedFlag)
            messages.append(assistantMessage)
            
            // Save to conversation history
            await saveConversation(baby: baby)
            
            // Track analytics
            AnalyticsService.shared.track(event: "ai_question_sent", properties: [
                "question_length": trimmed.count,
                "used_context": !recentEvents.isEmpty
            ])
            
            AnalyticsService.shared.track(event: "ai_answer_shown", properties: [
                "contains_red_flag_topic": containsRedFlag
            ])
            
        } catch {
            self.error = error
            Logger.dataError("AI assistant error: \(error.localizedDescription)")
            
            AnalyticsService.shared.track(event: "ai_error", properties: [
                "error_type": "network"
            ])
            
            // Add error message
            let errorMessage = AIMessage(
                role: .assistant,
                content: "I'm having trouble connecting right now. Please check your internet connection and try again.",
                containsRedFlag: false
            )
            messages.append(errorMessage)
        }
    }
    
    private func loadConversationHistory(for baby: Baby) async {
        let key = conversationStorageKey(for: baby.id)
        if let data = storage.data(forKey: key),
           let saved = try? JSONDecoder().decode([AIMessage].self, from: data) {
            messages = saved
        } else {
            messages = []
        }
        conversationId = UUID()
    }
    
    private func saveConversation(baby: Baby) async {
        let key = conversationStorageKey(for: baby.id)
        if let data = try? JSONEncoder().encode(messages) {
            storage.set(data, forKey: key)
        }
    }
    
    func clearConversation() {
        messages = []
        if let baby = currentBaby {
            storage.removeObject(forKey: conversationStorageKey(for: baby.id))
        }
    }
    
    func recordFeedback(for messageId: UUID, helpful: Bool) {
        AnalyticsService.shared.track(event: "ai_message_feedback", properties: [
            "message_id": messageId.uuidString,
            "helpful": helpful
        ])
    }
    
    private func conversationStorageKey(for babyId: UUID) -> String {
        "ai_conversation_\(babyId.uuidString)"
    }
    
    private func containsSensitiveContent(_ text: String) -> Bool {
        let lower = text.lowercased()
        return sensitiveKeywords.contains { lower.contains($0) }
    }
}

#Preview {
    NavigationStack {
        AssistantView()
            .environmentObject(AppEnvironment(dataStore: InMemoryDataStore()))
    }
}






