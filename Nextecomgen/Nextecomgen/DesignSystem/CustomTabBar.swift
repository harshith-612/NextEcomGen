import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: AppTab
    @Binding var shoppingCart: [CartItem]
    
    @Namespace private var animation
    var badgeCount: Int? = nil
    
    private var totalDisplayBadge: Int {
        if let badgeCount = badgeCount {
            return badgeCount
        }
        
        var total = 0
        for item in shoppingCart {
            total += item.quantity
        }
        return total
    }
    
    var body: some View {
        HStack(spacing: 0) {
            tabButton(tab: .home, title: "Home", icon: "house.fill")
            
            tabButton(
                tab: .cart,
                title: "Cart",
                icon: "bag.fill",
                badge: totalDisplayBadge
            )
            
            tabButton(tab: .profile, title: "Profile", icon: "person.crop.circle.fill")
        }
        .padding(.top, 10)
        .padding(.bottom, 10)
        .padding(.horizontal, 12)
        .background {
            ZStack {
                Capsule()
                    .fill(Color.freshMint.opacity(0.15))
                    .frame(width: 56, height: 32)
                    .matchedGeometryEffect(id: "liquidPill", in: animation, isSource: false)
                
                Capsule()
                    .fill(.ultraThinMaterial)
            }
            .clipShape(Capsule())
        }
        .overlay(
            Capsule()
                .stroke(Color(.secondarySystemBackground).opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 10)
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
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
            
            withAnimation(.spring(response: 0.38, dampingFraction: 0.65, blendDuration: 0)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                
                ZStack(alignment: .topTrailing) {
                    ZStack {
                        Color.clear
                            .frame(width: 56, height: 32)
                            .matchedGeometryEffect(
                                id: "liquidPill",
                                in: animation,
                                isSource: selectedTab == tab
                            )
                        
                        Image(systemName: icon)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(selectedTab == tab ? .freshMint : .secondary)
                            .scaleEffect(selectedTab == tab ? 1.12 : 1.0)
                    }
                    .frame(width: 60, height: 36)
                    
                    if let badge = badge, badge > 0 {
                        Text("\(badge)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.primary)
                            .frame(minWidth: 16, minHeight: 16)
                            .padding(2)
                            .background(Color.red)
                            .clipShape(Circle())
                            .offset(x: 6, y: -6)
                    }
                }
                
                Text(title)
                    .font(.system(size: 11, weight: selectedTab == tab ? .bold : .medium))
                    .foregroundColor(selectedTab == tab ? .freshMint : .secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
