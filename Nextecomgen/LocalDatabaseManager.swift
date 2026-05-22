import Foundation
class LocalDatabaseManager {
    static let shared = LocalDatabaseManager()
    private init() {}
    
    private let defaults = UserDefaults.standard
    func loadProducts() -> [Product]? {
        guard let data = defaults.data(forKey: "stored_products") else { return nil }
        return try? JSONDecoder().decode([Product].self, from: data)
    }
    
    func saveProducts(_ products: [Product]) {
        if let data = try? JSONEncoder().encode(products) {
            defaults.set(data, forKey: "stored_products")
        }
    }
    func getUserDetails(username: String) -> [String: String]? {
        return defaults.dictionary(forKey: "user_\(username)") as? [String: String]
    }
    
    func saveNewUser(username: String, profileData: [String: String]) {
        defaults.set(profileData, forKey: "user_\(username)")
    }
    func getAddresses(for username: String) -> [String] {
        return defaults.stringArray(forKey: "addresses_\(username)") ?? []
    }
    
    func saveAddresses(_ addresses: [String], for username: String) {
        defaults.set(addresses, forKey: "addresses_\(username)")
    }
    func getOrderHistory(for username: String) -> [Order] {
        guard let data = defaults.data(forKey: "orders_\(username)") else { return [] }
        return (try? JSONDecoder().decode([Order].self, from: data)) ?? []
    }
    
    func saveOrderHistory(_ orders: [Order], for username: String) {
        if let data = try? JSONEncoder().encode(orders) {
            defaults.set(data, forKey: "orders_\(username)")
        }
    }
}
