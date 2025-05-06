import SwiftUI
import Combine

struct TwoFactorAuthView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.dismiss) var dismiss
    
    let email: String
    let onVerification: (Bool) -> Void
    
    @State private var otpText: String = ""
    @State private var isVerifying: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var remainingTime: Int = 30
    @State private var isResending: Bool = false
    @State private var isGeneratingOTP: Bool = false
    
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    private var otpArray: [String] {
        let characters = Array(otpText)
        let stringArray = characters.map { String($0) }
        return stringArray + Array(repeating: "", count: max(0, 6 - stringArray.count))
    }
    
    var body: some View {
        ZStack {
            ReusableBackground(colorScheme: colorScheme)
            
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Two-Factor Authentication")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Color.text(for: colorScheme))
                    
                    Text("Enter the 6-digit verification code sent to \(email)")
                        .font(.system(size: 16))
                        .foregroundColor(Color.secondary(for: colorScheme))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .padding(.top, 40)
                
                // OTP Fields
                HStack(spacing: 12) {
                    ForEach(0..<6, id: \.self) { index in
                        OTPBox(text: index < otpArray.count ? otpArray[index] : "",
                               isFocused: index == otpText.count,
                               colorScheme: colorScheme)
                    }
                }
                .padding(.top, 20)
                .overlay(
                    TextField("", text: $otpText)
                        .keyboardType(.numberPad)
                        .onChange(of: otpText) { newValue in
                            // Limit to 6 digits
                            if newValue.count > 6 {
                                otpText = String(newValue.prefix(6))
                            }
                            
                            // Filter out non-numbers
                            let filtered = newValue.filter { "0123456789".contains($0) }
                            if filtered != newValue {
                                otpText = filtered
                            }
                        }
                        .accentColor(.clear)
                        .foregroundColor(.clear)
                        .opacity(0.1)  // Almost invisible but still functional
                )
                
                if showError {
                    Text(errorMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.red)
                        .padding(.top, 8)
                }
                
                Button(action: verifyCode) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accent(for: colorScheme))
                            .frame(height: 56)
                        
                        if isVerifying {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Verify")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .disabled(isVerifying || otpText.count < 6)
                .opacity(otpText.count == 6 ? 1.0 : 0.7)
                .padding(.top, 32)
                
                VStack(spacing: 4) {
                    Text("Didn't receive the code?")
                        .font(.system(size: 14))
                        .foregroundColor(Color.secondary(for: colorScheme))
                    
                    if remainingTime > 0 {
                        Text("Resend code in \(remainingTime)s")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(Color.primary(for: colorScheme))
                            .onReceive(timer) { _ in
                                if remainingTime > 0 {
                                    remainingTime -= 1
                                }
                            }
                    } else {
                        Button(action: resendCode) {
                            if isResending {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color.accent(for: colorScheme)))
                                    .scaleEffect(0.8)
                            } else {
                                Text("Resend Code")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color.accent(for: colorScheme))
                            }
                        }
                        .disabled(isResending)
                    }
                }
                .padding(.top, 24)
                
                if isGeneratingOTP {
                    Text("Sending verification code...")
                        .font(.caption)
                        .foregroundColor(Color.secondary(for: colorScheme))
                        .padding(.top, 8)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
        .onAppear {
            generateInitialOTP()
        }
    }
    
    private func generateInitialOTP() {
        isGeneratingOTP = true
        
        Task {
            do {
                print("🔄 Generating initial OTP for email: \(email)")
                let success = try await LoginManager.shared.generateOTP(email: email)
                
                await MainActor.run {
                    isGeneratingOTP = false
                    if !success {
                        showError = true
                        errorMessage = "Failed to send verification code. Please try again."
                    }
                }
            } catch {
                print("❌ Error generating initial OTP: \(error)")
                await MainActor.run {
                    isGeneratingOTP = false
                    showError = true
                    errorMessage = "An error occurred while sending the verification code. Please try again."
                }
            }
        }
    }
    
    private func verifyCode() {
        isVerifying = true
        showError = false
        
        Task {
            do {
                let success = try await LoginManager.shared.verifyOTP(email: email, otp: otpText)
                if success {
                    await MainActor.run {
                        onVerification(true)
                        dismiss()
                    }
                } else {
                    await MainActor.run {
                        showError = true
                        errorMessage = "Invalid verification code. Please try again."
                        otpText = ""
                        isVerifying = false
                        onVerification(false)
                    }
                }
            } catch {
                await MainActor.run {
                    showError = true
                    errorMessage = "An error occurred. Please try again."
                    otpText = ""
                    isVerifying = false
                    onVerification(false)
                }
            }
        }
    }
    
    private func resendCode() {
        isResending = true
        showError = false
        
        Task {
            do {
                print("🔄 Resending OTP for email: \(email)")
                let success = try await LoginManager.shared.generateOTP(email: email)
                await MainActor.run {
                    if success {
                        remainingTime = 60
                        otpText = ""
                    } else {
                        showError = true
                        errorMessage = "Failed to resend code. Please try again."
                    }
                    isResending = false
                }
            } catch {
                print("❌ Error resending OTP: \(error)")
                await MainActor.run {
                    showError = true
                    errorMessage = "An error occurred. Please try again."
                    isResending = false
                }
            }
        }
    }
}

// MARK: - OTP Box Component
struct OTPBox: View {
    let text: String
    let isFocused: Bool
    let colorScheme: ColorScheme
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .stroke(isFocused
                        ? Color.accent(for: colorScheme)
                        : Color.secondary(for: colorScheme).opacity(0.3),
                        lineWidth: 2)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.TabbarBackground(for: colorScheme))
                )
            
            if text.isEmpty {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isFocused
                          ? Color.accent(for: colorScheme).opacity(0.2)
                          : Color.secondary(for: colorScheme).opacity(0.1))
                    .frame(width: 10, height: 10)
            } else {
                Text(text)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(Color.text(for: colorScheme))
            }
        }
        .frame(width: 50, height: 60)
    }
}

// MARK: - Preview
struct TwoFactorAuthView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TwoFactorAuthView(email: "example@example.com") { _ in }
                .environmentObject(ThemeManager())
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            TwoFactorAuthView(email: "example@example.com") { _ in }
                .environmentObject(ThemeManager())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
