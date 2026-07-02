import SwiftUI
struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var isUserLoggedIn =
    LocalDatabaseManager.shared.getCurrentUser() != nil
    @State private var isShowingSignUpScreen = false
    @State private var isShowingAdminSheet = false
    @State private var isShowingPaymentScreen = false
    @State private var usernameInput = ""
    @State private var passwordInput = ""
    @State private var confirmPasswordInput = ""
    @State private var fullNameInput = ""
    @State private var emailInput = ""
    @State private var errorMessage = ""
    @State private var searchText = ""
    @State private var loggedInFullName = ""
    @State private var loggedInEmail = ""
    @State private var globalCartItems: [CartItem] = []
    @State private var storeProducts: [Product] = []
    @State private var shoppingCart: [Product] = []
    @State private var isInitialLoadComplete = false
    @State private var showDetail = false
    @State private var orderHistory: [AdminTransaction] = []
    @State var currentUserAddresses: [Address] = []
    @State private var editingAddressID: String?
    @EnvironmentObject var network: NetworkMonitor
    @State private var newAddressInput = ""
    @State private var isAddingAddress = false
    @State private var editingText = ""
    @State var isLoading = false
    @State var hasMoreData = true
    @State var currentPage = 1
    @FocusState private var isAddressFieldFocused: Bool
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    @State private var globalCartTotal: Double = 0.0
    @State private var isShowing: Bool = false
    
    
    init() {
        UITabBar.appearance().isHidden = true
    }
    private var cleanEmail: String {
        emailInput
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
    var grandTotalPriceInt: Double {
        shoppingCart.reduce(0) { total, product in
            let cleaned = String(product.price)
                .replacingOccurrences(of: "₹", with: "")
                .replacingOccurrences(of: ",", with: "")
            return total + (Double(cleaned) ?? 0)
        }
    }
    func resetUserSession() {
        isAddressFieldFocused = false
        if let user = LocalDatabaseManager.shared.getCurrentUser() {
            LocalDatabaseManager.shared.clearCart(for: user)
        }
        LocalDatabaseManager.shared.logout()
        DispatchQueue.main.async {
            self.isUserLoggedIn = false
            self.usernameInput = ""
            self.passwordInput = ""
            self.confirmPasswordInput = ""
            self.fullNameInput = ""
            self.emailInput = ""
            self.errorMessage = ""
            self.searchText = ""
            self.shoppingCart.removeAll()
            self.currentUserAddresses.removeAll()
            self.loggedInFullName = ""
            self.loggedInEmail = ""
            self.selectedTab = .home
        }
    }
    @State private var currentProductId = 1
    @State private var manuallyPaused = false
    private let pageSize = 5
    private let maxProducts = 20
    
    func fetchRemoteProducts() async {
        guard await MainActor.run(body: {
            if isLoading || !hasMoreData { return false }
            isLoading = true
            return true
        }) else { return }
        if currentPage < 1 { currentPage = 1 }
        let startId = ((currentPage - 1) * pageSize) + 1
        let endId = min(startId + pageSize - 1, maxProducts)
        guard startId > 0 && startId <= endId else {
            await MainActor.run {
                hasMoreData = false
                isLoading = false
            }
            return
        }
        
        print("FETCHING PAGE \(currentPage): IDs \(startId)-\(endId)")
        let idsToFetch = Array(startId...endId)
        let batchResults = await withTaskGroup(of: Product?.self) { group in
            for id in idsToFetch {
                group.addTask {
                    return await self.fetchSingleProduct(id: id)
                }
            }
            
            var collected: [Product] = []
            for await productOpt in group {
                if let product = productOpt {
                    collected.append(product)
                }
            }
            return collected
        }
        let sortedBatch = batchResults.sorted(by: { $0.id < $1.id })
        
        await MainActor.run {
            var currentIds = Set(self.storeProducts.map { $0.id })
            var uniqueNewProducts: [Product] = []
            
            for product in sortedBatch {
                if !currentIds.contains(product.id) {
                    currentIds.insert(product.id)
                    uniqueNewProducts.append(product)
                }
            }
            self.storeProducts.append(contentsOf: uniqueNewProducts)
            LocalDatabaseManager.shared.saveProducts(self.storeProducts)
            self.currentPage += 1
            self.isLoading = false
            
            if endId >= maxProducts {
                self.hasMoreData = false
                self.currentProductId = maxProducts + 1
            }
            
            print("Page \(currentPage - 1) loaded successfully. Global Total:", self.storeProducts.count)
        }
    }
    private func fetchSingleProduct(id: Int) async -> Product? {
        let urlString = "http://127.0.0.1:8000/products/\(id)"
        guard let url = URL(string: urlString) else { return nil }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                return nil
            }
            return try JSONDecoder().decode(Product.self, from: data)
        } catch {
            print("FastAPI fetch failed for Product ID \(id):", error.localizedDescription)
            return nil
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if isUserLoggedIn {
                if LocalDatabaseManager.shared.getCurrentUserRole() == .admin {
                    NavigationStack {
                        Text("Admin Console Workstation")
                            .font(.headline)
                            .padding()
                    }
                } else {
                    NavigationStack {
                        ZStack(alignment: .bottom) {
                            TabView(selection: $selectedTab) {
                                HomeView(
                                    storeProducts: $storeProducts,
                                    shoppingCart: $globalCartItems,
                                    selectedTab: $selectedTab,
                                    searchText: $searchText,
                                    isShowing: $showDetail,
                                    isLoading: $isLoading,
                                    hasMoreData: $hasMoreData,
                                    onFetchNextBatch: {
                                        Task {
                                            await self.fetchRemoteProducts()
                                        }
                                    }
                                )
                                .tag(AppTab.home)
                                .environmentObject(network)
                                SearchView(
                                    selectedTab: $selectedTab,
                                    searchText: $searchText,
                                    storeProducts: $storeProducts,
                                    shoppingCart: $shoppingCart
                                )
                                .tag(AppTab.search)
                                CartView(
                                    cartItems: $globalCartItems,
                                    cartTotal: $globalCartTotal,
                                    selectedTab: $selectedTab,
                                    isShowingPaymentScreen: $isShowingPaymentScreen,
                                    orderHistory: $orderHistory,
                                    fullNameInput: $fullNameInput,
                                    usernameInput: loggedInEmail
                                )
                                .tag(AppTab.cart)
                                ProfileView(
                                    selectedTab: $selectedTab,
                                    savedUsername: LocalDatabaseManager.shared.getCurrentUser() ?? "",
                                    isAddingAddress: $isAddingAddress,
                                    newAddressInput: $newAddressInput,
                                    editingAddressID: $editingAddressID,
                                    editingText: $editingText,
                                    onLogOut: {
                                        LocalDatabaseManager.shared.clearCurrentUserSession()
                                        UserDefaults.standard.set(false, forKey: "isLoggedIn")
                                        
                                        fullNameInput = ""
                                        emailInput = ""
                                        passwordInput = ""
                                        confirmPasswordInput = ""
                                        errorMessage = ""
                                        
                                        shoppingCart.removeAll()
                                        
                                        loggedInFullName = ""
                                        loggedInEmail = ""
                                        
                                        selectedTab = .home
                                        isUserLoggedIn = false
                                    }
                                )
                                .tag(AppTab.profile)
                            }
                            .onChange(of: shoppingCart) {_, newValue in
                                guard isInitialLoadComplete else { return }
                                guard let user = LocalDatabaseManager.shared.getCurrentUser(),
                                      !user.isEmpty else { return }
                                LocalDatabaseManager.shared.saveCart(newValue, for: user)
                            }
                            .padding(.bottom, 60)
                            CustomTabBar(
                                selectedTab: $selectedTab,
                                shoppingCart: $globalCartItems,
                                badgeCount: globalCartItems.reduce(0) { $0 + $1.quantity }
                            )
                            .padding(.bottom, 8)
                        }
                    }
                }
            }
            else {
                AuthView(
                    isShowingSignUpScreen: $isShowingSignUpScreen,
                    fullNameInput: $fullNameInput,
                    emailInput: $emailInput,
                    passwordInput: $passwordInput,
                    confirmPasswordInput: $confirmPasswordInput,
                    errorMessage: $errorMessage
                ) {
                    let cleanEmail = emailInput
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .lowercased()
                    
                    let cleanName = fullNameInput
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    if cleanEmail.isEmpty || passwordInput.isEmpty || (isShowingSignUpScreen && cleanName.isEmpty) {
                        alertTitle = "Missing Information"
                        alertMessage = "Please fill out all required fields."
                        showAlert = true
                        return
                    }
                    
                    if isShowingSignUpScreen {
                        struct RegisterRequest: Codable {
                            let email: String
                            let fullName: String
                            let role: String
                            let password: String
                        }
                        
                        Task {
                            
                            let body = RegisterRequest(
                                email: cleanEmail,
                                fullName: cleanName,
                                role: "user",
                                password: passwordInput
                            )
                            
                            guard let url = URL(string: "http://127.0.0.1:8000/users/") else {
                                return
                            }
                            
                            var request = URLRequest(url: url)
                            request.httpMethod = "POST"
                            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                            request.setValue("application/json", forHTTPHeaderField: "Accept")
                            
                            request.httpBody = try JSONEncoder().encode(body)
                            
                            do {
                                let (data, response) = try await URLSession.shared.data(for: request)
                                
                                guard let http = response as? HTTPURLResponse else {
                                    return
                                }
                                
                                print(http.statusCode)
                                print(String(data: data, encoding: .utf8) ?? "")
                                
                                if http.statusCode == 201 {
                                    
                                    DispatchQueue.main.async {
                                        alertTitle = "Account Created"
                                        alertMessage = "Your account has been created successfully. Please log in."
                                        showAlert = true
                                    }
                                    
                                } else {
                                    
                                    print(String(data: data, encoding: .utf8)!)
                                    
                                }
                                
                            } catch {
                                print(error)
                            }
                        }
                        
                    } else {
                        
                        Task {
                            do {
                                struct LoginRequest: Codable {
                                    let email: String
                                    let password: String
                                }
                                
                                let cleanEmail = emailInput
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                    .lowercased()
                                
                                let cleanPassword = passwordInput
                                    .trimmingCharacters(in: .whitespacesAndNewlines)
                                
                                let body = LoginRequest(
                                    email: cleanEmail,
                                    password: cleanPassword
                                )
                                
                                guard let url = URL(string: "http://127.0.0.1:8000/users/login") else {
                                    return
                                }
                                
                                var request = URLRequest(url: url)
                                request.httpMethod = "POST"
                                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                                request.setValue("application/json", forHTTPHeaderField: "Accept")
                                
                                request.httpBody = try JSONEncoder().encode(body)
                                
                                print("LOGIN REQUEST →", cleanEmail)
                                
                                let (data, response) = try await URLSession.shared.data(for: request)
                                
                                guard let httpResponse = response as? HTTPURLResponse else {
                                    throw URLError(.badServerResponse)
                                }
                                
                                print("Status Code:", httpResponse.statusCode)
                                print("Response:", String(data: data, encoding: .utf8) ?? "")
                                
                                if httpResponse.statusCode == 200 {
                                    
                                    let result = try JSONDecoder().decode([String: String].self, from: data)
                                    
                                    guard let token = result["access_token"], !token.isEmpty else {
                                        throw URLError(.userAuthenticationRequired)
                                    }
                                    
                                    LocalDatabaseManager.shared.setAuthToken(token)
                                    LocalDatabaseManager.shared.setCurrentUser(cleanEmail, role: .customer)
                                    
                                    let userData = LocalDatabaseManager.shared.getUserDetails(username: cleanEmail)
                                    let userName = userData["fullName"] ?? "User"
                                    
                                    DispatchQueue.main.async {
                                        alertTitle = "Login Successful"
                                        alertMessage = "Welcome back, \(userName)!"
                                        showAlert = true
                                        
                                        loggedInFullName = userName
                                        loggedInEmail = cleanEmail
                                        isUserLoggedIn = true
                                        selectedTab = .home
                                    }
                                    
                                } else {
                                    _ = parseErrorMessage(data)
                                    
                                    DispatchQueue.main.async {
                                        _ = parseErrorMessage(data)
                                        alertTitle = "Login Failed"
                                        alertMessage = errorMessage
                                        showAlert = true
                                    }
                                }
                                
                            } catch {
                                DispatchQueue.main.async {
                                    errorMessage = "Network error"
                                    alertTitle = "Login Failed"
                                    alertMessage = error.localizedDescription
                                    showAlert = true
                                }
                            }
                        }
                    }
                }
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if alertTitle == "Account Created" {
                    isShowingSignUpScreen = false
                    fullNameInput = ""
                    passwordInput = ""
                    confirmPasswordInput = ""
                    errorMessage = ""
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    private func restoreCartOnLaunch() {
        guard let user = LocalDatabaseManager.shared.getCurrentUser(),
              !user.isEmpty else { return }
        let saved = LocalDatabaseManager.shared.getCart(for: user)
        shoppingCart = saved
    }
    private func cleanErrorMessage(_ data: Data) -> String {
        return parseErrorMessage(data)
    }
    
}
