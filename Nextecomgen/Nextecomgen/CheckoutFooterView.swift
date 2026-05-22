import SwiftUI

struct CheckoutFooterView: View {
    @Binding var shoppingCart: [Product]
    @Binding var isShowingPaymentScreen: Bool
    @Binding var orderHistory: [AdminTransaction]
    @Binding var fullNameInput: String
    var usernameInput: String
    let actionTitle: String
    @State private var navigateToPayment: Bool = false
    @State private var isPaymentVerified: Bool = false
    var grandCartTotalInt: Float {
        shoppingCart.reduce(0) { total, product in
            let numericString = product.price.replacingOccurrences(of: "₹", with: "")
            return total + (Float(numericString) ?? 0)
        }
    }
    
    var grandCartTotalDisplay: String {
        return "₹ \(grandCartTotalInt)"
    }

    var body: some View {
        if !shoppingCart.isEmpty {
            VStack(spacing: 12) {
                HStack {
                    Text("Total Payable:")
                        .font(.headline)
                    Spacer()
                    Text(grandCartTotalDisplay)
                        .font(.title2)
                        .bold()
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 24)
                
                Button(action: {
                    navigateToPayment = true
                }) {
                    Text(actionTitle)
                        .bold()
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.horizontal, 24)
                }
                .navigationDestination(isPresented: $navigateToPayment) {
                    PaymentGatewayView(
                        grandTotalPriceInt: grandCartTotalInt,
                        merchantPhoneNumber: "8019324766",
                        isShowingPaymentScreen: $isShowingPaymentScreen,
                        isPaymentVerified: $isPaymentVerified,
                        shoppingCart: $shoppingCart,
                        orderHistory: $orderHistory,
                        fullNameInput: $fullNameInput,
                        currentUsername: usernameInput,
                        
                        onFinalizeOrder: {
                            isPaymentVerified = true
                        }
                    )
                }
            }
            .padding(.vertical, 12)
        }
    }
}
