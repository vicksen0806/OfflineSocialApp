import Foundation
import CoreBluetooth
import SwiftUI
import UIKit

struct NearbyUser: Identifiable, Equatable {
    let id: UUID
    var name: String
    var photoData: Data?
    var interests: [String]
    var peripheral: CBPeripheral?
    var lastSeen: Date
    var isConnected: Bool
    
    init(id: UUID = UUID(), name: String = "", photoData: Data? = nil, interests: [String] = [], peripheral: CBPeripheral? = nil, lastSeen: Date = Date(), isConnected: Bool = false) {
        self.id = id
        self.name = name
        self.photoData = photoData
        self.interests = interests
        self.peripheral = peripheral
        self.lastSeen = lastSeen
        self.isConnected = isConnected
    }
    
    var photo: Image? {
        guard let photoData = photoData,
              let uiImage = UIImage(data: photoData) else {
            return nil
        }
        return Image(uiImage: uiImage)
    }
    
    static func == (lhs: NearbyUser, rhs: NearbyUser) -> Bool {
        lhs.id == rhs.id
    }
}

