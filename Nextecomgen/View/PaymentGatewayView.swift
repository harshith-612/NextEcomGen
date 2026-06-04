import SwiftUI
import CoreImage.CIFilterBuiltins
struct PaymentGatewayView: View {
    let grandTotalPriceInt: Double
    let merchantPhoneNumber: String
    @Binding var isShowingPaymentScreen: Bool
    @Binding var isPaymentVerified: Bool
    @Binding var shoppingCart: [Product]
    let currentUsername: String
    var onFinalizeOrder: () -> Void
    @State private var transactionID: String = ""
    @State private var showingErrorAlert = false
    @State private var showingSuccessAlert = false
    @State private var showingUTRPrompt = false
    @Environment(\.dismiss) var dismiss
    @State private var capturedItemNames: [String] = []
    private func getResolvedUsername() -> String {
        let activeUser = LocalDatabaseManager.shared.getCurrentUser() ?? ""
        if activeUser.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return currentUsername.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        }
        return activeUser.lowercased()
    }
    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 6) {
                Text("Amount to Pay")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.gray)
                    .tracking(1)
                Text(String(format: "₹ %.2f/-", grandTotalPriceInt))
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(.freshMint)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)
            .padding(.horizontal)
            
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.freshMint, lineWidth: 3)
                        .frame(width: 220, height: 220)
                    if let qrCodeImage = generateUPIQRCode(
                        from: "upi://pay?pa=\(merchantPhoneNumber)@upi&pn=NextEcomGEN&am=\(grandTotalPriceInt)&cu=INR"
                    ) {
                        Image(uiImage: qrCodeImage)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 170, height: 170)
                    } else {
                        Image(systemName: "qrcode")
                            .font(.system(size: 140))
                            .foregroundColor(.gray)
                    }
                    Image(systemName: "viewfinder")
                        .font(.system(size: 240))
                        .foregroundColor(.freshMint.opacity(0.4))
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
                
                Text("or pay manually to mobile number:")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                HStack(spacing: 8) {
                    Image(systemName: "phone.fill")
                        .foregroundColor(.freshMint)
                    Text("+91 \(merchantPhoneNumber)")
                        .font(.headline)
                        .bold()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            }
            Spacer()
            Button {
                showingUTRPrompt = true
            } label: {
                Text("I Have Paid Natively")
                    .font(.headline)
                    .bold()
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [.freshMint, .deepEmerald],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(14)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .navigationTitle("Gateway Checkout")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    isShowingPaymentScreen = false
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(.freshMint)
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
        }
        .onAppear {
            if !shoppingCart.isEmpty {
                self.capturedItemNames = shoppingCart.map { $0.name }
                print("🔒 [CoreData Debug] GATEWAY CAPTURED \(capturedItemNames.count) ITEMS IN SAFE BUFFER")
            }
        }
        .alert("Verify Transaction", isPresented: $showingUTRPrompt) {
            TextField("Enter 12-digit UTR No.", text: $transactionID)
                .keyboardType(.numberPad)
                .foregroundColor(.black)
            Button("Submit Reference") {
                let cleanInput = transactionID.trimmingCharacters(in: .whitespacesAndNewlines)
                let isValidUTR = cleanInput.count == 12 && CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: cleanInput))
                guard isValidUTR else {
                    showingErrorAlert = true
                    return
                }
                let username = getResolvedUsername()
                let finalNames = capturedItemNames.isEmpty ? shoppingCart.map { $0.name } : capturedItemNames
                let newOrder = OrderHistoryItem(
                    id: UUID(),
                    itemNames: finalNames,
                    totalAmount: grandTotalPriceInt,
                    dateString: Date().formatted(date: .abbreviated, time: .omitted),
                    status: .placed
                )
                var updatedOrders = LocalDatabaseManager.shared.getOrderHistory(for: username)
                updatedOrders.append(newOrder)
                LocalDatabaseManager.shared.saveOrderHistory(updatedOrders, for: username)
                transactionID = ""
                showingSuccessAlert = true
            }
            Button("Cancel", role: .cancel) {
                transactionID = ""
            }
        } message: {
            Text("Enter your 12-digit UTR number to complete the order.")
        }
        .alert("Invalid Reference ID", isPresented: $showingErrorAlert) {
            Button("Try Again") {
                showingUTRPrompt = true
            }
        } message: {
            Text("UTR must be exactly 12 numeric digits.")
        }
        .alert("Order Placed Successfully 🎉", isPresented: $showingSuccessAlert) {
            Button("OK") {
                let username = getResolvedUsername()
                LocalDatabaseManager.shared.clearCart(for: username)
                shoppingCart.removeAll()
                isPaymentVerified = true
                isShowingPaymentScreen = false
                DispatchQueue.main.async {
                    onFinalizeOrder()
                }
                dismiss()
            }
        }
        message: {
            Text("Your order has been placed! Track it at Order History.")
        }
    }
    func generateUPIQRCode(from string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        if let outputImage = filter.outputImage,
           let cgImage = CIContext().createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
}
