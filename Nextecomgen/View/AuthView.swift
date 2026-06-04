import SwiftUI
import Lottie
struct AuthView: View {
    @FocusState private var focusedField: Field?
    @Binding var isShowingSignUpScreen: Bool
    @Binding var fullNameInput: String
    @Binding var emailInput: String
    @Binding var passwordInput: String
    @Binding var confirmPasswordInput: String
    @Binding var errorMessage: String
    var onAuthenticate: () -> Void
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    private var isEmailValid: Bool {
        let email = emailInput.trimmingCharacters(in: .whitespacesAndNewlines)
        return email.contains("@") &&
        email.contains(".") &&
        email.count > 5
    }
    private var isPasswordStrong: Bool {
        let password = passwordInput
        
        let hasMinLength = password.count >= 8
        let hasLetter = password.rangeOfCharacter(from: .letters) != nil
        let hasNumber = password.rangeOfCharacter(from: .decimalDigits) != nil
        
        return hasMinLength && hasLetter && hasNumber
    }
    private var isConfirmPasswordValid: Bool {
        guard isShowingSignUpScreen else { return true }
        return !confirmPasswordInput.isEmpty &&
        confirmPasswordInput == passwordInput
    }
    private var isNameValid: Bool {
        guard isShowingSignUpScreen else { return true }
        return !fullNameInput.trimmingCharacters(in: .whitespaces).isEmpty
    }
    private var isFormValid: Bool {
        let emailOK = isEmailValid
        let passwordOK = isPasswordStrong
        if isShowingSignUpScreen {
            return isNameValid &&
            emailOK &&
            passwordOK &&
            isConfirmPasswordValid
        } else {
            return emailOK && passwordOK
        }
    }
    var body: some View {
        ZStack {
            Color(hex: "011a09")
                .ignoresSafeArea()
            Circle()
                .fill(Color(hex: "033c15").opacity(0.15))
                .frame(width: 320)
                .offset(x: -120, y: -300)
            Circle()
                .fill(Color(hex: "033c15").opacity(0.15))
                .frame(width: 260)
                .offset(x: 140, y: -220)
            VStack(spacing: 0) {
                Spacer()
                LottieView(name: "boy_hide")
                    .frame(width: 260, height: 260)
                Spacer()
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .center, spacing: 8) {
                        Text(isShowingSignUpScreen ? "Create Account" : "Welcome Back")
                            .font(.system(size: 34, weight: .bold))
                            .frame(maxWidth: .infinity)
                        Text(isShowingSignUpScreen ? "Create your account to continue" : "Sign in to your account")
                            .font(.system(size: 15))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity)
                    }
                    VStack(spacing: 16) {
                        if isShowingSignUpScreen {
                            ModernTextField(
                                icon: "person",
                                placeholder: "Full Name",
                                text: $fullNameInput
                            )
                            .focused($focusedField, equals: .fullName)
                            .submitLabel(.next)
                            .onSubmit {
                                focusedField = .email
                            }
                        }
                        ModernTextField(
                            icon: "envelope",
                            placeholder: "Email Address",
                            text: $emailInput
                        )
                        .focused($focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .password
                        }
                        PasswordField(
                            icon: "lock",
                            placeholder: "Password",
                            text: $passwordInput,
                            showPassword: $showPassword
                        )
                        .focused($focusedField, equals: .password)
                        .submitLabel(isShowingSignUpScreen ? .next : .done)
                        .onSubmit {
                            if isShowingSignUpScreen {
                                focusedField = .confirmPassword
                            } else {
                                focusedField = nil
                            }
                        }
                        if isShowingSignUpScreen {
                            PasswordField(
                                icon: "lock.shield",
                                placeholder: "Confirm Password",
                                text: $confirmPasswordInput,
                                showPassword: $showConfirmPassword
                            )
                            .focused($focusedField, equals: .confirmPassword)
                            .submitLabel(.done)
                            .onSubmit {
                                focusedField = nil
                            }
                        }
                    }
                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                    Button {
                        onAuthenticate()
                    } label: {
                        Text(isShowingSignUpScreen ? "Create Account" : "Login")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 60)
                            .background(isFormValid ? Color.freshMint : Color.gray.opacity(0.4))
                            .clipShape(Capsule())
                    }
                    .disabled(!isFormValid)
                    HStack {
                        Spacer()
                        
                        Button {
                            withAnimation(.spring()) {
                                isShowingSignUpScreen.toggle()
                                errorMessage = ""
                            }
                            focusedField = isShowingSignUpScreen ? .fullName : .email
                            
                        } label: {
                            Text(
                                isShowingSignUpScreen
                                ? "Already have an account? Sign In"
                                : "Don't have an account? Sign Up"
                            )
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color(hex: "024818"))
                        }
                        
                        Spacer()
                    }
                }
                .padding(28)
                .background(.white)
                .clipShape(RoundedRectangle(cornerRadius: 36))
                .shadow(color: .black.opacity(0.08), radius: 30, x: 0, y: 15)
                .padding(.horizontal, 22)
                .padding(.bottom, 30)
            }
        }
        .onAppear {
            focusedField = isShowingSignUpScreen ? .fullName : .email
        }
    }
}

struct ModernTextField: View {
    
    let icon: String
    let placeholder: String
    
    @Binding var text: String
    
    var body: some View {
        
        HStack(spacing: 14) {
            
            Image(systemName: icon)
                .foregroundColor(.black)
            
            TextField(placeholder, text: $text)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never).foregroundColor(.black)
        }
        .padding(.horizontal, 18)
        .frame(height: 58)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: "cfecba"))
        )
    }
}
struct PasswordField: View {
    
    let icon: String
    let placeholder: String
    
    @Binding var text: String
    @Binding var showPassword: Bool
    
    var body: some View {
        
        HStack(spacing: 14) {
            
            Image(systemName: icon)
                .foregroundColor(.black)
            
            Group {
                
                if showPassword {
                    
                    TextField(
                        placeholder,
                        text: $text
                    ).foregroundColor(.black)
                    
                } else {
                    
                    SecureField(
                        placeholder,
                        text: $text
                    ).foregroundColor(.black)
                }
            }
            
            Button {
                
                showPassword.toggle()
                
            } label: {
                Image(
                    systemName:
                        showPassword
                    ? "eye.slash"
                    : "eye"
                )
                .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 18)
        .frame(height: 58)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: "cfecba"))
        )
    }
}
struct LottieView: UIViewRepresentable {
    let name: String
    func makeUIView(context: Context) -> UIView {
        let view = UIView(frame: .zero)
        let animationView = LottieAnimationView(name: name)
        animationView.contentMode = .scaleAspectFit
        animationView.loopMode = .loop
        animationView.play()
        animationView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(animationView)
        NSLayoutConstraint.activate([
            animationView.widthAnchor.constraint(
                equalTo: view.widthAnchor
            ),
            animationView.heightAnchor.constraint(
                equalTo: view.heightAnchor
            ),
            animationView.centerXAnchor.constraint(
                equalTo: view.centerXAnchor
            ),
            animationView.centerYAnchor.constraint(
                equalTo: view.centerYAnchor
            )
        ])
        return view
    }
    func updateUIView(
        _ uiView: UIView,
        context: Context
    ) { }
}
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted
        )
        var int: UInt64 = 0
        Scanner(string: hex)
            .scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = (
                int >> 16,
                int >> 8 & 0xFF,
                int & 0xFF
            )
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
