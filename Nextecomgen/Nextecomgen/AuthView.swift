import SwiftUI
struct AuthView: View {
    @Binding var isShowingSignUpScreen: Bool
    @Binding var fullNameInput: String
    @Binding var emailInput: String
    @Binding var passwordInput: String
    @Binding var confirmPasswordInput: String
    @Binding var errorMessage: String
    @State private var isSecured: Bool = true
    var onAuthenticate: () -> Void
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.black, .gray.opacity(0.3)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            VStack {
                Spacer()
                VStack(spacing: 8) {
                    Image("Image")
                        .resizable().scaledToFit().frame(width: 80, height: 80).padding(15).background(Color.white).clipShape(Circle()).padding(10).background(.ultraThinMaterial).clipShape(Circle()).shadow(color: .freshMint.opacity(0.25), radius: 15, x: 0, y: 8)
                    Text(isShowingSignUpScreen ? "Create Account" : "Welcome Back")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 10)
                    Text(isShowingSignUpScreen ? "Join our premium ecosystem today" : "Sign in to continue your premium collection")
                        .font(.caption).foregroundColor(.gray).multilineTextAlignment(.center).padding(.horizontal, 40)
                }
                .padding(.bottom, 30)
                VStack(spacing: 16) {
                    if isShowingSignUpScreen {
                        HStack(spacing: 15) {
                            Image(systemName: "person.crop.circle.fill")
                                .foregroundColor(.freshMint)
                                .font(.title3)
                            TextField("Full Name", text: $fullNameInput)
                                .foregroundColor(.white)
                                .disableAutocorrection(true)
                                .textContentType(.name)
                        }
                        .padding().background(Color.white.opacity(0.06)).cornerRadius(16).transition(.move(edge: .top).combined(with: .opacity))
                    }
                    HStack(spacing: 15) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(.freshMint).font(.title3)
                        TextField("Email Address", text: $emailInput)
                            .foregroundColor(.white).autocapitalization(.none).keyboardType(.emailAddress).disableAutocorrection(true).textContentType(.emailAddress)
                    }
                    .padding().background(Color.white.opacity(0.06)).cornerRadius(16)
                    HStack(spacing: 15) {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.freshMint).font(.title3)
                        Group {
                            if isSecured {
                                SecureField("Password", text: $passwordInput)
                            } else {
                                TextField("Password", text: $passwordInput)
                            }
                        }
                        .foregroundColor(.white).textContentType(.none).disableAutocorrection(true)
                        Button {
                            isSecured.toggle()
                        } label: {
                            Image(systemName: isSecured ? "eye.fill" : "eye.slash.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .padding()
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(16)
                    if isShowingSignUpScreen {
                        HStack(spacing: 15) {
                            Image(systemName: "lock.shield.fill")
                                .foregroundColor(.freshMint)
                                .font(.title3)
                            Group {
                                if isSecured {
                                    SecureField("Confirm Password", text: $confirmPasswordInput)
                                } else {
                                    TextField("Confirm Password", text: $confirmPasswordInput)
                                }
                            }
                            .foregroundColor(.white)
                            .textContentType(.none)
                            .disableAutocorrection(true)
                            Button {
                                isSecured.toggle()
                            } label: {
                                Image(systemName: isSecured ? "eye.fill" : "eye.slash.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(16)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .cornerRadius(28)
                .padding(.horizontal, 20)
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.system(.caption, design: .rounded))
                        .bold()
                        .padding(.top, 10)
                }
                VStack(spacing: 16) {
                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onAuthenticate()
                    } label: {
                        Text(isShowingSignUpScreen ? "Sign Up" : "Log In")
                            .font(.headline)
                            .bold()
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(passwordInput.count < 8 ? Color.white.opacity(0.5) : Color.white)
                            .clipShape(Capsule())
                            .shadow(color: .white.opacity(passwordInput.count < 8 ? 0.0 : 0.15), radius: 10, x: 0, y: 5)
                    }
                    .disabled(passwordInput.count < 8)
                    Button {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            isShowingSignUpScreen.toggle()
                            errorMessage = ""
                            passwordInput = ""
                            confirmPasswordInput = ""
                            fullNameInput = ""
                            emailInput = ""
                        }
                    } label: {
                        Text(isShowingSignUpScreen ? "Already have an account? Log In" : "Don't have an account? Create one")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.freshMint)
                    }
                    .padding(.top, 5)
                }
                .padding(.horizontal, 20)
                .padding(.top, 25)
                Spacer()
            }
            .padding(.vertical)
        }
        .preferredColorScheme(.dark)
    }
}
