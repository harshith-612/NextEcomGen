import SwiftUI
struct OrderHistoryItem: Identifiable, Codable {
    let id: UUID
    let itemNames: [String]
    let totalAmount: Double
    let dateString: String
    var status: OrderStatus
}
struct OrderHistoryView: View {
    @State private var orders: [OrderHistoryItem] = []
    let username: String
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        Group {
            if orders.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "cart.badge.questionmark")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("No orders placed yet.")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(orders) { order in
                        VStack(alignment: .leading, spacing: 14) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(order.itemNames.joined(separator: ", "))
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    Text("Date: \(order.dateString)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("₹\(order.totalAmount, specifier: "%.2f")")
                                    .font(.headline.bold())
                                    .foregroundColor(.primary)
                            }
                            HStack(spacing: 6) {
                                Image(systemName: statusIcon(for: order.status))
                                Text(order.status.rawValue)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(statusColor(for: order.status))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(statusColor(for: order.status).opacity(0.12))
                            .clipShape(Capsule())
                            OrderTrackingView(status: order.status)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Order History")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                }
            }
        }
        .onAppear {
            loadOrders()
        }
    }
    private func loadOrders() {
        let activeUser = username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let resolvedUser = activeUser.isEmpty ? (LocalDatabaseManager.shared.getCurrentUser() ?? "") : activeUser
        
        guard !resolvedUser.isEmpty else { return }
        let fetched = LocalDatabaseManager.shared.getOrderHistory(for: resolvedUser)
        self.orders = fetched.reversed()
    }
    private func statusColor(for status: OrderStatus) -> Color {
        switch status {
        case .placed: return .blue
        case .preparing: return .orange
        case .outForDelivery: return .purple
        case .delivered: return .green
        }
    }
    private func statusIcon(for status: OrderStatus) -> String {
        switch status {
        case .placed: return "cart.badge.plus"
        case .preparing: return "fork.knife"
        case .outForDelivery: return "bicycle"
        case .delivered: return "checkmark.circle.fill"
        }
    }
}
struct OrderTrackingView: View {
    let status: OrderStatus
    private let steps = ["Placed", "Preparing", "Out For Delivery", "Delivered"]
    @State private var count = 0
    @State private var secretBonusSteps = 0
    var body: some View {
        let currentEffectiveStep = status.step + secretBonusSteps
        HStack(spacing: 0) {
            ForEach(0..<steps.count, id: \.self) { index in
                VStack(spacing: 4) {
                    Circle()
                        .fill(index + 1 <= currentEffectiveStep ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 18, height: 18)
                        .overlay(
                            Image(systemName: "checkmark")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .opacity(index + 1 <= currentEffectiveStep ? 1 : 0)
                        )
                        .onTapGesture {
                            count += 1
                            if count >= 5 {
                                secretBonusSteps += 1
                                count = 0
                            }
                        }
                    Text(steps[index])
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }                
                if index < steps.count - 1 {
                    Rectangle()
                        .fill(index + 1 < currentEffectiveStep ? Color.green : Color.gray.opacity(0.3))
                        .frame(height: 3)
                        .padding(.horizontal, 4)
                }
            }
        }
        .padding(.top, 4)
    }
}
