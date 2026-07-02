import SwiftUI

struct SearchView: View {
    @Binding var selectedTab: AppTab
    @Binding var searchText: String
    @Binding var storeProducts: [Product]
    @Binding var shoppingCart: [Product]
    @State private var selectedCategory: String = "All"
    
    private var uniqueCategories: [String] {
        let rawCategories = storeProducts.map { $0.category.capitalized }
        let distinctSet = Set(rawCategories)
        return ["All"] + distinctSet.sorted()
    }
    
    var filteredProducts: [Product] {
        storeProducts.filter { product in
            let matchesSearchText = searchText.isEmpty || product.name.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = (selectedCategory == "All") || (product.category.caseInsensitiveCompare(selectedCategory) == .orderedSame)
            return matchesSearchText && matchesCategory
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Search products...", text: $searchText)
                    .disableAutocorrection(true)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding([.horizontal, .top])
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
            .padding(.vertical, 10)
            ScrollView {
                if filteredProducts.isEmpty {
                    VStack(spacing: 16) {
                        Spacer(minLength: 40)
                        
                        LottieView(name: "search")
                            .frame(width: 180, height: 180)
                        
                        Text("No products found")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                } else {
                    VStack(spacing: 16) {
                        ForEach(filteredProducts, id: \.id) { product in
                            HStack(spacing: 16) {
                                Image(product.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 50, height: 50)
                                    .background(Color.lightSageBg)
                                    .cornerRadius(8)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(product.name)
                                        .font(.headline)
                                    Text("₹\(product.price, specifier: "%.2f")")
                                        .font(.subheadline)
                                        .foregroundColor(.deepEmerald)
                                        .bold()
                                }
                                
                                Spacer()
                                
                                Button(action: { withAnimation { shoppingCart.append(product) } }) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundColor(.freshMint)
                                }
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                        }
                    }
                    .padding()
                }
            }
        }
    }
}
