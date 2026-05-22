import SwiftUI

struct AdminTransaction: Identifiable {
    let id: UUID
    let orderIDString: String
    let totalAmount: Float
    let transactionID: String
    let date: Date
    let associatedProducts: [Nextecomgen.Product] 
    let buyerUsername: String
    @Binding var fullNameInput: String
}

struct AdminSheetView: View {
    @Binding var fullNameInput: String
    @Binding var emailInput: String
    @Binding var passwordInput: String
    @Binding var confirmPasswordInput: String
    @Binding var isShowingAdminSheet: Bool
    @Binding var storeProducts: [Nextecomgen.Product]
    @Binding var orderHistory: [AdminTransaction]
    @Binding var currentUserOrderHistory: [Order]
    
    var onSaveProduct: () -> Void
    var onLogOut: () -> Void
    
    @State private var adminSubTab: Int = 0
    
    private var isFormValid: Bool {
        !fullNameInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !emailInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !passwordInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        VStack(spacing: 0) {
            Picker("Admin View Selection", selection: $adminSubTab) {
                Text("Transactions").tag(0)
                Text("Add Product").tag(1)
                Text("Products").tag(2)
            }
            .pickerStyle(.segmented)
            .padding()
            
            if adminSubTab == 0 {
                List {
                    Section(header: Text("Verify The Transaction")) {
                        if orderHistory.isEmpty {
                            Text("No reference codes waiting review")
                                .foregroundColor(.gray).italic()
                        } else {
                            ForEach(orderHistory) { order in
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        Text(order.orderIDString).bold()
                                        Spacer()
                                        Text("₹\(order.totalAmount)").foregroundColor(.green).bold()
                                    }
                                    
                                    Text("User: \(fullNameInput)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    HStack {
                                        Text("UTR ID:")
                                            .font(.caption).foregroundColor(.secondary)
                                        Text(order.transactionID)
                                            .font(.caption).bold().foregroundColor(.blue).textSelection(.enabled)
                                    }
                                    HStack(spacing: 12) {
                                        Button(action: { approveAndResolve(order) }) {
                                            Text("Approve Payment")
                                                .font(.caption).bold().foregroundColor(.white)
                                                .padding(.horizontal, 14).padding(.vertical, 6)
                                                .background(Color.green).cornerRadius(6)
                                        }
                                        .buttonStyle(.plain)
                                        
                                        Button(action: { resolveTransaction(order) }) {
                                            Text("Reject")
                                                .font(.caption).bold().foregroundColor(.red)
                                                .padding(.horizontal, 12).padding(.vertical, 6)
                                                .background(Color.red.opacity(0.1)).cornerRadius(6)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.top, 4)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }.listStyle(.insetGrouped)
                
            } else if adminSubTab == 1 {
                Form {
                    Section(header: Text("Catalog Creation Details")) {
                        TextField("Product Name", text: $fullNameInput)
                        TextField("Description", text: $emailInput)
                        TextField("Price (e.g., 1200/-)", text: $passwordInput)
                            .keyboardType(.numbersAndPunctuation)
                        TextField("Image Asset Name", text: $confirmPasswordInput)
                    }
                    
                    Section {
                        Button(action: onSaveProduct) {
                            Text("Add Product to Catalog")
                                .bold().frame(maxWidth: .infinity, alignment: .center).foregroundColor(.white)
                        }
                        .disabled(!isFormValid)
                        .listRowBackground(isFormValid ? Color.green : Color(uiColor: .systemGray3))
                    }
                }
                
            } else {
                List {
                    Section(header: Text("Current Active Inventory")) {
                        if storeProducts.isEmpty {
                            Text("No catalog contents").foregroundColor(.gray).italic()
                        } else {
                            ForEach(storeProducts, id: \.name) { product in
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(product.name).font(.headline)
                                        Text(product.price).font(.subheadline).bold()
                                    }
                                    Spacer()
                                    Button(action: { removeProduct(product) }) {
                                        Text("Remove").font(.caption).bold().foregroundColor(.white)
                                            .padding(.horizontal, 12).padding(.vertical, 6)
                                            .background(Color.red).cornerRadius(6)
                                    }.buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }.listStyle(.insetGrouped)
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
                        .bold()
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private func removeProduct(_ product: Nextecomgen.Product) {
        if let index = storeProducts.firstIndex(where: { $0.name == product.name && $0.price == product.price }) {
            storeProducts.remove(at: index)
            LocalDatabaseManager.shared.saveProducts(storeProducts)
        }
    }
    private func approveAndResolve(_ order: AdminTransaction) {
        let productNamesArray = order.associatedProducts.map { $0.name }
        let confirmedOrder = Order(
            id: UUID(),
            dateString: Date().formatted(date: .abbreviated, time: .omitted),
            totalAmount: order.totalAmount,
            itemNames: productNamesArray
        )
        currentUserOrderHistory.append(confirmedOrder)
        LocalDatabaseManager.shared.saveOrderHistory(currentUserOrderHistory, for: order.buyerUsername)
        resolveTransaction(order)
    }
    
    private func resolveTransaction(_ order: AdminTransaction) {
        if let index = orderHistory.firstIndex(where: { $0.id == order.id }) {
            orderHistory.remove(at: index)
        }
    }
}
