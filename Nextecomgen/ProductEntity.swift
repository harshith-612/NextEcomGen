import Foundation
import SwiftData
@Model
final class ProductEntity {
    var id: Int
    var name: String
    var imageName: String
    var productDescription: String
    var price: Double
    var category: String

    init(id: Int, name: String, imageName: String, productDescription: String, price: Double, category: String) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.productDescription = productDescription
        self.price = price
        self.category = category
    }
}
