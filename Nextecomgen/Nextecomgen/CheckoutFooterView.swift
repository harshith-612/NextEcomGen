/*import SwiftUI

struct CheckoutFooterView: View {

    @Binding var shoppingCart: [Product]
    @Binding var isShowingPaymentScreen: Bool
    @Binding var orderHistory: [AdminTransaction]
    @Binding var fullNameInput: String

    var usernameInput: String
    let actionTitle: String

    @State private var navigateToPayment = false
    @State private var isPaymentVerified = false
    var grandCartTotal: Double {

        shoppingCart.reduce(0) { total, product in

            let cleaned = String(product.price)
                .replacingOccurrences(of: "₹", with: "")
                .replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: .whitespaces)

            return total + (Double(cleaned) ?? 0)
        }
    }

    var grandCartTotalDisplay: String {
        "₹ \(String(format: "%.2f", grandCartTotal))"
    }

    var body: some View {

        if !shoppingCart.isEmpty {

            VStack(spacing: 14) {
                HStack {
                    Text("Total Payable")
                        .font(.headline)

                    Spacer()

                    Text(grandCartTotalDisplay)
                        .font(.title2.bold())
                        .foregroundColor(.green)
                }
                .padding(.horizontal, 20)
                Button {

                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    navigateToPayment = true

                } label: {

                    Text(actionTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(14)
                        .padding(.horizontal, 20)
                }

            }
            .padding(.vertical, 12)
            .navigationDestination(isPresented: $navigateToPayment) {

               /* PaymentGatewayView(
                    grandTotalPriceInt: grandCartTotal,
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
                )*/
            }
        }
    }
}
*/
