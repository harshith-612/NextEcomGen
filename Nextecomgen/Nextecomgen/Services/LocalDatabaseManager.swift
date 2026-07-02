import Foundation
import SwiftData
@MainActor
final class LocalDatabaseManager {
    static let shared = LocalDatabaseManager()
    private let tokenKey = "access_token"
    
    func setAuthToken(_ token: String) {
        UserDefaults.standard.set(token, forKey: tokenKey)
    }
    
    func getAuthToken() -> String? {
        UserDefaults.standard.string(forKey: tokenKey)
    }
    var container: ModelContainer?
    
    var context: ModelContext? {
        container?.mainContext
    }
    
    private init() {
        do {
            container = try ModelContainer(
                for:
                    UserEntity.self,
                CartItemEntity.self,
                AddressEntity.self,
                OrderEntity.self,
                OrderItemEntity.self
            )
            
        } catch {
            
            print("Migration failed: \(error)")
            
            let url = URL.applicationSupportDirectory
                .appending(path: "default.store")
            
            try? FileManager.default.removeItem(at: url)
            
            do {
                container = try ModelContainer(
                    for:
                        UserEntity.self,
                    CartItemEntity.self,
                    AddressEntity.self,
                    OrderEntity.self,
                    OrderItemEntity.self
                )
                
            } catch {
                print("Still failed: \(error)")
            }
        }
    }
    
    
    func saveContext() {
        guard let context = context, context.hasChanges else { return }
        do {
            try context.save()
        } catch {
        }
    }
    
    func clearCurrentUserSession() {
        let keysToRemove = [
            userKey,
            roleKey,
            "isLoggedIn",
            "access_token"
        ]
        
        let defaults = UserDefaults.standard
        keysToRemove.forEach { defaults.removeObject(forKey: $0) }
        
        cachedProducts.removeAll()
        pendingTransactions.removeAll()
    }
    
    private func normalize(_ username: String) -> String {
        username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    private let userKey = "current_user"
    private let roleKey = "current_role"
    
    func setCurrentUser(_ username: String, role: UserRole) {
        let k = normalize(username)
        UserDefaults.standard.set(k, forKey: userKey)
        UserDefaults.standard.set(role.rawValue, forKey: roleKey)
        UserDefaults.standard.set(true, forKey: "isLoggedIn")
    }
    
    private var cachedProducts: [Product] = []
    
    func saveProducts(_ products: [Product]) {
        guard let context = context else { return }
        
        for p in products {
            let entity = ProductEntity(
                id: p.id,
                name: p.name,
                imageName: p.imageName,
                productDescription: p.productDescription,
                price: p.price,
                category: p.category
            )
            context.insert(entity)
        }
        
        saveContext()
    }
    
    func loadProducts() -> [Product] {
        guard let context = context else { return [] }
        
        let descriptor = FetchDescriptor<ProductEntity>()
        
        do {
            let entities = try context.fetch(descriptor)
            return entities.map {
                Product(
                    id: $0.id,
                    name: $0.name,
                    imageName: $0.imageName,
                    productDescription: $0.productDescription,
                    price: $0.price,
                    category: $0.category
                )
            }
        } catch {
            print("Fetch error:", error)
            return []
        }
    }
    
    func authenticateUser(username: String, passwordInput: String) -> Bool {
        let k = normalize(username)
        if k == "admin@nextecomgen.com" && passwordInput == "admin123" {
            setCurrentUser(k, role: .admin)
            _ = ensureUserExists(username: k)
            return true
        }
        guard let user = getUser(username: k), user.password == passwordInput else { return false }
        setCurrentUser(k, role: .customer)
        return true
    }
    
    private var pendingTransactions: [AdminTransaction] = []
    
    func getPendingTransactions() -> [AdminTransaction] {
        return pendingTransactions
    }
    
    func savePendingTransactions(_ transactions: [AdminTransaction]) {
        pendingTransactions = transactions
    }
    
    func getCurrentUser() -> String? {
        UserDefaults.standard.string(forKey: userKey)
    }
    
    func getCurrentUserRole() -> UserRole {
        let raw = UserDefaults.standard.string(forKey: roleKey) ?? "customer"
        return UserRole(rawValue: raw) ?? .customer
    }
    
    func logout() {
        clearCurrentUserSession()
    }
    
    func ensureUserExists(username: String) -> UserEntity {
        let cleanKey = normalize(username)
        
        if let existing = getUser(username: cleanKey) {
            return existing
        }
        
        guard let context = context else {
            return UserEntity()
        }
        
        let user = UserEntity()
        user.username = cleanKey
        user.email = cleanKey
        user.fullName = cleanKey.components(separatedBy: "@").first?.capitalized ?? "User"
        user.role = "customer"
        
        context.insert(user)
        saveContext()
        
        return user
    }
    
    func getUser(username: String) -> UserEntity? {
        
        let cleanKey = normalize(username)
        
        guard let context = context else {
            return nil
        }
        
        let descriptor = FetchDescriptor<UserEntity>(
            predicate: #Predicate<UserEntity> {
                $0.username == cleanKey
            }
        )
        
        do {
            return try context.fetch(descriptor).first
        } catch {
            print("Fetch error: \(error)")
            return nil
        }
    }
    
    
    func saveCart(_ items: [Product], for username: String) {
        let user = ensureUserExists(username: normalize(username))
        guard let context = context else { return }
        
        user.cartItems.removeAll()
        
        for p in items {
            let item = CartItemEntity()
            item.id = Int64(p.id)
            item.name = p.name
            item.imageName = p.imageName
            item.productDescription = p.productDescription
            item.price = p.price
            item.category = p.category
            item.user = user
            
            user.cartItems.append(item)
            context.insert(item)
        }
        
        saveContext()
    }
    
