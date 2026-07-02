import Foundation
import SwiftData

@Model
final class OrderItemEntity {

    var id: Int64?
    var name: String?
    var price: Double?
    var imageName: String?
    var order: OrderEntity?

    init() {}
}
