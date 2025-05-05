//
//  AddUserView.swift
//  lms
//
//  Created by Diptayan Jash on 25/04/25.
//

import Foundation
import SwiftUI

struct ActivityIndicator: UIViewRepresentable {
    @Binding var isAnimating: Bool
    let style: UIActivityIndicatorView.Style

    func makeUIView(context: Context) -> UIActivityIndicatorView {
        let indicator = UIActivityIndicatorView(style: style)
        indicator.hidesWhenStopped = true
        return indicator
    }

    func updateUIView(_ uiView: UIActivityIndicatorView, context: Context) {
        isAnimating ? uiView.startAnimating() : uiView.stopAnimating()
    }
}


struct AddUserView: View {
    @ObservedObject var viewModel: UsersViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var focusField: AuthFieldType?

    @State private var showingImagePicker = false
    @State private var password: String = ""
    @State private var isLoading = false
    @State private var showError = false
    @State private var errorMessage = ""


    // Determine title and colors based on the role being added
    private var navigationTitle: String {
        viewModel.roleToAdd == .librarian ? "Add Librarian" : "Add Member"
    }
    private var accentColor: Color {
        viewModel.roleToAdd == .librarian ? Color.primary(for: colorScheme) : Color.accent(for: colorScheme)
    }

    // Check if form is valid for enabling Save button
    private var isFormValid: Bool {
        !viewModel.newUserInputName.isEmpty &&
        viewModel.isValidEmail(viewModel.newUserInputEmail)
    }

    var body: some View {
        NavigationView {
            ZStack {
                ReusableBackground(colorScheme: colorScheme)
                
                ScrollView {
                    VStack(spacing: 24) {
                        photoSection
                        formSection
                    }
                    .padding(.bottom, 50)
                }
                if isLoading {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    VStack {
                        ActivityIndicator(isAnimating: $isLoading, style: .large)
                        Text("Creating User...")
                            .foregroundColor(.white)
                            .font(.headline)
                            .padding(.top, 8)
                    }
                    .padding(24)
                    .background(Color.black.opacity(0.75))
                    .cornerRadius(12)
                }

            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelButton
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    saveButton
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $viewModel.newUserInputImage)
            }
        }
    }

    // MARK: - Subviews
    
    private var photoSection: some View {
        VStack(spacing: 16) {
            photoSelectorButton
            Text("Add \(viewModel.roleToAdd == .librarian ? "Librarian" : "Member") Photo (Optional)")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
        }
        .padding(.top, 20)
    }
    
    private var formSection: some View {
        VStack(spacing: 16) {
            if showError {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .font(.system(size: 14, design: .rounded))
                    .padding(.bottom, 4)
            }
            nameField
                .onChange(of: viewModel.newUserInputName) { _ in
                    showError = false
                    errorMessage = ""
                }
            emailField
                .onChange(of: viewModel.newUserInputEmail) { _ in
                    showError = false
                    errorMessage = ""
                }
        }
        .padding(.horizontal, 20)
    }
    
    private var nameField: some View {
        CustomTextField(
            text: $viewModel.newUserInputName,
            placeholder: "Enter full name",
            iconName: "person.fill",
            isSecure: false,
//            focusState: $focusField,
            colorScheme: colorScheme,
            fieldType: .name
        )
    }
    
    private var emailField: some View {
        CustomTextField(
            text: $viewModel.newUserInputEmail,
            placeholder: "Enter email address",
            iconName: "envelope.fill",
            isSecure: false,
//            focusState: $focusField,
            colorScheme: colorScheme,
            keyboardType: .emailAddress,
            fieldType: .email
        )
    }
    
    
    private var photoSelectorButton: some View {
        Button {
            hideKeyboard()
            showingImagePicker = true
        } label: {
            ZStack {
                if let image = viewModel.newUserInputImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(accentColor, lineWidth: 2))
                } else {
                    Circle()
                        .fill(Color.TabbarBackground(for: colorScheme))
                        .frame(width: 110, height: 110)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .foregroundColor(accentColor)
                                .font(.system(size: 40))
                        )
                }
                
                Circle()
                    .fill(accentColor)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "plus")
                            .foregroundColor(.white)
                            .font(.system(size: 18, weight: .bold))
                    )
                    .offset(x: 40, y: 40)
            }
        }
    }
    
    private var cancelButton: some View {
        Button("Cancel") {
            viewModel.resetUserInputForm()
            dismiss()
        }
        .foregroundColor(accentColor)
    }
    
    private var saveButton: some View {
        Button("Save") {
            if viewModel.newUserInputName.isEmpty {
                errorMessage = "Name is required."
                showError = true
                return
            } else if viewModel.newUserInputEmail.isEmpty {
                errorMessage = "Email is required."
                showError = true
                return
            } else if !viewModel.isValidEmail(viewModel.newUserInputEmail) {
                errorMessage = "Please enter a valid email address."
                showError = true
                return
            }
            let role = viewModel.roleToAdd == .librarian ? "librarian" : "member"
            password = randomPassword(length: 8)
            isLoading = true
            createUserWithAuth(
                email: viewModel.newUserInputEmail,
                password: password,
                name: viewModel.newUserInputName,
                role: role
            ) { result in
                DispatchQueue.main.async {
                    isLoading = false
                    switch result {
                    case .success:
                        viewModel.showAlert(
                            title: "Success",
                            message: "\(role.capitalized) added successfully",
                            type: .success
                        )
                        viewModel.resetUserInputForm()
                        viewModel.fetchUsersoflibrary() // Refresh the user list
                        dismiss()
                    case .failure(let error):
                        viewModel.showAlert(
                            title: "Error",
                            message: "Failed to add \(role): \(error.localizedDescription)",
                            type: .error
                        )
                    }
                }
            }
        }
        .foregroundColor(accentColor)
        .disabled(!isFormValid)
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
func randomPassword(length: Int) -> String {
    let characters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*()_+-=[]{}|;:,.<>?/"
    var password = ""

    for _ in 0..<length {
        if let randomChar = characters.randomElement() {
            password.append(randomChar)
        }
    }

    return password
}




#Preview {
    AddUserView(viewModel: UsersViewModel())
}
