import SwiftUI
import PhotosUI

struct ProfileView: View {
    @ObservedObject var profileService = ProfileService.shared
    @ObservedObject var bleManager = BLEManager.shared
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var name: String = ""
    @State private var interests: String = ""
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Profile Photo")) {
                    HStack {
                        Spacer()
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
                        Spacer()
                    }
                    .padding(.vertical)
                    
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Label("Select Photo", systemImage: "photo")
                    }
                }
                
                Section(header: Text("Personal Information")) {
                    TextField("Enter your name", text: $name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(false)
                }
                
                Section(header: Text("Interests")) {
                    TextField("Enter interests (comma-separated)", text: $interests, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Button("Save Profile") {
                        saveProfile()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        saveProfile()
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadProfile()
            }
            .onChange(of: selectedPhoto) { oldValue, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self) {
                        profileService.updateProfile(photoData: data)
                        // Restart advertising if currently advertising to update profile data
                        if bleManager.isAdvertising && profileService.profile.isVisible {
                            bleManager.stopAdvertising()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                bleManager.startAdvertising(profile: profileService.profile)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func loadProfile() {
        name = profileService.profile.name
        interests = profileService.profile.interests.joined(separator: ", ")
    }
    
    private func saveProfile() {
        let interestArray = interests.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        
        // Always update name, even if empty
        profileService.updateProfile(
            name: name,
            interests: interestArray.isEmpty ? nil : interestArray
        )
        
        // Update advertising if currently advertising to update profile data
        if bleManager.isAdvertising && profileService.profile.isVisible {
            // Update profile characteristic without restarting advertising
            bleManager.updateProfileData(profileService.profile)
            
            // Restart advertising to update the advertisement name
            bleManager.stopAdvertising()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                bleManager.startAdvertising(profile: profileService.profile)
            }
        }
    }
}

#Preview {
    ProfileView()
}

