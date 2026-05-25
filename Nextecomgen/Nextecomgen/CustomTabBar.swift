import SwiftUI
struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    @Binding var shoppingCart: [Product]
    @Namespace private var animation
    var body: some View {
        HStack(spacing: 0) {
            tabButton(tab: .home, title: "Home", icon: "house.fill")
            tabButton(tab: .cart, title: "Cart", icon: "bag.fill", badge: shoppingCart.count)
            tabButton(tab: .profile, title: "Profile", icon: "person.crop.circle.fill")
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal)
        .padding(.bottom, 10)
    }
    @ViewBuilder
    private func tabButton(
        tab: AppTab,
        title: String,
        icon: String,
        badge: Int? = nil
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .soft).impactOccurred()

            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    if selectedTab == tab {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.freshMint.opacity(0.2))
                            .frame(width: 44, height: 44)
                            .matchedGeometryEffect(id: "tabIndicator", in: animation)
                    }
                    Image(systemName: icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(selectedTab == tab ? .freshMint : .gray.opacity(0.7))
                        .scaleEffect(selectedTab == tab ? 1.15 : 1.0)
                }
                Text(title)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(selectedTab == tab ? .freshMint : .gray.opacity(0.7))
                if let badge = badge, badge > 0 {
                    Text("\(badge)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white)
                        .padding(5)
                        .background(Color.red)
                        .clipShape(Circle())
                        .offset(x: 18, y: -38)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
}
