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

                // Display only the librarians list
                librariansListView
            }
            // Load initial data
            .onAppear {
                viewModel.fetchUsersoflibrary()
            }
            .navigationTitle("Librarians")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Prepare to add a librarian
                        viewModel.prepareToAddUser(role: .librarian)
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
            .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.alertMessage)
            }
        }
    }

    // MARK: - List View (Private to UsersViewLibrarian)

    private var librariansListView: some View {
        List {
            // Use the computed property from ViewModel
            ForEach(viewModel.activeLibrarians) { user in
                // Navigate to the dedicated Row View (no deactivation action)
                LibrarianRow(user: user, viewModel: viewModel)
            }
        }
        .listStyle(.plain)
        .overlay {
            if viewModel.activeLibrarians.isEmpty {
                EmptyStateView(type: "Librarians", colorScheme: colorScheme) // Use helper view
            }
        }
        .refreshable {
            print("Refreshing librarians...")
            // Example: await viewModel.fetchUsers()
        }
    }

    // Helper function to add mock data for previews/testing
    private func addMockData() {
        #if DEBUG // Only include mock data in Debug builds
        viewModel.users = [
            User(id: UUID(), email: "librarian1@example.com", role: .librarian, name: "Alice (Mock)", is_active: true, library_id: "MAINLIB", profileImage: UIImage(systemName: "person.crop.circle.fill")?.jpegData(compressionQuality: 0.8)),
            User(id: UUID(), email: "librarian2@example.com", role: .librarian, name: "Charles (Mock)", is_active: false, library_id: "BRANCHLIB") // Inactive
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
            .previewDisplayName("Librarian View - Light")

        UsersViewLibrarian()
            .preferredColorScheme(.dark)
            .previewDisplayName("Librarian View - Dark")
    }
}
#endif
