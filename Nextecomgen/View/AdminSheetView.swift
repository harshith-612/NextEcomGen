/*import SwiftUI
import Foundation

struct AdminSheetView: View {

    @Binding var fullNameInput: String
    @Binding var emailInput: String
    @Binding var passwordInput: String
    @Binding var confirmPasswordInput: String
    @Binding var isShowingAdminSheet: Bool
    @Binding var orderHistory: [AdminTransaction]
    @Binding var currentUserOrderHistory: [OrderHistoryItem]
    var onLogOut: () -> Void

    var body: some View {

        NavigationView {

            ZStack {

                Color(red: 0.07, green: 0.07, blue: 0.08)
                    .ignoresSafeArea()

                ScrollView {

                    VStack(alignment: .leading, spacing: 20) {

                        HStack(spacing: 10) {

                            Image(systemName: "clock.badge.checkmark.fill")
                                .foregroundColor(.orange)

                            Text("Verify Incoming Transactions")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                        .padding(.top, 16)

                        if orderHistory.isEmpty {

                            emptyStateView

                        } else {

                            LazyVStack(spacing: 16) {

                                ForEach(orderHistory) { order in
                                    transactionCard(for: order)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Admin Dashboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {

                ToolbarItem(placement: .navigationBarTrailing) {

                    Button(action: {

                        withAnimation {
                            onLogOut()
                        }

                    }) {

                        Text("Log Out")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.red)
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    // MARK: EMPTY VIEW

    private var emptyStateView: some View {

        VStack(spacing: 12) {

            Spacer(minLength: 50)

            Image(systemName: "tray.fill")
                .font(.system(size: 42))
                .foregroundColor(.gray.opacity(0.5))

            Text("No reference codes waiting review")
                .font(.subheadline)
                .foregroundColor(.gray)
                .italic()

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    // MARK: TRANSACTION CARD

    private func transactionCard(for order: AdminTransaction) -> some View {

        VStack(alignment: .leading, spacing: 14) {

            // TOP SECTION

            HStack {

                Text(order.orderIDString)
                    .font(.headline)
                    .foregroundColor(.white)

                Spacer()

                Text("₹\(order.totalAmount, specifier: "%.2f")")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(
                        Color(red: 0.3, green: 0.85, blue: 0.4)
                    )
            }

            Divider()
                .background(Color.white.opacity(0.1))

            // USER DETAILS

            VStack(alignment: .leading, spacing: 10) {

                HStack(alignment: .top) {

                    Label("Customer:", systemImage: "person.fill")
                        .foregroundColor(.gray)

                    VStack(alignment: .leading, spacing: 4) {

                        Text(
                            order.buyerFullName.isEmpty
                            ? (
                                order.buyerUsername.isEmpty
                                ? "Unknown User"
                                : order.buyerUsername
                            )
                            : order.buyerFullName
                        )
                        .foregroundColor(.white)
                        .fontWeight(.semibold)

                        if !order.buyerUsername.isEmpty {

                            Text("@\(order.buyerUsername)")
                                .foregroundColor(.cyan)
                                .font(.caption)
                        }
                    }

                    Spacer()
                }
                .font(.subheadline)

                // UTR

                HStack(alignment: .top) {

                    Label("UTR ID:", systemImage: "doc.text.fill")
                        .foregroundColor(.gray)

                    Text(order.transactionID)
                        .fontWeight(.medium)
                        .foregroundColor(.cyan)
                        .textSelection(.enabled)

                    Spacer()
                }
                .font(.subheadline)
            }

            // BUTTONS

            HStack(spacing: 12) {

                Button(action: {

                    approveAndResolve(order)

                }) {

                    HStack {

                        Image(systemName: "checkmark.circle.fill")

                        Text("Approve")
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        Color(red: 0.3, green: 0.85, blue: 0.4)
                    )
                    .cornerRadius(10)
                }
                .buttonStyle(.plain)

                Button(action: {

                    resolveTransaction(order)

                }) {

                    HStack {

                        Image(systemName: "xmark.circle.fill")

                        Text("Reject")
                    }
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.red.opacity(0.15))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(
                                Color.red.opacity(0.3),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 6)
        }
        .padding(16)
        .background(
            Color(red: 0.12, green: 0.12, blue: 0.14)
        )
        .cornerRadius(16)
        .shadow(
            color: Color.black.opacity(0.2),
            radius: 10,
            x: 0,
            y: 4
        )
    }
    private func approveAndResolve(_ order: AdminTransaction) {

        let productNamesArray = order.associatedProducts.map { $0.name }

        let confirmedOrder = OrderHistoryItem(
            id: UUID(),
            itemNames: productNamesArray,
            totalAmount: Double(order.totalAmount),
            dateString: Date().formatted(date: .abbreviated, time: .omitted),
            status: .placed
        )

        LocalDatabaseManager.shared.adminApproveAndSaveOrder(
            confirmedOrder: confirmedOrder,
            customerUsername: order.buyerUsername
        )

        resolveTransaction(order)
    }

    private func resolveTransaction(_ order: AdminTransaction) {

        if let index = orderHistory.firstIndex(where: {
            $0.id == order.id
        }) {

            withAnimation(
                .spring(
                    response: 0.4,
                    dampingFraction: 0.8
                )
            ) {

                _ = orderHistory.remove(at: index)
            }

            LocalDatabaseManager.shared
                .savePendingTransactions(orderHistory)
        }
    }
}
*/
