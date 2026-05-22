import SwiftUI
struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    @Binding var shoppingCart: [Product]
    var isAdminUser: Bool = false
    var body: some View {
        HStack {
            Button(action: { selectedTab = .home }) {
                tabElement(title: "Home", icon: "house.fill", tab: .home)
            }
            Button(action: { selectedTab = .cart }) {
                VStack(spacing: 4) {
                    ZStack {
                        Image(systemName: "bag.fill").font(.system(size: 20))
                        if !shoppingCart.isEmpty {
                            Text("\(shoppingCart.count)")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 12, y: -8)
                        }
                    }
                    Text("Cart").font(.system(size: 10, weight: .bold))
                }
                .foregroundColor(selectedTab == .cart ? .freshMint : .gray.opacity(0.7))
                .frame(maxWidth: .infinity)
            }
            Button(action: { selectedTab = .profile }) {
                tabElement(title: "Profile", icon: "person.crop.circle.fill", tab: .profile)
            }
        }
        .padding(.vertical, 10)
        .overlay(Divider(), alignment: .top)
    }
    private func tabElement(title: String, icon: String, tab: AppTab) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 20))
            Text(title).font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(selectedTab == tab ? .freshMint : .gray.opacity(0.7))
        .frame(maxWidth: .infinity)
    }
}
