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
        guard context != nil else { return }
        
        
        saveContext()
    }
    
    func authenticateUser(username: String, passwordInput: String) -> Bool {
        let k = normalize(username)
        if k == "admin@nextecomgen.com" && passwordInput == "admin123" {
            setCurrentUser(k, role: .admin)
            return true
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
}
