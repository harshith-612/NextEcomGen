import Foundation
import SwiftData
@Model
final class UserEntity {
    var email: String?
    var fullName: String?
    var password: String?
    var role: String?
    var username: String?
    var addresses: [AddressEntity] = []
    var cartItems: [CartItemEntity] = []
    var orders: [OrderEntity] = []
    init() {}
}
