import SwiftUI
struct CheckoutView: View {
    @Binding var shoppingCart: [CartItem]
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
                    .foregroundColor(Color(.systemBackground))
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(shoppingCart, id: \.id) { item in
                            HStack(spacing: 15) {
                                AsyncImage(url: URL(string: item.imageName)) { phase in
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
                                        .foregroundColor(Color(.systemBackground))
                                        .fontWeight(.bold)
                                    Text("\(item.price)")
                                        .foregroundColor(.freshMint)
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
                            .foregroundColor(Color(.systemBackground))
                    }
                    Button {
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                    } label: {
                        Text("Proceed Payment")
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(22)
                    }
                }
                .padding()
            }
            .padding(.top, 30)
        }
    }
}

