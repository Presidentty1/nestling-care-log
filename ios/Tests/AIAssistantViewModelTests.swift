import XCTest
@testable import Nestling

final class AIAssistantViewModelTests: XCTestCase {
    var viewModel: AssistantViewModel!
    var mockService: MockAIAssistantService!
    var baby: Baby!
    var settings: AppSettings!

    override func setUp() {
        super.setUp()

        mockService = MockAIAssistantService()
        baby = Baby.mock()
        settings = AppSettings()

        viewModel = AssistantViewModel(service: mockService, baby: baby, settings: settings)
    }

    override func tearDown() {
        viewModel = nil
        mockService = nil
        baby = nil
        settings = nil
        super.tearDown()
    }

    func testInitialState() {
        XCTAssertFalse(viewModel.isSending)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.inputText, "")
        // Should have welcome message
        XCTAssertEqual(viewModel.messages.count, 1)
        XCTAssertEqual(viewModel.messages.first?.role, .assistant)
    }

    func testBootstrapConversation() {
        // Test that welcome message is added
        let welcomeMessage = viewModel.messages.first
        XCTAssertNotNil(welcomeMessage)
        XCTAssertEqual(welcomeMessage?.role, .assistant)
        XCTAssertTrue(welcomeMessage?.content.contains("Nestling's AI helper") ?? false)
    }

    func testSendMessageWithValidInput() async {
        // Given
        viewModel.inputText = "How should I feed my baby?"
        settings.aiDataSharingEnabled = true
        mockService.shouldSucceed = true

        // When
        await viewModel.send()

        // Then
        XCTAssertFalse(viewModel.isSending)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.inputText, "") // Should be cleared
        XCTAssertEqual(viewModel.messages.count, 3) // Welcome + user + assistant
        XCTAssertEqual(viewModel.messages[1].role, .user)
        XCTAssertEqual(viewModel.messages[2].role, .assistant)
    }

    func testSendMessageWithoutConsent() async {
        // Given
        viewModel.inputText = "Test message"
        settings.aiDataSharingEnabled = false

        // When
        await viewModel.send()

        // Then
        XCTAssertFalse(viewModel.isSending)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.errorMessage, "AI features are disabled. Enable in Settings → AI & Data Sharing.")
        XCTAssertEqual(viewModel.inputText, "Test message") // Should not be cleared
        XCTAssertEqual(viewModel.messages.count, 1) // Only welcome message
    }

    func testSendMessageWithEmptyInput() async {
        // Given
        viewModel.inputText = "   " // Only whitespace
        settings.aiDataSharingEnabled = true

        // When
        await viewModel.send()

        // Then
        XCTAssertFalse(viewModel.isSending)
        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.inputText, "   ") // Should not be cleared
        XCTAssertEqual(viewModel.messages.count, 1) // Only welcome message
    }

    func testSendMessageWhileAlreadySending() async {
        // Given
        viewModel.inputText = "Test message"
        viewModel.isSending = true
        settings.aiDataSharingEnabled = true

        // When
        await viewModel.send()

        // Then
        XCTAssertTrue(viewModel.isSending) // Should remain true
        XCTAssertEqual(viewModel.inputText, "Test message") // Should not be cleared
        XCTAssertEqual(viewModel.messages.count, 1) // Only welcome message
    }

    func testSendMessageFailure() async {
        // Given
        viewModel.inputText = "Test message"
        settings.aiDataSharingEnabled = true
        mockService.shouldSucceed = false
        mockService.errorToThrow = AIAssistantError.apiError("Network error")

        // When
        await viewModel.send()

        // Then
        XCTAssertFalse(viewModel.isSending)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.inputText, "") // Should be cleared even on failure
        XCTAssertEqual(viewModel.messages.count, 1) // Only welcome message (user message not added)
    }

    func testClearError() {
        // Given
        viewModel.errorMessage = "Test error"

        // When
        viewModel.clearError()

        // Then
        XCTAssertNil(viewModel.errorMessage)
    }
}

// Mock service for testing
class MockAIAssistantService: AIAssistantServiceProtocol {
    var shouldSucceed = true
    var errorToThrow: Error?
    var sentMessages: [AIChatMessage] = []
    var sentBaby: Baby?
    var sentConversationId: String?

    func sendMessage(messages: [AIChatMessage], baby: Baby?, conversationId: String?) async throws -> [AIChatMessage] {
        sentMessages = messages
        sentBaby = baby
        sentConversationId = conversationId

        if !shouldSucceed {
            throw errorToThrow ?? AIAssistantError.apiError("Mock error")
        }

        // Return mock response
        let assistantMessage = AIChatMessage(
            role: .assistant,
            content: "This is a mock response to: \(messages.last?.content ?? "")",
            createdAt: Date()
        )

        return messages + [assistantMessage]
    }
}

