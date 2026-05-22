import SwiftUI

struct HomeView: View {
    @Binding var storeProducts: [Product]
    @Binding var shoppingCart: [Product]
    @Binding var selectedTab: AppTab
    @Binding var isShowingPaymentScreen: Bool
    @Binding var orderHistory: [AdminTransaction]
    var usernameInput: String
    @Binding var selectedProduct: Product?
    @Binding var fullNameInput: String
    @State private var searchText = ""
    @State private var isLoading = false
    @State private var navigateToPayment: Bool = false
    @State private var isPaymentVerified: Bool = false
    @State private var selectedCategory: String = "All"
    
    private var uniqueCategories: [String] {
        let rawCategories = storeProducts.map { $0.category.capitalized }
        let distinctSet = Set(rawCategories)
        return ["All"] + distinctSet.sorted()
    }
    
    var filteredIndices: [Int] {
        storeProducts.indices.filter { index in
            let product = storeProducts[index]
            
            let matchesCategory = (selectedCategory == "All") ||
            (product.category.caseInsensitiveCompare(selectedCategory) == .orderedSame)
            
            let matchesSearchText = searchText.isEmpty ||
            product.name.localizedCaseInsensitiveContains(searchText)
            
            return matchesCategory && matchesSearchText
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                
                Image(systemName: "magnifyingglass").foregroundColor(.gray)
                TextField("Search products...", text: $searchText)
                    .autocorrectionDisabled(true).cornerRadius(20)
                    
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill").foregroundColor(.gray)
                    }
                }
            }
            .padding()
            .shadow(color: Color.black.opacity(0.04), radius: 4, x: 0, y: 2)
            .background(Color(.white))
            .padding([.horizontal, .top])
            .padding(.bottom, 8)
            
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(uniqueCategories, id: \.self) { category in
                        Text(category)
                            .font(.subheadline.bold())
                            .padding(.vertical, 8)
                            .padding(.horizontal, 16)
                            .background(selectedCategory == category ? Color.deepEmerald : Color(.systemGray6))
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                            .cornerRadius(20)
                            .onTapGesture {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                    selectedCategory = category
                                }
                            }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 4)
            
            ScrollView {
                if isLoading {
                    VStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .scaleEffect(1.2)
                        Text("Loading Products...")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 100)
                } else if filteredIndices.isEmpty && !searchText.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No items match '\(searchText)'")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                } else if filteredIndices.isEmpty && searchText.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "bag.badge.questionmark")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("No items available in '\(selectedCategory)'")
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                } else {
                    VStack(spacing: 16) {
                        ForEach(filteredIndices, id: \.self) { index in
                            ProductCardRow(
                                product: $storeProducts[index],
                                shoppingCart: $shoppingCart,
                                onImageTapped: {
                                    selectedProduct = storeProducts[index]
                                    selectedTab = .search
                                }
                            )
                        }

                    }
                    .padding()
                }
            }
        }
        .task {
            await fetchLiveProducts()
        }
    }
    
    func fetchLiveProducts() async {
        guard storeProducts.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }
        
        guard let url = URL(string: "https://dummyjson.com") else { return }
        
        do {
            let config = URLSessionConfiguration.default
            config.requestCachePolicy = .returnCacheDataElseLoad
            let session = URLSession(configuration: config)
            
            let (data, _) = try await session.data(from: url)
            let decodedData = try JSONDecoder().decode(DummyJSONRoot.self, from: data)
            
            await MainActor.run {
                self.storeProducts = decodedData.products
            }
        } catch {
            print("Failed to load products: \(error)")
        }
    }
}
struct ProductCardRow: View {
    @Binding var product: Product
    @Binding var shoppingCart: [Product]
    var onImageTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            AsyncImage(url: URL(string: product.imageName)) { phase in
                switch phase {
                case .empty:
                    VStack { ProgressView() }
                        .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 140)
                        .background(Color.lightSageBg)
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                        .frame(height: 140)
                        .frame(maxWidth: .infinity)
                case .failure:
                    VStack { Image(systemName: "photo").foregroundColor(.gray) }
                        .frame(maxWidth: .infinity, minHeight: 140, maxHeight: 140)
                        .background(Color.lightSageBg)
                @unknown default:
                    EmptyView()
                }
            }
            .cornerRadius(12)
            .contentShape(Rectangle())
            .onTapGesture { onImageTapped() }
            
            Text(product.name).font(.system(.headline, design: .rounded))
            
            HStack(spacing: 55) {
                Text(product.price)
                    .font(.system(.subheadline, design: .rounded))
                    .bold()
                    .foregroundColor(.deepEmerald)
                
                CartItemCounter(product: product, shoppingCart: $shoppingCart)
            }
            .padding(.horizontal, 10)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
    }
}
