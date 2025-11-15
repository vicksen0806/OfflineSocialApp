import Foundation

struct ChatMessage: Codable, Identifiable {
    let id: UUID
    let senderId: UUID
    let receiverId: UUID
    let content: String
    let timestamp: Date
    let isFromMe: Bool
    
    init(id: UUID = UUID(), senderId: UUID, receiverId: UUID, content: String, timestamp: Date = Date(), isFromMe: Bool) {
        self.id = id
        self.senderId = senderId
        self.receiverId = receiverId
        self.content = content
        self.timestamp = timestamp
        self.isFromMe = isFromMe
    }
}

