import SwiftUI
struct HomeView: View {
    @Namespace private var animation
    @Binding var storeProducts: [Product]
    @Binding var shoppingCart: [Product]
    @Binding var selectedTab: AppTab
    @Binding var searchText: String

    @State private var selectedProduct: Product?
    @State private var showDetail = false
    @State private var selectedCategory = "All"
    @State private var showCheckout = false

    let columns = [
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18)
    ]
    var uniqueCategories: [String] {

        let categories = storeProducts.map {
            $0.category.capitalized
        }

        return ["All"] + Array(Set(categories)).sorted()
    }

    var filteredProducts: [Product] {
        storeProducts.filter { product in
            let categoryMatch =
            selectedCategory == "All" ||
            product.category.caseInsensitiveCompare(
                selectedCategory
            ) == .orderedSame
            let searchMatch =
            searchText.isEmpty ||
            product.name.localizedCaseInsensitiveContains(searchText)
            return categoryMatch && searchMatch
        }
    }

    var body: some View {

        ZStack(alignment: .bottomTrailing) {
            LinearGradient(
                colors: [
                    Color.black,
                    Color(.systemGray6)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {

                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 20) {

                        HStack {

                            VStack(alignment: .leading, spacing: 6) {

                                Text("Discover")
                                    .font(.system(size: 38, weight: .bold))
                                    .foregroundColor(.white)

                                Text("Premium Collection")
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            ZStack {

                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 55, height: 55)

                                Image(systemName: "bag.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                            }
                        }

                        HStack(spacing: 12) {

                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)

                            TextField(
                                "Search products...",
                                text: $searchText
                            )
                            .foregroundColor(.white)
                            .autocorrectionDisabled(true)

                            if !searchText.isEmpty {

                                Button {

                                    searchText = ""

                                } label: {

                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .clipShape(
                            RoundedRectangle(cornerRadius: 22)
                        )
                    }
                    .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {

                        HStack(spacing: 12) {

                            ForEach(uniqueCategories, id: \.self) { category in

                                Button {

                                    UIImpactFeedbackGenerator(
                                        style: .soft
                                    ).impactOccurred()

                                    withAnimation(.spring()) {
                                        selectedCategory = category
                                    }

                                } label: {

                                    Text(category)
                                        .fontWeight(.semibold)
                                        .foregroundColor(
                                            selectedCategory == category
                                            ? .black
                                            : .white
                                        )
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 10)
                                        .background(
                                            selectedCategory == category
                                            ? Color.white
                                            : Color.white.opacity(0.1)
                                        )
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    LazyVGrid(columns: columns, spacing: 20) {
                        ForEach(filteredProducts, id: \.id) { product in
                            let cartQuantity = shoppingCart.filter { $0.id == product.id }.count
                            
                            ProductCard(
                                quantity: cartQuantity,
                                product: product,
                                namespace: animation,
                                removeFromCart: {
                                    if let index = shoppingCart.firstIndex(where: { $0.id == product.id }) {
                                        withAnimation {
                                            _ = shoppingCart.remove(at: index)
                                        }
                                    }
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                },
                                onTap: {
                                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                        selectedProduct = product
                                        showDetail = true
                                    }
                                },
                                addToCart: {
                                    withAnimation {
                                        shoppingCart.append(product)
                                    }
                                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                }
                                
                            )
                        }
                    }
                    .padding()

                }
                .padding(.top)
            }
            /*Button {
                showCheckout = true
            } label: {
                ZStack(alignment: .topTrailing) {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 65, height: 65)

                    Image(systemName: "cart.fill")
                        .font(.title2)
                        .foregroundColor(.white)

                    if !shoppingCart.isEmpty {
                        Text("\(shoppingCart.count)")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(7)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 10, y: -10)
                    }
                }
            }
            .padding(25)
            .navigationDestination(isPresented: $showCheckout) {
                CheckoutView(shoppingCart: $shoppingCart)
            }*/

            if let selectedProduct,
               showDetail {

                ProductDetailView(
                    product: selectedProduct,
                    namespace: animation,
                    isShowing: $showDetail,
                    shoppingCart: $shoppingCart,
                    showCheckout: $showCheckout,
                    selectedTab: $selectedTab
                )
                .zIndex(10)
            }
        }
        .preferredColorScheme(.dark)
    }
}
struct ProductCard: View {
    let quantity: Int
    var product: Product

    var namespace: Namespace.ID
    var removeFromCart: () -> Void
    var onTap: () -> Void
    var addToCart: () -> Void

    @State private var isWishlisted = false
    @State private var animateHeart = false

    var body: some View {

        VStack(alignment: .leading, spacing: 14) {

            ZStack(alignment: .topTrailing) {

                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)

                VStack(spacing: 16) {

                    AsyncImage(
                        url: URL(string: product.imageName)
                    ) { phase in

                        switch phase {

                        case .empty:

                            SkeletonLoader()

                        case .success(let image):

                            image
                                .resizable()
                                .scaledToFit()
                                .frame(height: 140)
                                .matchedGeometryEffect(
                                    id: product.id,
                                    in: namespace
                                )

                        case .failure(_):

                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)

                        @unknown default:

                            EmptyView()
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {

                        Text(product.category.capitalized)
                            .font(.caption)
                            .foregroundColor(.gray)

                        Text(product.name)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(2)

                        HStack {

                            Text("₹\(product.price, specifier: "%.2f")")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            VStack{
                                
                                Spacer()
                                if quantity > 0 {
                                    HStack(spacing: 8) {
                                        Button(action: removeFromCart) {
                                            Image(systemName: "minus")
                                                .font(.subheadline.bold())
                                                .foregroundColor(.black)
                                                .padding(5)
                                                .background(Color.red)
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(.plain)
                                        Text("\(quantity)")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(minWidth: 20)
                                        Button(action: addToCart) {
                                            Image(systemName: "plus")
                                                .font(.subheadline.bold())
                                                .foregroundColor(.black)
                                                .padding(5)
                                                .background(Color.deepEmerald)
                                                .clipShape(Circle())
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(4)
                                    .background(Color.white.opacity(0.15))
                                    .clipShape(Capsule())
                                } else {
                                    Button(action: addToCart) {
                                        Image(systemName: "plus")
                                            .font(.headline)
                                            .foregroundColor(.black)
                                            .padding(5)
                                            .background(Color.white)
                                            .clipShape(Circle())
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                        }
                    }
                }
                .padding()
            }
            .frame(height: 310)

                    }
        .onTapGesture {
            onTap()
        }
    }
}
struct ProductDetailView: View {

    var product: Product
    var namespace: Namespace.ID
    
    @State private var navigateToDirectPayment = false
    @Binding var isShowing: Bool
    @Binding var shoppingCart: [Product]
    @Binding var showCheckout: Bool
    @Binding var selectedTab: AppTab
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color.black
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 25) {
                    AsyncImage(
                        url: URL(string: product.imageName)
                    ) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFit()
                                .matchedGeometryEffect(
                                    id: "\(product.id)_image",
                                    in: namespace
                                )
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
                            .foregroundColor(.green)

                        Text("""
Premium ecommerce experience with \
hero animations, glassmorphism UI, \
smooth transitions and premium styling.
""")
                        .foregroundColor(.gray)
                        Button {
                            shoppingCart.append(product)
                            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                        } label: {
                            Text("Add To Cart")
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(20)
                        }
                        Button {
                            shoppingCart.removeAll()
                            shoppingCart.append(product)
                            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                            isShowing = false
                            selectedTab = .cart
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
                                Text("No reviews available for this product.")
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
                withAnimation(.spring()) {
                    isShowing = false
                }
            } label: {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .padding()
        }
        .transition(.move(edge: .bottom))
    }
}

struct CheckoutView: View {

    @Binding var shoppingCart: [Product]

    var totalPrice: Double {

        shoppingCart.reduce(0) { result, item in

            let cleanPrice = String(item.price)
                .replacingOccurrences(of: "₹", with: "")

            return result + (Double(cleanPrice) ?? 0)
        }
    }

    var body: some View {

        ZStack {

            LinearGradient(
                colors: [
                    .black,
                    .gray.opacity(0.4)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 25) {

                Text("Checkout")
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                ScrollView {

                    VStack(spacing: 16) {

                        ForEach(shoppingCart, id: \.id) { item in

                            HStack(spacing: 15) {

                                AsyncImage(
                                    url: URL(string: item.imageName)
                                ) { phase in

                                    switch phase {

                                    case .success(let image):

                                        image
                                            .resizable()
                                            .scaledToFit()

                                    default:

                                        Color.gray
                                    }
                                }
                                .frame(width: 70, height: 70)
                                .background(.ultraThinMaterial)
                                .cornerRadius(18)

                                VStack(alignment: .leading) {

                                    Text(item.name)
                                        .foregroundColor(.white)
                                        .fontWeight(.bold)

                                    Text("\(item.price)")
                                        .foregroundColor(.green)
                                }

                                Spacer()
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(24)
                        }
                    }
                    .padding()
                }

                VStack(spacing: 14) {

                    HStack {

                        Text("Total")
                            .foregroundColor(.gray)

                        Spacer()

                        Text("₹\(totalPrice, specifier: "%.2f")")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }

                    Button {

                        UIImpactFeedbackGenerator(
                            style: .heavy
                        ).impactOccurred()

                    } label: {

                        Text("Proceed Payment")
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(22)
                    }
                }
                .padding()
            }
            .padding(.top, 30)
        }
        .preferredColorScheme(.dark)
    }
}
struct SkeletonLoader: View {

    @State private var shimmer = false

    var body: some View {

        RoundedRectangle(cornerRadius: 20)
            .fill(Color.gray.opacity(0.3))
            .overlay(

                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.4),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(25))
                .offset(
                    x: shimmer ? 300 : -300
                )
            )
            .onAppear {

                withAnimation(
                    .linear(duration: 1.2)
                    .repeatForever(
                        autoreverses: false
                    )
                ) {
                    shimmer = true
                }
            }
    }
}
