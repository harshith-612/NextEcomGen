import Foundation
import SwiftData

@Model
final class OrderEntity {

    var date: Date?
    var id: UUID?
    var status: String?
    var totalAmount: Double = 0.0
    var items: [OrderItemEntity] = []
    var user: UserEntity?

    init() {}
}
