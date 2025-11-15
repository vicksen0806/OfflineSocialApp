import SwiftUI

struct NearbyUsersView: View {
    @ObservedObject var bleManager = BLEManager.shared
    @State private var selectedUser: NearbyUser?
    
    var body: some View {
        NavigationView {
            VStack {
                if bleManager.nearbyUsers.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.slash")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No nearby users found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Make sure Bluetooth is enabled and other users have visibility turned on")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(bleManager.nearbyUsers) { user in
                            Button(action: {
                                selectedUser = user
                            }) {
                                UserProfileCard(user: user)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Nearby Users")
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedUser) { user in
                ChatView(user: user)
            }
            .onAppear {
                if !bleManager.isScanning {
                    bleManager.startScanning()
                }
            }
        }
    }
}

#Preview {
    NearbyUsersView()
}

