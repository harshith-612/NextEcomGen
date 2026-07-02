import SwiftUI
import SwiftData
import UIKit
@main
struct NextecomgenApp: App {
    
    @StateObject private var network = NetworkMonitor()
    @AppStorage("selectedTheme") private var selectedTheme: String = AppTheme.dark.rawValue
    
    private var colorScheme: ColorScheme? {
        switch selectedTheme {
        case AppTheme.light.rawValue:
            return .light
        case AppTheme.dark.rawValue:
            return .dark
        default:
            return nil
        }
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                ContentView()
                    .environmentObject(network)
                    .preferredColorScheme(colorScheme)
            }
        }
    }
}
