import SwiftUI
@main
struct NextecomgenApp: App {
    @State private var isLoggedIn: Bool = LocalDatabaseManager.shared.getCurrentUser() != nil
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
