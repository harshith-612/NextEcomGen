import SwiftUI
struct HomeView: View {
    @Namespace private var animation
    @Binding var storeProducts: [Product]
    @Binding var shoppingCart: [CartItem]
    @Binding var selectedTab: AppTab
    @Binding var searchText: String
    @Binding var isShowing: Bool
    @Binding var isLoading: Bool
    @Binding var hasMoreData: Bool
    @State private var selectedCategory = "All"
    @State private var showCheckout = false
    @State private var manuallyPaused = false
    @EnvironmentObject var network: NetworkMonitor
    @State var cartItems: [CartItem] = []
    @State var cartTotal: Double = 0.0
    @State private var hasBeenOffline = false
    @State private var bannerState: NetworkBannerState = .none
    @State private var bannerTask: Task<Void, Never>?
    @State private var isFirstNetworkCheck = true
    @State private var previousNetworkState: Bool?
    var onFetchNextBatch: () async -> Void
    var filteredProducts: [Product] {
        let search = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return storeProducts.filter { product in
            let categoryMatch =
            selectedCategory == "All" ||
            product.category.localizedCaseInsensitiveCompare(selectedCategory) == .orderedSame
            let searchMatch =
            search.isEmpty ||
            product.name.localizedCaseInsensitiveContains(search)
            
            return categoryMatch && searchMatch
        }
    }
    var uniqueCategories: [String] {
        let categories = storeProducts.map {
            $0.category
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .capitalized
        }
        
        let unique = Set(categories).sorted()
        return ["All"] + unique
    }
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Group {
                    if bannerState == .offline {
                        bannerView(
                            icon: "wifi.slash",
                            text: "No Internet Connection",
                            color: .red
                        )
                    }
                    else if bannerState == .reconnected {
                        bannerView(
                            icon: "wifi",
                            text: "Reconnected",
                            color: .green
                        )
                    }
                }
                .animation(.easeInOut, value: bannerState)
                
                headerView
                searchBar
                
                ScrollView {
                    LazyVStack(spacing: 24) {
                        categoryScrollView
                        
                        if storeProducts.isEmpty {
                            skeletonSection
                        } else {
                            productsSection
                        }
                        
                        if !storeProducts.isEmpty && hasMoreData && searchText.isEmpty {
                            SkeletonLoader()
                                .padding()
                                .onAppear {
                                    Task {
                                        guard network.isConnected else {
                                            print("Skip fetch - offline")
                                            return
                                        }
                                        
                                        await onFetchNextBatch()
                                    }
                                }
                        }
                    }
                    .padding(.bottom, 120)
                }
            }
            .task {
                previousNetworkState = network.isConnected
                for await connected in network.$isConnected.values {
                    await MainActor.run {
                        handleNetworkChange(connected)
                    }
                }
            }
            .task {
                if storeProducts.isEmpty {
                    await onFetchNextBatch()
                }
            }
            .onDisappear {
                bannerTask?.cancel()
            }
        }
    }
    @MainActor
    private func handleNetworkChange(_ connected: Bool) {
        
        print("NETWORK CHANGE:", connected)
        if isFirstNetworkCheck {
            
            isFirstNetworkCheck = false
            
            hasBeenOffline = !connected
            
            print(
                "INITIAL NETWORK:",
                connected
            )
            
            return
        }
        
        
        
        if !connected {
            
            print("OFFLINE")
            
            hasBeenOffline = true
            
            bannerTask?.cancel()
            
            withAnimation(.spring()) {
                
                bannerState = .offline
                
            }
            
            return
        }
        guard hasBeenOffline else {
            
            print(
                "Already online - no banner"
            )
            
            return
        }
        
        
        
        print(
            "INTERNET RESTORED"
        )
        
        
        hasBeenOffline = false
        
        
        withAnimation(.spring()) {
            
            bannerState = .reconnected
            
        }
        
        
        
        bannerTask?.cancel()
        
        
        bannerTask = Task {
            try? await Task.sleep(
                for: .seconds(3)
            )
            await MainActor.run {
                withAnimation(.spring()) {
                    bannerState = .none
                }
            }
        }
    }
}

