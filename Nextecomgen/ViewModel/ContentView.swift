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
    @State private var storeProducts: [Product] = []
    @State private var shoppingCart: [Product] = []
    @State private var isInitialLoadComplete = false
    @State private var showDetail = false
    @State private var orderHistory: [AdminTransaction] = []
    @State private var currentUserOrderHistory: [OrderHistoryItem] = []
    @State var currentUserAddresses: [Address] = []
    @State var editingAddressID: UUID? = nil
    @State private var newAddressInput = ""
    @State private var isAddingAddress = false
    @State private var editingText = ""
    @State private var isLoading = false
    @State private var hasMoreData = true
    @State private var dummyJsonSkip = 0
    @State private var fakeStoreLimit = 10
    @State private var currentLimit = 10
    @FocusState private var isAddressFieldFocused: Bool
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
            self.currentUserOrderHistory.removeAll()

            self.loggedInFullName = ""
            self.loggedInEmail = ""

            self.selectedTab = .home
        }
    }
    private struct FakeStoreProductItem: Codable {
        let id: Int
        let title: String
        let price: Double
        let description: String
        let category: String
        let image: String
    }
    @State private var currentProductId = 1
    @State private var manuallyPaused = false

    func fetchRemoteProducts() async {
        guard await MainActor.run(body: {
            if isLoading || !hasMoreData { return false }
            isLoading = true
            return true
        }) else { return }
        
        print("🚀 SAFE DATA FETCH STARTED...")
        let maxProductId = 50
        let idRange = 1...maxProductId
        let concurrentBatchProducts = await withTaskGroup(of: [Product].self) { group in
            for productId in idRange {
                group.addTask {
                    var singlePairProducts: [Product] = []
                    
                    let fakeStoreUrlString = "https://fakestoreapi.com/products/\(productId)"
                    let dummyJsonUrlString = "https://dummyjson.com/products/\(productId)"
                    
                    guard let url1 = URL(string: dummyJsonUrlString),
                    let url2 = URL(string: fakeStoreUrlString) else { return [] }
                    var request1 = URLRequest(url: url1)
                    request1.setValue("application/json", forHTTPHeaderField: "Accept")
                    var request2 = URLRequest(url: url2)
                    request2.setValue("application/json", forHTTPHeaderField: "Accept")
                    do {
                        let (data1, response1) = try await URLSession.shared.data(for: request1)
                        if let http1 = response1 as? HTTPURLResponse, http1.statusCode == 200 {
                            let dummyProduct = try JSONDecoder().decode(Product.self, from: data1)
                            singlePairProducts.append(dummyProduct)
                        }
                    } catch {}
                    if productId <= 20 {
                        do {
                            let (data2, response2) = try await URLSession.shared.data(for: request2)
                            if let http2 = response2 as? HTTPURLResponse, http2.statusCode == 200 {
                                let fakeItem = try JSONDecoder().decode(FakeStoreProductItem.self, from: data2)
                                let mappedProduct = Product(
                                    id: fakeItem.id + 1000,
                                    name: fakeItem.title,
                                    imageName: fakeItem.image,
                                    images: [fakeItem.image],
                                    description: fakeItem.description,
                                    price: fakeItem.price,
                                    reviews: [],
                                    category: fakeItem.category.capitalized
                                )
                                singlePairProducts.append(mappedProduct)
                            }
                        } catch {}
                    }
                    
                    return singlePairProducts
                }
            }
            var accumulatedResults: [Product] = []
            for await taskResult in group {
                accumulatedResults.append(contentsOf: taskResult)
            }
            return accumulatedResults
        }
        await MainActor.run {
            defer {
                self.isLoading = false
                print("🔓 LOCK RELEASED: isLoading is now false.")
            }
            self.currentProductId = maxProductId + 1
            self.hasMoreData = false
            print("🏁 REACHED MAX: hasMoreData set to false.")
            
            if !concurrentBatchProducts.isEmpty {
                let sortedBatch = concurrentBatchProducts.sorted(by: { anisotropySort($0.id) < anisotropySort($1.id) })
                
                var newlyAddedCount = 0
                for product in sortedBatch {
                    if !self.storeProducts.contains(where: { $0.id == product.id }) {
                        self.storeProducts.append(product)
                        newlyAddedCount += 1
                    }
                }
                
                LocalDatabaseManager.shared.saveProducts(self.storeProducts)
                print("✅ SUCCESS: Added \(newlyAddedCount) products. Total Array Count: \(self.storeProducts.count)")
            } else {
                print("⚠️ EMPTY: No items returned from the APIs. Double check your data models.")
            }
        }
    }


    private func anisotropySort(_ id: Int) -> Int {
        return id >= 1000 ? id - 1000 : id
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
                                    shoppingCart: $shoppingCart,
                                    selectedTab: $selectedTab,
                                    searchText: $searchText,
                                    isShowing: $showDetail,
                                    isLoading: $isLoading,
                                    hasMoreData: $hasMoreData,
                                    onFetchNextBatch: {
                                        await fetchRemoteProducts()
                                    }
                                )
                                .tag(AppTab.home)
                                SearchView(
                                    selectedTab: $selectedTab,
                                    searchText: $searchText,
                                    storeProducts: $storeProducts,
                                    shoppingCart: $shoppingCart
                                )
                                .tag(AppTab.search)

                                CartView(
                                    selectedTab: $selectedTab,
                                    shoppingCart: $shoppingCart,
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
                                        shoppingCart = []
                                        currentUserOrderHistory = []
                                        currentUserAddresses = []
                                        loggedInFullName = ""
                                        loggedInEmail = ""
                                        selectedTab = .home
                                        isUserLoggedIn = false
                                    }
                                )




                                .tag(AppTab.profile)
                            }
                            .onChange(of: shoppingCart) { newValue in
                                guard isInitialLoadComplete else { return }
                                
                                guard let user = LocalDatabaseManager.shared.getCurrentUser(),
                                      !user.isEmpty else { return }
                                LocalDatabaseManager.shared.saveCart(newValue, for: user)
                            }

                            .padding(.bottom, 60)

                            CustomTabBar(
                                selectedTab: $selectedTab,
                                shoppingCart: $shoppingCart
                            )
                            .padding(.bottom, 8)
                        }
                    }
                }

            } else {

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

                    if isShowingSignUpScreen {

                        LocalDatabaseManager.shared.saveNewUser(
                            username: cleanEmail,
                            profileData: [
                                "fullName": cleanName,
                                "password": passwordInput,
                                "email": cleanEmail
                            ],
                            role: .customer
                        )

                        LocalDatabaseManager.shared.setCurrentUser(cleanEmail, role: .customer)

                        isUserLoggedIn = true
                        loggedInFullName = cleanName
                        loggedInEmail = cleanEmail

                        shoppingCart =
                            LocalDatabaseManager.shared.getCart(for: cleanEmail)

                    } else {

                        let success = LocalDatabaseManager.shared.authenticateUser(
                            username: cleanEmail,
                            passwordInput: passwordInput
                        )

                        if success {

                            let role = LocalDatabaseManager.shared.getCurrentUserRole()

                            let userData =
                                LocalDatabaseManager.shared.getUserDetails(username: cleanEmail)

                            let restored =
                                LocalDatabaseManager.shared.restoreUserData(username: cleanEmail)

                            isUserLoggedIn = true
                            loggedInFullName = userData["fullName"] ?? ""
                            loggedInEmail = cleanEmail

                            shoppingCart = restored.cart
                            currentUserOrderHistory = restored.orders
                            currentUserAddresses =
                                restored.addresses.map { Address(value: $0) }

                            if role == .admin {
                                orderHistory = LocalDatabaseManager.shared.getPendingTransactions()
                            } else {
                                selectedTab = .home
                            }

                        } else {
                            errorMessage = "Invalid credentials"
                        }
                    }
                }
            }
        }

        .task {
            restoreUserSessionOnLaunch()
            await fetchRemoteProducts()
            restoreCartOnLaunch()
            self.isInitialLoadComplete = true
        }
    }
    private func restoreCartOnLaunch() {
        guard let user = LocalDatabaseManager.shared.getCurrentUser(),
              !user.isEmpty else { return }

        let saved = LocalDatabaseManager.shared.getCart(for: user)
        shoppingCart = saved
    }

    private func restoreUserSessionOnLaunch() {

        guard let email = LocalDatabaseManager.shared.getCurrentUser() else {
            isUserLoggedIn = false
            return
        }

        let role = LocalDatabaseManager.shared.getCurrentUserRole()

        let userData =
            LocalDatabaseManager.shared.getUserDetails(username: email)

        let restored =
            LocalDatabaseManager.shared.restoreUserData(username: email)

        loggedInEmail = email
        loggedInFullName = userData["fullName"] ?? ""

        shoppingCart = restored.cart
        currentUserOrderHistory = restored.orders
        currentUserAddresses =
            restored.addresses.map { Address(value: $0) }

        if role == .admin {
            orderHistory = LocalDatabaseManager.shared.getPendingTransactions()
        } else {
            selectedTab = .home
        }

        isUserLoggedIn = true
    }
}
