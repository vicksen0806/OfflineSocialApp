import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @ObservedObject var profileService = ProfileService.shared
    @ObservedObject var bleManager = BLEManager.shared
    @State private var showingProfile = false
    @State private var showingNearbyUsers = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                    .frame(height: 0)
                
                // Profile Section
                VStack(spacing: 16) {
                    if let photo = profileService.profile.photo {
                        photo
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 120, height: 120)
                            .foregroundColor(.gray)
                    }
                    
                    Text(profileService.profile.name.isEmpty ? "No Name Set" : profileService.profile.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    if !profileService.profile.interests.isEmpty {
                        Text(profileService.profile.interests.joined(separator: ", "))
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .padding()
                
                // Visibility Toggle
                VStack(spacing: 16) {
                    Button(action: toggleVisibility) {
                        HStack {
                            Image(systemName: profileService.profile.isVisible ? "eye.fill" : "eye.slash.fill")
                            Text(profileService.profile.isVisible ? "Visible to Others" : "Not Visible")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(profileService.profile.isVisible ? Color.green : Color.gray)
                        .cornerRadius(12)
                    }
                    
                    Text(profileService.profile.isVisible ? "Others can discover you nearby" : "You are hidden from others")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showingNearbyUsers = true
                    }) {
                        HStack {
                            Image(systemName: "person.2.fill")
                            Text("Find Nearby Users")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showingProfile = true
                    }) {
                        HStack {
                            Image(systemName: "person.circle")
                            Text("Edit Profile")
                        }
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                // Bluetooth Status
                if bleManager.bluetoothState != .poweredOn {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(bluetoothStatusText)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Offline Social")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
            .sheet(isPresented: $showingNearbyUsers) {
                NearbyUsersView()
            }
            .onAppear {
                if !bleManager.isScanning {
                    bleManager.startScanning()
                }
            }
        }
    }
    
    private var bluetoothStatusText: String {
        switch bleManager.bluetoothState {
        case .poweredOff:
            return "Bluetooth is turned off"
        case .unauthorized:
            return "Bluetooth permission required"
        case .unsupported:
            return "Bluetooth not supported"
        default:
            return "Bluetooth status unknown"
        }
    }
    
    private func toggleVisibility() {
        let newVisibility = !profileService.profile.isVisible
        profileService.updateProfile(isVisible: newVisibility)
        
        if newVisibility {
            bleManager.startAdvertising(profile: profileService.profile)
        } else {
            bleManager.stopAdvertising()
        }
    }
}

#Preview {
    ContentView()
}

