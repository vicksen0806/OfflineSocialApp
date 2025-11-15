import Foundation
import Combine

class ChatService: ObservableObject {
    static let shared = ChatService()
    
    private let sessionsKey = "chatSessions"
    
    @Published var sessions: [ChatSession] = []
    
    private init() {
        loadSessions()
    }
    
    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let decoded = try? JSONDecoder().decode([ChatSession].self, from: data) {
            self.sessions = decoded
        }
    }
    
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: sessionsKey)
        }
    }
    
    func getOrCreateSession(with userId: UUID, userName: String) -> ChatSession {
        if let index = sessions.firstIndex(where: { $0.userId == userId }) {
            return sessions[index]
        } else {
            let newSession = ChatSession(userId: userId, userName: userName)
            sessions.append(newSession)
            saveSessions()
            return newSession
        }
    }
    
    func addMessage(_ message: ChatMessage, to userId: UUID) {
        if let index = sessions.firstIndex(where: { $0.userId == userId }) {
            // Check for duplicates before adding
            let existingMessages = sessions[index].messages
            let isDuplicate = existingMessages.contains { existingMessage in
                // Check by ID or by content + timestamp (within 1 second)
                existingMessage.id == message.id ||
                (existingMessage.content == message.content &&
                 existingMessage.senderId == message.senderId &&
                 existingMessage.receiverId == message.receiverId &&
                 abs(existingMessage.timestamp.timeIntervalSince(message.timestamp)) < 1.0)
            }
            
            if !isDuplicate {
                sessions[index].addMessage(message)
                saveSessions()
            }
        } else {
            // Create new session if it doesn't exist
            var newSession = ChatSession(userId: userId, userName: "Unknown")
            newSession.addMessage(message)
            sessions.append(newSession)
            saveSessions()
        }
    }
    
    func getMessages(for userId: UUID) -> [ChatMessage] {
        return sessions.first(where: { $0.userId == userId })?.messages ?? []
    }
    
    func updateSessionUserName(userId: UUID, userName: String) {
        if let index = sessions.firstIndex(where: { $0.userId == userId }) {
            sessions[index].userName = userName
            saveSessions()
        }
    }
}

