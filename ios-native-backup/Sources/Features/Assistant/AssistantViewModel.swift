import Foundation
import Combine

/// ViewModel for AI Assistant chat
@MainActor
class AssistantViewModel: ObservableObject {
    @Published var messages: [AIChatMessage] = []
    @Published var inputText: String = ""
    @Published var isSending: Bool = false
    @Published var errorMessage: String?
    @Published var showPaywall: Bool = false // Epic 7: Paywall trigger
    
    private let service: AIAssistantServiceProtocol
    private let baby: Baby?
    private let settings: AppSettings
    private var conversationId: String?
    
    init(service: AIAssistantServiceProtocol, baby: Baby?, settings: AppSettings) {
        self.service = service
        self.baby = baby
        self.settings = settings
        bootstrapConversation()
    }
    
    /// Initialize conversation with welcome message if needed
    private func bootstrapConversation() {
        guard messages.isEmpty else { return }
        
        let introMessage = AIChatMessage(
            role: .assistant,
            content: "Hi, I'm Nestling's AI helper. I can help with quick questions about sleep, feeds, diapers, and what to do next. I'm not a doctor, so for medical concerns please contact a pediatric professional.",
            createdAt: Date()
        )
        
        messages.append(introMessage)
    }
    
    /// Send a message to the AI assistant
    func send() async {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isSending else { return }
        
        // Check AI data sharing consent
        guard settings.aiDataSharingEnabled else {
            errorMessage = "AI features are disabled. Enable in Settings → AI & Data Sharing."
            return
        }
        
        isSending = true
        errorMessage = nil
        
        // Create user message
        let userMessage = AIChatMessage(
            role: .user,
            content: trimmed,
            createdAt: Date()
        )
        
        // Add user message to array
        messages.append(userMessage)
        let previousInput = trimmed
        inputText = ""
        
        do {
            // Send to service
            let updated = try await service.sendMessage(
                messages: messages,
                baby: baby,
                conversationId: conversationId
            )
            
            // Update messages with assistant reply
            messages = updated
            
            // Extract conversation ID from response if available
            // (This would come from the service response in a real implementation)
            
        } catch {
            // Remove user message on error
            messages.removeAll { $0.id == userMessage.id }
            inputText = previousInput
            
            // Handle upgrade required (Epic 7 AC5)
            if let aiError = error as? AIAssistantError,
               case .upgradeRequired(let message) = aiError {
                errorMessage = message
                showPaywall = true
            } else if let aiError = error as? AIAssistantError {
                errorMessage = aiError.localizedDescription
            } else {
                errorMessage = error.localizedDescription
            }
        }
        
        isSending = false
    }
    
    /// Clear error message
    func clearError() {
        errorMessage = nil
    }
}

