import Foundation
import CoreBluetooth
import Combine

class BLEManager: NSObject, ObservableObject {
    static let shared = BLEManager()
    
    // BLE Service and Characteristic UUIDs
    static let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABC")
    static let profileCharacteristicUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABD")
    static let messageCharacteristicUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABE")
    static let statusCharacteristicUUID = CBUUID(string: "12345678-1234-1234-1234-123456789ABF")
    
    // Central Manager (for scanning)
    private var centralManager: CBCentralManager?
    
    // Peripheral Manager (for advertising)
    private var peripheralManager: CBPeripheralManager?
    
    // Connected peripherals
    private var connectedPeripherals: [UUID: CBPeripheral] = [:]
    private var peripheralCharacteristics: [UUID: [CBCharacteristic]] = [:]
    
    // Mutable characteristics for peripheral mode
    private var messageCharacteristic: CBMutableCharacteristic?
    private var profileCharacteristic: CBMutableCharacteristic?
    
    // Published properties
    @Published var nearbyUsers: [NearbyUser] = []
    @Published var isScanning = false
    @Published var isAdvertising = false
    @Published var bluetoothState: CBManagerState = .unknown
    
    // Message handling
    var onMessageReceived: ((ChatMessage, UUID) -> Void)?
    
    // Global persistent message handler that always saves messages
    private var globalMessageHandler: ((ChatMessage, UUID) -> Void)?
    
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        peripheralManager = CBPeripheralManager(delegate: self, queue: nil)
        setupGlobalMessageHandler()
    }
    
    private func setupGlobalMessageHandler() {
        // Global handler that always saves messages to ChatService
        globalMessageHandler = { [weak self] message, userId in
            guard let self = self else { return }
            let profileId = ProfileService.shared.profile.id
            
            // Only process incoming messages (where we are the receiver)
            if message.receiverId == profileId && message.senderId != profileId {
                let newMessage = ChatMessage(
                    senderId: message.senderId,
                    receiverId: message.receiverId,
                    content: message.content,
                    timestamp: message.timestamp,
                    isFromMe: false
                )
                
                // Always save to ChatService (even if no ChatView is open)
                ChatService.shared.addMessage(newMessage, to: userId)
                
                // Also call the view-specific handler if set
                DispatchQueue.main.async {
                    self.onMessageReceived?(message, userId)
                }
            }
        }
    }
    
    // MARK: - Central Role (Scanning)
    func startScanning() {
        guard let centralManager = centralManager,
              centralManager.state == .poweredOn else {
            print("Central manager not ready")
            return
        }
        
        let serviceUUIDs = [BLEManager.serviceUUID]
        centralManager.scanForPeripherals(withServices: serviceUUIDs, options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        isScanning = true
    }
    
    func stopScanning() {
        centralManager?.stopScan()
        isScanning = false
    }
    
    // MARK: - Peripheral Role (Advertising)
    func startAdvertising(profile: UserProfile) {
        guard let peripheralManager = peripheralManager,
              peripheralManager.state == .poweredOn else {
            print("Peripheral manager not ready")
            return
        }
        
        guard !isAdvertising else { return }
        
        let service = CBMutableService(type: BLEManager.serviceUUID, primary: true)
        
        // Profile Characteristic (Read-only)
        let profileCharacteristic = CBMutableCharacteristic(
            type: BLEManager.profileCharacteristicUUID,
            properties: [.read],
            value: nil,
            permissions: [.readable]
        )
        
        // Message Characteristic (Write/Notify)
        let messageCharacteristic = CBMutableCharacteristic(
            type: BLEManager.messageCharacteristicUUID,
            properties: [.write, .notify],
            value: nil,
            permissions: [.writeable]
        )
        
        // Store reference to mutable characteristics
        self.messageCharacteristic = messageCharacteristic
        self.profileCharacteristic = profileCharacteristic
        
        // Status Characteristic (Read-only)
        let statusCharacteristic = CBMutableCharacteristic(
            type: BLEManager.statusCharacteristicUUID,
            properties: [.read],
            value: "available".data(using: .utf8),
            permissions: [.readable]
        )
        
        service.characteristics = [profileCharacteristic, messageCharacteristic, statusCharacteristic]
        
        peripheralManager.add(service)
        
        // Set profile data
        if let profileData = BLEProfileExchange.encodeProfile(profile) {
            profileCharacteristic.value = profileData
        }
        
        let advertisementData: [String: Any] = [
            CBAdvertisementDataServiceUUIDsKey: [BLEManager.serviceUUID],
            CBAdvertisementDataLocalNameKey: profile.name.isEmpty ? "OfflineSocial User" : profile.name
        ]
        
        peripheralManager.startAdvertising(advertisementData)
        isAdvertising = true
    }
    
    func stopAdvertising() {
        peripheralManager?.stopAdvertising()
        peripheralManager?.removeAllServices()
        isAdvertising = false
        messageCharacteristic = nil
        profileCharacteristic = nil
    }
    
    // MARK: - Connection Management
    private func connect(to peripheral: CBPeripheral) {
        guard !connectedPeripherals.values.contains(peripheral) else { return }
        connectedPeripherals[peripheral.identifier] = peripheral
        centralManager?.connect(peripheral, options: nil)
    }
    
    private func disconnect(from peripheral: CBPeripheral) {
        centralManager?.cancelPeripheralConnection(peripheral)
        connectedPeripherals.removeValue(forKey: peripheral.identifier)
        peripheralCharacteristics.removeValue(forKey: peripheral.identifier)
    }
    
    // MARK: - Message Sending
    func sendMessage(_ message: ChatMessage, to userId: UUID) {
        guard let peripheral = connectedPeripherals[userId],
              let characteristics = peripheralCharacteristics[userId],
              let messageCharacteristic = characteristics.first(where: { $0.uuid == BLEManager.messageCharacteristicUUID }),
              let messageData = BLEProfileExchange.encodeMessage(message) else {
            print("Cannot send message: peripheral or characteristic not found")
            return
        }
        
        peripheral.writeValue(messageData, for: messageCharacteristic, type: .withResponse)
    }
}

