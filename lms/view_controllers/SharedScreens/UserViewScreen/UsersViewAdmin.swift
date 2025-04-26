//
//  UsersViewAdmin.swift
//  lms
//
//  Created by Diptayan Jash on 25/04/25.
//

import Foundation
import SwiftUI

struct UsersViewAdmin: View {
    // Use @StateObject to create and own the ViewModel instance for this view hierarchy
    @StateObject private var viewModel = UsersViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            ZStack {
                ReusableBackground(colorScheme: colorScheme) // Use helper

                VStack(spacing: 0) {
                    Picker("User Type", selection: $viewModel.selectedSegment) {
                        Text("Librarians").tag(0)
                        Text("Members").tag(1)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    // Display the appropriate list based on selection
                    if viewModel.selectedSegment == 0 {
                        librariansListView
                    } else {
                        membersListView
                    }
                }
                // Example: Load initial data or handle user activity if needed
                 .onAppear {
                     // If you need to fetch data initially, do it here.
                     // Example: viewModel.fetchUsers()
                     // For demo: Add some mock data if the list is empty
                     if viewModel.users.isEmpty {
                          addMockData() // Use mock data for preview/demo
                     }
                 }
            }
            .navigationTitle("Users")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Determine role based on segment and prepare to add
                        let role: UserRole = (viewModel.selectedSegment == 0) ? .librarian : .member
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
                let userType = user.role == .librarian ? "librarian" : "member"
                Text("Are you sure you want to deactivate this \(userType) (\(user.name))? They will no longer have access.")
            }
        }
        // Ensure the ViewModel is accessible to child views needing it
        // .environmentObject(viewModel) // Optional: Use if deeply nested views need it
    }

    // MARK: - List Views (Private to UsersViewAdmin)

    private var librariansListView: some View {
        List {
            // Use the computed property from ViewModel
            ForEach(viewModel.activeLibrarians) { user in
                 // Navigate to the dedicated Row View
                 LibrarianRow(user: user, viewModel: viewModel)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            // Pass the user object to start confirmation
                             viewModel.confirmDeactivateUser(user)
                        } label: {
                            Label("Deactivate", systemImage: "person.fill.xmark")
                        }
                        .tint(.red)
                    }
            }
        }
        .listStyle(.plain)
        .overlay { // Show empty state if list is empty
            if viewModel.activeLibrarians.isEmpty {
                EmptyStateView(type: "Librarians", colorScheme: colorScheme) // Use helper view
            }
        }
        .refreshable { // Example refresh action
             // Add logic to fetch/refresh users from your data source
             print("Refreshing librarians...")
             // Example: await viewModel.fetchUsers()
         }
    }

    private var membersListView: some View {
        List {
            // Use the computed property from ViewModel
            ForEach(viewModel.activeMembers) { user in
                 // Navigate to the dedicated Row View
                 MemberRow(user: user, viewModel: viewModel)
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            // Pass the user object to start confirmation
                             viewModel.confirmDeactivateUser(user)
                        } label: {
                            Label("Deactivate", systemImage: "person.fill.xmark")
                        }
                        .tint(.red)
                    }
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
struct UsersViewAdmin_Previews: PreviewProvider {
    static var previews: some View {
        UsersViewAdmin()
            .preferredColorScheme(.light)
            .previewDisplayName("Main View - Light")

        UsersViewAdmin()
            .preferredColorScheme(.dark)
            .previewDisplayName("Main View - Dark")
    }
}
#endif
