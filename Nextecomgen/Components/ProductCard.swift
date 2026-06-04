import SwiftUI
struct ProductCard: View {

    let quantity: Int
    var product: Product
    var namespace: Namespace.ID

    var removeFromCart: () -> Void
    var addToCart: () -> Void
    var onBuyNow: () -> Void

    @Binding var shoppingCart: [Product]
    @Binding var showCheckout: Bool
    @Binding var selectedTab: AppTab
    private var username: String {
        LocalDatabaseManager.shared.getCurrentUser() ?? ""
    }

    var body: some View {

        NavigationLink(destination: ProductDetailView(
            product: product,
            namespace: namespace,
            isShowing: .constant(true),
            shoppingCart: $shoppingCart,
            showCheckout: $showCheckout,
            selectedTab: $selectedTab
        )) {

            ZStack(alignment: .topTrailing) {

                RoundedRectangle(cornerRadius: 32)
                    .fill(.ultraThinMaterial)

                VStack(spacing: 12) {

                    Spacer(minLength: 0)

                    AsyncImage(url: URL(string: product.imageName)) { phase in
                        switch phase {

                        case .empty:
                            SkeletonLoader()

                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxHeight: 130)
                                .matchedGeometryEffect(id: product.id, in: namespace)

                        case .failure(_):
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)

                        @unknown default:
                            EmptyView()
                        }
                    }

                    Spacer(minLength: 0)

                    VStack(alignment: .leading, spacing: 10) {

                        Text(product.name)
                            .font(.title3.bold())
                            .foregroundColor(.white)
                            .lineLimit(1)

                        HStack(alignment: .center) {

                            Text("₹\(product.price, specifier: "%.2f")")
                                .font(.title2.bold())
                                .foregroundColor(.white)

                            Spacer()

                            if quantity > 0 {

                                HStack(spacing: 10) {

                                    Button {
                                        removeFromCart()
                                    } label: {
                                        Image(systemName: "minus")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.black)
                                            .padding(6)
                                            .background(Color.red)
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)

                                    Text("\(quantity)")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(minWidth: 20)

                                    Button {
                                        addToCart()
                                    } label: {
                                        Image(systemName: "plus")
                                            .font(.subheadline.bold())
                                            .foregroundColor(.black)
                                            .padding(6)
                                            .background(Color.deepEmerald)
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(4)
                                .background(Color.white.opacity(0.15))
                                .clipShape(Capsule())

                            } else {

                                Button {
                                    addToCart()

                                } label: {
                                    Image(systemName: "plus")
                                        .font(.title3.bold())
                                        .foregroundColor(.black)
                                        .padding(8)
                                        .background(Color.white)
                                        .clipShape(Circle())
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Button {
                            onBuyNow()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "bolt.fill")
                                    .font(.headline)
                                    .foregroundColor(.black)
                                Text("Buy Now")
                                    .fontWeight(.bold)
                                    .foregroundColor(.black)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
        }
        .buttonStyle(.plain)
        .aspectRatio(1, contentMode: .fit)
        
    }
    
}
