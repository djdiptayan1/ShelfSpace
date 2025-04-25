import SwiftUI

struct signupView: View {
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var viewModel: SignupModel
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var showImagePicker = false
    @FocusState private var focusedField: AuthFieldType?
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                ReusableBackground(colorScheme: colorScheme)

                ScrollView {
                    VStack(spacing: 30) {
                        // Profile Image Section
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
                            CustomTextField(
                                text: $viewModel.email,
                                placeholder: "Email ID",
                                iconName: "envelope.fill",
                                isSecure: false,
                                focusState: _focusedField,
                                colorScheme: colorScheme,
                                fieldType: .email
                            )
                            .focused($focusedField, equals: .email)

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

                            CustomTextField(
                                text: $viewModel.confirmPassword,
                                placeholder: "Confirm Password",
                                iconName: "lock.fill",
                                isSecure: !showConfirmPassword,
                                showSecureToggle: true,
                                secureToggleAction: { showConfirmPassword.toggle() },
                                focusState: _focusedField,
                                colorScheme: colorScheme,
                                fieldType: .confirmPassword
                            )
                            .focused($focusedField, equals: .confirmPassword)
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
                                if viewModel.isStep1Valid {
                                    viewModel.createAuthAccount { success in
                                        
                                        if success {
                                            viewModel.nextStep()
                                        }
                                    }
                                } else {
                                    viewModel.errorMessage = "Please fill in all fields correctly."
                                    viewModel.showError = true
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
        }
    }
}
