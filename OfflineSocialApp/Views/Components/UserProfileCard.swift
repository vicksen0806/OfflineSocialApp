import SwiftUI

struct UserProfileCard: View {
    let user: NearbyUser
    
    var body: some View {
        HStack(spacing: 12) {
            // Profile Photo
            if let photo = user.photo {
                photo
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                    .foregroundColor(.gray)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(user.name.isEmpty ? "Unknown User" : user.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if user.isConnected {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                    }
                }
                
                if !user.interests.isEmpty {
                    Text(user.interests.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                } else {
                    Text("No interests listed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    UserProfileCard(user: NearbyUser(
        name: "John Doe",
        interests: ["Music", "Sports", "Technology"],
        isConnected: true
    ))
    .padding()
}

