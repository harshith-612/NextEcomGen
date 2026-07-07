import SwiftUI

struct ProfileView: View {
    @Binding var selectedTab: AppTab
    let savedUsername: String
    @State private var showFullAddress: Address? = nil
    @State private var showAddForm = false
    @State private var tempAddress = Address(
        id: nil,
        name: "",
        phoneNumber: "",
        houseNumber: "",
        street: "",
        pincode: "",
        state: ""
    )
    @State private var profileImage: UIImage? = nil
    @State private var showImagePicker = false
    @State private var profileImageURL: String = ""
    @State private var loggedInFullName: String = ""
    @State private var loggedInEmail: String = ""
    @State private var currentUserAddresses: [Address] = []
    @Binding var isAddingAddress: Bool
    @Binding var newAddressInput: String
    @Binding var editingAddressID: String?
    @Binding var editingText: String
    @FocusState private var isAddressFieldFocused: Bool
    var onLogOut: () -> Void
    @State private var isEditingProfile = false
    @State private var tempFullName = ""
    @State private var tempEmail = ""
    @State private var showAlert = false
    private var token: String {
        LocalDatabaseManager.shared.getAuthToken() ?? ""
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("NextEcomGEN")
                                    .font(.largeTitle.bold())
                                    .foregroundColor(.freshMint)

                                Text("Account Dashboard")
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                Button {

                                    let vc = TodoViewController()

                                    if let scene =
                                        UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                       let window =
                                        scene.windows.first,
                                       let root =
                                        window.rootViewController {


                                        var top = root

                                        while let presented = top.presentedViewController {
                                            top = presented
                                        }


                                        let nav =
                                        UINavigationController(rootViewController: vc)

                                        nav.modalPresentationStyle = .fullScreen

                                        top.present(nav, animated:true)
                                    }


                                } label: {

                                    Image(systemName:"checklist")
                                        .font(.system(size:20))
                                        .padding(10)
                                        .background(Color.gray.opacity(0.15))
                                        .clipShape(Circle())

                                }
                            }

                            Spacer()

                            Button {
                                let storyboard = UIStoryboard(name: "Main", bundle: nil)

                                guard let vc = storyboard.instantiateViewController(
                                    withIdentifier: "ThemeViewController"
                                ) as? ThemeViewController else {
                                    return
                                }

                                vc.modalPresentationStyle = .fullScreen

                                if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                   let window = scene.windows.first,
                                   let rootVC = window.rootViewController {

                                    var topVC = rootVC
                                    while let presented = topVC.presentedViewController {
                                        topVC = presented
                                    }

                                    topVC.present(vc, animated: true)
                                }
                            } label: {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .padding(10)
                                    .background(Color.gray.opacity(0.15))
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.top, 10)
                        .padding(.horizontal)

