import Foundation

struct ChatSession: Codable, Identifiable {
    let id: UUID
    let userId: UUID
    var userName: String
    var messages: [ChatMessage]
    var lastMessageTime: Date
    
    init(id: UUID = UUID(), userId: UUID, userName: String, messages: [ChatMessage] = [], lastMessageTime: Date = Date()) {
        self.id = id
        self.userId = userId
        self.userName = userName
        self.messages = messages
        self.lastMessageTime = lastMessageTime
    }
    
    mutating func addMessage(_ message: ChatMessage) {
        messages.append(message)
        lastMessageTime = message.timestamp
    }
}

