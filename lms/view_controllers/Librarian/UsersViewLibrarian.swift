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
                AddUserView(viewModel: viewModel)
            }
            // Confirmation dialog for activation/deactivation
            .confirmationDialog(
                viewModel.toggleActionIsActivate ? "Confirm Activation" : "Confirm Deactivation",
                isPresented: $viewModel.showToggleConfirmation,
                presenting: viewModel.userToToggle
            ) { user in
                Button(
                    viewModel.toggleActionIsActivate ? "Activate \(user.name)" : "Deactivate \(user.name)",
                    role: viewModel.toggleActionIsActivate ? .none : .destructive
                ) {
                    viewModel.confirmToggleUserStatus()
                }
                Button("Cancel", role: .cancel) {
                    viewModel.userToToggle = nil
                }
            } message: { user in
                let action = viewModel.toggleActionIsActivate ? "activate" : "deactivate"
                Text("Are you sure you want to \(action) this member (\(user.name))?")
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
            ForEach(viewModel.activeMembers) { user in
                MemberRow(user: user, viewModel: viewModel)
                    .id(user.id.uuidString + (user.is_active ?? false ? "-active" : "-inactive"))
            }
        }
        .id(viewModel.activeMembers.map { $0.id.uuidString + ($0.is_active ?? false ? "-active" : "-inactive") }.joined())
        .listStyle(.plain)
        .overlay {
            if viewModel.activeMembers.isEmpty {
                EmptyStateView(type: "Members", colorScheme: colorScheme)
            }
        }
        .refreshable {
            print("Refreshing members...")
            viewModel.fetchUsersoflibrary()
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
