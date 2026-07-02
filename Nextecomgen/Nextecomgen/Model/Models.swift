import Foundation
import SwiftUI
struct DummyJSONRoot: Codable {
    let products: [Product]
}
struct Product: Identifiable, Codable, Equatable,Hashable {
    let id: Int
    let name: String
    let imageName: String
    let images: [String]
    let productDescription: String
    let price: Double
    let category: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case imageName
        case productDescription
        case price
        case category
        case images
    }
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        imageName = try container.decode(String.self, forKey: .imageName)
        productDescription = try container.decode(String.self, forKey: .productDescription)
        category = try container.decodeIfPresent(String.self, forKey: .category) ?? "General"
        price = try container.decodeIfPresent(Double.self, forKey: .price) ?? 0.0
        if let decodedImages = try? container.decode([String].self, forKey: .images), !decodedImages.isEmpty {
            images = decodedImages
        } else {
            images = [imageName]
        }
        struct JSONReviewItem: Decodable {
            let name: String
            let rating: Int
            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                let dictionary = try container.decode([String: Int].self)
                if let (key, value) = dictionary.first {
                    self.name = key
                    self.rating = value
                } else {
                    throw DecodingError.dataCorruptedError(
                        in: container,
                        debugDescription: "Review item dictionary is empty"
                    )
                }
            }
        }
    }
    init(
        id: Int,
        name: String,
        imageName: String,
        images: [String] = [],
        productDescription: String,
        price: Double,
        category: String
    ) {
        self.id = id
        self.name = name
        self.imageName = imageName
        self.images = images.isEmpty ? [imageName] : images
        self.productDescription = productDescription
        self.price = price
        self.category = category
    }
    var formattedPrice: String {
        "₹\(Int(price))"
    }
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

struct Address: Identifiable, Codable, Equatable {
    var id: String?
    var name: String
    var phoneNumber: String
    var houseNumber: String
    var street: String
    var pincode: String
    var state: String
}

struct AddressDTO: Codable {
    let id: String?
    let userId: String?
    let name: String
    let phoneNumber: String
    let houseNumber: String
    let street: String
    let pincode: String
    let state: String
}
enum AppTab: String, Hashable {
    case home, search, cart, profile, admin, detail
}
extension AppTab {
    var tabIndex: CGFloat {
        switch self {
        case .home:
            return 0
        case .cart:
            return 1
        case .profile:
            return 2
        case .search:
            return 0
        case .admin:
            return 0
        case .detail:
            return 0
        }
    }
}
enum NetworkBannerState: Equatable {
    case none
    case offline
    case reconnected
}
struct APIErrorResponse: Codable {
    let detail: APIErrorDetail?
    let message: String?
}
struct APIErrorDetail: Codable {
    let msg: String?
}
func parseErrorMessage(_ data: Data) -> String {
    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        if let detail = json["detail"] as? String {
            return detail
        }
        if let message = json["message"] as? String {
            return message
        }
        if let detailArray = json["detail"] as? [[String: Any]],
           let first = detailArray.first,
           let msg = first["msg"] as? String {
            return msg
        }
    }
    return String(data: data, encoding: .utf8) ?? "Unknown error"
}
struct StoryboardThemeContainer: UIViewControllerRepresentable {

    var onClose: () -> Void

    func makeUIViewController(context: Context) -> UIViewController {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        let vc = storyboard.instantiateViewController(
            identifier: "ThemeViewController"
        ) as! ThemeViewController

        vc.onClose = onClose

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen

        return nav
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

import PhotosUI
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard let provider = results.first?.itemProvider,
                  provider.canLoadObject(ofClass: UIImage.self) else { return }
            provider.loadObject(ofClass: UIImage.self) { image, _ in
                DispatchQueue.main.async {
                    self.parent.image = image as? UIImage
                }
            }
        }
    }
}
