import SwiftUI
import CoreBluetooth

struct ContentView: View {
    @ObservedObject var profileService = ProfileService.shared
    @ObservedObject var bleManager = BLEManager.shared
    @State private var showingProfile = false
    @State private var showingNearbyUsers = false
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            NavigationView {
                ZStack {
                    Color.white
                        .ignoresSafeArea()

                VStack(spacing: 18) {
                Spacer()
                    .frame(minHeight: 10)

                // Profile Section
                VStack(spacing: 10) {
                    if let photo = profileService.profile.photo {
                        photo
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 90, height: 90)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 90, height: 90)
                            .foregroundColor(.gray.opacity(0.5))
                    }

                    Text(profileService.profile.name.isEmpty ? "No Name Set" : profileService.profile.name)
                        .font(.title3)
                        .fontWeight(.bold)

                    if !profileService.profile.interests.isEmpty {
                        Text(profileService.profile.interests.joined(separator: ", "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                    }
                }
                .padding(.horizontal)

                // Visibility Toggle
                VStack(spacing: 6) {
                    Button(action: toggleVisibility) {
                        HStack(spacing: 8) {
                            Image(systemName: profileService.profile.isVisible ? "eye.fill" : "eye.slash.fill")
                            Text(profileService.profile.isVisible ? "Visible to Others" : "Not Visible")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .padding(.horizontal)
                        .background(profileService.profile.isVisible ? Color.green : Color.gray)
                        .cornerRadius(10)
                        .shadow(color: (profileService.profile.isVisible ? Color.green : Color.gray).opacity(0.3), radius: 3, x: 0, y: 2)
                    }

                    Text(profileService.profile.isVisible ? "Others can discover you nearby" : "You are hidden from others")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 20)

                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        showingNearbyUsers = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.2.fill")
                            Text("Find Nearby Users")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .padding(.horizontal)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 2)
                    }

                    Button(action: {
                        showingProfile = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "person.circle")
                            Text("Edit Profile")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .padding(.horizontal)
                        .background(Color.blue)
                        .cornerRadius(10)
                        .shadow(color: Color.blue.opacity(0.3), radius: 3, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 20)

                // Bluetooth Status
                if bleManager.bluetoothState != .poweredOn {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text(bluetoothStatusText)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 20)
                }

                Spacer()
                    .frame(minHeight: 20)
                }
            }
            .navigationTitle("TuTu")
            .navigationBarTitleDisplayMode(.inline)
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
        .accentColor(.blue)
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

