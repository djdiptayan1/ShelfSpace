//import Foundation
//import SwiftUI
//
//struct UsersViewLibrarian: View {
//    @StateObject private var viewModel = UsersViewModel()
//    @Environment(\.colorScheme) private var colorScheme
//    
//    var body: some View {
//        NavigationView {
//            ZStack {
//                ReusableBackground(colorScheme: colorScheme)
//                
//                
//                VStack(spacing: 0) {
//                    // Custom header with "Users" title and "+" button
//                    HStack {
//                        Text("Users")
//                            .font(.largeTitle)
//                            .fontWeight(.bold)
//                            .foregroundColor(.black) // Fixed black color
//                        Spacer()
//                        Button(action: {
//                            // Prepare to add a librarian
//                            viewModel.prepareToAddUser(role: .librarian)
//                        }) {
//                            Image(systemName: "plus")
//                                .font(.title2)
//                                .foregroundColor(Color.primary(for: colorScheme))
//                        }
//                    }
//                    .padding(.horizontal)
//                    .padding(.top, 10)
//                    .padding(.bottom, 8)
//                    
//                    // Display only the librarians list
//                    librariansListView
//                }
//                
//                // Changed to show members list instead of librarians
//                membersListView
//                
//            }
//            .onAppear {
//                viewModel.fetchUsersoflibrary()
//            }
//            
//            // Present the AddLibrarianView sheet
//            .sheet(isPresented: $viewModel.isShowingAddUserSheet) {
//                // Pass the single ViewModel instance down
//                AddLibrarianView(viewModel: viewModel)
//                
//                    .navigationTitle("Members") // Changed title
//                    .navigationBarTitleDisplayMode(.large)
//                    .toolbar {
//                        ToolbarItem(placement: .navigationBarTrailing) {
//                            Button(action: {
//                                // Changed to add member instead of librarian
//                                viewModel.prepareToAddUser(role: .member)
//                            }) {
//                                Image(systemName: "plus")
//                                    .foregroundColor(Color.primary(for: colorScheme))
//                            }
//                        }
//                    }
//                    .sheet(isPresented: $viewModel.isShowingAddUserSheet) {
//                        AddUserView(viewModel: viewModel)
//                        
//                    }
//                    .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
//                        Button("OK", role: .cancel) { }
//                    } message: {
//                        Text(viewModel.alertMessage)
//                    }
//            }
//        }
//             
//                
//         
//    }
//    var librariansListView: some View {
//       List {
//           // Use the computed property from ViewModel
//           ForEach(viewModel.activeLibrarians) { user in
//               // Navigate to the dedicated Row View (no deactivation action)
//               LibrarianRow(user: user, viewModel: viewModel)
//           }
//       }
//       .listStyle(.plain)
//       .overlay {
//           if viewModel.activeLibrarians.isEmpty {
//               EmptyStateView(type: "Users", colorScheme: colorScheme) // Use helper view
//           }
//       }
//       .refreshable {
//           print("Refreshing Users...")
//           // Example: await viewModel.fetchUsers()
//       }
//   }
//
//    var membersListView: some View {
//        List {
//            // Changed to show members instead of librarians
//            ForEach(viewModel.activeMembers) { user in
//                MemberRow(user: user, viewModel: viewModel) // Changed to MemberRow
//            }
//        }
//        .listStyle(.plain)
//        .overlay {
//            
//            if viewModel.activeLibrarians.isEmpty {
//                EmptyStateView(type: "Users", colorScheme: colorScheme) // Use helper view
//            }
//        }
//        .refreshable {
//            print("Refreshing Users...")
//            // Example: await viewModel.fetchUsers()
//            
//            if viewModel.activeMembers.isEmpty {
//                EmptyStateView(type: "members", colorScheme: colorScheme)
//            }
//        }
//        .refreshable {
//            viewModel.fetchUsersoflibrary()
//            
//        }
//    }
//
//    private func addMockData() {
//#if DEBUG
//       viewModel.users = [
//           
//           User(id: UUID(), email: "user1@example.com", role: .librarian, name: "Alice (Mock)", is_active: true, library_id: "MAINLIB", profileImage: UIImage(systemName: "person.crop.circle.fill")?.jpegData(compressionQuality: 0.8)),
//           User(id: UUID(), email: "user2@example.com", role: .librarian, name: "Charles (Mock)", is_active: false, library_id: "BRANCHLIB"), // Inactive
//           
//           // Changed mock data to show members
//           User(id: UUID(), email: "member1@example.com", role: .member, name: "John Doe", is_active: true,
//                library_id: "MAINLIB", borrowed_book_ids: [], reserved_book_ids: [], wishlist_book_ids: [],
//                created_at: "", updated_at: "", profileImage: UIImage(systemName: "person.crop.circle.fill")?.jpegData(compressionQuality: 0.8)),
//           User(id: UUID(), email: "member2@example.com", role: .member, name: "Jane Smith", is_active: true,
//                library_id: "MAINLIB", borrowed_book_ids: [], reserved_book_ids: [], wishlist_book_ids: [])
//           
//       ]
//#endif
//   }
//}
//
//
//// MARK: - AddLibrarianView (Customized for Librarian with Static Text)
//struct AddLibrarianView: View {
//    @ObservedObject var viewModel: UsersViewModel
//    @Environment(\.dismiss) private var dismiss
//    @Environment(\.colorScheme) private var colorScheme
//    @FocusState private var focusField: AuthFieldType?
//
//    @State private var showingImagePicker = false
//    @State private var password: String = ""
//    @State private var isLoading = false
//
//    // Check if form is valid for enabling Save button
//    private var isFormValid: Bool {
//        !viewModel.newUserInputName.isEmpty &&
//        viewModel.isValidEmail(viewModel.newUserInputEmail)
//    }
//
//    var body: some View {
//        NavigationView {
//            ZStack {
//                ReusableBackground(colorScheme: colorScheme)
//                
//                ScrollView {
//                    VStack(spacing: 24) {
//                        photoSection
//                        formSection
//                    }
//                    .padding(.bottom, 50)
//                }
//                if isLoading {
//                    Color.black.opacity(0.4)
//                        .ignoresSafeArea()
//                    VStack {
//                        ActivityIndicator(isAnimating: $isLoading, style: .large)
//                        Text("Creating User...")
//                            .foregroundColor(.white)
//                            .font(.headline)
//                            .padding(.top, 8)
//                    }
//                    .padding(24)
//                    .background(Color.black.opacity(0.75))
//                    .cornerRadius(12)
//                }
//            }
//            .navigationTitle("Add User")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    cancelButton
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    saveButton
//                }
//            }
//            .sheet(isPresented: $showingImagePicker) {
//                ImagePicker(image: $viewModel.newUserInputImage)
//            }
//        }
//    }
//
//    // MARK: - Subviews
//    
//    private var photoSection: some View {
//        VStack(spacing: 16) {
//            photoSelectorButton
//            Text("Add User Photo (Optional)")
//                .font(.system(size: 16, weight: .medium, design: .rounded))
//                .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
//        }
//        .padding(.top, 20)
//    }
//    
//    private var formSection: some View {
//        VStack(spacing: 16) {
//            nameField
//            emailField
//        }
//        .padding(.horizontal, 20)
//    }
//    
//    private var nameField: some View {
//        CustomTextField(
//            text: $viewModel.newUserInputName,
//            placeholder: "Enter full name",
//            iconName: "person.fill",
//            isSecure: false,
//            colorScheme: colorScheme,
//            fieldType: .name
//        )
//    }
//    
//    private var emailField: some View {
//        CustomTextField(
//            text: $viewModel.newUserInputEmail,
//            placeholder: "Enter email address",
//            iconName: "envelope.fill",
//            isSecure: false,
//            colorScheme: colorScheme,
//            keyboardType: .emailAddress,
//            fieldType: .email
//        )
//    }
//    
//    private var photoSelectorButton: some View {
//        Button {
//            hideKeyboard()
//            showingImagePicker = true
//        } label: {
//            ZStack {
//                if let image = viewModel.newUserInputImage {
//                    Image(uiImage: image)
//                        .resizable()
//                        .scaledToFill()
//                        .frame(width: 110, height: 110)
//                        .clipShape(Circle())
//                        .overlay(Circle().stroke(accentColor, lineWidth: 2))
//                } else {
//                    Circle()
//                        .fill(Color.TabbarBackground(for: colorScheme))
//                        .frame(width: 110, height: 110)
//                        .overlay(
//                            Image(systemName: "camera.fill")
//                                .foregroundColor(accentColor)
//                                .font(.system(size: 40))
//                        )
//                }
//                
//                Circle()
//                    .fill(accentColor)
//                    .frame(width: 32, height: 32)
//                    .overlay(
//                        Image(systemName: "plus")
//                            .foregroundColor(.white)
//                            .font(.system(size: 18, weight: .bold))
//                    )
//                    .offset(x: 40, y: 40)
//            }
//        }
//    }
//    
//    private var cancelButton: some View {
//        Button("Cancel") {
//            viewModel.resetUserInputForm()
//            dismiss()
//        }
//        .foregroundColor(accentColor)
//    }
//    
//    private var saveButton: some View {
//        Button("Save") {
//            let role = viewModel.roleToAdd == .librarian ? "librarian" : "member"
//            password = randomPassword(length: 8)
//            //loading
//            isLoading = true
//            
//            createUserWithAuth(
//                email: viewModel.newUserInputEmail,
//                password: password,
//                name: viewModel.newUserInputName,
//                role: role
//            ) { result in
//                DispatchQueue.main.async {
//                    isLoading = false
//                    switch result {
//                    case .success:
//                        viewModel.showAlert(
//                            title: "Success",
//                            message: "\(role.capitalized) added successfully",
//                            type: .success
//                        )
//                        viewModel.resetUserInputForm()
//                        viewModel.fetchUsersoflibrary() // Refresh the user list
//                        dismiss()
//                    case .failure(let error):
//                        viewModel.showAlert(
//                            title: "Error",
//                            message: "Failed to add \(role): \(error.localizedDescription)",
//                            type: .error
//                        )
//                    }
//                }
//            }
//        }
//        .foregroundColor(accentColor)
//        .disabled(!isFormValid)
//    }
//
//    private var accentColor: Color {
//        viewModel.roleToAdd == .librarian ? Color.primary(for: colorScheme) : Color.accent(for: colorScheme)
//    }
//
//    private func hideKeyboard() {
//        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//    }
//}
//
//// MARK: - Preview Provider
//
//
//#if DEBUG
//struct UsersViewLibrarian_Previews: PreviewProvider {
//    static var previews: some View {
//        UsersViewLibrarian()
//            .preferredColorScheme(.light)
//            .previewDisplayName("Members Management - Light")
//
//        UsersViewLibrarian()
//            .preferredColorScheme(.dark)
//            .previewDisplayName("Members Management - Dark")
//    }
//}
//#endif


