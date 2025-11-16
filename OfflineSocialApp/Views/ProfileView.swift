import SwiftUI
import PhotosUI

struct ProfileView: View {
    @ObservedObject var profileService = ProfileService.shared
    @ObservedObject var bleManager = BLEManager.shared
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var name: String = ""
    @State private var interests: String = ""
    @FocusState private var focusedField: Field?
    @Environment(\.dismiss) var dismiss

    enum Field {
        case name
        case interests
    }
    
    var body: some View {
        NavigationStack {
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
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                }
                
                Section(header: Text("Interests")) {
                    TextField("Enter interests (comma-separated)", text: $interests, axis: .vertical)
                        .lineLimit(3...6)
                        .focused($focusedField, equals: .interests)
                        .submitLabel(.done)
                }
                
                Section {
                    Button("Save Profile") {
                        focusedField = nil // Dismiss keyboard
                        saveProfile()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .onSubmit {
                switch focusedField {
                case .name:
                    focusedField = .interests
                case .interests:
                    focusedField = nil
                case .none:
                    break
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        focusedField = nil // Dismiss keyboard
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

