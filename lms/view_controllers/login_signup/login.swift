//
//  login.swift
//  lms
//
//  Created by Diptayan Jash on 17/04/25.
//
import DotLottie
import Foundation
import SwiftUI

enum LoginDestination: Identifiable {
    case admin, librarian, member

    var id: String {
        switch self {
        case .admin: return "admin"
        case .librarian: return "librarian"
        case .member: return "member"
        }
    }
}

// Group related state variables in a single class
class LoginState: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var showPassword = false
    @Published var isProcessing = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var currentUser: User?
    @Published var showLoginAnimation = false
    @Published var otpVerified = false

    // Navigation states
    @Published var showForgotPassword = false
    @Published var showSignup = false
    @Published var destination: LoginDestination?
    @Published var show2FA = false

    func setError(_ error: Error) {
        if let loginError = error as? LoginError {
            errorMessage = loginError.userMessage
        } else if let urlError = error as? URLError {
            errorMessage = "Network error: \(urlError.localizedDescription)"
        } else {
            errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
        }
        showError = true
    }
}

struct LoginView: View {
    @StateObject private var state = LoginState()
    @FocusState private var focusedField: AuthFieldType?
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appState: AppState

    @State private var isLandscape = UIDevice.current.orientation.isLandscape
    @State private var tempUser: (User, UserRole)?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ReusableBackground(colorScheme: colorScheme)

