import SwiftUI
struct AuthView: View {
    @Binding var isShowingSignUpScreen: Bool
    @Binding var fullNameInput: String
    @Binding var emailInput: String
    @Binding var usernameInput: String
    @Binding var passwordInput: String
    @Binding var confirmPasswordInput: String
    @Binding var errorMessage: String
    @State private var isSecured: Bool = true
    var onAuthenticate: () -> Void
    var body: some View {
        VStack {
            Spacer()
            Image("Image")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
                .padding(.bottom, 10)
            VStack(spacing: 14) {
                if isShowingSignUpScreen {
                    HStack {
                        Image(systemName: "person.text.rectangle").foregroundColor(.deepEmerald.opacity(0.5))
                        TextField("Full Name", text: $fullNameInput)
                            .disableAutocorrection(true)
                            .textContentType(.name)
                    }.padding().background(Color.lightSageBg).cornerRadius(12)
                    HStack {
                        Image(systemName: "envelope").foregroundColor(.deepEmerald.opacity(0.5))
                        TextField("Email Address", text: $emailInput)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .disableAutocorrection(true)
                            .textContentType(.emailAddress)
                    }.padding().background(Color.lightSageBg).cornerRadius(12)
                }
                if !isShowingSignUpScreen {
                    HStack {
                        Image(systemName: "envelope").foregroundColor(.deepEmerald.opacity(0.5))
                        TextField("Email Address", text: $emailInput)
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                            .disableAutocorrection(true)
                            .textContentType(.emailAddress)
                    }.padding().background(Color.lightSageBg).cornerRadius(12)
                }
                HStack {
                    Image(systemName: "lock")
                        .foregroundColor(.deepEmerald.opacity(0.5))
                    if isSecured {
                        SecureField("Password", text: $passwordInput)
                            .textContentType(.none)
                            .disableAutocorrection(true)
                    } else {
                        TextField("Password", text: $passwordInput)
                            .textContentType(.none)
                            .disableAutocorrection(true)
                    }
                    Button(action: {
                        isSecured.toggle()
                    }) {
                        Image(systemName: isSecured ? "eye" : "eye.slash")
                            .foregroundColor(.deepEmerald)
                    }
                }
                .padding()
                .background(Color.lightSageBg)
                .cornerRadius(12)

                if isShowingSignUpScreen {
                    HStack {
                        Image(systemName: "lock.shield").foregroundColor(.deepEmerald.opacity(0.5))
                        if isSecured {
                            SecureField("Confirm Password", text: $confirmPasswordInput)
                                .textContentType(.none)
                                .disableAutocorrection(true)
                        } else {
                            TextField("Confirm Password", text: $confirmPasswordInput)
                                .textContentType(.none)
                                .disableAutocorrection(true)
                        }
                        Button(action: {
                            isSecured.toggle()
                        }) {
                            Image(systemName: isSecured ? "eye" : "eye.slash")
                                .foregroundColor(.deepEmerald)
                        }
                    }.padding().background(Color.lightSageBg).cornerRadius(12).transition(.opacity)
                }
            }
            .padding(.horizontal)
            if !errorMessage.isEmpty {
                Text(errorMessage).foregroundColor(.red).font(.system(.caption, design: .rounded)).bold()
            }
            Button(action: onAuthenticate) {
                Text(isShowingSignUpScreen ? "Sign Up" : "LogIn")
                    .font(.headline)
                    .bold()
                    .foregroundColor(.white)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity)
                    .background(passwordInput.count < 8 ? Color.deepEmerald.opacity(0.5) : Color.deepEmerald)
                    .clipShape(Capsule())
                    .shadow(color: Color.deepEmerald.opacity(0.8), radius: 8, x: 0, y: 5)
            }
            .disabled(passwordInput.count < 8)
            .padding(.horizontal)
            Button(action: {
                withAnimation {
                    isShowingSignUpScreen.toggle()
                    errorMessage = ""
                    passwordInput = ""
                    confirmPasswordInput = ""
                    fullNameInput = ""
                    emailInput = ""
                }
            }) {
                Text(isShowingSignUpScreen ? "Back to LogIn" : "Create Account").font(.subheadline).fontWeight(.semibold).foregroundColor(.freshMint)
            }.padding(.top, 5)
            Spacer()
        }
        .padding(.vertical)
    }
}
