import SwiftUI
import Combine

struct TwoFactorAuthView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.colorScheme) var colorScheme
    
    @State private var otpText: String = ""
    @State private var isVerifying: Bool = false
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    @State private var remainingTime: Int = 60
    
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
                    
                    Text("Enter the 6-digit verification code sent to your device")
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
                            Text("Resend Code")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(Color.accent(for: colorScheme))
                        }
                    }
                }
                .padding(.top, 24)
                
                Spacer()
            }
            .padding(.horizontal, 24)
        }
    }
    
    private func verifyCode() {
        isVerifying = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isVerifying = false
            
            if otpText == "123456" {
                print("Verification successful")
            } else {
                showError = true
                errorMessage = "Invalid verification code. Please try again."
                otpText = ""
            }
        }
    }
    
    private func resendCode() {
        remainingTime = 60
        otpText = ""
        showError = false
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
            TwoFactorAuthView()
                .environmentObject(ThemeManager())
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            TwoFactorAuthView()
                .environmentObject(ThemeManager())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