// MARK: - CBCentralManagerDelegate
extension BLEManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        bluetoothState = central.state
        switch central.state {
        case .poweredOn:
            if isScanning {
                startScanning()
            }
        case .poweredOff, .unauthorized, .unsupported:
            stopScanning()
        default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        // Update or add nearby user
        if let existingIndex = nearbyUsers.firstIndex(where: { $0.peripheral?.identifier == peripheral.identifier }) {
            nearbyUsers[existingIndex].lastSeen = Date()
        } else {
            let newUser = NearbyUser(
                id: peripheral.identifier,
                name: advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? "Unknown",
                peripheral: peripheral,
                lastSeen: Date()
            )
            nearbyUsers.append(newUser)
            connect(to: peripheral)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([BLEManager.serviceUUID])
        
        if let index = nearbyUsers.firstIndex(where: { $0.peripheral?.identifier == peripheral.identifier }) {
            nearbyUsers[index].isConnected = true
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        if let index = nearbyUsers.firstIndex(where: { $0.peripheral?.identifier == peripheral.identifier }) {
            nearbyUsers[index].isConnected = false
        }
        connectedPeripherals.removeValue(forKey: peripheral.identifier)
        peripheralCharacteristics.removeValue(forKey: peripheral.identifier)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to peripheral: \(error?.localizedDescription ?? "unknown error")")
    }
}

// MARK: - CBPeripheralDelegate
extension BLEManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        var charDict = peripheralCharacteristics[peripheral.identifier] ?? []
        charDict.append(contentsOf: characteristics)
        peripheralCharacteristics[peripheral.identifier] = charDict
        
        for characteristic in characteristics {
            if characteristic.uuid == BLEManager.profileCharacteristicUUID {
                peripheral.readValue(for: characteristic)
            } else if characteristic.uuid == BLEManager.messageCharacteristicUUID {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard let data = characteristic.value else { return }
        
        if characteristic.uuid == BLEManager.profileCharacteristicUUID {
            if let profile = BLEProfileExchange.decodeProfile(from: data) {
                if let index = nearbyUsers.firstIndex(where: { $0.peripheral?.identifier == peripheral.identifier }) {
                    nearbyUsers[index].name = profile.name
                    nearbyUsers[index].photoData = profile.photoData
                    nearbyUsers[index].interests = profile.interests
                }
            }
        } else if characteristic.uuid == BLEManager.messageCharacteristicUUID {
            if let message = BLEProfileExchange.decodeMessage(from: data) {
                // Call global handler first (always saves messages)
                globalMessageHandler?(message, peripheral.identifier)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error writing characteristic: \(error.localizedDescription)")
        }
    }
}

// MARK: - CBPeripheralManagerDelegate
extension BLEManager: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        bluetoothState = peripheral.state
        switch peripheral.state {
        case .poweredOn:
            // Ready to advertise
            break
        case .poweredOff, .unauthorized, .unsupported:
            stopAdvertising()
        default:
            break
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        if let error = error {
            print("Error adding service: \(error.localizedDescription)")
        } else {
            // Service added successfully, can now start advertising if not already
            // Note: Advertising might have already started before service was added
            // which is acceptable in Core Bluetooth
        }
    }
    
    // Helper method to update profile characteristic without restarting advertising
    func updateProfileData(_ profile: UserProfile) {
        guard isAdvertising, let profileCharacteristic = profileCharacteristic,
              let profileData = BLEProfileExchange.encodeProfile(profile) else {
            return
        }
        profileCharacteristic.value = profileData
    }
    
    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        if let error = error {
            print("Error starting advertising: \(error.localizedDescription)")
            isAdvertising = false
        }
    }
    
    func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if request.characteristic.uuid == BLEManager.messageCharacteristicUUID {
                if let data = request.value,
                   let message = BLEProfileExchange.decodeMessage(from: data) {
                    // Update the characteristic value
                    messageCharacteristic?.value = data
                    
                    // Get the central's identifier from the request
                    let centralId = request.central.identifier
                    
                    // Notify subscribers
                    if let characteristic = messageCharacteristic {
                        peripheral.updateValue(data, for: characteristic, onSubscribedCentrals: nil)
                    }
                    
                    // Call global handler first (always saves messages)
                    self.globalMessageHandler?(message, centralId)
                }
                peripheral.respond(to: request, withResult: .success)
            }
        }
    }
}

