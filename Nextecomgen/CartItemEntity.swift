import Foundation
import SwiftData

@Model
final class CartItemEntity {

    var category: String?
    var id: Int64?
    var imageName: String?
    var name: String?
    var price: Double?
    var productDescription: String?

    var user: UserEntity?

    init() {}
}