private func bannerView(icon: String, text: String, color: Color) -> some View {
    HStack(spacing: 8) {
        Image(systemName: icon)
        Text(text)
            .font(.subheadline)
            .fontWeight(.medium)
        Spacer()
    }
    .padding()
    .background(color)
    .foregroundColor(Color(.systemBackground))
    .transition(
        .asymmetric(
            insertion: .move(edge: .top)
                .combined(with: .opacity),
            removal: .move(edge: .top)
                .combined(with: .opacity)
        )
    )
    .animation(.spring(), value: text)
}
extension HomeView {
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Discover")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.primary)
                    Text("Premium Collection")
                        .foregroundColor(.secondary)
                }
                Spacer()
                ZStack {
                    LottieView(name: "hi")
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                        .font(.title2)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top)
    }
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary).opacity(0.4)
            TextField(
                "Search products...",
                text: $searchText
            )
            .foregroundColor(Color(.systemBackground))
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.never)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary).opacity(0.4)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    private var categoryScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(uniqueCategories, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Text(category)
                            .fontWeight(.semibold)
                            .foregroundColor(
                                selectedCategory == category
                                ? Color(.systemBackground)
                                : .primary
                            )
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(
                                selectedCategory == category
                                ? Color.primary
                                : Color.secondary.opacity(0.15)
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
    }
    private var skeletonSection: some View {
        ScrollView {
            VStack(spacing: 20) {
                ForEach(0..<4, id: \.self) { _ in
                    SkeletonLoader()
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 24)
        }
    }
    private var emptySearchSection: some View {
        VStack(spacing: 16) {
            LottieView(name: "search")
        }
    }
    private var token: String {
        LocalDatabaseManager.shared.getAuthToken() ?? ""
    }
    private func syncCart(productId: Int, quantity: Int) {
        Task {
            guard let url = URL(string: "http://127.0.0.1:8000/users/cart") else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = [
                "productId": productId,
                "quantity": quantity
            ]
            
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            do {
                let (_, _) = try await URLSession.shared.data(for: request)
                
                
            } catch {
                print("Cart sync error:", error)
            }
        }
    }
    private var productsSection: some View {
        VStack(spacing: 18) {
            ForEach(filteredProducts, id: \.id) { product in
                let cartQuantity = cartItems.first(where: { $0.productId == product.id })?.quantity ?? 0
                
                ProductCard(
                    quantity: cartQuantity,
                    product: product,
                    namespace: animation,
                    
                    removeFromCart: {
                        Task {
                            let currentQty = cartItems.first(where: { $0.productId == product.id })?.quantity ?? 0
                            
                            if currentQty <= 1 {
                                cartItems.removeAll { $0.productId == product.id }
                                
                                await deleteCartItem(productId: product.id)
                            } else {
                                let newQty = currentQty - 1
                                if let index = cartItems.firstIndex(where: { $0.productId == product.id }) {
                                    cartItems[index].quantity = newQty
                                }
                                
                                await updateCartItem(productId: product.id, quantity: newQty)
                            }
                        }
                    },
                    
                    addToCart: {
                        Task {
                            let currentQty = cartItems.first(where: { $0.productId == product.id })?.quantity ?? 0
                            
                            if currentQty == 0 {
                                await addCartItem(productId: product.id, quantity: 1)
                            } else {
                                await updateCartItem(productId: product.id, quantity: currentQty + 1)
                            }
                        }
                    },
                    
                    onBuyNow: {
                        handleBuyNow(product: product)
                    },
                    
                    shoppingCart: $shoppingCart,
                    showCheckout: $showCheckout,
                    selectedTab: $selectedTab
                )
            }
        }
        .task {
            await loadCartItemsFromBackend()
        }
    }
    private func handleBuyNow(product: Product) {
        Task {
            let currentQty = cartItems.first(where: { $0.productId == product.id })?.quantity ?? 0
            
            if currentQty == 0 {
                await addCartItem(productId: product.id, quantity: 1)
            }
            
            await loadCartItemsFromBackend()
            
            await MainActor.run {
                selectedTab = .cart
            }
        }
    }
    private func addCartItem(productId: Int, quantity: Int) async {
        guard let url = URL(string: "http://127.0.0.1:8000/users/cart") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "productId": productId,
            "quantity": quantity
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, http.statusCode == 200 || http.statusCode == 201 {
                await loadCartItemsFromBackend()
            }
        } catch {
            print("ADD error:", error)
        }
    }
    
    private func updateCartItem(productId: Int, quantity: Int) async {
        guard let url = URL(string: "http://127.0.0.1:8000/users/cart") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "productId": productId,
            "quantity": quantity
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                await loadCartItemsFromBackend()
            }
        } catch {
            print("UPDATE error:", error)
        }
    }
    
    private func deleteCartItem(productId: Int) async {
        guard let url = URL(string: "http://127.0.0.1:8000/users/cart?productId=\(productId)") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let http = response as? HTTPURLResponse, http.statusCode == 200 {
                await loadCartItemsFromBackend()
            }
        } catch {
            print("DELETE error:", error)
        }
    }
    
    private func updateBackendCart(productId: Int, quantity: Int) async {
        guard let url = URL(string: "http://127.0.0.1:8000/users/cart") else { return }
        
        let token = LocalDatabaseManager.shared.getAuthToken() ?? ""
        
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let body: [String: Any] = [
            "productId": productId,
            "quantity": quantity
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }
            
            await loadCartItemsFromBackend()
        } catch {
            print("Failed to sync quantity update to backend: \(error)")
        }
    }
    private func loadCartItemsFromBackend() async {
        let token = LocalDatabaseManager.shared.getAuthToken() ?? ""
        guard let url = URL(string: "http://127.0.0.1:8000/users/cart") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }
            
            if let decoded = try? JSONDecoder().decode(CartResponse.self, from: data) {
                await MainActor.run {
                    self.cartItems = decoded.items
                    self.cartTotal = decoded.cartTotal
                }
            }
        } catch {
            print("Failed to load cart items:", error)
        }
    }
    
}
