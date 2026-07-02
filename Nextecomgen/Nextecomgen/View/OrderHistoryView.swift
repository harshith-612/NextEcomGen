import SwiftUI
import Foundation
struct OrderItem: Codable, Identifiable {
    var id: Int { productId }
    let productId: Int
    let orderId: Int
    let name: String
    let price: Double
    let imageName: String
    let productDescription: String
    let category: String
}
struct Order: Codable, Identifiable {
    let id: Int
    let userId: String
    let date: String
    let status: String
    let totalAmount: Double
    let items: [OrderItem]
}
enum OrderStatus: String {
    case pending
    case placed
    case preparing
    case outForDelivery
    case delivered
}
func mapStatus(_ status: String) -> OrderStatus {
    return OrderStatus(rawValue: status.lowercased()) ?? .pending
}
final class OrderService {
    static let shared = OrderService()
    private init() {}
    let baseURL = "http://127.0.0.1:8000"
    func fetchOrders(token: String) async throws -> [Order] {
        let url = URL(string: "\(baseURL)/users/orders/")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              200..<300 ~= http.statusCode else {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode([Order].self, from: data)
    }
}
struct OrderHistoryView: View {
    
    @State private var orders: [Order] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    private var token: String {
        LocalDatabaseManager.shared.getAuthToken() ?? ""
    }
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        
        Group {
            
            if isLoading {
                ProgressView("Loading Orders...")
            }
            
            else if orders.isEmpty {
                emptyView
            }
            
            else {
                List {
                    ForEach(orders) { order in
                        
                        let statusEnum = mapStatus(order.status)
                        
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(order.items.map { $0.name }.joined(separator: ", "))
                                        .font(.headline)
                                    
                                    Text(order.date)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Text("₹\(order.totalAmount, specifier: "%.2f")")
                                    .font(.headline.bold())
                            }
                            HStack(spacing: 6) {
                                Image(systemName: statusIcon(statusEnum))
                                Text(statusEnum.rawValue.capitalized)
                                    .font(.caption.bold())
                            }
                            .foregroundColor(statusColor(statusEnum))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(statusColor(statusEnum).opacity(0.15))
                            .clipShape(Capsule())
                            OrderTrackingView(status: statusEnum)
                        }
                        .padding(.vertical, 8)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Order History")
        .toolbar {
            
        }
        .task {
            await loadOrders()
        }
    }
    
    private func loadOrders() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let fetched = try await OrderService.shared.fetchOrders(token: token)
            self.orders = fetched.reversed()
        } catch {
            self.errorMessage = error.localizedDescription
            print("Error:", error)
        }
    }
    
    private var emptyView: some View {
        VStack(spacing: 12) {
            Image(systemName: "cart.badge.questionmark")
                .font(.system(size: 50))
                .foregroundColor(.gray)
            
            Text("No orders placed yet.")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func statusColor(_ status: OrderStatus) -> Color {
        switch status {
        case .pending: return .gray
        case .placed: return .blue
        case .preparing: return .orange
        case .outForDelivery: return .purple
        case .delivered: return .green
        }
    }
    
    private func statusIcon(_ status: OrderStatus) -> String {
        switch status {
        case .pending: return "clock"
        case .placed: return "cart.badge.plus"
        case .preparing: return "fork.knife"
        case .outForDelivery: return "bicycle"
        case .delivered: return "checkmark.circle.fill"
        }
    }
}

struct OrderTrackingView: View {
    
    let status: OrderStatus
    
    private let steps: [OrderStatus] = [
        .placed,
        .preparing,
        .outForDelivery,
        .delivered
    ]
    
    var body: some View {
        
        let currentIndex = steps.firstIndex(of: status) ?? 0
        
        HStack(spacing: 0) {
            
            ForEach(0..<steps.count, id: \.self) { index in
                
                VStack(spacing: 4) {
                    
                    Circle()
                        .fill(index <= currentIndex ? Color.green : Color.gray.opacity(0.3))
                        .frame(width: 16, height: 16)
                    
                    Text(steps[index].rawValue.capitalized)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                
                if index < steps.count - 1 {
                    Rectangle()
                        .fill(index < currentIndex ? Color.green : Color.gray.opacity(0.3))
                        .frame(height: 3)
                        .padding(.horizontal, 4)
                }
            }
        }
        .padding(.top, 6)
    }
}
