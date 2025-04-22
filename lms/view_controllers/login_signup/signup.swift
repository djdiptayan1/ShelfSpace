//
//  signup.swift
//  lms
//
//  Created by Diptayan Jash on 17/04/25.
//

import Foundation
import SwiftUI

struct SignupView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var isSignupProcessing = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var selectedImage: UIImage?
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
                                
                                if let image = selectedImage {
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
                            // Email Field
                            CustomTextField(
                                text: $email,
                                placeholder: "Email ID",
                                iconName: "envelope.fill",
                                isSecure: false,
                                focusState: _focusedField,
                                fieldType: .email,
                                colorScheme: colorScheme
                            )
                            .focused($focusedField, equals: .email)
                            
                            // Password Field
                            CustomTextField(
                                text: $password,
                                placeholder: "Password",
                                iconName: "lock.fill",
                                isSecure: !showPassword,
                                showSecureToggle: true,
                                secureToggleAction: { showPassword.toggle() },
                                focusState: _focusedField,
                                fieldType: .password,
                                colorScheme: colorScheme
                            )
                            .focused($focusedField, equals: .password)
                            
                            // Confirm Password Field
                            CustomTextField(
                                text: $confirmPassword,
                                placeholder: "Confirm Password",
                                iconName: "lock.fill",
                                isSecure: !showConfirmPassword,
                                showSecureToggle: true,
                                secureToggleAction: { showConfirmPassword.toggle() },
                                focusState: _focusedField,
                                fieldType: .confirmPassword,
                                colorScheme: colorScheme
                            )
                            .focused($focusedField, equals: .confirmPassword)
                        }
                        .padding(.horizontal, 24)
                        
                        if showError {
                            Text(errorMessage)
                                .font(.system(size: 14, design: .rounded))
                                .foregroundColor(.red)
                                .padding(.horizontal, 24)
                        }
                        
                        Button {
                            withAnimation {
                                signupAction()
                            }
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.secondary(for: colorScheme))
                                
                                if isSignupProcessing {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.2)
                                } else {
                                    Text("Create Account")
                                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(height: 54)
                            .padding(.horizontal, 24)
                        }
                        .disabled(isSignupProcessing || !isFormValid)
                        .opacity(isFormValid ? 1 : 0.7)
                        
                        Spacer()
                    }
                    .padding(.top, geometry.size.height * 0.05)
                    .padding(.bottom, 24)
                    .frame(minHeight: geometry.size.height)
                }
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
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $selectedImage)
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword
    }
    
    private func signupAction() {
        focusedField = nil
        isSignupProcessing = true
        showError = false
        
        // Simulate signup process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSignupProcessing = false
            presentationMode.wrappedValue.dismiss()
        }
    }
}

struct SignupView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SignupView()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            SignupView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
