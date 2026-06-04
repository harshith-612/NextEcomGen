import SwiftUI
struct Address: Identifiable, Codable, Equatable {
    var id = UUID()
    var value: String
}
struct ProfileView: View {
    @Binding var selectedTab: AppTab
    let savedUsername: String
    
    @State private var loggedInFullName: String = ""
    @State private var loggedInEmail: String = ""
    @State private var currentUserAddresses: [Address] = []
    
    @Binding var isAddingAddress: Bool
    @Binding var newAddressInput: String
    @Binding var editingAddressID: UUID?
    @Binding var editingText: String
    @FocusState private var isAddressFieldFocused: Bool
    var onLogOut: () -> Void
    
    @State private var isEditingProfile = false
    @State private var tempFullName = ""
    @State private var tempEmail = ""
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            ScrollView {
                VStack(spacing: 18) {
                    VStack(spacing: 4) {
                        Text("NextEcomGEN")
                            .font(.largeTitle.bold())
                            .foregroundColor(.freshMint)
                        Text("Account Dashboard")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 10)
                    
                    profileCard
                    ordersCard
                    addressCard
                    logoutCard
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            loadUserProfile()
        }
    }
    
    private func resolvedUsername() -> String {
        let username = savedUsername.isEmpty ? (LocalDatabaseManager.shared.getCurrentUser() ?? "") : savedUsername
        return username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    private func loadUserProfile() {
        let username = resolvedUsername()
        guard !username.isEmpty else { return }
        
        let profile = LocalDatabaseManager.shared.getUserDetails(username: username)
        
        self.loggedInFullName = profile["fullName"] ?? "User Account"
        self.loggedInEmail = profile["email"] ?? username
        self.tempFullName = self.loggedInFullName
        self.tempEmail = self.loggedInEmail
        
        let rawAddresses = LocalDatabaseManager.shared.getAddresses(for: username)
        self.currentUserAddresses = rawAddresses.map { Address(value: $0) }
    }
    
    private func saveProfileDataSecurely() {
        let username = resolvedUsername()
        guard !username.isEmpty else { return }
        LocalDatabaseManager.shared.updateUserProfile(name: loggedInFullName, email: loggedInEmail, for: username)
    }
    
    private func saveAddressesSecurely() {
        let username = resolvedUsername()
        guard !username.isEmpty else { return }
        LocalDatabaseManager.shared.saveAddresses(currentUserAddresses.map { $0.value }, for: username)
    }
    
    private var profileCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text("PROFILE")
                    .font(.caption)
                    .foregroundColor(.gray)
                Spacer()
                Button {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    if isEditingProfile {
                        loggedInFullName = tempFullName
                        loggedInEmail = tempEmail
                        saveProfileDataSecurely()
                    } else {
                        tempFullName = loggedInFullName
                        tempEmail = loggedInEmail
                    }
                    isEditingProfile.toggle()
                } label: {
                    Text(isEditingProfile ? "Done" : "Edit")
                        .font(.subheadline.bold())
                        .foregroundColor(.freshMint)
                }
            }
            Divider()
            if isEditingProfile {
                VStack(spacing: 10) {
                    TextField("Full Name", text: $tempFullName)
                        .padding()
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(12)
                    TextField("Email", text: $tempEmail)
                        .padding()
                        .background(Color.gray.opacity(0.15))
                        .cornerRadius(12)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(loggedInFullName)
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                    Text(loggedInEmail)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.12))
        .cornerRadius(18)
    }
    
    private var ordersCard: some View {
        NavigationLink(destination: OrderHistoryView(username: resolvedUsername())) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Order History")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("View your past orders")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color.gray.opacity(0.12))
            .cornerRadius(18)
        }
    }
    
    private var addressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Saved Addresses")
                    .font(.headline)
                Spacer()
                Button { isAddingAddress = true } label: {
                    Image(systemName: "plus.circle.fill").foregroundColor(.freshMint)
                }
            }
            Divider()
            if currentUserAddresses.isEmpty {
                Text("No saved addresses").foregroundColor(.gray)
            }
            ForEach(currentUserAddresses) { address in
                VStack(spacing: 10) {
                    if editingAddressID == address.id {
                        HStack {
                            TextField("Edit address", text: $editingText)
                                .padding().background(Color.gray.opacity(0.2)).cornerRadius(12).focused($isAddressFieldFocused)
                            Button("Save") {
                                isAddressFieldFocused = false
                                if let index = currentUserAddresses.firstIndex(of: address) {
                                    currentUserAddresses[index].value = editingText
                                    saveAddressesSecurely()
                                }
                                editingAddressID = nil
                            }
                            .foregroundColor(.freshMint)
                        }
                    } else {
                        HStack {
                            Image(systemName: "mappin.circle.fill").foregroundColor(.freshMint)
                            Text(address.value).foregroundColor(.primary)
                            Spacer()
                            Button {
                                editingAddressID = address.id
                                editingText = address.value
                                isAddressFieldFocused = true
                            } label: {
                                Image(systemName: "pencil").foregroundColor(.gray)
                            }
                        }
                    }
                    Divider()
                }
            }
            if isAddingAddress {
                HStack {
                    TextField("New address", text: $newAddressInput).padding().background(Color.gray.opacity(0.15)).cornerRadius(12)
                    Button("Add") {
                        guard !newAddressInput.isEmpty else { return }
                        currentUserAddresses.append(Address(value: newAddressInput))
                        saveAddressesSecurely()
                        newAddressInput = ""
                        isAddingAddress = false
                    }
                    .foregroundColor(.freshMint)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.12))
        .cornerRadius(18)
    }
    
    private var logoutCard: some View {
        Button(role: .destructive) { onLogOut() } label: {
            Text("Log Out \(Image(systemName: "rectangle.portrait.and.arrow.right"))")
                .font(.headline.bold()).foregroundColor(.white).frame(maxWidth: .infinity).padding().background(Color.red).cornerRadius(18)
        }
    }
}
