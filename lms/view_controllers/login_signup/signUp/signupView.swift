import SwiftUI

struct signupView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: SignupModel
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var showImagePicker = false
    @FocusState private var focusedField: AuthFieldType?
    @Environment(\.colorScheme) private var colorScheme
    
    // Add state for showing user exists alert
    @State private var showUserExistsAlert = false

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ReusableBackground(colorScheme: colorScheme)

                ScrollView {
                    VStack(spacing: 30) {
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.primary(for: colorScheme).opacity(0.1))
                                    .frame(width: 120, height: 120)

                                if let image = viewModel.selectedImage {
                                    Image(uiImage: image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipShape(Circle())
                                } else {
                                    Image(systemName: "person.badge.plus")
                                        .font(.system(size: 60))
                                        .foregroundColor(Color.primary(for: colorScheme))
                                }

                                Button {
                                    showImagePicker = true
                                } label: {
                                    Image(systemName: "camera.circle.fill")
                                        .font(.system(size: 32))
                                        .foregroundColor(Color.primary(for: colorScheme))
                                        .background(
                                            Circle()
                                                .fill(Color.background(for: colorScheme))
                                                .frame(width: 32, height: 32)
                                        )
                                }
                                .offset(x: 45, y: 45)
                            }
                        }
                        .padding(.bottom, 10)

                        Text("Create Account")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(Color.text(for: colorScheme))

                        Text("Enter your details to get started")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                            .padding(.bottom, 20)

                        // Form Fields
                        VStack(spacing: 16) {
                            // Email field with validation
                            VStack(alignment: .leading, spacing: 4) {
                                CustomTextField(
                                    text: $viewModel.email,
                                    placeholder: "Email ID",
                                    iconName: "envelope.fill",
                                    isSecure: false,
                                    focusState: _focusedField,
                                    colorScheme: colorScheme,
                                    keyboardType: .emailAddress,
                                    fieldType: .email
                                )
                                .focused($focusedField, equals: .email)
                                .onChange(of: viewModel.email) { _ in
                                    viewModel.resetError()
                                    viewModel.validateEmail()
                                }
                                
                                if !viewModel.isEmailValid && !viewModel.email.isEmpty {
                                    Text(viewModel.emailMessage)
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.leading, 8)
                                }
                            }

                            // Password field with strength indicator
                            VStack(alignment: .leading, spacing: 4) {
                                CustomTextField(
                                    text: $viewModel.password,
                                    placeholder: "Password",
                                    iconName: "lock.fill",
                                    isSecure: !showPassword,
                                    showSecureToggle: true,
                                    secureToggleAction: { showPassword.toggle() },
                                    focusState: _focusedField,
                                    colorScheme: colorScheme,
                                    fieldType: .password
                                )
                                .focused($focusedField, equals: .password)
                                .onChange(of: viewModel.password) { _ in
                                    viewModel.resetError()
                                    viewModel.validatePassword()
                                    if !viewModel.confirmPassword.isEmpty {
                                        viewModel.validateConfirmPassword()
                                    }
                                }
                                
                                // Password strength indicator
                                if !viewModel.password.isEmpty {
                                    HStack {
                                        Text(viewModel.passwordStrength.description)
                                            .font(.caption)
                                            .foregroundColor(viewModel.passwordStrength.color)
                                        
                                        Spacer()
                                    }
                                    .padding(.horizontal, 8)
                                    
                                    // Password strength bar
                                    GeometryReader { geometry in
                                        HStack(spacing: 4) {
                                            ForEach(0..<4) { index in
                                                RoundedRectangle(cornerRadius: 2)
                                                    .fill(index < viewModel.passwordStrength.rawValue 
                                                          ? viewModel.passwordStrength.color 
                                                          : Color.gray.opacity(0.3))
                                                    .frame(width: (geometry.size.width - 12) / 4, height: 4)
                                            }
                                        }
                                    }
                                    .frame(height: 4)
                                    .padding(.horizontal, 8)
                                    
                                    // Password requirements
                                    if !viewModel.passwordMessages.isEmpty {
                                        VStack(alignment: .leading, spacing: 4) {
                                            ForEach(viewModel.passwordMessages, id: \.self) { message in
                                                Text(message)
                                                    .font(.caption2)
                                                    .foregroundColor(.red)
                                            }
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.top, 4)
                                    }
                                }
                            }

                            // Confirm password field
                            VStack(alignment: .leading, spacing: 4) {
                                CustomTextField(
                                    text: $viewModel.confirmPassword,
                                    placeholder: "Confirm Password",
                                    iconName: "lock.shield.fill",
                                    isSecure: !showConfirmPassword,
                                    showSecureToggle: true,
                                    secureToggleAction: { showConfirmPassword.toggle() },
                                    focusState: _focusedField,
                                    colorScheme: colorScheme,
                                    fieldType: .confirmPassword
                                )
                                .focused($focusedField, equals: .confirmPassword)
                                .onChange(of: viewModel.confirmPassword) { _ in
                                    viewModel.resetError()
                                    viewModel.validateConfirmPassword()
                                }
                                
                                if !viewModel.confirmPassword.isEmpty && !viewModel.isPasswordsMatching {
                                    Text("Passwords do not match")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.leading, 8)
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        if viewModel.showError {
                            Text(viewModel.errorMessage)
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.red)
                                .padding(.horizontal, 24)
                        }

                        Button {
                            withAnimation {
                                viewModel.createAuthAccount { success in
                                    if success {
                                        viewModel.nextStep()
                                    } else if viewModel.isUserAlreadyExistsError {
                                        // Show the user exists alert instead of the generic error
                                        showUserExistsAlert = true
                                    }
                                }
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.secondary(for: colorScheme))

                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.2)
                                } else {
                                    Text("Continue")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(height: 54)
                            .padding(.horizontal, 24)
                        }
                        .disabled(viewModel.isLoading || !viewModel.isStep1Valid)
                        .opacity(viewModel.isStep1Valid ? 1 : 0.7)

                        Spacer()
                    }
                    .padding(.top, geometry.size.height * 0.05)
                    .padding(.bottom, 24)
                    .frame(minHeight: geometry.size.height)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $viewModel.selectedImage)
            }
            .onTapGesture {
                focusedField = nil
            }
            // Add a specific alert for "user already exists" error
            .alert("Account Already Exists", isPresented: $showUserExistsAlert) {
//                Button("Go to Login", role: .destructive) {
//                    presentationMode.wrappedValue.dismiss()
//                }
                Button("Try Different Email", role: .cancel) {
                    // Clear the email field for convenience
                    viewModel.email = ""
                    viewModel.password = ""
                    viewModel.confirmPassword = ""
                    viewModel.resetError()
                    // Set focus to email field
                    focusedField = .email
                }
            }
//            message: {
//                Text("An account with this email already exists. Would you like to login instead, or use a different email?")
//            }
            // Keep the regular error alert for other error types
            .alert("Signup Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {
                    viewModel.showError = false
                }
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }
}
