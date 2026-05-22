import SwiftUI
struct ProfileView: View {
    @Binding var selectedTab: AppTab
    @Binding var usernameInput: String
    @Binding var loggedInFullName: String
    @Binding var loggedInEmail: String
    @Binding var currentUserOrderHistory: [Order]
    @Binding var currentUserAddresses: [String]
    @Binding var isAddingAddress: Bool
    @Binding var newAddressInput: String
    @Binding var editingAddressIndex: Int?
    @Binding var editingText: String
    var isAddressFieldFocused: FocusState<Bool>.Binding
    var onLogOut: () -> Void
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Account Management Dashboard").font(.subheadline.bold()).foregroundColor(.primary)
                Spacer()
            }
            .padding()
            List {
                Section {
                    HStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.fill").font(.system(size: 60)).foregroundColor(.freshMint)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(loggedInFullName).font(.title3).fontWeight(.bold)
                            Text(loggedInEmail).font(.subheadline).foregroundColor(.secondary)
                        }
                    }.padding(.vertical, 8)
                }
                Section(header: Text("Purchase Order History")) {
                    if currentUserOrderHistory.isEmpty {
                        Text("No orders placed yet.").font(.subheadline).foregroundColor(.secondary).padding(.vertical, 8)
                    } else {
                        ForEach(currentUserOrderHistory.reversed()) { order in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text("Order Completed").font(.subheadline).fontWeight(.bold).foregroundColor(.deepEmerald)
                                    Spacer()
                                    Text("\(order.totalAmount)").font(.subheadline).bold().foregroundColor(.freshMint)
                                }
                                Text("Date: \(order.dateString)").font(.caption2).foregroundColor(.gray)
                                Text("Items: \(order.itemNames.joined(separator: ", "))").font(.caption).foregroundColor(.secondary).lineLimit(1)
                            }.padding(.vertical, 6)
                        }
                    }
                }
                Section(header: Text("Saved Delivery Addresses (Swipe to Delete)")) {
                    if currentUserAddresses.isEmpty {
                        Text("No saved addresses found.").font(.subheadline).foregroundColor(.secondary)
                    } else {
                        ForEach(Array(currentUserAddresses.enumerated()), id: \.offset) { index, address in
                            if editingAddressIndex == index {
                                HStack {
                                    TextField("Edit Address", text: $editingText).font(.subheadline)
                                    Button("Update") {
                                        if !editingText.trimmingCharacters(in: .whitespaces).isEmpty {
                                            currentUserAddresses[index] = editingText
                                            LocalDatabaseManager.shared.saveAddresses(currentUserAddresses, for: loggedInEmail)
                                        }
                                        editingAddressIndex = nil
                                    }.foregroundColor(.freshMint).bold()
                                }
                            } else {
                                HStack {
                                    Label(address, systemImage: "mappin.and.ellipse").font(.subheadline)
                                    Spacer()
                                    Button(action: { editingAddressIndex = index; editingText = address }) {
                                        Image(systemName: "pencil").foregroundColor(.gray).font(.subheadline)
                                    }.buttonStyle(.plain)
                                }
                            }
                        }.onDelete(perform: deleteAddressItem)
                    }
                    if isAddingAddress {
                        HStack {
                            TextField("Enter delivery location...", text: $newAddressInput).font(.subheadline)
                                .focused(isAddressFieldFocused)
                                .onAppear { isAddressFieldFocused.wrappedValue = true }
                            Button("Save") {
                                if !newAddressInput.trimmingCharacters(in: .whitespaces).isEmpty {
                                    currentUserAddresses.append(newAddressInput)
                                    LocalDatabaseManager.shared.saveAddresses(currentUserAddresses, for: loggedInEmail)
                                    newAddressInput = ""
                                    isAddressFieldFocused.wrappedValue = false
                                    isAddingAddress = false
                                }
                            }.foregroundColor(.freshMint).bold()
                        }
                    } else {
                        Button(action: { isAddingAddress = true }) {
                            Label("Add New Address", systemImage: "plus.circle.fill").foregroundColor(.freshMint).font(.subheadline).fontWeight(.semibold)
                        }
                    }
                }
                Section {
                    Button(action: { withAnimation { onLogOut() } }) {
                        Label("Log Out from Device", systemImage: "rectangle.portrait.and.arrow.right").foregroundColor(.red).fontWeight(.bold)
                    }
                }
            }
        }
    }
    
    func deleteAddressItem(at offsets: IndexSet) {
        currentUserAddresses.remove(atOffsets: offsets)
        LocalDatabaseManager.shared.saveAddresses(currentUserAddresses, for: loggedInEmail)
    }
}
