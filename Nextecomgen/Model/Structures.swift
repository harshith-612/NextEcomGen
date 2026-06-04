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
enum OrderStatus: String, Codable, CaseIterable {
    case placed = "Order Placed"
    case preparing = "Preparing"
    case outForDelivery = "Out for Delivery"
    case delivered = "Delivered"
    var step: Int {
        switch self {
        case .placed: return 1
        case .preparing: return 2
        case .outForDelivery: return 3
        case .delivered: return 4
        }
    }
}
