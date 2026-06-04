import Foundation
struct DummyJSONRoot: Codable {
    let products: [Product]
}
struct Product: Identifiable, Codable, Equatable {
    let id: Int
    let name: String
    let imageName: String
    let images: [String]
    let description: String
    let price: Double
    let reviews: [[String: String]]
    let category: String
    enum CodingKeys: String, CodingKey {
        case id
        case name = "title"
        case imageName = "thumbnail"
        case images
        case description
        case price
        case reviews
        case category
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        imageName = try container.decode(String.self, forKey: .imageName)
        description = try container.decode(String.self, forKey: .description)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? "General"
        price = try container.decodeIfPresent(Double.self, forKey: .price) ?? 0.0
        if let decodedImages = try? container.decode([String].self, forKey: .images), !decodedImages.isEmpty {
            images = decodedImages
        } else {
            images = [imageName]
        }
        if let raw = try? container.decode([JSONReviewItem].self, forKey: .reviews) {
            reviews = raw.map {
                [
                    "rating": "\($0.rating)",
                    "comment": $0.comment,
                    "date": $0.date,
                    "reviewerName": $0.reviewerName,
                    "reviewerEmail": $0.reviewerEmail
                ]
            }
        } else {
            reviews = []
        }
    }
    init(
        id: Int,
        name: String,
        imageName: String,
        images: [String] = [],
        description: String,
        price: Double,
        reviews: [[String: String]] = [],
        category: String
    ) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.images = images.isEmpty ? [imageName] : images
        self.description = description
        self.price = price
        self.reviews = reviews
        self.category = category
    }
    var formattedPrice: String {
        "₹\(Int(price))"
    }
}
fileprivate struct JSONReviewItem: Codable {
    let rating: Int
    let comment: String
    let date: String
    let reviewerName: String
    let reviewerEmail: String
}
struct Order: Identifiable, Codable {
    var id = UUID()
    var dateString: String
    var totalAmount: Double
    var itemNames: [String]
    var status: String = "Pending"
}
struct AdminTransaction: Identifiable, Codable {
    let id: UUID
    let orderIDString: String
    let totalAmount: Float
    let transactionID: String
    let date: Date
    let associatedProducts: [Product]
    let buyerUsername: String
    let buyerFullName: String
}
enum AppTab: String, Hashable {
    case home, search, cart, profile, admin, detail
}
/*enum UserRole: String {
    case admin
    case customer
}

enum OrderStatus: String {
    case placed
    case shipped
    case delivered
}*/
