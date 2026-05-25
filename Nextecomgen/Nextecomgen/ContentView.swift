import SwiftUI

struct ContentView: View {

    @State private var selectedTab: AppTab = .home
    @State private var isUserLoggedIn = false
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
    var grandTotalPriceInt: Double {
        shoppingCart.reduce(0) { total, product in
            let cleaned = String(product.price)
                .replacingOccurrences(of: "₹", with: "")
                .replacingOccurrences(of: ",", with: "")
            return total + (Double(cleaned) ?? 0)
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
        guard let url = URL(string: "https://dummyjson.com/products") else { return }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            if let http = response as? HTTPURLResponse {
                print("HTTP Status:", http.statusCode)
            }

            let decoded = try JSONDecoder().decode(DummyJSONRoot.self, from: data)

            await MainActor.run {
                self.storeProducts = decoded.products
                LocalDatabaseManager.shared.saveProducts(decoded.products)
                print("Loaded products:", decoded.products.count)
            }

        } catch {
            print("Fetch error:", error)
        }
    }
    var body: some View {
        VStack {
            if isUserLoggedIn {

                NavigationStack {
                    VStack {

                        Text("NextEcomGEN")
                            .font(.largeTitle.bold())
                            .foregroundColor(.deepEmerald)
                            .padding()

                        TabView(selection: $selectedTab) {

                            HomeView(
                                storeProducts: $storeProducts,
                                shoppingCart: $shoppingCart,
                                selectedTab: $selectedTab,
                                searchText: $searchText
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
                                usernameInput: usernameInput
                            )
                            .tag(AppTab.cart)

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
                                onLogOut: { resetUserSession() }
                            )
                            .tag(AppTab.profile)

                            AdminSheetView(
                                fullNameInput: $fullNameInput,
                                emailInput: $emailInput,
                                passwordInput: $passwordInput,
                                confirmPasswordInput: $confirmPasswordInput,
                                isShowingAdminSheet: $isShowingAdminSheet,
                                storeProducts: $storeProducts,
                                orderHistory: $orderHistory,
                                currentUserOrderHistory: $currentUserOrderHistory,

                                onSaveProduct: {
                                    let newProduct = Product(
                                        id: Int.random(in: 1000...9999),
                                        name: productName,
                                        imageName: productImage,
                                        description: productDescription,
                                        price: Double(productPrice) ?? 0,
                                        reviews: [],
                                        category: "General"
                                    )

                                    storeProducts.append(newProduct)
                                    clearAdminInputFields()
                                },

                                onLogOut: { resetUserSession() }
                            )
                            .tag(AppTab.admin)
                        }

                        CustomTabBar(selectedTab: $selectedTab, shoppingCart: $shoppingCart)
                            .padding(.top,8)
                    }
                }

            } else {
                AuthView(
                    isShowingSignUpScreen: $isShowingSignUpScreen,
                    fullNameInput: $fullNameInput,
                    emailInput: $emailInput,
                    passwordInput: $passwordInput,
                    confirmPasswordInput: $confirmPasswordInput,
                    errorMessage: $errorMessage,
                    onAuthenticate: {
                        let cleanEmail = emailInput.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        if isShowingSignUpScreen {
                            if fullNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                errorMessage = "Please enter your full name."
                                return
                            }
                            if passwordInput != confirmPasswordInput {
                                errorMessage = "Passwords do not match."
                                return
                            }
                            if LocalDatabaseManager.shared.getUserDetails(username: cleanEmail) != nil {
                                errorMessage = "Account already exists with this email."
                                return
                            }
                            let profileData = [
                                "name": fullNameInput,
                                "email": cleanEmail,
                                "password": passwordInput
                            ]
                            LocalDatabaseManager.shared.saveNewUser(username: cleanEmail, profileData: profileData)
                            errorMessage = ""
                            withAnimation {
                                isUserLoggedIn = true
                                loggedInFullName = fullNameInput
                                loggedInEmail = cleanEmail
                            }
                            
                        } else {
                            let success = LocalDatabaseManager.shared.authenticateUser(username: cleanEmail, passwordInput: passwordInput)
                            
                            if success {
                                let userData = LocalDatabaseManager.shared.getUserDetails(username: cleanEmail)
                                let savedName = userData?["name"] ?? "User"
                                errorMessage = ""
                                withAnimation {
                                    isUserLoggedIn = true
                                    loggedInFullName = savedName
                                    loggedInEmail = cleanEmail
                                }
                            } else {
                                errorMessage = "Incorrect email address or password."
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
