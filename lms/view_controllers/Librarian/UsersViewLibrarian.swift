import Foundation
import SwiftUI

struct UsersViewLibrarian: View {
    @StateObject private var viewModel = UsersViewModel()
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            ZStack {
                ReusableBackground(colorScheme: colorScheme)

                // Changed to show members list instead of librarians
                membersListView
            }
            .onAppear {
                viewModel.fetchUsersoflibrary()
            }
            .navigationTitle("Members") // Changed title
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Changed to add member instead of librarian
                        viewModel.prepareToAddUser(role: .member)
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(Color.primary(for: colorScheme))
                    }
                }
            }
            .sheet(isPresented: $viewModel.isShowingAddUserSheet) {
                AddUserView(viewModel: viewModel)
            }
            .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(viewModel.alertMessage)
            }
        }
    }

    private var membersListView: some View {
        List {
            // Changed to show members instead of librarians
            ForEach(viewModel.activeMembers) { user in
                MemberRow(user: user, viewModel: viewModel) // Changed to MemberRow
            }
        }
        .listStyle(.plain)
        .overlay {
            if viewModel.activeMembers.isEmpty {
                EmptyStateView(type: "members", colorScheme: colorScheme)
            }
        }
        .refreshable {
            viewModel.fetchUsersoflibrary()
        }
    }

    private func addMockData() {
        #if DEBUG
        viewModel.users = [
            // Changed mock data to show members
            User(id: UUID(), email: "member1@example.com", role: .member, name: "John Doe", is_active: true,
                 library_id: "MAINLIB", borrowed_book_ids: [], reserved_book_ids: [], wishlist_book_ids: [],
                 created_at: "", updated_at: "", profileImage: UIImage(systemName: "person.crop.circle.fill")?.jpegData(compressionQuality: 0.8)),
            User(id: UUID(), email: "member2@example.com", role: .member, name: "Jane Smith", is_active: true,
                 library_id: "MAINLIB", borrowed_book_ids: [], reserved_book_ids: [], wishlist_book_ids: [])
        ]
        #endif
    }
}

#if DEBUG
struct UsersViewLibrarian_Previews: PreviewProvider {
    static var previews: some View {
        UsersViewLibrarian()
            .preferredColorScheme(.light)
            .previewDisplayName("Members Management - Light")

        UsersViewLibrarian()
            .preferredColorScheme(.dark)
            .previewDisplayName("Members Management - Dark")
    }
}
#endif
