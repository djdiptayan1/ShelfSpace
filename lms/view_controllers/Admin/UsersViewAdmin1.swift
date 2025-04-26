////
////  userModel.swift
////  lms
////
////  Created by Diptayan Jash on 18/04/25.
////
//
//import Foundation
//import SwiftUI // Needed for UIImage if used temporarily
//import Combine // For ObservableObject
//import PhotosUI // For PhotosPickerItem
//
//class UsersViewModel: ObservableObject {
//    @Published var selectedSegment = 0 // 0 for Librarians, 1 for Members
//    @Published var users: [User] = [] // Single list using your User model
//
//    // Computed properties to filter users for the UI
//    var activeLibrarians: [User] {
//        users.filter { $0.role == .librarian && ($0.isActive != nil) } // Assuming isActive logic is still needed externally or added later
//    }
//    var activeMembers: [User] {
//        users.filter { $0.role == .member && ($0.isActive != nil) } // Assuming isActive logic is still needed externally or added later
//    }
//
//    // State for Add User Sheet
//    @Published var isShowingAddUserSheet = false
//    @Published var roleToAdd: UserRole? // Track which type to add
//    // Temporary state for the form input
//    @Published var newUserInputName: String = ""
//    @Published var newUserInputEmail: String = ""
//    @Published var newUserInputLibraryId: String = "" // Required field based on your model
//    @Published var newUserInputImage: UIImage? = nil // Use UIImage temporarily for picker/display
//    @Published var selectedPhoto: PhotosPickerItem?
//
//    // State for Deactivation Confirmation
//    // Note: Your User model doesn't have `isActive`. Deactivation logic here
//    // will just remove the user from the `users` array for this example.
//    // If you need persistence or actual deactivation, your backend/data layer
//    // needs to handle it, potentially adding an `isActive` flag to your model.
//    @Published var userToDeactivate: UUID?
//    @Published var showDeactivateConfirmation = false
//    @Published var userMarkedForDeactivation: User? // Store the user temporarily for the message
//
//    // --- Functions ---
//
//    func prepareToAddUser(role: UserRole) {
//        roleToAdd = role
//        resetUserInputForm() // Reset form fields
//        isShowingAddUserSheet = true
//    }
//
//    func addUser() {
//        guard let role = roleToAdd,
//              !newUserInputName.isEmpty,
//              !newUserInputEmail.isEmpty, // Add proper email validation if needed
//              !newUserInputLibraryId.isEmpty // Ensure Library ID is provided
//        else {
//             print("Validation failed for adding user. Ensure Name, Email, and Library ID are provided.")
//             // Optionally show an alert to the user here
//             return
//         }
//
//        // Convert UIImage to Data?
//        let profileImageData = newUserInputImage?.jpegData(compressionQuality: 0.8) // Or pngData()
//
//        // Create the User object using your model's init
//        let newUser = User(
//            id: UUID(), // Generate new ID
//            email: newUserInputEmail,
//            role: role,
//            name: newUserInputName,
//            isActive: true,
//            library_id: newUserInputLibraryId, // Use the required input
//            profileImage: profileImageData
//        )
//
//        users.append(newUser)
//        resetUserInputForm() // Reset after adding
//        isShowingAddUserSheet = false // Close the sheet
//        objectWillChange.send() // Ensure UI updates
//    }
//
//    // MARK: Deactivation Handling (Simulated by Removal)
//    // Replace this with actual deactivation logic (e.g., setting isActive flag via API call) if needed.
//    func confirmDeactivateUser(_ user: User) {
//        userToDeactivate = user.id
//        userMarkedForDeactivation = user // Store for message
//        showDeactivateConfirmation = true
//    }
//
//    func deactivateConfirmed() {
//        if let id = userToDeactivate {
//            users.removeAll { $0.id == id } // Remove the user from the list
//            userToDeactivate = nil
//            userMarkedForDeactivation = nil
//            objectWillChange.send() // Ensure UI updates
//        }
//        // Hide confirmation dialog implicitly by isPresented binding
//    }
//
//    func resetUserInputForm() {
//        newUserInputName = ""
//        newUserInputEmail = ""
//        newUserInputLibraryId = ""
//        newUserInputImage = nil
//        selectedPhoto = nil
//        // roleToAdd remains set until the sheet is dismissed or saved
//    }
//
//    // Basic email validation (optional, enhance as needed)
//    func isValidEmail(_ email: String) -> Bool {
//        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
//        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
//        return emailPred.evaluate(with: email)
//    }
//
//     // Helper to convert Data to UIImage for display
//     func uiImage(from data: Data?) -> UIImage? {
//         guard let data = data else { return nil }
//         return UIImage(data: data)
//     }
//}
//
//// MARK: - Main View
//struct UsersViewAdmin: View {
//    @StateObject private var viewModel = UsersViewModel()
//    @Environment(\.colorScheme) private var colorScheme
//
//    // Temporary isActive flag for demonstration, remove if model gets 'isActive'
//    // Or manage active status externally
//    @State private var userActivity: [UUID: Bool] = [:]
//
//    // Helper to check active status
//    func isUserActive(_ user: User) -> Bool {
//        userActivity[user.id, default: true] // Default to active
//    }
//
//    // Filtered views based on local state (if needed) or ViewModel computed props
//    private var activeLibrarians: [User] {
//         viewModel.users.filter { $0.role == .librarian && isUserActive($0) }
//     }
//     private var activeMembers: [User] {
//         viewModel.users.filter { $0.role == .member && isUserActive($0) }
//     }
//
//    var body: some View {
//        NavigationView {
//            ZStack {
//                ReusableBackground(colorScheme: colorScheme) // Assuming this exists
//
//                VStack(spacing: 0) {
//                    Picker("User Type", selection: $viewModel.selectedSegment) {
//                        Text("Librarians").tag(0)
//                        Text("Members").tag(1)
//                    }
//                    .pickerStyle(SegmentedPickerStyle())
//                    .padding()
//
//                    if viewModel.selectedSegment == 0 {
//                        librariansListView
//                    } else {
//                        membersListView
//                    }
//                }
//                // Initialize user activity on appear (for demo)
//                 .onAppear {
//                     viewModel.users.forEach { user in
//                         if userActivity[user.id] == nil {
//                              userActivity[user.id] = true // Initialize all as active
//                          }
//                     }
//                 }
//
//            }
//            .navigationTitle("Users")
//            .navigationBarTitleDisplayMode(.large)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button(action: {
//                        let role: UserRole = (viewModel.selectedSegment == 0) ? .librarian : .member
//                        viewModel.prepareToAddUser(role: role)
//                    }) {
//                        Image(systemName: "plus.circle.fill")
//                            .font(.title2)
//                            .foregroundColor(Color.primary(for: colorScheme)) // Use helper
//                    }
//                }
//            }
//            .sheet(isPresented: $viewModel.isShowingAddUserSheet) {
//                AddUserView(viewModel: viewModel) // Present the single AddUserView
//            }
//            .confirmationDialog(
//                "Confirm Deactivation",
//                isPresented: $viewModel.showDeactivateConfirmation,
//                // Use the temporarily stored user for the message
//                presenting: viewModel.userMarkedForDeactivation
//            ) { user in // Receive the user data
//                 Button("Deactivate \(user.name)", role: .destructive) {
//                    // viewModel.deactivateConfirmed() // Original removal logic
//                    // --- OR --- If using local state for demo:
//                    if let id = viewModel.userToDeactivate {
//                        userActivity[id] = false // Mark as inactive locally
//                        viewModel.userToDeactivate = nil // Reset state
//                        viewModel.userMarkedForDeactivation = nil
//                    }
//                 }
//                 Button("Cancel", role: .cancel) {
//                     viewModel.userToDeactivate = nil // Reset state
//                     viewModel.userMarkedForDeactivation = nil
//                 }
//            } message: { user in // Use the user data in the message
//                let userType = user.role == .librarian ? "librarian" : "member"
//                 // Adapt message if just hiding vs permanent action
//                Text("Are you sure you want to deactivate this \(userType) (\(user.name))? They will be hidden from the list.")
//                // Original message: Text("Are you sure you want to deactivate this \(userType) (\(user.name))? They will no longer have access to the system.")
//            }
//        }
//    }
//
//    private var librariansListView: some View {
//        List {
//            // Use the filtered list based on local active state
//            ForEach(activeLibrarians) { user in
//                 LibrarianRow(user: user, viewModel: viewModel) // Pass User object and ViewModel
//                    .swipeActions(edge: .trailing) {
//                        Button(role: .destructive) {
//                             viewModel.confirmDeactivateUser(user) // Pass the whole user object
//                        } label: {
//                            Label("Deactivate", systemImage: "person.fill.xmark")
//                        }
//                        .tint(.red)
//                    }
//            }
//        }
//        .listStyle(.plain)
//        .overlay {
//            if activeLibrarians.isEmpty { // Check filtered list
//                emptyStateView(type: "Librarians")
//            }
//        }
//        .refreshable {
//             // Add logic to fetch users if needed
//             print("Refreshing librarians...")
//         }
//    }
//
//    private var membersListView: some View {
//        List {
//             // Use the filtered list based on local active state
//            ForEach(activeMembers) { user in
//                 MemberRow(user: user, viewModel: viewModel) // Pass User object and ViewModel
//                    .swipeActions(edge: .trailing) {
//                        Button(role: .destructive) {
//                             viewModel.confirmDeactivateUser(user) // Pass the whole user object
//                        } label: {
//                            Label("Deactivate", systemImage: "person.fill.xmark")
//                        }
//                        .tint(.red)
//                    }
//            }
//        }
//        .listStyle(.plain)
//        .overlay {
//            if activeMembers.isEmpty { // Check filtered list
//                emptyStateView(type: "Members")
//            }
//        }
//         .refreshable {
//             // Add logic to fetch users if needed
//             print("Refreshing members...")
//         }
//    }
//
//    // Empty state view remains the same as before
//    @ViewBuilder
//    private func emptyStateView(type: String) -> some View {
//        VStack(spacing: 16) {
//            Image(systemName: type == "Librarians" ? "person.text.rectangle" : "person.2")
//                .font(.system(size: 60))
//                .foregroundColor(Color.primary(for: colorScheme).opacity(0.7))
//                .padding(.top, 60)
//
//            Text("No Active \(type) Yet") // Updated text slightly
//                .font(.title2)
//                .fontWeight(.medium)
//                .foregroundColor(Color.text(for: colorScheme))
//
//            Text("Tap the + button to add a new \(type.dropLast().lowercased()) or pull down to refresh.") // Updated text
//                .font(.subheadline)
//                .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
//                .multilineTextAlignment(.center)
//                .padding(.horizontal, 40)
//        }
//        .frame(maxWidth: .infinity, maxHeight: .infinity)
//    }
//}
//
//// MARK: - Row Views (Using your User model)
//struct LibrarianRow: View {
//    let user: User
//    @ObservedObject var viewModel: UsersViewModel // Needed for image conversion
//    @Environment(\.colorScheme) private var colorScheme
//
//    var body: some View {
//        HStack(spacing: 16) {
//            Group {
//                // Use viewModel helper to convert Data to UIImage
//                if let uiImage = viewModel.uiImage(from: user.profileImage) {
//                    Image(uiImage: uiImage)
//                        .resizable()
//                        .scaledToFill()
//                        .frame(width: 50, height: 50)
//                        .clipShape(Circle())
//                } else {
//                    Image(systemName: "person.circle.fill")
//                        .font(.system(size: 30))
//                        .foregroundColor(Color.primary(for: colorScheme))
//                        .frame(width: 50, height: 50)
//                }
//            }
//            .overlay(
//                Circle().stroke(Color.primary(for: colorScheme).opacity(0.2), lineWidth: 1)
//            )
//
//            VStack(alignment: .leading, spacing: 4) {
//                Text(user.name)
//                    .font(.system(size: 16, weight: .semibold, design: .rounded))
//                    .foregroundColor(Color.text(for: colorScheme))
//
//                Text(user.email)
//                    .font(.system(size: 14, design: .rounded))
//                    .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
//
//                // Display Library ID (common field from your model)
//                Text("Library ID: \(user.library_id)")
//                    .font(.system(size: 12, weight: .medium, design: .rounded))
//                    .foregroundColor(Color.primary(for: colorScheme).opacity(0.8))
//
//                // Phone number removed as it's not in the User model
//            }
//
//            Spacer()
//
//            Text("Staff") // Role indicator
//                .font(.system(size: 10, weight: .semibold, design: .rounded))
//                .padding(.horizontal, 8)
//                .padding(.vertical, 4)
//                .background(Capsule().fill(Color.primary(for: colorScheme).opacity(0.2)))
//                .foregroundColor(Color.primary(for: colorScheme))
//        }
//        .padding(.vertical, 8) // Consistent padding
//    }
//}
//
//struct MemberRow: View {
//    let user: User
//    @ObservedObject var viewModel: UsersViewModel // Needed for image conversion
//    @Environment(\.colorScheme) private var colorScheme
//
//    var body: some View {
//        HStack(spacing: 16) {
//            Group {
//                 // Use viewModel helper to convert Data to UIImage
//                 if let uiImage = viewModel.uiImage(from: user.profileImage) {
//                    Image(uiImage: uiImage)
//                        .resizable()
//                        .scaledToFill()
//                        .frame(width: 50, height: 50)
//                        .clipShape(Circle())
//                } else {
//                    Image(systemName: "person.circle.fill")
//                        .font(.system(size: 30))
//                        .foregroundColor(Color.accent(for: colorScheme)) // Use accent color for members
//                        .frame(width: 50, height: 50)
//                }
//            }
//            .overlay(
//                Circle().stroke(Color.accent(for: colorScheme).opacity(0.2), lineWidth: 1)
//            )
//
//            VStack(alignment: .leading, spacing: 4) {
//                Text(user.name)
//                    .font(.system(size: 16, weight: .semibold, design: .rounded))
//                    .foregroundColor(Color.text(for: colorScheme))
//
//                Text(user.email)
//                    .font(.system(size: 14, design: .rounded))
//                    .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
//
//                 // Display Library ID (common field from your model)
//                 Text("Library ID: \(user.library_id)")
//                    .font(.system(size: 12, weight: .medium, design: .rounded))
//                    .foregroundColor(Color.accent(for: colorScheme).opacity(0.8))
//
//                 // Phone number removed as it's not in the User model
//            }
//
//            Spacer()
//
//            Text("Member") // Role indicator
//                .font(.system(size: 10, weight: .semibold, design: .rounded))
//                .padding(.horizontal, 8)
//                .padding(.vertical, 4)
//                .background(Capsule().fill(Color.accent(for: colorScheme).opacity(0.2)))
//                .foregroundColor(Color.accent(for: colorScheme))
//        }
//        .padding(.vertical, 8) // Consistent padding
//    }
//}
//
//
//// MARK: - Unified Add User View (Using your User model)
//struct AddUserView: View {
//    @ObservedObject var viewModel: UsersViewModel
//    @Environment(\.dismiss) private var dismiss
//    @Environment(\.colorScheme) private var colorScheme
//    @FocusState private var focusField: AddUserField?
//
//    enum AddUserField {
//        case name, email, libraryId // Updated fields
//    }
//
//    // Determine title and colors based on the role being added
//    private var navigationTitle: String {
//        viewModel.roleToAdd == .librarian ? "Add Librarian" : "Add Member"
//    }
//    private var accentColor: Color {
//        viewModel.roleToAdd == .librarian ? Color.primary(for: colorScheme) : Color.accent(for: colorScheme)
//    }
//    // Check if form is valid for enabling Save button
//     private var isFormValid: Bool {
//         !viewModel.newUserInputName.isEmpty &&
//         !viewModel.newUserInputEmail.isEmpty &&
//         viewModel.isValidEmail(viewModel.newUserInputEmail) && // Added email format check
//         !viewModel.newUserInputLibraryId.isEmpty
//     }
//
//
//    var body: some View {
//        NavigationView {
//            ZStack {
//                LinearGradient( // Background
//                    gradient: Gradient(colors: [Color(.systemGroupedBackground), Color(.secondarySystemGroupedBackground)]),
//                    startPoint: .top, endPoint: .bottom
//                ).edgesIgnoringSafeArea(.all)
//
//                ScrollView {
//                    VStack(spacing: 24) {
//                        // Photo Selector
//                        VStack(spacing: 16) {
//                            photoSelector
//                            Text("Add \(viewModel.roleToAdd == .librarian ? "Librarian" : "Member") Photo (Optional)")
//                                .font(.system(size: 16, weight: .medium, design: .rounded))
//                                .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
//                        }
//                        .padding(.top, 20)
//
//                        // Form Fields
//                        VStack(spacing: 16) {
//                            formField(
//                                title: "Full Name",
//                                placeholder: "Enter full name",
//                                text: $viewModel.newUserInputName, // Bind to input state
//                                field: .name
//                            )
//
//                            emailField( // Use dedicated email field for validation feedback
//                                title: "Email",
//                                placeholder: "Enter email address",
//                                text: $viewModel.newUserInputEmail, // Bind to input state
//                                field: .email
//                            )
//
//                            formField( // Field for the required library_id
//                                title: "Library ID",
//                                placeholder: "Enter library identifier",
//                                text: $viewModel.newUserInputLibraryId, // Bind to input state
//                                field: .libraryId
//                            )
//                            // Phone field removed
//
//                        }
//                        .padding(.horizontal, 20)
//                    }
//                    .padding(.bottom, 50)
//                }
//            }
//            .navigationTitle(navigationTitle)
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Cancel") {
//                        viewModel.resetUserInputForm() // Reset input fields
//                        dismiss()
//                    }
//                    .foregroundColor(accentColor)
//                }
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Save") {
//                        viewModel.addUser()
//                        // Dismissal is handled within addUser on success now
//                        // dismiss() // Removed from here
//                    }
//                    .foregroundColor(accentColor)
//                    .disabled(!isFormValid) // Disable Save if form is invalid
//                }
//            }
//             // Ensure form resets if the sheet is dismissed by swipe
//             .onDisappear {
//                 // Optional: Decide if reset is needed on any disappearance
//                 // viewModel.resetUserInputForm()
//             }
//        }
//    }
//
//    // Photo Selector View (Handles UIImage temporarily)
//    private var photoSelector: some View {
//        PhotosPicker(selection: $viewModel.selectedPhoto, matching: .images) {
//            ZStack {
//                // Display the temporary UIImage
//                if let image = viewModel.newUserInputImage {
//                    Image(uiImage: image)
//                        .resizable().scaledToFill()
//                        .frame(width: 110, height: 110).clipShape(Circle())
//                        .overlay(Circle().stroke(accentColor, lineWidth: 2))
//                } else {
//                    Circle() // Placeholder
//                        .fill(Color.TabbarBackground(for: colorScheme))
//                        .frame(width: 110, height: 110)
//                        .overlay(Image(systemName: "camera.fill").foregroundColor(accentColor).font(.system(size: 40)))
//                }
//                // Plus badge
//                Circle().fill(accentColor).frame(width: 32, height: 32)
//                    .overlay(Image(systemName: "plus").foregroundColor(.white).font(.system(size: 18, weight: .bold)))
//                    .offset(x: 40, y: 40)
//            }
//        }
//        .onChange(of: viewModel.selectedPhoto) { newItem in
//            Task { // Load image data asynchronously
//                if let data = try? await newItem?.loadTransferable(type: Data.self) {
//                     // Update the temporary UIImage state in ViewModel
//                     viewModel.newUserInputImage = UIImage(data: data)
//                }
//            }
//        }
//    }
//
//    // Generic Form Field Builder
//    @ViewBuilder
//    private func formField(title: String, placeholder: String, text: Binding<String>, field: AddUserField) -> some View {
//         VStack(alignment: .leading, spacing: 8) {
//            Text(title)
//                .font(.system(size: 14, weight: .medium, design: .rounded))
//                .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
//            TextField(placeholder, text: text)
//                .font(.system(size: 16, design: .rounded))
//                .foregroundColor(Color.text(for: colorScheme))
//                .focused($focusField, equals: field)
//                .padding(16)
//                .background(fieldBackground) // Use helper
//         }
//    }
//
//     // Email Field Builder with Validation Feedback
//    @ViewBuilder
//    private func emailField(title: String, placeholder: String, text: Binding<String>, field: AddUserField) -> some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text(title)
//                 .font(.system(size: 14, weight: .medium, design: .rounded))
//                 .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
//
//            TextField(placeholder, text: text)
//                .font(.system(size: 16, design: .rounded))
//                .foregroundColor(Color.text(for: colorScheme))
//                .focused($focusField, equals: field)
//                .keyboardType(.emailAddress)
//                .textContentType(.emailAddress)
//                .autocapitalization(.none)
//                .padding(16)
//                .background(fieldBackground) // Use helper
//                .overlay( // Validation indicator
//                     RoundedRectangle(cornerRadius: 12)
//                        .stroke(emailInputBorderColor(text.wrappedValue), lineWidth: emailInputBorderWidth(text.wrappedValue))
//                 )
//
//            // Validation message
//            if !text.wrappedValue.isEmpty && !viewModel.isValidEmail(text.wrappedValue) {
//                 Text("Please enter a valid email address.")
//                     .font(.system(size: 12))
//                     .foregroundColor(.red)
//                     .padding(.leading, 4)
//                     .transition(.opacity.animation(.easeIn))
//             }
//         }
//    }
//
//     // Helper for email border color
//     private func emailInputBorderColor(_ email: String) -> Color {
//         if email.isEmpty {
//             return Color.gray.opacity(0.2) // Default subtle border
//         }
//         return viewModel.isValidEmail(email) ? Color.green.opacity(0.6) : Color.red.opacity(0.7)
//     }
//     // Helper for email border width
//      private func emailInputBorderWidth(_ email: String) -> CGFloat {
//          return email.isEmpty ? 0.5 : 1.0
//      }
//
//    // Common background for text fields
//    private var fieldBackground: some View {
//        RoundedRectangle(cornerRadius: 12)
//             .fill(Color.TabbarBackground(for: colorScheme)) // Use helper
//             .shadow(color: Color.black.opacity(colorScheme == .light ? 0.05 : 0.15), radius: 2, x: 0, y: 1)
//             .overlay( // Optional subtle border
//                 RoundedRectangle(cornerRadius: 12)
//                     .stroke(Color.gray.opacity(0.2), lineWidth: 0.5)
//             )
//    }
//}
//
//
//// MARK: - Preview Provider (Requires Mock Data)
//struct UsersViewAdmin_Previews: PreviewProvider {
//     // Create mock data using YOUR User model structure
//     static func createMockViewModel() -> UsersViewModel {
//         let vm = UsersViewModel()
//         vm.users = [
//            User(id: UUID(), email: "librarian1@example.com", role: .librarian, name: "Alice The Librarian", isActive: true, library_id: "MAINLIB", profileImage: UIImage(systemName: "person.crop.circle.fill")?.jpegData(compressionQuality: 0.8)),
//             User(id: UUID(), email: "member1@example.com", role: .member, name: "Bob The Member",isActive: true, library_id: "MAINLIB"),
//             User(id: UUID(), email: "librarian2@example.com", role: .librarian, name: "Charles Staff",isActive: true, library_id: "BRANCHLIB"),
//             User(id: UUID(), email: "member2@example.com", role: .member, name: "Diana User",isActive: true, library_id: "MAINLIB", profileImage: UIImage(systemName: "person.crop.circle")?.jpegData(compressionQuality: 0.8))
//         ]
//         return vm
//     }
//
//     // Create a ViewModel configured for adding a specific role
//     static func createAddViewModel(role: UserRole) -> UsersViewModel {
//         let vm = UsersViewModel()
//         vm.prepareToAddUser(role: role)
//         return vm
//     }
//
//    static var previews: some View {
//        Group {
//            UsersViewAdmin()
//                 .preferredColorScheme(.light)
//                 .previewDisplayName("Main View - Light")
//
//            UsersViewAdmin() // Empty state
//                 .preferredColorScheme(.dark)
//                 .previewDisplayName("Main View - Dark (Empty)")
//
//             AddUserView(viewModel: createAddViewModel(role: .librarian))
//                 .preferredColorScheme(.light)
//                 .previewDisplayName("Add Librarian Sheet")
//
//             AddUserView(viewModel: createAddViewModel(role: .member))
//                 .preferredColorScheme(.dark)
//                 .previewDisplayName("Add Member Sheet")
//        }
//    }
//}
