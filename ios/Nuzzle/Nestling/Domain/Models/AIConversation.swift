import Foundation

/// AI conversation model
struct AIConversation: Identifiable, Codable {
    let id: UUID
    let babyId: UUID?
    let title: String
    var messages: [AIMessage]
    let createdAt: Date
    var updatedAt: Date
    
    init(id: UUID = UUID(), babyId: UUID? = nil, title: String, messages: [AIMessage] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.babyId = babyId
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// AI message model
struct AIMessage: Identifiable, Codable {
    let id: UUID
    let role: MessageRole
    let content: String
    let createdAt: Date
    let containsRedFlag: Bool
    
    enum MessageRole: String, Codable {
        case user
        case assistant
    }
    
    init(id: UUID = UUID(), role: MessageRole, content: String, createdAt: Date = Date(), containsRedFlag: Bool = false) {
        self.id = id
        self.role = role
        self.content = content
        self.createdAt = createdAt
        self.containsRedFlag = containsRedFlag
    }
}




