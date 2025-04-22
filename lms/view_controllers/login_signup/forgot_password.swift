import SwiftUI
import Supabase

struct ForgotPasswordView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var isSubmitting = false
    @State private var showSuccessAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    let colorScheme: ColorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                ReusableBackground(colorScheme: colorScheme)
                
                VStack(spacing: 24) {
                    VStack {
                        Image(systemName: "lock.open.fill")
                            .font(.system(size: 45))
                            .foregroundColor(Color.primary(for: colorScheme))
                            .padding()
                            .background(
                                Circle()
                                    .fill(Color.primary(for: colorScheme).opacity(0.1))
                                    .frame(width: 110, height: 110)
                            )
                    }
                    .padding(.top, 30)
                    .padding(.bottom, 10)
                    
                    // Header
                    VStack(spacing: 8) {
                        Text("Forgot Password?")
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(Color.text(for: colorScheme))
                        
                        Text("Don't worry! It happens. Please enter the address associated with your account.")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                    
                    // Email Field
                    VStack {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 16))
                                .foregroundColor(Color.text(for: colorScheme).opacity(0.5))
                                .frame(width: 24)
                            
                            TextField("Email ID", text: $email)
                                .font(.system(size: 16, design: .rounded))
                                .textContentType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .keyboardType(.emailAddress)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.text(for: colorScheme).opacity(0.1), lineWidth: 1)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.text(for: colorScheme).opacity(0.03))
                                )
                        )
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    
                    Button {
                        withAnimation {
                            submitAction()
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.secondary(for: colorScheme))
                            
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.2)
                            } else {
                                Text("Submit")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(height: 54)
                        .padding(.horizontal, 24)
                    }
                    .disabled(isSubmitting || email.isEmpty)
                    .opacity(email.isEmpty ? 0.7 : 1)
                    
                    Spacer()
                }
                .navigationBarItems(
                    leading: Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(Color.text(for: colorScheme))
                            .padding(8)
                            .background(
                                Circle()
                                    .fill(Color.text(for: colorScheme).opacity(0.1))
                            )
                    }
                )
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .alert("Success", isPresented: $showSuccessAlert) {
            Button("OK") {
                presentationMode.wrappedValue.dismiss()
            }
        } message: {
            Text("Password reset email has been sent. Please check your inbox.")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func submitAction() {
        isSubmitting = true
        
        Task {
            do {
                // Send password reset email
                try await supabase.auth.resetPasswordForEmail(
                    email,
                    redirectTo: URL(string: "io.supabase.user-management://reset-password")!
                )
                
                await MainActor.run {
                    isSubmitting = false
                    showSuccessAlert = true
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}

struct ForgotPasswordView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForgotPasswordView(colorScheme: .light)
                .previewDisplayName("Light Mode")
            
            ForgotPasswordView(colorScheme: .dark)
                .previewDisplayName("Dark Mode")
        }
    }
} 
