import SwiftUI
import CoreImage.CIFilterBuiltins

struct PaymentGatewayView: View {
    let grandTotalPriceInt: Double
    let merchantPhoneNumber: String
    @Binding var isShowingPaymentScreen: Bool
    @Binding var isPaymentVerified: Bool
    @Binding var shoppingCart: [Nextecomgen.Product]
    @Binding var orderHistory: [AdminTransaction]
    @Binding var fullNameInput: String
    let currentUsername: String
    
    var onFinalizeOrder: () -> Void
    
    @State private var transactionID: String = ""
    @State private var showingErrorAlert = false
    @State private var showingSuccessAlert = false
    @State private var showingUTRPrompt = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            TabView{
                VStack(spacing: 24) {
                    VStack(spacing: 6) {
                        Text("Amount to Pay").font(.caption).bold().foregroundColor(.gray).tracking(1)
                        Text(String(format: "₹ %.2f/-", grandTotalPriceInt)).font(.system(size: 34, weight: .black, design: .rounded)).foregroundColor(.green)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(16)
                    .padding(.horizontal)
                    
                    VStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16).stroke(Color.green, lineWidth: 3).frame(width: 220, height: 220)
                            if let qrCodeImage = generateUPIQRCode(from: "upi://pay?pa=\(merchantPhoneNumber)@upi&pn=NextEcomGEN&am=\(grandTotalPriceInt)&cu=INR") {
                                Image(uiImage: qrCodeImage).resizable().interpolation(.none).scaledToFit().frame(width: 170, height: 170)
                            } else {
                                Image(systemName: "qrcode").font(.system(size: 140)).foregroundColor(.gray)
                            }
                            Image(systemName: "viewfinder").font(.system(size: 240)).foregroundColor(.green.opacity(0.4))
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(20)
                        .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 5)
                        
                        Text("or pay manually to mobile number:").font(.footnote).foregroundColor(.secondary)
                        HStack(spacing: 8) {
                            Image(systemName: "phone.fill").foregroundColor(.green)
                            Text("+91 \(merchantPhoneNumber)").font(.headline).bold().foregroundColor(.primary)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(10)
                    }
                    Spacer()
                    Button(action: {
                        showingUTRPrompt = true
                    }) {
                        Text("I Have Paid Natively").font(.headline).bold().foregroundColor(.white).frame(maxWidth: .infinity).padding(.vertical, 16).background(
                            LinearGradient(
                                colors: [.freshMint, .deepEmerald],
                                startPoint: .leading,
                                endPoint: .trailing
                            ))
                        .cornerRadius(14)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
                .navigationTitle("Gateway Checkout")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") { isShowingPaymentScreen = false }.foregroundColor(.red)
                    }
                }
                .alert("Verify Transaction", isPresented: $showingUTRPrompt) {
                    TextField("Enter 12-digit UTR No.", text: $transactionID)
                        .keyboardType(.numberPad)
                        .foregroundColor(.black)
                    
                    Button("Submit Reference") {
                        let cleanInput = transactionID.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        if cleanInput.count == 12, CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: cleanInput)) {
                            let incomingTx = AdminTransaction(
                                id: UUID(),
                                orderIDString: "ORD-\(Int.random(in: 100000...999999))",
                                totalAmount: Float(grandTotalPriceInt),
                                transactionID: cleanInput,
                                date: Date(),
                                associatedProducts: shoppingCart,
                                buyerUsername: currentUsername,
                                fullNameInput: $fullNameInput
                            )
                            orderHistory.append(incomingTx)
                            transactionID = ""
                            onFinalizeOrder()
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                showingSuccessAlert = true
                            }
                        } else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                showingErrorAlert = true
                            }
                        }
                    }
                    Button("Cancel", role: .cancel) { transactionID = "" }
                } message: {
                    Text("Please enter the 12-digit UPI transaction ID from your bank statement to finish ordering.")
                }
                .alert("Invalid Reference ID", isPresented: $showingErrorAlert) {
                    Button("Try Again") { showingUTRPrompt = true }
                } message: {
                    Text("A standard UPI UTR code must contain exactly 12 numeric digits. Please double-check your receipt.")
                }
                .alert("Verification Submitted! ⏳", isPresented: $showingSuccessAlert) {
                    Button("OK") {
                        shoppingCart.removeAll()
                        isPaymentVerified = true
                        isShowingPaymentScreen = false
                        dismiss()
                    }
                } message: {
                    Text("Thank you! Your transaction reference has been recorded. Admin will verify your payment and update your order history soon.")
                }
            }
        }
    }
    func generateUPIQRCode(from string: String) -> UIImage? {
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        if let outputImage = filter.outputImage, let cgImage = CIContext().createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgImage)
        }
        return nil
    }
}
