import SwiftUI
struct ProductDetailView: View {
    var product: Product
    var namespace: Namespace.ID
    @State private var navigateToDirectPayment = false
    @State private var showingAlert = false
    @Binding var isShowing: Bool
    @Binding var shoppingCart: [Product]
    @Binding var showCheckout: Bool
    @Binding var selectedTab: AppTab
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Text("         ")
        ZStack(alignment: .topLeading) {
            Color.black
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    AsyncImage(url: URL(string: product.imageName)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .matchedGeometryEffect(id: "\(product.id)_image", in: namespace)
                        case .empty:
                            ProgressView()
                        case .failure(_):
                            Image(systemName: "photo")
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .frame(height: 320)
                    .padding(.top, 60)
                    VStack(alignment: .leading, spacing: 18) {
                        Text(product.name)
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        Text("₹\(product.price, specifier: "%.2f")")
                            .font(.title.bold())
                            .foregroundColor(.freshMint)
                        Text(product.description)
                        .foregroundColor(.gray)
                        Button {
                            shoppingCart.append(product)
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                            showingAlert = true
                        } label: {
                            Text("Add To Cart")
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(20)
                        }
                        .alert("Item Added to Cart ✅", isPresented: $showingAlert) {
                            Button("OK", role: .cancel) { }
                        }
                        Button {
                            shoppingCart.append(product)
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            dismiss()
                            withAnimation {
                                isShowing = false
                                selectedTab = .cart
                            }
                        } label: {
                            HStack {
                                Image(systemName: "bolt.fill")
                                Text("Buy Now")
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.freshMint, .deepEmerald],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(20)
                        }
                        VStack(alignment: .leading, spacing: 15) {
                            Divider()
                                .background(Color.gray.opacity(0.5))
                                .padding(.vertical, 10)
                            Text("Customer Reviews")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            if product.reviews.isEmpty {
                                Text("Be the first Person to review it.")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .padding(.vertical, 5)
                            } else {
                                ForEach(0..<product.reviews.count, id: \.self) { index in
                                    let review = product.reviews[index]
                                    VStack(alignment: .leading, spacing: 8) {
                                        HStack {
                                            Text("⭐ \(review["rating"] ?? "5")")
                                                .font(.subheadline.bold())
                                                .foregroundColor(.orange)
                                            Spacer()
                                            Text(review["reviewerName"] ?? "Anonymous User")
                                                .font(.caption.bold())
                                                .foregroundColor(.gray)
                                        }
                                        Text(review["comment"] ?? "")
                                            .font(.subheadline)
                                            .foregroundColor(.white.opacity(0.85))
                                            .lineLimit(3)
                                        if let date = review["date"] {
                                            Text(date.prefix(10))
                                                .font(.system(size: 10))
                                                .foregroundColor(.gray.opacity(0.7))
                                        }
                                    }
                                    .padding()
                                    .background(Color.white.opacity(0.06))
                                    .cornerRadius(16)
                                }
                            }
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                    .padding(.bottom, 60)
                }
            }
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    dismiss()
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .padding()
        }
        .navigationBarBackButtonHidden(true)
    }
}
import Foundation

extension String {
    func cleanedKey() -> String {
        self.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
}