    func saveAddresses(_ addresses: [String], for username: String) {
        let user = ensureUserExists(username: normalize(username))
        guard let context = context else { return }
        
        user.addresses.removeAll()
        
        for value in addresses {
            let addr = AddressEntity()
            addr.id = UUID()
            addr.addressValue = value
            addr.user = user
            
            user.addresses.append(addr)
            context.insert(addr)
        }
        
        saveContext()
    }
    
    
    func saveNewUser(username: String, profileData: [String: String], role: UserRole) {
        let k = normalize(username)
        let user = ensureUserExists(username: k)
        user.fullName = profileData["fullName"] ?? k.components(separatedBy: "@").first?.capitalized ?? "User Account"
        user.email = profileData["email"] ?? k
        user.password = profileData["password"]
        user.role = role.rawValue
        saveContext()
    }
    
    func getUserDetails(username: String) -> [String: String] {
        let k = normalize(username)
        guard !k.isEmpty else { return [:] }
        let user = ensureUserExists(username: k)
        let emailValue = (user.email ?? "").isEmpty ? k : user.email!
        let nameValue = (user.fullName ?? "").isEmpty ? k.components(separatedBy: "@").first?.capitalized ?? "User Account" : user.fullName!
        
        return [
            "fullName": nameValue,
            "email": emailValue,
            "username": user.username ?? k
        ]
    }
    
    func updateUserProfile(name: String, email: String, for username: String) {
        let k = normalize(username)
        guard !k.isEmpty else { return }
        let user = ensureUserExists(username: k)
        user.fullName = name
        user.email = email
        saveContext()
    }
    
    func getCart(for username: String) -> [Product] {
        let k = normalize(username)
        guard !k.isEmpty else { return [] }
        let user = ensureUserExists(username: k)
        let items = user.cartItems
        return items.map {
            Product(
                id: Int($0.id ?? 0),
                name: $0.name ?? "",
                imageName: $0.imageName ?? "",
                productDescription: $0.productDescription ?? "",
                price: $0.price ?? 0.0,
                category: $0.category ?? ""
            )
        }
    }
    
    func clearCart(for username: String) {
        let k = normalize(username)
        guard !k.isEmpty, let context = context else { return }
        let user = ensureUserExists(username: k)
        user.cartItems.forEach { context.delete($0) }
        user.cartItems = []
        saveContext()
    }
    
    func getAddresses(for username: String) -> [String] {
        let k = normalize(username)
        guard !k.isEmpty else { return [] }
        let user = ensureUserExists(username: k)
        let addresses = user.addresses
        return addresses.compactMap { $0.addressValue }
    }
}
