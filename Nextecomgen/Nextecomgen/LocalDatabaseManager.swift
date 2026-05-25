import Foundation

class LocalDatabaseManager {
    static let shared = LocalDatabaseManager()
    private init() {}
    
    private let defaults = UserDefaults.standard
    func setCurrentUser(_ username: String?) {
        defaults.set(username, forKey: "current_logged_in_user")
    }
    
    func getCurrentUser() -> String? {
        return defaults.string(forKey: "current_logged_in_user")
    }
    
    func logout() {
        defaults.removeObject(forKey: "current_logged_in_user")
    }
    func authenticateUser(username: String, passwordInput: String) -> Bool {
        let key = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        guard let userProfile = getUserDetails(username: key) else {
            return false
        }
        if let storedPassword = userProfile["password"], storedPassword == passwordInput {
            setCurrentUser(key)
            return true
        }
        
        return false
    }
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
        let key = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return defaults.dictionary(forKey: "user_\(key)") as? [String: String]
    }
    
    func saveNewUser(username: String, profileData: [String: String]) {
        let key = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        defaults.set(profileData, forKey: "user_\(key)")
        setCurrentUser(key) 
    }
    
    func getAddresses(for username: String) -> [String] {
        let key = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return defaults.stringArray(forKey: "addresses_\(key)") ?? []
    }
    
    func saveAddresses(_ addresses: [String], for username: String) {
        let key = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        defaults.set(addresses, forKey: "addresses_\(key)")
    }
    
    func getOrderHistory(for username: String) -> [Order] {
        let key = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let data = defaults.data(forKey: "orders_\(key)") else { return [] }
        return (try? JSONDecoder().decode([Order].self, from: data)) ?? []
    }
    
    func saveOrderHistory(_ orders: [Order], for username: String) {
        let key = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if let data = try? JSONEncoder().encode(orders) {
            defaults.set(data, forKey: "orders_\(key)")
        }
    }
}
