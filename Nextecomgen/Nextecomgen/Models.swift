import Foundation

struct DummyJSONRoot: Codable {
    let products: [Product]
}

struct Product: Identifiable, Codable {
    var id: Int
    var name: String
    var imageName: String
    var images: [String]
    var description: String
    var price: String
    var reviews: [[String: String]]
    var category: String
    
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
        
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.imageName = try container.decode(String.self, forKey: .imageName)
        self.description = try container.decode(String.self, forKey: .description)
        self.category = try container.decodeIfPresent(String.self, forKey: .category) ?? "general"
        if let rawReviewsArray = try? container.decode([JSONReviewItem].self, forKey: .reviews) {
            self.reviews = rawReviewsArray.map { item in
                return [
                    "rating": String(item.rating),
                    "comment": item.comment,
                    "date": item.date,
                    "reviewerName": item.reviewerName,
                    "reviewerEmail": item.reviewerEmail
                ]
            }
        } else if let cachedReviews = try? container.decode([[String: String]].self, forKey: .reviews) {
            self.reviews = cachedReviews
        } else {
            self.reviews = [
                ["reviewerName": "Verified Buyer", "comment": "Excellent quality!", "rating": "5", "date": "2026-05-21T12:00:00Z"],
                ["reviewerName": "Anonymous", "comment": "Worth the purchase.", "rating": "4", "date": "2026-05-20T09:30:00Z"]
            ]
        }
        
        if let decodedImages = try? container.decode([String].self, forKey: .images), !decodedImages.isEmpty {
            self.images = decodedImages
        } else {
            self.images = [self.imageName]
        }
        
        if let doublePrice = try? container.decode(Float.self, forKey: .price) {
            self.price = String(format: "₹%.2f", doublePrice)
        } else if let intPrice = try? container.decode(Int.self, forKey: .price) {
            self.price = "₹\(intPrice)"
        } else if let stringPrice = try? container.decode(String.self, forKey: .price) {
            if stringPrice.contains("$") {
                self.price = stringPrice.replacingOccurrences(of: "$", with: "₹")
            } else if !stringPrice.contains("₹") {
                self.price = "₹\(stringPrice)"
            } else {
                self.price = stringPrice
            }
        } else {
            self.price = "₹0.00"
        }
    }
    
    init(id: Int, name: String, imageName: String, images: [String] = [], description: String, price: String, reviews: [[String: String]] = [], category: String) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.images = images.isEmpty ? [imageName] : images
        self.description = description
        self.price = price
        self.reviews = reviews.isEmpty ? [
            ["reviewerName": "Verified Buyer", "comment": "Excellent quality!", "rating": "5", "date": "2026-05-21T12:00:00Z"],
            ["reviewerName": "Anonymous", "comment": "Worth the purchase.", "rating": "4", "date": "2026-05-20T09:30:00Z"]
        ] : reviews
        self.category = category
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
    var totalAmount: Float
    var itemNames: [String]
}

enum AppTab {
    case home, search, cart, profile, admin
}
