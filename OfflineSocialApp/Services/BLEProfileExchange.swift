import Foundation

struct BLEProfileExchange {
    static func encodeProfile(_ profile: UserProfile) -> Data? {
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(profile)
            return jsonData
        } catch {
            print("Error encoding profile: \(error)")
            return nil
        }
    }
    
    static func decodeProfile(from data: Data) -> UserProfile? {
        let decoder = JSONDecoder()
        do {
            let profile = try decoder.decode(UserProfile.self, from: data)
            return profile
        } catch {
            print("Error decoding profile: \(error)")
            return nil
        }
    }
    
    static func encodeMessage(_ message: ChatMessage) -> Data? {
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(message)
            return jsonData
        } catch {
            print("Error encoding message: \(error)")
            return nil
        }
    }
    
    static func decodeMessage(from data: Data) -> ChatMessage? {
        let decoder = JSONDecoder()
        do {
            let message = try decoder.decode(ChatMessage.self, from: data)
            return message
        } catch {
            print("Error decoding message: \(error)")
            return nil
        }
    }
}

