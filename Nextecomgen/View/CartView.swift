import SwiftUI
struct CartView: View {
    @Binding var selectedTab: AppTab
    @Binding var shoppingCart: [Product]
    @Binding var isShowingPaymentScreen: Bool
    @Binding var orderHistory: [AdminTransaction]
    @Binding var fullNameInput: String
    var usernameInput: String
    @State private var navigateToPayment: Bool = false
    @State private var isPaymentVerified: Bool = false
    var grandCartTotalInt: Float {
        shoppingCart.reduce(0) { total, product in
            let numericString = String(product.price)
                .replacingOccurrences(of: "₹", with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if let floatValue = Float(numericString) {
                return total + floatValue
            }
            return total
        }
    }
    var grandCartTotalDisplay: String {
        return String(format: "₹ %.2f", grandCartTotalInt)
    }
    var uniqueGroupedCartItems: [Product] {
        var uniqueList: [Product] = []
        for item in shoppingCart {
            if !uniqueList.contains(where: { $0.name == item.name }) {
                uniqueList.append(item)
            }
        }
        return uniqueList
    }
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Text("My Shopping Cart")
                        .font(.headline)
                        .foregroundColor(.primary)

                    Spacer()
                }
                .padding([.horizontal, .top])
                if shoppingCart.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "bag.badge.questionmark")
                            .font(.system(size: 50))
                            .foregroundColor(.gray.opacity(0.6))
                        Text("Your cart is empty")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()

                } else {

                    List {
                        ForEach(uniqueGroupedCartItems) { item in

                            let count =
                            shoppingCart.filter {
                                $0.name == item.name
                            }.count

                            HStack(spacing: 16) {

                                AsyncImage(
                                    url: URL(string: item.imageName)
                                ) { phase in

                                    switch phase {

                                    case .empty:
                                        ProgressView()
                                            .frame(
                                                width: 50,
                                                height: 50
                                            )

                                    case .success(let image):
                                        image
                                            .resizable()
                                            .scaledToFit()
                                            .frame(
                                                width: 50,
                                                height: 50
                                            )

                                    case .failure:
                                        Image(systemName: "photo")
                                            .font(.title2)
                                            .foregroundColor(.gray)
                                            .frame(
                                                width: 50,
                                                height: 50
                                            )

                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .background(
                                    Color.gray.opacity(0.1)
                                )
                                .cornerRadius(8)

                                VStack(
                                    alignment: .leading,
                                    spacing: 4
                                ) {

                                    Text(item.name)
                                        .font(.headline)

                                    Text(
                                        "₹\(item.price, specifier: "%.2f")"
                                    )
                                }

                                Spacer()

                                HStack(spacing: 12) {
                                    Button {
                                        if let firstIndex = shoppingCart.firstIndex(where: { $0.name == item.name }) {
                                            withAnimation {
                                                shoppingCart.remove(at: firstIndex)
                                            }
                                            LocalDatabaseManager.shared.saveCart(shoppingCart, for: usernameInput)
                                        }
                                    } label: {
                                        Image(systemName: "minus.square.fill")
                                            .font(.title3)
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    Text("\(count)")
                                        .font(.headline)
                                        .frame(minWidth: 20)
                                    
                                    Button {
                                        withAnimation {
                                            shoppingCart.append(item)
                                        }
                                        LocalDatabaseManager.shared.saveCart(shoppingCart, for: usernameInput)
                                    } label: {
                                        Image(systemName: "plus.square.fill")
                                            .font(.title3)
                                            .foregroundColor(.freshMint)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)

                    VStack(spacing: 12) {

                        Spacer()
                        Spacer()

                        HStack {

                            Text("Total Payable:")
                                .font(.headline)

                            Spacer()

                            Text(grandCartTotalDisplay)
                                .font(.title2)
                                .bold()
                                .foregroundColor(.freshMint)
                        }
                        .padding(.horizontal, 24)

                        Button {

                            navigateToPayment = true

                        } label: {

                            Text("Proceed to Pay")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [
                                            .freshMint,
                                            .deepEmerald
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(10)
                                .padding(.horizontal, 24)
                        }

                        Spacer()
                            .navigationDestination(
                                isPresented: $navigateToPayment
                            ) {
                                    PaymentGatewayView(
                                        grandTotalPriceInt: Double(grandCartTotalInt),
                                        merchantPhoneNumber: "8019324766",
                                        isShowingPaymentScreen: $isShowingPaymentScreen,
                                        isPaymentVerified: $isPaymentVerified,
                                        shoppingCart: $shoppingCart,
                                        currentUsername: usernameInput,
                                        onFinalizeOrder: {
                                            isPaymentVerified = true
                                            let user = LocalDatabaseManager.shared.getCurrentUser() ?? usernameInput
                                            _ = LocalDatabaseManager.shared.getOrderHistory(for: user)
                                        }
                                    )


                            }
                    }
                    .padding(.bottom)
                }
            }
        }
        
    }
}
