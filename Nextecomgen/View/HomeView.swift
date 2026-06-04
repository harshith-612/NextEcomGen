import SwiftUI
struct HomeView: View {
    @Namespace private var animation
    @Binding var storeProducts: [Product]
    @Binding var shoppingCart: [Product]
    @Binding var selectedTab: AppTab
    @Binding var searchText: String
    @Binding var isShowing: Bool
    @Binding var isLoading: Bool
    @Binding var hasMoreData: Bool
    let onFetchNextBatch: () async -> Void
    @State private var selectedCategory = "All"
    @State private var showCheckout = false
    @State private var manuallyPaused = false
    var filteredProducts: [Product] {
        let search = searchText
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return storeProducts.filter { product in
            let categoryMatch =
            selectedCategory == "All" ||
            product.category.localizedCaseInsensitiveCompare(
                selectedCategory
            ) == .orderedSame
            let searchMatch =
            search.isEmpty ||
            product.name.localizedCaseInsensitiveContains(search)
            return categoryMatch && searchMatch
        }
    }
    var uniqueCategories: [String] {
        let categories = storeProducts.map {
            $0.category.trimmingCharacters(in: .whitespacesAndNewlines).capitalized
        }
        let unique = Set(categories).sorted()
        return ["All"] + unique
    }
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color.black,
                        Color(.systemGray6)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                VStack(spacing: 0) {
                    headerView
                    searchBar
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 24) {
                            categoryScrollView
                            if storeProducts.isEmpty {
                                skeletonSection
                            }
                            else if !searchText.isEmpty &&
                                        filteredProducts.isEmpty {
                                emptySearchSection
                            }
                            else {
                                productsSection
                            }
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 120)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
        .task {
            if storeProducts.isEmpty {
                await onFetchNextBatch()
            }
        }
    }
}
extension HomeView {
    private var headerView: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Discover")
                        .font(.system(size: 28, weight: .bold))
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
        }
        .padding(.horizontal)
        .padding(.top)
    }
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            TextField(
                "Search products...",
                text: $searchText
            )
            .foregroundColor(.white)
            .autocorrectionDisabled(true)
            .textInputAutocapitalization(.never)
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
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
    private var categoryScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(uniqueCategories, id: \.self) { category in
                    Button {
                        selectedCategory = category
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
            .padding(.vertical, 10)
        }
    }
    private var skeletonSection: some View {
        VStack(spacing: 18) {
            ForEach(0..<4, id: \.self) { _ in
                SkeletonLoader()
                    .frame(height: 220)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 18)
                    )
            }
        }
        .padding(.horizontal, 24)
    }
    private var emptySearchSection: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 55))
                .foregroundColor(.gray.opacity(0.7))
                .padding(.top, 40)
            Text("No Products Found")
                .font(.title3.bold())
                .foregroundColor(.white)
            Text(
                "We couldn't find matches for '\(searchText)'."
            )
            .font(.subheadline)
            .foregroundColor(.gray)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 32)
            Button {
                searchText = ""
                selectedCategory = "All"
            } label: {
                Text("Clear Filters")
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.white)
                    .clipShape(Capsule())
            }
        }
    }
    private var productsSection: some View {
        VStack(spacing: 18) {
            ForEach(filteredProducts) { product in
                let cartQuantity = shoppingCart.filter { $0.id == product.id }.count
                ProductCard(
                    quantity: cartQuantity,
                    product: product,
                    namespace: animation,
                    removeFromCart: {
                        if let index = shoppingCart.firstIndex(where: { $0.id == product.id }) {
                            shoppingCart.remove(at: index)
                        }
                    },
                    addToCart: {
                        shoppingCart.append(product)
                    },
                    onBuyNow: {
                        if shoppingCart.isEmpty {
                            shoppingCart.append(product)
                        }
                        isShowing = false
                        selectedTab = .cart
                    },
                    shoppingCart: $shoppingCart,
                    showCheckout: $showCheckout,
                    selectedTab: $selectedTab
                )
            }
            if isLoading {
                ProgressView()
                    .tint(.white)
                    .padding(.vertical)
            }
        }
    }

}
