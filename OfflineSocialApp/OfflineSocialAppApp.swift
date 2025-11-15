import SwiftUI

@main
struct OfflineSocialAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
}

