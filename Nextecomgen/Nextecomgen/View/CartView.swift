import SwiftUI

struct CartItem: Codable, Identifiable, Equatable,Hashable {
    var id: Int { productId }
    let productId: Int
    let name: String
    let imageName: String
    let price: Double
    let category: String
    var quantity: Int
    let itemTotal: Double
    
}

struct CartResponse: Codable {
    let items: [CartItem]
    let cartTotal: Double
}

import SwiftUI

struct CartView: View {

    @State private var selectedProduct: Product? = nil
    @State private var isLoadingProduct = false

    @Binding var cartItems: [CartItem]
    @Binding var cartTotal: Double

    @State private var updatingProductId: Int? = nil
    @State private var navigateToPayment: Bool = false
    @State private var isPaymentVerified: Bool = false

    @Binding var selectedTab: AppTab
    @Binding var isShowingPaymentScreen: Bool
    @Binding var orderHistory: [AdminTransaction]
    @Binding var fullNameInput: String

    var usernameInput: String

    @Namespace private var detailNamespace

    private var token: String {
        LocalDatabaseManager.shared.getAuthToken() ?? ""
    }

    var body: some View {
        NavigationStack {

            VStack {
                header

                if cartItems.isEmpty {
                    emptyCartView
                } else {
                    cartList
                    footer
                }
            }
            .onAppear {
                loadCart()
            }
            .navigationDestination(item: $selectedProduct) { product in
                ProductDetailView(
                    product: product,
                    namespace: detailNamespace,
                    isShowing: .constant(true),
                    shoppingCart: .constant(cartItems),
                    showCheckout: .constant(false),
                    selectedTab: $selectedTab,
                    addToCart: {},
                    onBuyNow: {}
                )
            }
        }
    }

    private var cartList: some View {
        List {
            ForEach(cartItems) { item in

                let qty = item.quantity

                HStack(spacing: 16) {
                    Button {
                        Task {
                            isLoadingProduct = true
                            defer { isLoadingProduct = false }

                            do {
                                let product = try await fetchProductDetails(id: item.productId)
                                selectedProduct = product
                            } catch {
                                print("Error loading product:", error)
                            }
                        }
                    } label: {

                        HStack(spacing: 16) {

                            AsyncImage(url: URL(string: item.imageName)) { phase in
                                switch phase {
                                case .empty:
                                    ProgressView()
                                        .frame(width: 50, height: 50)

                                case .success(let image):
                                    image.resizable()
                                        .scaledToFit()
                                        .frame(width: 50, height: 50)

                                case .failure:
                                    Image(systemName: "photo")
                                        .frame(width: 50, height: 50)

                                @unknown default:
                                    EmptyView()
                                }
                            }

                            VStack(alignment: .leading) {
                                Text(item.name).font(.headline)
                                Text("₹\(item.price, specifier: "%.2f")")
                            }

                            Spacer()
                            HStack(spacing: 12) {

                                Button {
                                    changeQuantity(productId: item.productId, delta: -1)
                                } label: {
                                    Image(systemName: "minus.square.fill")
                                        .foregroundColor(.red)
                                }
                                .disabled(updatingProductId == item.productId)
                                .buttonStyle(.borderless)

                                Text("\(qty)")
                                    .frame(minWidth: 20)

                                Button {
                                    changeQuantity(productId: item.productId, delta: 1)
                                } label: {
                                    Image(systemName: "plus.square.fill")
                                        .foregroundColor(.green)
                                }
                                .disabled(updatingProductId == item.productId)
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .listStyle(.plain)
    }

    private func fetchProductDetails(id: Int) async throws -> Product {
        let url = URL(string: "http://127.0.0.1:8000/products/\(id)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(Product.self, from: data)
    }
    private func changeQuantity(productId: Int, delta: Int) {
        guard updatingProductId != productId else { return }

        updatingProductId = productId

        guard let index = cartItems.firstIndex(where: { $0.productId == productId }) else {
            updatingProductId = nil
            return
        }

        let newQty = max(cartItems[index].quantity + delta, 0)

        Task {
            updatingProductId = productId

            await updateCart(productId: productId, quantity: newQty)

            await MainActor.run {
                if newQty == 0 {
                    cartItems.remove(at: index)
                } else {
                    cartItems[index].quantity = newQty
                }

                recalcTotal()
                updatingProductId = nil
            }
        }
    }

    private func recalcTotal() {
        cartTotal = cartItems.reduce(0) {
            $0 + (Double($1.quantity) * $1.price)
        }
    }

    private func loadCart() {
        Task {
            guard let url = URL(string: "http://127.0.0.1:8000/users/cart") else { return }

            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "accept")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let http = response as? HTTPURLResponse,
                  http.statusCode == 200 else { return }

            let decoded = try JSONDecoder().decode(CartResponse.self, from: data)

            await MainActor.run {
                self.cartItems = decoded.items
                self.cartTotal = decoded.cartTotal
            }
        }
    }
    private var header: some View {
        HStack {
            Text("My Shopping Cart")
                .font(.headline)
            Spacer()
        }
        .padding()
    }
    private var emptyCartView: some View {
        VStack {
            Spacer()
            LottieView(name: "cart")
            Spacer()
        }
    }
    private var footer: some View {
        VStack(spacing: 12) {

            HStack {
                Text("Total Payable:")
                    .font(.headline)

                Spacer()

                Text("₹ \(cartTotal, specifier: "%.2f")")
                    .font(.title2)
                    .bold()
                    .foregroundColor(.green)
            }
            .padding(.horizontal)

            Button {
                navigateToPayment = true
            } label: {
                Text("Proceed to Pay")
                    .bold()
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
            }
        }
        .navigationDestination(isPresented: $navigateToPayment) {
            PaymentGatewayView(
                grandTotalPriceInt: cartTotal,
                merchantPhoneNumber: "8019324766",
                isShowingPaymentScreen: $isShowingPaymentScreen,
                isPaymentVerified: $isPaymentVerified,
                shoppingCart: $cartItems,
                currentUsername: usernameInput,
                onFinalizeOrder: {
                    isPaymentVerified = true
                }
            )
        }
        .padding(.bottom, 90)
    }
    private func updateCart(productId: Int, quantity: Int) async {
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

        _ = try? await URLSession.shared.data(for: request)
    }
}