                ScrollViewReader { scrollProxy in
                    ScrollView(showsIndicators: false) {
                        Color.clear
                            .frame(height: 0)
                            .id("scrollDetector")

                        // Determine layout mode just once
                        let useHorizontalLayout = isLandscape || geometry.size.width > geometry.size.height

                        layoutView(geometry: geometry, isHorizontal: useHorizontalLayout)
                            .padding(.vertical, 20)
                            .frame(minHeight: geometry.size.height)
                    }
                    .coordinateSpace(name: "scrollView")
                    // Optimize scroll handling
                    .onChange(of: focusedField) { newValue in
                        if newValue != nil {
                            withAnimation {
                                scrollProxy.scrollTo("lottieAnimation", anchor: .top)
                            }
                        }
                    }
                }
                loginAnimationOverlay()
            }
            .sheet(isPresented: $state.showForgotPassword) {
                ForgotPasswordView(colorScheme: colorScheme)
            }
            .sheet(isPresented: $state.showSignup) {
                SignupContainerView()
            }
            .sheet(isPresented: $state.show2FA, onDismiss: {
                if state.otpVerified {
                    // Only proceed to destination if OTP was verified
                    if let (user, role) = tempUser {
                        state.destination = destinationForRole(role)
                        appState.currentUser = user
                        appState.currentUserRole = role
                        appState.isLoggedIn = true
                    }
                }
            }) {
                TwoFactorAuthView(email: state.email) { success in
                    state.otpVerified = success
                }
            }
            .fullScreenCover(item: $state.destination) { destination in
                switch destination {
                case .admin: AdminTabbar()
                case .librarian: LibrarianTabbar()
                case .member: UserTabbar()
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .alert("Login Error", isPresented: $state.showError) {
                Button("OK", role: .cancel) { 
                    state.showError = false
                    state.errorMessage = ""
                }
            } message: {
                Text(state.errorMessage)
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(Color.text(for: colorScheme))
            }
            // More efficient orientation change handling
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
                self.isLandscape = windowScene.interfaceOrientation.isLandscape
            }
            .onTapGesture {
                focusedField = nil
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    // Consolidated layout function that handles both orientations
    @ViewBuilder
    private func layoutView(geometry: GeometryProxy, isHorizontal: Bool) -> some View {
        if isHorizontal {
            HStack(alignment: .center, spacing: 20) {
                animationSection(geometry: geometry, isHorizontal: true)
                    .frame(width: geometry.size.width * 0.45)
                    .padding(.leading, 20)

                formSection(geometry: geometry, isHorizontal: true)
                    .frame(width: geometry.size.width * 0.45)
                    .padding(.trailing, 20)
            }
        } else {
            VStack(spacing: 30) {
                animationSection(geometry: geometry, isHorizontal: false)
                    .frame(height: 300)
                    .fixedSize(horizontal: false, vertical: true)

                formSection(geometry: geometry, isHorizontal: false)

                Spacer(minLength: UIScreen.main.bounds.height * 0.2)
            }
            .padding(.top, geometry.size.height * 0.05)
            .padding(.bottom, 24)
        }
    }

    // Create a new full-screen overlay view for the login animation
    @ViewBuilder
    private func loginAnimationOverlay() -> some View {
        if state.showLoginAnimation {
            ZStack {
                // Blurred background
                BlurView(style: .systemMaterial)
                    .edgesIgnoringSafeArea(.all)

                // Login animation centered
                DotLottieAnimation(
                    fileName: "shelfspace",
                    config: AnimationConfig(
                        autoplay: true,
                        loop: true,
                        mode: .bounce,
                        speed: 0.5
                    )
                )
                .view()
                .frame(width: 400, height: 400)
            }
            .transition(.opacity)
        }
    }

    // Add a BlurView struct if you don't have one already
    struct BlurView: UIViewRepresentable {
        var style: UIBlurEffect.Style

        func makeUIView(context: Context) -> UIVisualEffectView {
            return UIVisualEffectView(effect: UIBlurEffect(style: style))
        }

        func updateUIView(_ uiView: UIVisualEffectView, context: Context) {
            uiView.effect = UIBlurEffect(style: style)
        }
    }

    // Reusable animation section
    @ViewBuilder
    private func animationSection(geometry: GeometryProxy, isHorizontal: Bool) -> some View {
        VStack(alignment: .center, spacing: isHorizontal ? 0 : 10) {
            // Optimize animation rendering
            DotLottieAnimation(
                fileName: "bookStack",
                config: AnimationConfig(
                    autoplay: true,
                    loop: true,
                    mode: .bounce,
                    speed: 1.0
                )
            )
            .view()
            .frame(
                width: isHorizontal
                    ? min(geometry.size.width * 0.4, 300)
                    : min(geometry.size.width, 350),
                height: isHorizontal ? 300 : 350
            )
            .id("lottieAnimation")
            .padding(.leading, isHorizontal ? 0 : -30)

            VStack(spacing: 8) {
                Text("Welcome Back")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color.text(for: colorScheme))

                if !isHorizontal {
                    Text("Sign in to continue")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                        .padding(.bottom, 10)
                }
            }
            .frame(width: isHorizontal ? nil : geometry.size.width)
            .padding(.top, isHorizontal ? 0 : -90)
        }
    }

    @ViewBuilder
    private func formSection(geometry: GeometryProxy, isHorizontal: Bool) -> some View {
        VStack(spacing: isHorizontal ? 30 : 16) {
            if isHorizontal {
                Text("Sign in to continue")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 10)
            }

            VStack(spacing: 16) {
                CustomTextField(
                    text: $state.email,
                    placeholder: "Email ID",
                    iconName: "envelope.fill",
                    isSecure: false,
                    focusState: _focusedField,
                    colorScheme: colorScheme,
                    keyboardType: .emailAddress,
                    fieldType: .email
                )
                .focused($focusedField, equals: .email)
                .autocorrectionDisabled()
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)

                CustomTextField(
                    text: $state.password,
                    placeholder: "Password",
                    iconName: "lock.fill",
                    isSecure: !state.showPassword,
                    showSecureToggle: true,
                    secureToggleAction: { state.showPassword.toggle() },
                    focusState: _focusedField,
                    colorScheme: colorScheme, fieldType: .password
                )
                .focused($focusedField, equals: .password)
                .textContentType(.password)
            }
            .padding(.horizontal, isHorizontal ? 0 : 24)

            HStack {
                Spacer()
                Button {
                    withAnimation {
                        state.showForgotPassword = true
                    }
                } label: {
                    Text("Forgot Password?")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color.primary(for: colorScheme).opacity(0.6))
                }
            }
            .padding(.horizontal, isHorizontal ? 0 : 24)

            Button {
                withAnimation {
                    guard !state.isProcessing else { return }
                    loginAction()
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.primary(for: colorScheme).opacity(0.8))

                    if state.isProcessing {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                    } else {
                        Text("Login")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.text(for: colorScheme))
                    }
                }
                .frame(height: 54)
                .padding(.horizontal, isHorizontal ? 0 : 24)
            }
            .disabled(state.isProcessing || state.email.isEmpty || state.password.isEmpty)
            .opacity((state.email.isEmpty || state.password.isEmpty) ? 0.7 : 1)

            HStack(spacing: 4) {
                Text("New to Library?")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(Color.text(for: colorScheme).opacity(0.8))

                Button {
                    state.showSignup = true
                } label: {
                    Text("Register")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.primary(for: colorScheme).opacity(0.6))
                }
            }
            .padding(.top, 12)
        }
    }

    private func loginAction() {
        focusedField = nil
        state.isProcessing = true
        state.showError = false
        state.errorMessage = ""
        state.otpVerified = false

        withAnimation {
            state.showLoginAnimation = true
        }

        Task {
            do {
                let (user, role) = try await LoginManager.shared.login(email: state.email, password: state.password)
                
                await MainActor.run {
                    state.isProcessing = false
                    state.showLoginAnimation = false
                    tempUser = (user, role)
                    state.show2FA = true
                }
            } catch let error as LoginError {
                await MainActor.run {
                    state.isProcessing = false
                    state.showLoginAnimation = false
                    state.showError = true
                    state.errorMessage = error.userMessage
                    print("Login Error: \(error.userMessage)")
                }
            } catch let error as URLError {
                await MainActor.run {
                    state.isProcessing = false
                    state.showLoginAnimation = false
                    state.showError = true
                    state.errorMessage = "Network error: \(error.localizedDescription)"
                    print("Network Error: \(error.localizedDescription)")
                }
            } catch {
                await MainActor.run {
                    state.isProcessing = false
                    state.showLoginAnimation = false
                    state.showError = true
                    state.errorMessage = "An unexpected error occurred: \(error.localizedDescription)"
                    print("Unexpected Error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func destinationForRole(_ role: UserRole) -> LoginDestination {
        switch role {
        case .admin:
            return .admin
        case .librarian:
            return .librarian
        case .member:
            return .member
        }
    }
}

// Extension for LoginError to provide user-friendly messages
extension LoginError {
    var userMessage: String {
        switch self {
        case .invalidCredentials:
            return "Invalid email or password. Please try again."
        case .networkError:
            return "Network error. Please check your connection."
        case .roleNotFound:
            return "User role not found. Please contact support."
        case .unknownError:
            return "An unknown error occurred. Please try again later."
        case .tokenError:
            return "Token error. Please log in again."
        case .signupError:
            return "Signup error. Please try again."
        case .userInactive:
            return "Your account has been deactivated. Please contact your administrator."
        }
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoginView()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")

            LoginView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")

            // Add landscape previews
            LoginView()
                .preferredColorScheme(.light)
                .previewInterfaceOrientation(.landscapeLeft)
                .previewDisplayName("Landscape Light")

            LoginView()
                .preferredColorScheme(.dark)
                .previewInterfaceOrientation(.landscapeLeft)
                .previewDisplayName("Landscape Dark")
        }
    }
}
