import Foundation
import SwiftData

@Model final class CartEntity {
    public var id: UUID?
    public var imageName: String?
    public var name: String?
    public var price: String?
    public var productID: UUID?
    public var quantity: Int64? = 0
    var user: UserEntity?
    public init() {

    }
    
}
