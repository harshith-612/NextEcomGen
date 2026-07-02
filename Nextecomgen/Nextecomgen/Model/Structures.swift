import Foundation

enum UserRole: String {
    case admin
    case customer
}
enum Field: Hashable {
    case fullName
    case email
    case password
    case confirmPassword
}
enum AppTheme: String {
    case light
    case dark
    case system
}
