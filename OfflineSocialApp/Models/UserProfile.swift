import Foundation
import SwiftUI
import UIKit

struct UserProfile: Codable, Identifiable {
    var id: UUID
    var name: String
    var photoData: Data?
    var interests: [String]
    var isVisible: Bool
    
    init(id: UUID = UUID(), name: String = "", photoData: Data? = nil, interests: [String] = [], isVisible: Bool = false) {
        self.id = id
        self.name = name
        self.photoData = photoData
        self.interests = interests
        self.isVisible = isVisible
    }
    
    var photo: Image? {
        guard let photoData = photoData,
              let uiImage = UIImage(data: photoData) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }
}

