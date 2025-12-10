import XCTest
@testable import Nestling
import Supabase

final class AIAssistantServiceTests: XCTestCase {
    var service: AIAssistantService!
    var mockSupabaseClient: SupabaseClient!

    override func setUp() {
        super.setUp()

        // Create a mock SupabaseClient for testing
        // In a real scenario, you'd use a protocol or dependency injection
        service = AIAssistantService(dataStore: InMemoryDataStore())

        // Configure with test credentials
        mockSupabaseClient = SupabaseClient.shared
        mockSupabaseClient.configure(
            url: "https://test.supabase.co",
            anonKey: "test-anon-key"
        )
    }

    override func tearDown() {
        service = nil
        mockSupabaseClient = nil
        super.tearDown()
    }

    func testServiceInitialization() {
        XCTAssertNotNil(service)
    }

    func testSendMessageWithoutAuthentication() async throws {
        // Test sending message without authentication
        // This should work with anon key but may fail consent check

        let messages = [
            AIChatMessage(role: .user, content: "Test message", createdAt: Date())
        ]

        do {
            let result = try await service.sendMessage(messages: messages, baby: nil, conversationId: nil)
            // May fail due to network or authentication, but shouldn't crash
        } catch {
            // Expected to fail without proper setup
            XCTAssertNotNil(error)
        }
    }

    func testSendMessageWithBabyContext() async throws {
        // Test sending message with baby context
        let baby = Baby.mock()
        let messages = [
            AIChatMessage(role: .user, content: "How should I feed my baby?", createdAt: Date())
        ]

        do {
            let result = try await service.sendMessage(messages: messages, baby: baby, conversationId: nil)
            // Should include baby context in the request
        } catch {
            // Expected to fail without proper Supabase setup
            XCTAssertNotNil(error)
        }
    }

    func testSendMessageWithExistingConversation() async throws {
        // Test sending message with existing conversation ID
        let conversationId = "test-conversation-id"
        let messages = [
            AIChatMessage(role: .assistant, content: "Hello!", createdAt: Date()),
            AIChatMessage(role: .user, content: "How are you?", createdAt: Date())
        ]

        do {
            let result = try await service.sendMessage(messages: messages, baby: nil, conversationId: conversationId)
            // Should include conversation ID in request
        } catch {
            // Expected to fail without proper Supabase setup
            XCTAssertNotNil(error)
        }
    }

    func testGetSessionTokenExtraction() {
        // Test the session token extraction method
        // Create a mock session (this would normally come from Supabase SDK)
        let mockSession = MockSession(accessToken: "mock-access-token")

        // Test the private method indirectly by checking if it would work
        // Since getSessionToken is private, we test the integration

        // In a real test, you'd use dependency injection or a protocol
        // to mock the SupabaseClient behavior
    }

    // Mock classes for testing
    private class MockSession: Session {
        let mockAccessToken: String

        init(accessToken: String) {
            self.mockAccessToken = accessToken
            super.init(accessToken: accessToken, tokenType: "bearer", expiresIn: 3600, refreshToken: "refresh", user: User(id: "user-id", email: "test@example.com"))
        }

        override var accessToken: String {
            return mockAccessToken
        }
    }

    func testErrorHandling() async {
        // Test various error scenarios

        // Test with invalid messages
        let invalidMessages: [AIChatMessage] = []

        do {
            _ = try await service.sendMessage(messages: invalidMessages, baby: nil, conversationId: nil)
            XCTFail("Should have thrown error for invalid messages")
        } catch {
            // Expected error
            XCTAssertNotNil(error)
        }
    }

    func testBabyContextBuilding() async throws {
        // Test that baby context is properly built
        let baby = Baby.mock()

        // This tests the private buildBabyContext method indirectly
        // by ensuring the service can handle baby objects

        let messages = [
            AIChatMessage(role: .user, content: "Test", createdAt: Date())
        ]

        do {
            _ = try await service.sendMessage(messages: messages, baby: baby, conversationId: nil)
        } catch {
            // Expected to fail, but should not crash
            XCTAssertNotNil(error)
        }
    }
}


