import SwiftUI

struct ChatView: View {
    let user: NearbyUser
    @ObservedObject var chatService = ChatService.shared
    @ObservedObject var profileService = ProfileService.shared
    @ObservedObject var bleManager = BLEManager.shared
    @State private var messageText: String = ""
    @State private var messages: [ChatMessage] = []
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(messages) { message in
                                MessageBubble(message: message, isFromMe: message.isFromMe)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: messages.count) { oldValue, newValue in
                        if let lastMessage = messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
                
                // Message Input
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $messageText, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(1...4)
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor((messageText.isEmpty || !user.isConnected) ? .gray : .blue)
                            .opacity((messageText.isEmpty || !user.isConnected) ? 0.5 : 1.0)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(messageText.isEmpty || !user.isConnected)
                    .contentShape(Rectangle()) // Makes entire button area tappable
                }
                .padding()
                .background(Color(.systemBackground))
            }
            .navigationTitle(user.name.isEmpty ? "Chat" : user.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadMessages()
                setupMessageHandler()
            }
            .onDisappear {
                bleManager.onMessageReceived = nil
            }
        }
    }
    
    private func loadMessages() {
        messages = chatService.getMessages(for: user.id)
        chatService.updateSessionUserName(userId: user.id, userName: user.name)
    }
    
    private func setupMessageHandler() {
        let userId = user.id
        // View-specific handler just updates the UI
        // Global handler already saves messages to ChatService
        bleManager.onMessageReceived = { message, receivedUserId in
            if receivedUserId == userId {
                // Refresh messages from ChatService (already saved by global handler)
                DispatchQueue.main.async {
                    self.messages = self.chatService.getMessages(for: userId)
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty, user.isConnected else { return }
        
        let contentToSend = messageText
        messageText = "" // Clear immediately to prevent double-send
        
        let message = ChatMessage(
            senderId: profileService.profile.id,
            receiverId: user.id,
            content: contentToSend,
            isFromMe: true
        )
        
        // Add message locally first
        chatService.addMessage(message, to: user.id)
        messages = chatService.getMessages(for: user.id)
        
        // Send via BLE
        bleManager.sendMessage(message, to: user.id)
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    let isFromMe: Bool
    
    var body: some View {
        HStack {
            if isFromMe {
                Spacer()
            }
            
            VStack(alignment: isFromMe ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(isFromMe ? Color.blue : Color(.systemGray5))
                    .foregroundColor(isFromMe ? .white : .primary)
                    .cornerRadius(18)
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: isFromMe ? .trailing : .leading)
            
            if !isFromMe {
                Spacer()
            }
        }
    }
}

#Preview {
    ChatView(user: NearbyUser(
        name: "John Doe",
        interests: ["Music", "Sports"],
        isConnected: true
    ))
}

