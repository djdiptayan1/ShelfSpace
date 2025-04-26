////
////  UsersViewModel.swift
////  lms
////
////  Created by Diptayan Jash on 25/04/25.
////
//import Foundation
//import SwiftUI
//import Combine
//
//class UsersViewModel: ObservableObject {
//    @Published var selectedSegment = 0
//    @Published var users: [User] = [] // Your User model list
//
//    // Computed properties - Filter using the User model's is_active flag
//    var activeLibrarians: [User] {
//        users.filter { $0.role == .librarian && ($0.is_active != nil) }
//    }
//    var activeMembers: [User] {
//        users.filter { $0.role == .member && ($0.is_active != nil) }
//    }
//
//    // State for Add User Sheet
//    @Published var isShowingAddUserSheet = false
//    @Published var roleToAdd: UserRole?
//    @Published var newUserInputName: String = ""
//    @Published var newUserInputEmail: String = ""
//    @Published var newUserInputLibraryId: String = ""
//    @Published var newUserInputImage: UIImage? = nil
//
//    // State for Deactivation Confirmation
//    @Published var userToDeactivate: UUID?
//    @Published var showDeactivateConfirmation = false
//    @Published var userMarkedForDeactivation: User?
//
//    // --- Functions ---
//
//    func prepareToAddUser(role: UserRole) {
//        roleToAdd = role
//        resetUserInputForm()
//        isShowingAddUserSheet = true
//    }
//
//    func addUser() {
//        guard let role = roleToAdd,
//              !newUserInputName.isEmpty,
//              isValidEmail(newUserInputEmail),
//              !newUserInputLibraryId.isEmpty
//        else {
//             print("Validation failed for adding user.")
//             return
//         }
//        let profileImageData = newUserInputImage?.jpegData(compressionQuality: 0.8)
//        let newUser = User(
//            id: UUID(),
//            email: newUserInputEmail,
//            role: role,
//            name: newUserInputName,
//            is_active: true, // New users are active
//            library_id: newUserInputLibraryId,
//            profileImage: profileImageData
//        )
//        users.append(newUser)
//        resetUserInputForm()
//        isShowingAddUserSheet = false
//        objectWillChange.send()
//    }
//
//    // MARK: Deactivation Handling (Updates is_active flag)
//    func confirmDeactivateUser(_ user: User) {
//        userToDeactivate = user.id
//        userMarkedForDeactivation = user
//        showDeactivateConfirmation = true
//    }
//
//    // --- THIS IS THE CORRECTED FUNCTION ---
//    func deactivateConfirmed() {
//        guard let id = userToDeactivate else {
//             print("Error: No user ID marked for deactivation.")
//             return
//         }
//
//        // Find the index of the user in the main users array
//        if let index = users.firstIndex(where: { $0.id == id }) {
//            // Modify the is_active property directly on the user object in the array
//            users[index].is_active = false
//            print("User '\(users[index].name)' (ID: \(id)) marked as inactive.")
//
//            // --- IMPORTANT ---
//            // If 'users' comes from a database/API, you MUST also call a function here
//            // to update the backend/persistent storage with the new 'isActive' status.
//            // Example: updateUserStatusOnBackend(userId: id, isActive: false)
//            // ---
//
//            objectWillChange.send() // Notify SwiftUI about the data change
//        } else {
//            print("Error: User with ID \(id) not found in the users array for deactivation.")
//        }
//
//        // Reset the temporary state variables
//        userToDeactivate = nil
//        userMarkedForDeactivation = nil
//        // showDeactivateConfirmation is handled by its binding
//    }
//    // --- END OF CORRECTION ---
//
//
//    func resetUserInputForm() {
//        newUserInputName = ""
//        newUserInputEmail = ""
//        newUserInputLibraryId = ""
//        newUserInputImage = nil
//    }
//
//    func isValidEmail(_ email: String) -> Bool {
//        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
//        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
//        return emailPred.evaluate(with: email)
//    }
//
//     func uiImage(from data: Data?) -> UIImage? {
//         guard let data = data else { return nil }
//         return UIImage(data: data)
//     }
//}