//
//  UsersViewAdmin.swift
//  lms
//
//  Created by Diptayan Jash on 25/04/25.
//

import Foundation
import SwiftUI

struct UsersViewLibrarian: View {
    // Use @StateObject to create and own the ViewModel instance for this view hierarchy
    @StateObject private var viewModel = UsersViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            ZStack {
                ReusableBackground(colorScheme: colorScheme) // Use helper

                VStack(spacing: 0) {
//                    Picker("User Type", selection: $viewModel.selectedSegment) {
//                        Text("Librarians").tag(0)
//                        Text("Members").tag(1)
//                    }
//                    .pickerStyle(SegmentedPickerStyle())
//                    .padding()
                        membersListView
                }
                // Example: Load initial data or handle user activity if needed
                 .onAppear {
                     viewModel.fetchUsersoflibrary()
                 }
            }
            .navigationTitle("User Management")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Determine role based on segment and prepare to add
                        let role: UserRole = .member
                        viewModel.prepareToAddUser(role: role)
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(Color.primary(for: colorScheme)) // Use color helper
                    }
                }
            }
            // Present the AddUserView sheet
            .sheet(isPresented: $viewModel.isShowingAddUserSheet) {
                // Pass the single ViewModel instance down
                AddUserView(viewModel: viewModel)
            }
            // Confirmation dialog for deactivation
            .confirmationDialog(
                "Confirm Deactivation",
                isPresented: $viewModel.showDeactivateConfirmation,
                presenting: viewModel.userMarkedForDeactivation // Pass user data
            ) { user in // Closure receives the user data
                 Button("Deactivate \(user.name)", role: .destructive) {
                    viewModel.deactivateConfirmed() // Call VM function
                 }
                 Button("Cancel", role: .cancel) {
                     // Reset temporary state if needed (VM handles main reset)
                     viewModel.userToDeactivate = nil
                     viewModel.userMarkedForDeactivation = nil
                 }
            } message: { user in // Closure for the message, receives user data
                let userType = "member"
                Text("Are you sure you want to deactivate this \(userType) (\(user.name))? They will no longer have access.")
            }
            .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.alertMessage)
            }
        }
        // Ensure the ViewModel is accessible to child views needing it
        // .environmentObject(viewModel) // Optional: Use if deeply nested views need it
    }

    // MARK: - List Views (Private to UsersViewAdmin)

    private var membersListView: some View {
        List {
            // Use the computed property from ViewModel
            ForEach(viewModel.activeMembers) { user in
                 // Navigate to the dedicated Row View
                 MemberRow(user: user, viewModel: viewModel)
            }
        }
        .listStyle(.plain)
        .overlay { // Show empty state if list is empty
            if viewModel.activeMembers.isEmpty {
                 EmptyStateView(type: "Members", colorScheme: colorScheme) // Use helper view
            }
        }
         .refreshable { // Example refresh action
             // Add logic to fetch/refresh users from your data source
             print("Refreshing members...")
             // Example: await viewModel.fetchUsers()
         }
    }

     // Helper function to add mock data for previews/testing
     private func addMockData() {
         #if DEBUG // Only include mock data in Debug builds
         viewModel.users = [
            User(id: UUID(), email: "librarian1@example.com", role: .librarian, name: "Alice (Mock)", is_active: true, library_id: "MAINLIB", profileImage: UIImage(systemName: "person.crop.circle.fill")?.jpegData(compressionQuality: 0.8)),
            User(id: UUID(), email: "member1@example.com", role: .member, name: "Bob (Mock)", is_active: true, library_id: "MAINLIB"),
            User(id: UUID(), email: "librarian2@example.com", role: .librarian, name: "Charles (Mock)", is_active: false, library_id: "BRANCHLIB"), // Inactive
            User(id: UUID(), email: "member2@example.com", role: .member, name: "Diana (Mock)", is_active: true, library_id: "MAINLIB", profileImage: UIImage(systemName: "person.crop.circle")?.jpegData(compressionQuality: 0.8))
         ]
         #endif
     }
}

// MARK: - Preview Provider
#if DEBUG
struct UsersViewLibrarian_Previews: PreviewProvider {
    static var previews: some View {
        UsersViewLibrarian()
            .preferredColorScheme(.light)
            .previewDisplayName("Main View - Light")

        UsersViewLibrarian()
            .preferredColorScheme(.dark)
            .previewDisplayName("Main View - Dark")
    }
}
#endif
