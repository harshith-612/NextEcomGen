import SwiftUI
struct ContentView: View {
    @State private var selectedTab: AppTab = .home
    @State private var isUserLoggedIn = false
    @State private var isShowingSignUpScreen = false
    @State private var isShowingAdminSheet = false
    @State private var isShowingPaymentScreen = false
    @State private var isPaymentVerified = false
    
    @State private var usernameInput = ""
    @State private var passwordInput = ""
    @State private var confirmPasswordInput = ""
    @State private var fullNameInput = ""
    @State private var emailInput = ""
    @State private var errorMessage = ""
    @State private var searchText = ""
    
    @State private var loggedInFullName = ""
    @State private var loggedInEmail = ""
    
    @State private var storeProducts: [Product] = []
    @State private var shoppingCart: [Product] = []
    @State private var selectedProduct: Product?
    
    @State private var orderHistory: [AdminTransaction] = []
    @State private var currentUserOrderHistory: [Order] = []
    
    @State private var currentUserAddresses: [String] = []
    @State private var newAddressInput = ""
    @State private var isAddingAddress = false
    @State private var editingAddressIndex: Int?
    @State private var editingText = ""
    
    @State private var productName = ""
    @State private var productDescription = ""
    @State private var productPrice = ""
    @State private var productImage = ""
    
    @FocusState private var isAddressFieldFocused: Bool
    
