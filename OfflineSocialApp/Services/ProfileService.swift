import Foundation
import Combine

class ProfileService: ObservableObject {
    static let shared = ProfileService()
    
    private let profileKey = "userProfile"
    
    @Published var profile: UserProfile {
        didSet {
            saveProfile()
        }
    }
    
    private init() {
        if let data = UserDefaults.standard.data(forKey: profileKey),
           let decoded = try? JSONDecoder().decode(UserProfile.self, from: data) {
            self.profile = decoded
        } else {
            self.profile = UserProfile()
        }
    }
    
    func saveProfile() {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: profileKey)
        }
    }
    
    func updateProfile(name: String? = nil, photoData: Data? = nil, interests: [String]? = nil, isVisible: Bool? = nil) {
        // Allow setting name to empty string (when name is not nil)
        if name != nil {
            profile.name = name ?? ""
        }
        if let photoData = photoData {
            profile.photoData = photoData
        }
        if let interests = interests {
            profile.interests = interests
        }
        if let isVisible = isVisible {
            profile.isVisible = isVisible
        }
        saveProfile()
    }
}

