import SwiftUI

struct ProductCard: View {
    let quantity: Int
    var product: Product
    var namespace: Namespace.ID
    var removeFromCart: () -> Void
    let addToCart: () -> Void
    let onBuyNow: () -> Void
    @Binding var shoppingCart: [CartItem]
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
            selectedTab: $selectedTab,
            addToCart: addToCart,
            onBuyNow: onBuyNow
        )) {
            ZStack {
                RoundedRectangle(cornerRadius: 32)
                    .fill(.secondary).opacity(0.4)
                
                VStack {
                    AsyncImage(url: URL(string: product.imageName)) { phase in
                        switch phase {
                        case .empty:
                            Image(systemName: "progress.indicator")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 52, height: 52)
                                .foregroundStyle(.black).opacity(0.5)
                            
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .matchedGeometryEffect(id: product.id, in: namespace)
                        case .failure(_):
                            Image(systemName: "photo.badge.exclamationmark")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                        @unknown default:
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 52, height: 52)
                                .foregroundStyle(.black).opacity(0.5)
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .frame(maxWidth: .infinity)
                    .background(Color(hex: "ddf7c4"))
                    .clipShape(UnevenRoundedRectangle(
                        topLeadingRadius: 20,
                        bottomLeadingRadius: 0,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 20))
                    
                    Text(product.name)
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    HStack(alignment: .center) {
                        Text("₹\(product.price, specifier: "%.2f")")
                            .font(.title2.bold())
                            .foregroundColor(.primary)
                        
                        Spacer()
                        if quantity > 0 {
                            HStack(spacing: 12) {
                                Button {
                                    removeFromCart()
                                } label: {
                                    Image("Minus")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 22, height: 22)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                                
                                Text("\(quantity)")
                                    .font(.system(.headline, design: .rounded))
                                    .foregroundColor(Color(.systemBackground))
                                    .frame(minWidth: 20)
                                
                                Button {
                                    addToCart()
                                } label: {
                                    Image("Plus")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 22, height: 22)
                                }
                                .buttonStyle(BorderlessButtonStyle())
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.secondary)
                            .clipShape(Capsule())
                        } else {
                            Button {
                                addToCart()
                            } label: {
                                Image(systemName: "plus")
                                    .font(.title3.bold())
                                    .foregroundColor(Color(.systemBackground))
                                    .padding(8)
                                    .background(Color.primary)
                                    .clipShape(Circle())
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                    .padding(.vertical, 4)
                    
                    Button {
                        onBuyNow()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "bolt.fill")
                                .font(.headline)
                                .foregroundColor(Color(.systemBackground))
                            Text("Buy Now")
                                .fontWeight(.bold)
                                .foregroundColor(Color(.systemBackground))
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.primary)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .buttonStyle(BorderlessButtonStyle()) 
                }
                .padding(30)
            }
            .padding(20)
        }
        .buttonStyle(.plain)
        .aspectRatio(1, contentMode: .fit)
    }
}
