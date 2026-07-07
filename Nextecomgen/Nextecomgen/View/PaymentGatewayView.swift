import SwiftUI
import CoreImage.CIFilterBuiltins

struct PaymentGatewayView: View {
    
    let grandTotalPriceInt: Double
    let merchantPhoneNumber: String
    
    @State private var orderSnapshot: [CartItem] = []
    
    @Binding var isShowingPaymentScreen: Bool
    @Binding var isPaymentVerified: Bool
    @Binding var shoppingCart: [CartItem]
    
    let currentUsername: String
    var onFinalizeOrder: () -> Void
    
    @State private var transactionID: String = ""
    @State private var showingErrorAlert = false
    @State private var showingSuccessAlert = false
    @State private var showingUTRPrompt = false
    @State private var capturedItemNames: [String] = []
    
    @Environment(\.dismiss) var dismiss
    
    private var token: String {
        LocalDatabaseManager.shared.getAuthToken() ?? ""
    }
    
    struct ProductItemInput: Encodable {
        let productId: Int
        let quantity: Int
    }
    
    struct CreateOrderRequest: Encodable {
        let date: String
        let status: String
        let totalAmount: Double
        let products: [ProductItemInput]
    }
    
    
    private var formattedPriceString: String {
        String(format: "₹ %.2f/-", grandTotalPriceInt)
    }
    
    private var total: Double {
        shoppingCart.reduce(0) {
            $0 + (Double($1.quantity) * $1.price)
        }
    }
    private var qrCodeImageInstance: UIImage? {
        let upiPayload = "upi://pay?pa=\(merchantPhoneNumber)@upi&pn=NextEcomGEN&am=\(grandTotalPriceInt)&cu=INR"
        return generateUPIQRCode(from: upiPayload)
    }
    
    var body: some View {
        VStack(spacing: 24) {
            
            VStack(spacing: 6) {
                Text("Amount to Pay")
                    .font(.caption)
                    .bold()
                    .foregroundColor(.gray)
                
                Text(formattedPriceString)
                    .font(.system(size: 34, weight: .black))
                    .foregroundColor(.freshMint)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(16)
            
            VStack(spacing: 12) {
                
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.freshMint, lineWidth: 3)
                        .frame(width: 220, height: 220)
                    
                    if let qrCodeImage = qrCodeImageInstance {
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
                .background(Color(.secondarySystemBackground))
                .cornerRadius(20)
                
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
            }
            
            Spacer()
            
            Button {
                orderSnapshot = Array(shoppingCart)
                showingUTRPrompt = true
            } label: {
                Text("I Have Paid Natively")
                    .font(.headline)
                    .bold()
                    .foregroundColor(Color(.systemBackground))
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
            .padding(.horizontal)
            .padding(.bottom, 20)
        }
        
        .navigationTitle("Gateway Checkout")
        .navigationBarTitleDisplayMode(.inline)
        
        .alert("Verify Transaction", isPresented: $showingUTRPrompt) {
            TextField("Enter 12-digit UTR No.", text: $transactionID).autocorrectionDisabled(true)
            
            Button("Submit Reference") {
                handleOrderSubmission()
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
                handleSuccessRedirection()
            }
        } message: {
            Text("Your order has been placed! Track it at Order History.")
        }
    }
    
    private func handleOrderSubmission() {
        
        let cleanInput = transactionID.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let isValidUTR =
        cleanInput.count == 12 &&
        CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: cleanInput))
        
        guard isValidUTR else {
            showingErrorAlert = true
            return
        }
        
        createOrderOnBackend()
    }
    
    private func createOrderOnBackend() {
        Task {
            guard let url = URL(string: "http://127.0.0.1:8000/users/orders/") else { return }
            
            let snapshotCart = orderSnapshot
            
            guard !snapshotCart.isEmpty else {
                return
            }
            let productsPayload = snapshotCart.map { item in
                ProductItemInput(productId: item.productId, quantity: item.quantity)
            }
            
            let totalAmount = snapshotCart.reduce(0) {
                $0 + (Double($1.quantity) * $1.price)
            }
            let body = CreateOrderRequest(
                date: ISO8601DateFormatter().string(from: Date()),
                status: "placed",
                totalAmount: totalAmount,
                products: productsPayload
            )
            
            do {
                let encoded = try JSONEncoder().encode(body)
                
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.setValue("application/json", forHTTPHeaderField: "accept")
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                request.httpBody = encoded
                
                let (_, response) = try await URLSession.shared.data(for: request)
                
                if let http = response as? HTTPURLResponse {
                    
                    if http.statusCode == 201 {
                        await MainActor.run {
                            showingSuccessAlert = true
                        }
                        await clearCart()
                    }
                }
                
            } catch {
                print("Create Order Error:", error)
            }
        }
    }
    
    
    private func clearCart() async {
        
        guard let url = URL(string: "http://127.0.0.1:8000/users/cart/clear") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        do {
            let (_, _) = try await URLSession.shared.data(for: request)
            
            await MainActor.run {
                shoppingCart.removeAll()
            }
            
        } catch {
            print("Clear cart error:", error)
        }
    }
    
    private func handleSuccessRedirection() {
        
        shoppingCart.removeAll()
        isPaymentVerified = true
        isShowingPaymentScreen = false
        
        DispatchQueue.main.async {
            onFinalizeOrder()
        }
        
        dismiss()
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
