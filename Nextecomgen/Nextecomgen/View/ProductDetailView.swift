import SwiftUI
struct ProductDetailView: View {
    var product: Product
    var namespace: Namespace.ID
    @State private var navigateToDirectPayment = false
    @State private var showingAlert = false
    @Binding var isShowing: Bool
    @Binding var shoppingCart: [CartItem]
    @Binding var showCheckout: Bool
    @Binding var selectedTab: AppTab
    let addToCart: () -> Void
    let onBuyNow: () -> Void
    @GestureState private var magnifyScale: CGFloat = 1.0
    @State private var finalScale: CGFloat = 1.0
    private let minZoom: CGFloat = 1.0
    private let maxZoom: CGFloat = 5.0
    @State private var isExpanded: Bool = false
    @Namespace private var imageNamespace
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            ScrollView {
                VStack(spacing: 25) {
                    VStack(spacing: 12) {
                        AsyncImage(url: URL(string: product.imageName)) { phase in
                            switch phase {
                            case .success(let image):
                                if !isExpanded {
                                    image
                                        .resizable()
                                        .scaledToFit()
                                        .matchedGeometryEffect(
                                            id: "\(product.id)_image",
                                            in: imageNamespace
                                        )
                                        .frame(width: 400,height: 400)
                                        .scaleEffect(finalScale * magnifyScale)
                                        .onTapGesture {
                                            withAnimation(
                                                .spring(
                                                    response: 0.4,
                                                    dampingFraction: 0.75
                                                )
                                            ) {
                                                isExpanded = true
                                            }
                                        }
                                } else {
                                    Color.clear
                                        .frame(maxWidth: .infinity)
                                }
                            case .empty:
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            case .failure:
                                Image(systemName: "photo")
                                    .foregroundColor(.gray)
                                    .frame(maxWidth: .infinity)
                            @unknown default:
                                EmptyView()
                            }
                        }
                    }
                    VStack(alignment: .leading, spacing: 18) {
                        Text(product.name)
                            .font(.largeTitle.bold())
                            .foregroundColor(Color(.systemBackground))
                        Text("₹\(product.price, specifier: "%.2f")")
                            .font(.title.bold())
                            .foregroundColor(.freshMint)
                        Text(product.productDescription)
                            .foregroundColor(.gray)
                        Button {
                            addToCart()
                            
                            let item = CartItem(
                                productId: product.id,
                                name: product.name,
                                imageName: product.imageName,
                                price: product.price,
                                category: product.category,
                                quantity: 1,
                                itemTotal: product.price
                            )
                        
                            
                            shoppingCart.append(item)
                            UIImpactFeedbackGenerator(style: .rigid)
                                .impactOccurred()
                            showingAlert = true
                        } label: {
                            Text("Add To Cart")
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(20)
                        }
                        .alert(
                            "Item Added to Cart ✅",
                            isPresented: $showingAlert
                        ) {
                            Button("OK", role: .cancel) { }
                        }
                        Button {
                            onBuyNow()
                            
                            DispatchQueue.main.async {
                                selectedTab = .cart
                                isShowing = false
                                dismiss()
                            }
                        } label:  {
                            HStack {
                                Image(systemName: "bolt.fill")
                                Text("Buy Now")
                                    .fontWeight(.bold)
                            }
                            .foregroundColor(.primary)
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
                            .cornerRadius(20)
                        }
                        VStack(alignment: .leading, spacing: 15) {
                            Divider()
                                .background(
                                    Color.gray.opacity(0.5)
                                )
                                .padding(.vertical, 10)
                        }
                        .padding(.top, 10)
                    }
                    .padding()
                    .padding(.bottom, 60)
                }
            }
            if !isExpanded {
                Button {
                    withAnimation(
                        .spring(
                            response: 0.4,
                            dampingFraction: 0.85
                        )
                    ) {
                        dismiss()
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                        .foregroundColor(Color(.systemBackground))
                        .padding()
                        .background(Color.secondary)
                        .clipShape(Circle())
                }
                .padding()
            }
            if isExpanded {
                AsyncImage(url: URL(string: product.imageName)) { phase in
                    if case .success(let expandedImage) = phase {
                        ZStack(alignment: .topTrailing) {
                            Color.black
                                .ignoresSafeArea()
                            
                            expandedImage
                                .resizable()
                                .scaledToFit()
                                .scaleEffect(finalScale * magnifyScale)
                                .matchedGeometryEffect(
                                    id: "\(product.id)_image",
                                    in: imageNamespace
                                )
                                .frame(
                                    maxWidth: .infinity,
                                    maxHeight: .infinity
                                )
                                .gesture(
                                    MagnifyGesture()
                                        .updating($magnifyScale) { value, state, _ in
                                            state = value.magnification
                                        }
                                        .onEnded { value in
                                            finalScale *= value.magnification
                                            finalScale = min(
                                                max(finalScale, minZoom),
                                                maxZoom
                                            )
                                        }
                                )
                            
                            Button {
                                withAnimation(.spring()) {
                                    isExpanded = false
                                    finalScale = minZoom
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 34))
                                    .foregroundColor(Color.white)
                                    .opacity(0.85)
                                    .padding(.top, 60)
                                    .padding(.trailing, 24)
                            }
                        }
                        .overlay(alignment: .bottom) {
                            if finalScale > minZoom || magnifyScale != 1.0 {
                                Text("\(Int((finalScale * magnifyScale) * 100))%")
                                    .foregroundColor(Color(.systemBackground))
                                    .font(.subheadline)
                                    .bold()
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                                    .padding(.bottom, 40)
                                    .transition(.opacity.combined(with: .scale))
                                    .animation(.easeInOut(duration: 0.2), value: finalScale > minZoom || magnifyScale != 1.0)
                            }
                        }
                    }
                }
                .transition(.identity)
                .zIndex(99)
            }
        }
        .navigationBarBackButtonHidden(true)
    }
}
