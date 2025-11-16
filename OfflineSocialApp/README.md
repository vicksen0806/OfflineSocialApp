# Offline Social App

An iOS app that enables offline social interaction using Bluetooth Low Energy (BLE). Users can discover nearby people, view their profiles, and chat with them without internet connectivity.

## Features

- **Offline Discovery**: Find nearby users using Bluetooth Low Energy
- **Visibility Toggle**: Control whether others can discover you
- **User Profiles**: Set your name, photo, and interests
- **Real-time Chat**: Message with nearby users via BLE
- **Profile Exchange**: Automatically share profile information when discovered

## Requirements

- iOS 17.0 or later
- Xcode 15.0 or later
- Physical iOS device (Bluetooth requires real hardware, not simulator)

## Setup Instructions

### 1. Create Xcode Project

1. Open Xcode
2. Create a new project:
   - Choose "App" template
   - Product Name: `OfflineSocialApp`
   - Interface: SwiftUI
   - Language: Swift
   - Minimum Deployment: iOS 17.0

### 2. Add Files to Project

Add all files from this directory to your Xcode project:
- Models/ (all .swift files)
- Services/ (all .swift files)
- Views/ (all .swift files including Components/)
- OfflineSocialAppApp.swift

### 3. Configure Info.plist

The Info.plist file is already configured with required permissions:
- `NSBluetoothAlwaysUsageDescription`
- `NSBluetoothPeripheralUsageDescription`
- `NSPhotoLibraryUsageDescription`

Make sure these are added to your project's Info.plist in Xcode.

### 4. Add Capabilities

In Xcode:
1. Select your project target
2. Go to "Signing & Capabilities"
3. Add "Background Modes" capability
4. Enable "Uses Bluetooth LE accessories"

### 5. Build and Run

1. Connect a physical iOS device (BLE doesn't work in simulator)
2. Select your device as the run destination
3. Build and run the app

## Project Structure

```
OfflineSocialApp/
├── OfflineSocialAppApp.swift    # App entry point
├── Models/
│   ├── UserProfile.swift         # User profile model
│   ├── NearbyUser.swift          # Nearby user model
│   ├── ChatMessage.swift         # Chat message model
│   └── ChatSession.swift         # Chat session model
├── Services/
│   ├── BLEManager.swift          # Bluetooth Low Energy manager
│   ├── BLEProfileExchange.swift  # Profile data serialization
│   ├── ProfileService.swift      # Profile persistence
│   └── ChatService.swift         # Chat message storage
├── Views/
│   ├── ContentView.swift         # Main view
│   ├── ProfileView.swift         # Profile editing
│   ├── NearbyUsersView.swift     # Nearby users list
│   ├── ChatView.swift            # Chat interface
│   └── Components/
│       └── UserProfileCard.swift # User profile card component
└── Info.plist                    # App configuration
```

## Usage

1. **Set Up Profile**: Tap "Edit Profile" to set your name, photo, and interests
2. **Toggle Visibility**: Use the visibility button to allow others to discover you
3. **Find Users**: Tap "Find Nearby Users" to see people nearby
4. **Start Chatting**: Tap on a nearby user to open a chat

## Technical Details

### BLE Service Design

- **Service UUID**: `12345678-1234-1234-1234-123456789ABC`
- **Profile Characteristic**: Read-only, contains user profile data
- **Message Characteristic**: Write/Notify for chat messages
- **Status Characteristic**: Read-only, indicates availability

### Data Persistence

- User profiles stored in UserDefaults
- Chat messages stored locally per user
- All data persists between app launches

## Testing

To test the app:
1. Install on at least 2 physical iOS devices
2. Set up profiles on both devices
3. Enable visibility on both devices
4. Verify discovery and chat functionality

## Notes

- Bluetooth requires physical devices - the iOS Simulator does not support BLE
- Users must be within Bluetooth range (typically 10-30 meters)
- Both users must have visibility enabled to discover each other
- Chat messages are only delivered when both users are connected