                        profileCard
                        ordersCard
                        addressCard
                        logoutCard
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                loadUserProfile()
                loadProfileFromBackend()
                loadAddressesFromBackend()
            }
        }
        .preferredColorScheme(ThemeManager.shared.currentTheme == .dark ? .dark : .light)
    }


    private func resolvedUsername() -> String {
        let username = savedUsername.isEmpty
        ? (LocalDatabaseManager.shared.getCurrentUser() ?? "")
        : savedUsername
        
        return username.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }
    
    private func loadUserProfile() {
        let username = resolvedUsername()
        guard !username.isEmpty else { return }
        
        tempFullName = loggedInFullName
        tempEmail = loggedInEmail
    }
    
    private func loadProfileFromBackend() {
        Task {
            guard let url = URL(string: "http://127.0.0.1:8000/users/") else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "accept")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let http = response as? HTTPURLResponse,
                      http.statusCode == 200 else { return }
                
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                DispatchQueue.main.async {
                    self.loggedInFullName = json?["fullName"] as? String ?? self.loggedInFullName
                    self.loggedInEmail = json?["email"] as? String ?? self.loggedInEmail
                    self.profileImageURL = json?["profileImage"] as? String ?? ""
                }
                
            } catch {
                print("Profile fetch error:", error)
            }
        }
    }
    
    private func saveProfileDataSecurely() {
        Task {
            guard let url = URL(string: "http://127.0.0.1:8000/users/") else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "PATCH"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = [
                "full_name": loggedInFullName,
                "email": loggedInEmail
            ]
            
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            do {
                _ = try await URLSession.shared.data(for: request)
            } catch {
                print("Profile update error:", error)
            }
        }
    }
    
    private func loadAddressesFromBackend() {
        Task {
            guard let url = URL(string: "http://127.0.0.1:8000/users/addresses") else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue("application/json", forHTTPHeaderField: "accept")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            do {
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let http = response as? HTTPURLResponse,
                      http.statusCode == 200 else { return }
                
                let list = try JSONDecoder().decode([AddressDTO].self, from: data)
                
                DispatchQueue.main.async {
                    self.currentUserAddresses = list.map {
                        Address(
                            id: $0.id,
                            name: $0.name,
                            phoneNumber: $0.phoneNumber,
                            houseNumber: $0.houseNumber,
                            street: $0.street,
                            pincode: $0.pincode,
                            state: $0.state
                        )
                    }
                }
                
            } catch {
                print("Address fetch error:", error)
            }
        }
    }
    private func addAddressToBackend(_ address: Address) {
        Task {
            guard let url = URL(string: "http://127.0.0.1:8000/users/addresses") else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("application/json", forHTTPHeaderField: "accept")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = [
                "name": address.name,
                "phoneNumber": address.phoneNumber,
                "houseNumber": address.houseNumber,
                "street": address.street,
                "pincode": address.pincode,
                "state": address.state
            ]
            
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            do {
                _ = try await URLSession.shared.data(for: request)
                loadAddressesFromBackend()
            } catch {
                print(error)
            }
        }
    }
    private func updateAddressOnBackend(id: String, address: Address) {
        Task {
            guard let url = URL(string: "http://127.0.0.1:8000/users/addresses/\(id)") else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            let body: [String: Any] = [
                "name": address.name,
                "phoneNumber": address.phoneNumber,
                "houseNumber": address.houseNumber,
                "street": address.street,
                "pincode": address.pincode,
                "state": address.state
            ]
            
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            
            do {
                _ = try await URLSession.shared.data(for: request)
                loadAddressesFromBackend()
            } catch {
                print(error)
            }
        }
    }
    
    private func deleteAddress(id: String) {
        Task {
            guard let url = URL(string: "http://127.0.0.1:8000/users/addresses/\(id)") else { return }
            
            var request = URLRequest(url: url)
            request.httpMethod = "DELETE"
            request.setValue("application/json", forHTTPHeaderField: "accept")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            
            do {
                _ = try await URLSession.shared.data(for: request)
                loadAddressesFromBackend()
            } catch {
                print("Delete error:", error)
            }
        }
    }
    
    private var profileCard: some View {
        VStack(spacing: 12) {
            profileHeader
            HStack {
                Text("PROFILE")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button {
                    if isEditingProfile {
                        saveProfileDataSecurely()
                        tempFullName = loggedInFullName
                        tempEmail = loggedInEmail
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
                    TextField("Full Name", text: $loggedInFullName)
                        .textFieldStyle(.roundedBorder)
                        .autocorrectionDisabled(true)
                    
                    TextField("Email", text: $loggedInEmail)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.emailAddress)
                        .autocorrectionDisabled(true)
                }
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text(loggedInFullName)
                        .font(.title3.bold())
                    
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
    private var profileHeader: some View {
        VStack(spacing: 10) {
            
            ZStack(alignment: .bottomTrailing) {
                Group {
                    if let image = profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else if !profileImageURL.isEmpty {
                        AsyncImage(url: URL(string: profileImageURL)) { image in
                            image.resizable().scaledToFill()
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .foregroundColor(.gray)
                    }
                }
                .frame(width: 110, height: 110)
                .clipShape(Circle())
                Button {
                    showImagePicker = true
                } label: {
                    Image(systemName: "camera.fill")
                        .padding(8)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(radius: 2)
                }
            }
            
            Text("Profile Photo")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 10)
    }
    private var ordersCard: some View {
        NavigationLink(destination: OrderHistoryView()) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Order History").bold()
                    Text("View your past orders")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
            }
            .padding()
            .foregroundColor(.freshMint)
            .background(Color.gray.opacity(0.12))
            .cornerRadius(18)
        }
    }
    
    private var addressCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Saved Addresses")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    tempAddress = Address(id: nil, name: "", phoneNumber: "", houseNumber: "", street: "", pincode: "", state: "")
                    showAddForm = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                }
            }
            
            Divider()
            ForEach(currentUserAddresses, id: \.id) { address in
                HStack(alignment: .top) {
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(address.houseNumber)
                            .font(.headline)
                        
                        Text(address.street)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 14) {
                        
                        Button {
                            showFullAddress = address
                        } label: {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                        }
                        
                        Button {
                            tempAddress = address
                            showAddForm = true
                        } label: {
                            Image(systemName: "pencil")
                                .foregroundColor(.orange)
                        }
                        
                        Button {
                            if let id = address.id {
                                deleteAddress(id: id)
                            }
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.clear)
                        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
                )
            }
        }
        .padding()
        .background(Color.gray.opacity(0.10))
        .cornerRadius(18)
        .sheet(isPresented: $showAddForm) {
            ScrollView {
                VStack(spacing: 16) {
                    
                    Text("Address Details")
                        .font(.title2.bold())
                    
                    labeledField("Name", text: $tempAddress.name)
                    labeledField("Phone Number", text: $tempAddress.phoneNumber)
                    labeledField("House Number", text: $tempAddress.houseNumber)
                    labeledField("Street", text: $tempAddress.street)
                    labeledField("Pincode", text: $tempAddress.pincode)
                    labeledField("State", text: $tempAddress.state)
                    
                    Button {
                        if let id = tempAddress.id {
                            updateAddressOnBackend(id: id, address: tempAddress)
                        } else {
                            addAddressToBackend(tempAddress)
                        }
                        
                        showAddForm = false
                        loadAddressesFromBackend()
                    } label: {
                        Text("Save Address")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(Color(.systemBackground))
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
        }
        .sheet(item: $showFullAddress) { addr in
            ScrollView {
                VStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Full Address")
                            .font(.title2.bold())
                        
                        Text("Address details")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.blue.opacity(0.08))
                    )
                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("Contact")
                        
                        infoRow("Name", addr.name)
                        Divider()
                        infoRow("Phone", addr.phoneNumber)
                    }
                    .padding()
                    .background(cardBackground)
                    VStack(alignment: .leading, spacing: 12) {
                        sectionTitle("Address")
                        
                        infoRow("House No", addr.houseNumber)
                        Divider()
                        infoRow("Street", addr.street)
                        Divider()
                        infoRow("Pincode", addr.pincode)
                        Divider()
                        infoRow("State", addr.state)
                    }
                    .padding()
                    .background(cardBackground)
                }
                .padding()
            }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(image: $profileImage)
                .onDisappear {
                    if let img = profileImage {
                        uploadProfileImage(img)
                    }
                }
        }
    }
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.clear)
            .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
    }
    private func sectionTitle(_ title: String) -> some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.primary)
    }
    private func infoRow(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .fontWeight(.medium)
                .multilineTextAlignment(.trailing)
        }
    }
    private func labeledField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField("", text: text)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.3))
                )
                .autocorrectionDisabled(true)
        }
    }
    private func detailRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title + ":")
                .fontWeight(.semibold)
            
            Spacer()
            
            Text(value)
                .foregroundColor(.secondary)
        }
    }
    private var logoutCard: some View {
        Button(role: .destructive) {
            showAlert = true
        } label: {
            Text("Logout \(Image(systemName: "rectangle.portrait.and.arrow.right"))")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .foregroundColor(Color.white).bold()
                .cornerRadius(12)
        }
        .alert("Logout", isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                onLogOut()
            }
        }
    }
    private func uploadProfileImage(_ image: UIImage) {
        
        guard let imageData = image.jpegData(compressionQuality: 0.8),
              let url = URL(string: "http://127.0.0.1:8000/users/profile-image") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)",
                         forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"profile.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        URLSession.shared.uploadTask(with: request, from: body) { data, _, error in
            
            if let error = error {
                print("Upload error:", error)
                return
            }
            
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let url = json["imageUrl"] as? String else {
                return
            }
            
            DispatchQueue.main.async {
                self.profileImageURL = url
            }
            
        }.resume()
    }
}
