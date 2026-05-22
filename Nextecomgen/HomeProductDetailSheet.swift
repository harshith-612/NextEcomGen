import SwiftUI
struct HomeProductDetailSheet: View {
    let product: Product
    @Binding var shoppingCart: [Product]
    @Binding var isShowingPaymentScreen: Bool
    @Binding var orderHistory: [AdminTransaction]
    var usernameInput: String
    @State private var selectedQuantity: Int = 1
    @Environment(\.dismiss) var dismiss
    @State private var currentImageIndex: Int = 0
    @State private var currentReviewIndex: Int = 0
    @State private var navigateToPayment: Bool = false
    @State private var isPaymentVerified: Bool = false
    @Binding var fullNameInput: String
    var onBackAction: () -> Void
    let quantities = Array(1...5)
    
    var currentItemCount: Int {
        shoppingCart.filter { $0.name == product.name }.count
    }
    
    var grandCartTotalInt: Float {
        shoppingCart.reduce(0) { total, product in
            let numericString = product.price
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
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        ZStack(alignment: .bottomTrailing) {
                            if !product.images.isEmpty {
                                AsyncImage(url: URL(string: product.images[currentImageIndex])) { phase in
                                    switch phase {
                                    case .empty:
                                        VStack { ProgressView().scaleEffect(1.2) }
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .background(Color.lightSageBg.opacity(0.3))
                                    case .success(let image):
                                        image.resizable().scaledToFit().frame(maxWidth: .infinity, maxHeight: .infinity)
                                    case .failure:
                                        VStack(spacing: 8) {
                                            Image(systemName: "photo.fill").font(.largeTitle).foregroundColor(.gray)
                                            Text("Failed to load image").font(.caption).foregroundColor(.secondary)
                                        }
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .background(Color.lightSageBg.opacity(0.3))
                                    @unknown default:
                                        EmptyView()
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture { advanceImage() }
                            } else {
                                VStack { Image(systemName: "photo").font(.largeTitle).foregroundColor(.gray) }
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .background(Color.lightSageBg)
                            }
                            
                            if product.images.count > 1 {
                                HStack(spacing: 8) {
                                    Text("\(currentImageIndex + 1) / \(product.images.count)").font(.caption2.monospacedDigit())
                                    Button(action: { advanceImage() }) {
                                        HStack(spacing: 2) {
                                            Text("Next")
                                            Image(systemName: "chevron.right")
                                        }
                                    }
                                }
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.vertical, 6)
                                .padding(.horizontal, 12)
                                .background(Color.black.opacity(0.65))
                                .cornerRadius(20)
                                .padding(12)
                            }
                        }
                        .frame(height: 320)
                        .background(Color.lightSageBg)
                        .cornerRadius(16)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(alignment: .top) {
                                Text(product.name).font(.system(.title2, design: .rounded)).bold()
                                Spacer()
                                Text(product.price).font(.system(.title3, design: .rounded)).bold().foregroundColor(.deepEmerald)
                            }
                            
                            Text(product.category.capitalized)
                                .font(.caption.bold())
                                .padding(.vertical, 4)
                                .padding(.horizontal, 10)
                                .background(Color.deepEmerald.opacity(0.15))
                                .foregroundColor(.deepEmerald)
                                .cornerRadius(8)
                        }
                        
                        Divider()
                        Text("Product Description").font(.system(.headline, design: .rounded))
                        
                        Text(product.description).font(.body).foregroundColor(.secondary)
                        Divider()
                        
                        if !product.reviews.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text("Customer Reviews").font(.system(.headline, design: .rounded))
                                    Spacer()
                                    
                                    if product.reviews.count > 1 {
                                        HStack(spacing: 8) {
                                            Text("\(currentReviewIndex + 1) / \(product.reviews.count)").font(.caption2.monospacedDigit())
                                            Button(action: { advanceReview() }) {
                                                HStack(spacing: 2) {
                                                    Text("Next")
                                                    Image(systemName: "chevron.right")
                                                }
                                            }
                                        }
                                        .font(.caption.bold())
                                        .foregroundColor(.white)
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 10)
                                        .background(Color.black.opacity(0.65))
                                        .cornerRadius(20)
                                    }
                                }
                                
                                let currentReview = product.reviews[currentReviewIndex]
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(currentReview["reviewerName"] ?? "Anonymous User")
                                            .font(.subheadline)
                                            .bold()
                                        Spacer()
                                        Text(" \(Image(systemName: "star.circle.fill"))\(currentReview["rating"] ?? "5")")
                                            .font(.caption.bold())
                                            .foregroundColor(.yellow)
                                    }
                                    
                                    Text(currentReview["comment"] ?? "No comment provided.")
                                        .font(.body)
                                        .foregroundColor(.primary)
                                        .italic()
                                    
                                    if let rawDate = currentReview["date"] {
                                        Text(rawDate)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .toolbarBackground(Color(.systemGray6))
                                .cornerRadius(12)
                            }
                        } else {
                            Text("No reviews available for this product.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
                
                VStack {
                    HStack {
                        Spacer()
                        Button(action: {
                            if !shoppingCart.contains(where: { $0.id == product.id }) {
                                shoppingCart.append(product)
                            }
                            navigateToPayment = true
                        }) {
                            Text("Buy Now")
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(8)
                                .padding(.horizontal, 15)
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
                        Spacer()
                        HStack(spacing: 15) {
                            Spacer()
                            Picker("Qty", selection: Binding(get: { shoppingCart.filter { $0.name == product.name }.count }, set: { count in withAnimation { while shoppingCart.filter({ $0.name == product.name }).count != count { if count > shoppingCart.filter({ $0.name == product.name }).count { shoppingCart.append(product) } else { shoppingCart.remove(at: shoppingCart.firstIndex(where: { $0.name == product.name })!) } } } })) {
                                ForEach(quantities, id: \.self) { num in
                                    Label("Qty \(num) ", systemImage: "cart.badge.plus").tag(num)
                                }
                            }
                            .pickerStyle(.menu)
                            Spacer()
                        }
                    }
                }
                .padding(.bottom, 16)
                .toolbarBackground(Color(.systemGray6))
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { onBackAction() }) { 
                        HStack {
                            Image(systemName: "chevron.backward")
                            Text("Back to Store")
                        }
                    }
                }
            }
        }
    }
    
    private func advanceImage() {
        guard !product.images.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            if currentImageIndex + 1 < product.images.count {
                currentImageIndex += 1
            } else {
                currentImageIndex = 0
            }
        }
    }
    
    private func advanceReview() {
        guard !product.reviews.isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            if currentReviewIndex + 1 < product.reviews.count {
                currentReviewIndex += 1
            } else {
                currentReviewIndex = 0
            }
        }
    }
}