    let merchantPhoneNumber = "8019324766"
    var grandTotalPriceInt: Float {
        shoppingCart.reduce(0) { total, product in
            let cleaned = product.price
                .replacingOccurrences(of: "₹", with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            return total + (Float(cleaned) ?? 0)
        }
    }
    func resetUserSession() {
        isUserLoggedIn = false
        
        usernameInput = ""
        passwordInput = ""
        confirmPasswordInput = ""
        fullNameInput = ""
        emailInput = ""
        errorMessage = ""
        searchText = ""
        
        shoppingCart.removeAll()
        currentUserAddresses.removeAll()
        currentUserOrderHistory.removeAll()
        
        loggedInFullName = ""
        loggedInEmail = ""
        
        selectedTab = .home
    }
    func clearAdminInputFields() {
        productName = ""
        productDescription = ""
        productPrice = ""
        productImage = ""
    }
    func fetchRemoteProducts() async {
        
        if let cachedItems = LocalDatabaseManager.shared.loadProducts(),
           !cachedItems.isEmpty {
            
            await MainActor.run {
                self.storeProducts = cachedItems
            }
            
            return
        }
        
        guard let url = URL(string: "https://dummyjson.com/products") else {
            print("Invalid URL")
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                print("Server error")
                return
            }
            
            let decodedRoot = try JSONDecoder().decode(DummyJSONRoot.self, from: data)
            
            await MainActor.run {
                self.storeProducts = decodedRoot.products
                LocalDatabaseManager.shared.saveProducts(decodedRoot.products)
            }
            
        } catch {
            print("Fetch failed: \(error.localizedDescription)")
        }
    }
    var body: some View {
        Group {
            
            if isUserLoggedIn {
                
                NavigationStack {
                    
                    VStack(spacing: 0) {
                        
                        if loggedInFullName != "Store Administrator" {
                            
                            HStack {
                                
                                Text("NextEcomGEN")
                                    .font(.system(.title, design: .rounded))
                                    .fontWeight(.heavy)
                                    .foregroundColor(.green)
                                
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 10)
                            .padding(.bottom, 8)
                            .background(Color(.systemBackground))
                        }
                        
                        TabView(selection: $selectedTab) {
                             
                            HomeView(
                                storeProducts: $storeProducts,
                                shoppingCart: $shoppingCart,
                                selectedTab: $selectedTab,
                                isShowingPaymentScreen: $isShowingPaymentScreen,
                                orderHistory: $orderHistory,
                                usernameInput: usernameInput,
                                selectedProduct: $selectedProduct,
                                fullNameInput: $fullNameInput
                            )
                            .tag(AppTab.home)
                            .background(Color(.systemGray6))
                            Group {
                                if let product = selectedProduct {
                                    HomeProductDetailSheet(
                                        product: product,
                                        shoppingCart: $shoppingCart,
                                        isShowingPaymentScreen: $isShowingPaymentScreen,
                                        orderHistory: $orderHistory,
                                        usernameInput: usernameInput,
                                        fullNameInput: $fullNameInput,
                                        onBackAction: {
                                            self.selectedProduct = nil
                                            self.selectedTab = .home
                                        }
                                    )
                                } else {
                                    SearchView(
                                        selectedTab: $selectedTab,
                                        searchText: $searchText,
                                        storeProducts: $storeProducts,
                                        shoppingCart: $shoppingCart
                                    )
                                }
                            }
                            .tag(AppTab.search)
                            .background(Color(.systemGray6))
                            
                            
                            CartView(
                                selectedTab: $selectedTab,
                                shoppingCart: $shoppingCart,
                                isShowingPaymentScreen: $isShowingPaymentScreen,
                                orderHistory: $orderHistory,
                                fullNameInput: $fullNameInput,
                                usernameInput: usernameInput
                            )
                            .tag(AppTab.cart)
                            .background(Color(.systemGray6))
                            
                            
                            ProfileView(
                                selectedTab: $selectedTab,
                                usernameInput: $usernameInput,
                                loggedInFullName: $loggedInFullName,
                                loggedInEmail: $loggedInEmail,
                                currentUserOrderHistory: $currentUserOrderHistory,
                                currentUserAddresses: $currentUserAddresses,
                                isAddingAddress: $isAddingAddress,
                                newAddressInput: $newAddressInput,
                                editingAddressIndex: $editingAddressIndex,
                                editingText: $editingText,
                                isAddressFieldFocused: $isAddressFieldFocused,
                                onLogOut: {
                                    withAnimation {
                                        resetUserSession()
                                    }
                                }
                            )
                            .tag(AppTab.profile)
                            .background(Color(.systemGray6))
                            
                            
                            AdminSheetView(
                                fullNameInput: $productName,
                                emailInput: $productDescription,
                                passwordInput: $productPrice,
                                confirmPasswordInput: $productImage,
                                isShowingAdminSheet: $isShowingAdminSheet,
                                storeProducts: $storeProducts,
                                orderHistory: $orderHistory,
                                currentUserOrderHistory: $currentUserOrderHistory,
                                onSaveProduct: {
                                    
                                    let newProduct = Product(
                                        id: Int.random(in: 1000...99999),
                                        name: productName,
                                        imageName: productImage.isEmpty ? "1" : productImage,
                                        description: productDescription,
                                        price: productPrice.contains("₹")
                                        ? productPrice
                                        : "₹\(productPrice)",
                                        reviews: [],
                                        category: "general"
                                    )
                                    
                                    storeProducts.append(newProduct)
                                    
                                    LocalDatabaseManager.shared.saveProducts(storeProducts)
                                    
                                    clearAdminInputFields()
                                },
                                onLogOut: {
                                    resetUserSession()
                                }
                            )
                            .tag(AppTab.admin)
                            .background(Color(.systemGray6))
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        
                        
                        if loggedInFullName != "Store Administrator" {
                            
                            CustomTabBar(
                                selectedTab: $selectedTab,
                                shoppingCart: $shoppingCart,
                                isAdminUser: false
                            )
                        }
                    }
                }
                
            } else {
                
                AuthView(
                    isShowingSignUpScreen: $isShowingSignUpScreen,
                    fullNameInput: $fullNameInput,
                    emailInput: $emailInput,
                    usernameInput: $usernameInput,
                    passwordInput: $passwordInput,
                    confirmPasswordInput: $confirmPasswordInput,
                    errorMessage: $errorMessage,
                    
                    onAuthenticate: {
                        
                        if isShowingSignUpScreen {
                            
                            
                            let cleanEmail = emailInput
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                                .lowercased()
                            
                            let cleanName = fullNameInput
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                            
                            if cleanEmail.isEmpty || cleanName.isEmpty || passwordInput.isEmpty {
                                errorMessage = "Fields empty!"
                                return
                            }
                            
                            if passwordInput != confirmPasswordInput {
                                errorMessage = "Passwords do not match!"
                                return
                            }
                            
                            if LocalDatabaseManager.shared.getUserDetails(username: cleanEmail) != nil {
                                errorMessage = "Email already registered!"
                                return
                            }
                            
                            let profileData: [String: String] = [
                                "fullName": cleanName,
                                "email": cleanEmail,
                                "password": passwordInput
                            ]
                            
                            LocalDatabaseManager.shared.saveNewUser(
                                username: cleanEmail,
                                profileData: profileData
                            )
                            
                            errorMessage = ""
                            loggedInFullName = cleanName
                            loggedInEmail = cleanEmail
                            currentUserAddresses = []
                            currentUserOrderHistory = []
                            isUserLoggedIn = true
                            
                        } else {
                            
                            
                            let cleanLoginEmail = emailInput
                                .trimmingCharacters(in: .whitespacesAndNewlines)
                                .lowercased()
                            
                            if cleanLoginEmail.isEmpty || passwordInput.isEmpty {
                                errorMessage = "Fields empty!"
                                return
                            }
                            
                            
                            if cleanLoginEmail == "admin@nextecomgen.com"
                                && passwordInput == "admin123" {
                                
                                errorMessage = ""
                                loggedInFullName = "Store Administrator"
                                loggedInEmail = cleanLoginEmail
                                selectedTab = .admin
                                isUserLoggedIn = true
                                return
                            }
                            
                            if let accountMap = LocalDatabaseManager.shared.getUserDetails(username: cleanLoginEmail) {
                                
                                let savedPassword = accountMap["password"] ?? ""
                                
                                if savedPassword == passwordInput {
                                    
                                    errorMessage = ""
                                    
                                    loggedInFullName = accountMap["fullName"] ?? "Customer Profile"
                                    
                                    loggedInEmail = accountMap["email"] ?? cleanLoginEmail
                                    
                                    currentUserAddresses = LocalDatabaseManager.shared.getAddresses(for: cleanLoginEmail)
                                    
                                    currentUserOrderHistory = LocalDatabaseManager.shared.getOrderHistory(for: cleanLoginEmail)
                                    
                                    selectedTab = .home
                                    isUserLoggedIn = true
                                    
                                } else {
                                    errorMessage = "Invalid email or password!"
                                }
                                
                            } else {
                                errorMessage = "Invalid email or password!"
                            }
                        }
                    }
                )
            }
        }
        .task {
            await fetchRemoteProducts()
        }
    }
}


