//
//  AddUserView.swift
//  lms
//
//  Created by Diptayan Jash on 25/04/25.
//

import Foundation
import SwiftUI

struct AddUserView: View {
    @ObservedObject var viewModel: UsersViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var focusField: AddUserField?

    @State private var showingImagePicker = false

    // Focus state fields
    enum AddUserField {
        case name, email, libraryId
    }

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
         viewModel.isValidEmail(viewModel.newUserInputEmail) && // Use VM validation
         !viewModel.newUserInputLibraryId.isEmpty
     }

    var body: some View {
        NavigationView {
            ZStack {
                // Background
                LinearGradient(
                    gradient: Gradient(colors: [Color(.systemGroupedBackground), Color(.secondarySystemGroupedBackground)]),
                    startPoint: .top, endPoint: .bottom
                ).edgesIgnoringSafeArea(.all)

                ScrollView {
                    VStack(spacing: 24) {
                        // Photo Selector Area
                        VStack(spacing: 16) {
                            photoSelectorButton // Use the button to trigger ImagePicker
                            Text("Add \(viewModel.roleToAdd == .librarian ? "Librarian" : "Member") Photo (Optional)")
                                .font(.system(size: 16, weight: .medium, design: .rounded))
                                .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                        }
                        .padding(.top, 20)

                        // Form Fields
                        VStack(spacing: 16) {
                            formField(
                                title: "Full Name",
                                placeholder: "Enter full name",
                                text: $viewModel.newUserInputName,
                                field: .name
                            )

                            emailField(
                                title: "Email",
                                placeholder: "Enter email address",
                                text: $viewModel.newUserInputEmail,
                                field: .email
                            )

                            formField(
                                title: "Library ID",
                                placeholder: "Enter library identifier",
                                text: $viewModel.newUserInputLibraryId,
                                field: .libraryId
                            )
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 50)
                }
            }
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        viewModel.resetUserInputForm()
                        dismiss()
                    }
                    .foregroundColor(accentColor)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.addUser()
                        // Dismissal is handled within addUser or can happen automatically if successful
                    }
                    .foregroundColor(accentColor)
                    .disabled(!isFormValid) // Use validation computed property
                }
            }
            // Present the custom ImagePicker using a sheet
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $viewModel.newUserInputImage) // Pass the binding
            }
        }
    }

    // MARK: - Subviews for AddUserView

    // Button that looks like the photo picker area
    private var photoSelectorButton: some View {
        Button {
            hideKeyboard() // Dismiss keyboard before showing sheet
            showingImagePicker = true // Trigger the sheet presentation
        } label: {
            ZStack {
                // Display the selected UIImage from the ViewModel
                if let image = viewModel.newUserInputImage {
                    Image(uiImage: image)
                        .resizable().scaledToFill()
                        .frame(width: 110, height: 110).clipShape(Circle())
                        .overlay(Circle().stroke(accentColor, lineWidth: 2))
                } else {
                    // Placeholder view
                    Circle()
                        .fill(Color.TabbarBackground(for: colorScheme)) // Use color helper
                        .frame(width: 110, height: 110)
                        .overlay(Image(systemName: "camera.fill").foregroundColor(accentColor).font(.system(size: 40)))
                }
                // Plus badge overlay
                Circle().fill(accentColor).frame(width: 32, height: 32)
                    .overlay(Image(systemName: "plus").foregroundColor(.white).font(.system(size: 18, weight: .bold)))
                    .offset(x: 40, y: 40)
            }
        }
        // .buttonStyle(.plain) // Optional: Remove button default styling if needed
    }

    // Generic Form Field Builder
    @ViewBuilder
    private func formField(title: String, placeholder: String, text: Binding<String>, field: AddUserField) -> some View {
         VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
            TextField(placeholder, text: text)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(Color.text(for: colorScheme))
                .focused($focusField, equals: field)
                .submitLabel(.next) // Improve keyboard navigation
                .onSubmit { // Move focus on submit
                    focusNextField(current: field)
                }
                .padding(16)
                .background(fieldBackground)
         }
    }

     // Email Field Builder with Validation Feedback
    @ViewBuilder
    private func emailField(title: String, placeholder: String, text: Binding<String>, field: AddUserField) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                 .font(.system(size: 14, weight: .medium, design: .rounded))
                 .foregroundColor(Color.text(for: colorScheme).opacity(0.7))

            TextField(placeholder, text: text)
                .font(.system(size: 16, design: .rounded))
                .foregroundColor(Color.text(for: colorScheme))
                .focused($focusField, equals: field)
                .keyboardType(.emailAddress)
                .textContentType(.emailAddress)
                .autocapitalization(.none)
                .submitLabel(.next) // Use .done for the last field if applicable
                .onSubmit {
                    focusNextField(current: field)
                }
                .padding(16)
                .background(fieldBackground)
                .overlay(
                     RoundedRectangle(cornerRadius: 12)
                        .stroke(emailInputBorderColor(text.wrappedValue), lineWidth: emailInputBorderWidth(text.wrappedValue))
                 )

            // Validation message
            if !text.wrappedValue.isEmpty && !viewModel.isValidEmail(text.wrappedValue) {
                 Text("Please enter a valid email address.")
                     .font(.system(size: 12))
                     .foregroundColor(.red)
                     .padding(.leading, 4)
                     .transition(.opacity.animation(.easeIn))
             }
         }
    }

    // Common background for text fields
    private var fieldBackground: some View {
        RoundedRectangle(cornerRadius: 12)
             .fill(Color.TabbarBackground(for: colorScheme))
             .shadow(color: Color.black.opacity(colorScheme == .light ? 0.05 : 0.15), radius: 2, x: 0, y: 1)
             .overlay(
                 RoundedRectangle(cornerRadius: 12)
                     .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
             )
    }

     // Helper for email border color
     private func emailInputBorderColor(_ email: String) -> Color {
         if email.isEmpty { return Color.gray.opacity(0.2) }
         return viewModel.isValidEmail(email) ? Color.green.opacity(0.6) : Color.red.opacity(0.7)
     }

     // Helper for email border width
      private func emailInputBorderWidth(_ email: String) -> CGFloat {
          return email.isEmpty ? 0.5 : 1.0
      }

      // Helper function to move focus between fields
      private func focusNextField(current: AddUserField) {
           switch current {
           case .name:
               focusField = .email
           case .email:
               focusField = .libraryId
           case .libraryId:
               focusField = nil // Dismiss keyboard or move to a final action
               // Consider calling viewModel.addUser() or similar if appropriate
           }
       }

       // Helper to dismiss keyboard
       private func hideKeyboard() {
           UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
       }
}
