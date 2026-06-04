import Foundation
import CoreData
final class LocalDatabaseManager {
    static let shared = LocalDatabaseManager()
    private init() {}
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "Data")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData error: \(error)")
            }
        }
        return container
    }()
    var context: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    func saveContext() {
        guard context.hasChanges else { return }
        do {
            try context.save()
            print("💾 [CoreData] Successfully saved and committed context changes to disk.")
        } catch {
            print("❌ [CoreData Error] Failed to write changes to storage context: \(error)")
        }
    }
    func clearCurrentUserSession() {
        UserDefaults.standard.removeObject(forKey: userKey)
        UserDefaults.standard.removeObject(forKey: roleKey)
        UserDefaults.standard.removeObject(forKey: "isLoggedIn")
        self.cachedProducts = []
        self.pendingTransactions = []
        print("User database session cleared and synced successfully.")
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
        self.cachedProducts = products
    }
    func loadProducts() -> [Product] {
        return self.cachedProducts
    }
    func authenticateUser(username: String, passwordInput: String) -> Bool {
        let k = normalize(username)
        if k == "admin@nextecomgen.com" && passwordInput == "admin123" {
            setCurrentUser(k, role: .admin)
            _ = ensureUserExists(username: k)
            return true
        }
        guard let user = getUser(username: k),
              user.password == passwordInput else {
            return false
        }
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
        let user = UserEntity(context: context)
        user.username = cleanKey
        user.fullName = cleanKey.components(separatedBy: "@").first?.capitalized ?? "User Account"
        user.email = cleanKey
        user.role = "customer"
        saveContext()
        return user
    }
    func getUser(username: String) -> UserEntity? {
        let cleanKey = normalize(username)
        guard !cleanKey.isEmpty else { return nil }
        let req: NSFetchRequest<UserEntity> = UserEntity.fetchRequest()
        req.predicate = NSPredicate(format: "username ==[c] %@", cleanKey)
        req.fetchLimit = 1
        return (try? context.fetch(req))?.first
    }
    func saveOrderHistory(_ orders: [OrderHistoryItem], for username: String) {
        let k = normalize(username)
        guard !k.isEmpty else { return }
        let key = "orders_history_\(k)"
        if let encodedData = try? JSONEncoder().encode(orders) {
            UserDefaults.standard.set(encodedData, forKey: key)
            print("💾 SUCCESSFULLY SAVED \(orders.count) ORDERS PERSISTENTLY FOR: '\(k)'")
        } else {
            print("❌ Failed to encode order history model structures.")
        }
    }
    func getOrderHistory(for username: String) -> [OrderHistoryItem] {
        let k = normalize(username)
        guard !k.isEmpty else { return [] }
        let key = "orders_history_\(k)"
        guard let rawData = UserDefaults.standard.data(forKey: key) else {
            print("ℹ No historical records found on disk for user account: '\(k)'")
            return []
        }
        if let decodedOrders = try? JSONDecoder().decode([OrderHistoryItem].self, from: rawData) {
            print("📖 RETRIEVED \(decodedOrders.count) ORDERS SUCCESSFULLY FOR: '\(k)'")
            return decodedOrders
        }
        return []
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
    func saveCart(_ items: [Product], for username: String) {
        let k = normalize(username)
        guard !k.isEmpty else { return }
        let user = ensureUserExists(username: k)
        if let existing = user.cartItems as? Set<CartItemEntity> {
            existing.forEach { context.delete($0) }
        }
        for p in items {
            let item = CartItemEntity(context: context)
            item.id = Int64(p.id)
            item.name = p.name
            item.imageName = p.imageName
            item.productDescription = p.description
            item.price = p.price
            item.category = p.category
            item.user = user
        }
        saveContext()
    }
    func getCart(for username: String) -> [Product] {
        let k = normalize(username)
        guard !k.isEmpty else { return [] }
        let user = ensureUserExists(username: k)
        guard let items = user.cartItems as? Set<CartItemEntity> else { return [] }
        return items.map {
            Product(id: Int($0.id), name: $0.name ?? "", imageName: $0.imageName ?? "", description: $0.productDescription ?? "", price: $0.price, reviews: [], category: $0.category ?? "")
        }
    }
    func clearCart(for username: String) {
        let k = normalize(username)
        guard !k.isEmpty else { return }
        let user = ensureUserExists(username: k)
        if let items = user.cartItems as? Set<CartItemEntity> {
            items.forEach { context.delete($0) }
        }
        saveContext()
    }
    func saveAddresses(_ addresses: [String], for username: String) {
        let k = normalize(username)
        guard !k.isEmpty else { return }
        let user = ensureUserExists(username: k)
        if let existing = user.addresses as? Set<AddressEntity> {
            existing.forEach { context.delete($0) }
        }
        for value in addresses {
            let addr = AddressEntity(context: context)
            addr.id = UUID()
            addr.addressValue = value
            addr.user = user
        }
        saveContext()
    }
    func getAddresses(for username: String) -> [String] {
        let k = normalize(username)
        guard !k.isEmpty else { return [] }
        
        let user = ensureUserExists(username: k)
        guard let addresses = user.addresses as? Set<AddressEntity> else { return [] }
        return addresses.compactMap { $0.addressValue }
    }
    func restoreUserData(username: String) -> (cart: [Product], orders: [OrderHistoryItem], addresses: [String]) {
        let k = normalize(username)
        guard !k.isEmpty else { return (cart: [], orders: [], addresses: []) }
        
        return (
            cart: getCart(for: k),
            orders: getOrderHistory(for: k),
            addresses: getAddresses(for: k)
        )
    }
}
