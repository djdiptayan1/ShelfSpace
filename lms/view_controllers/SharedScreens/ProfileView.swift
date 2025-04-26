//import SwiftUI
//
//struct ProfileViewAdmin: View {
//    @Environment(\.colorScheme) private var colorScheme
//    @State private var user: User?
//    @State private var isLoading = true
//    @State private var showLogoutAlert = false
//    @State private var showErrorAlert = false
//    @State private var errorMessage = ""
//    
//    var body: some View {
//        NavigationView {
//            ZStack {
//                ReusableBackground(colorScheme: colorScheme)
//                
//                if isLoading {
//                    ProgressView()
//                        .progressViewStyle(CircularProgressViewStyle())
//                } else if let user = user {
//                    ScrollView {
//                        VStack(spacing: 24) {
//                            // Profile Header
//                            VStack(spacing: 16) {
//                                ZStack {
//                                    Circle()
//                                        .fill(Color.primary(for: colorScheme).opacity(0.1))
//                                        .frame(width: 120, height: 120)
//                                    
//                                    Image(systemName: "person.circle.fill")
//                                        .font(.system(size: 60))
//                                        .foregroundColor(Color.primary(for: colorScheme))
//                                }
//                                
//                                VStack(spacing: 4) {
//                                    Text(user.name)
//                                        .font(.title2)
//                                        .fontWeight(.bold)
//                                        .foregroundColor(Color.text(for: colorScheme))
//                                    
//                                    Text(user.email)
//                                        .font(.subheadline)
//                                        .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
//                                }
//                            }
//                            .padding(.top, 32)
//                            
//                            // User Details Card
//                            VStack(alignment: .leading, spacing: 16) {
//                                Text("Account Details")
//                                    .font(.headline)
//                                    .foregroundColor(Color.text(for: colorScheme))
//                                
//                                DetailRow(title: "Role", value: user.role.rawValue.capitalized)
//                                DetailRow(title: "User ID", value: user.id.uuidString)
//                            }
//                            .padding()
//                            .background(
//                                RoundedRectangle(cornerRadius: 12)
//                                    .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
//                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
//                            )
//                            .padding(.horizontal)
//                            
//                            Spacer()
//                            
//                            // Logout Button
//                            Button {
//                                showLogoutAlert = true
//                            } label: {
//                                HStack {
//                                    Image(systemName: "rectangle.portrait.and.arrow.right")
//                                    Text("Log Out")
//                                }
//                                .foregroundColor(.white)
//                                .frame(maxWidth: .infinity)
//                                .padding()
//                                .background(Color.red)
//                                .cornerRadius(12)
//                            }
//                            .padding(.horizontal)
//                            .padding(.bottom, 32)
//                        }
//                    }
//                } else {
//                    VStack(spacing: 16) {
//                        Image(systemName: "person.crop.circle.badge.exclamationmark")
//                            .font(.system(size: 60))
//                            .foregroundColor(.gray)
//                        
//                        Text("Unable to load profile")
//                            .font(.headline)
//                            .foregroundColor(Color.text(for: colorScheme))
//                        
//                        Button {
//                            loadUserProfile()
//                        } label: {
//                            Text("Try Again")
//                                .foregroundColor(.white)
//                                .padding()
//                                .background(Color.blue)
//                                .cornerRadius(8)
//                        }
//                    }
//                }
//            }
//            .navigationTitle("Profile")
//            .alert("Log Out", isPresented: $showLogoutAlert) {
//                Button("Cancel", role: .cancel) { }
//                Button("Log Out", role: .destructive) {
//                    logout()
//                }
//            } message: {
//                Text("Are you sure you want to log out?")
//            }
//            .alert("Error", isPresented: $showErrorAlert) {
//                Button("OK", role: .cancel) { }
//            } message: {
//                Text(errorMessage)
//            }
//        }
//        .onAppear {
//            loadUserProfile()
//        }
//    }
//    
//    private func loadUserProfile() {
//        isLoading = true
//        Task {
//            do {
//                if let currentUser = try await LoginManager.shared.getCurrentUser() {
//                    await MainActor.run {
//                        self.user = currentUser
//                        self.isLoading = false
//                    }
//                } else {
//                    await MainActor.run {
//                        self.isLoading = false
//                        self.errorMessage = "No user found. Please log in again."
//                        self.showErrorAlert = true
//                    }
//                }
//            } catch {
//                await MainActor.run {
//                    self.isLoading = false
//                    self.errorMessage = error.localizedDescription
//                    self.showErrorAlert = true
//                }
//            }
//        }
//    }
//    
//    private func logout() {
//        Task {
//            do {
//                try await LoginManager.shared.signOut()
//                // Clear any other user data if needed
//                await MainActor.run {
//                    // You might want to navigate to login screen here
//                    // or handle the navigation in the parent view
//                }
//            } catch {
//                await MainActor.run {
//                    self.errorMessage = "Failed to log out: \(error.localizedDescription)"
//                    self.showErrorAlert = true
//                }
//            }
//        }
//    }
//}
//
//struct DetailRow: View {
//    let title: String
//    let value: String
//    @Environment(\.colorScheme) private var colorScheme
//    
//    var body: some View {
//        HStack {
//            Text(title)
//                .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
//            Spacer()
//            Text(value)
//                .foregroundColor(Color.text(for: colorScheme))
//        }
//    }
//}
import SwiftUI

struct ProfileView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss // Add dismiss environment action

    // Receive user and library data via initializer
    let user: User
    let library: Library? // Library can still be optional if fetching fails

    // State for alerts remains
    @State private var showLogoutAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    var body: some View {
        // No need for NavigationView here if presented in a sheet
        // The parent NavigationView provides the context
        ZStack {
            ReusableBackground(colorScheme: colorScheme)

            // Directly show content as user is guaranteed by initializer
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header with Avatar
                    ProfileHeaderView(user: user)

                    // Main Content Cards
                    VStack(spacing: 16) {
                        // User Details Card
                        InfoCardView(
                            title: "Account Details",
                            icon: "person.text.rectangle",
                            content: {
                                VStack(spacing: 8) {
                                    DetailRow(title: "Full Name", value: user.name)
                                    DetailRow(title: "Email", value: user.email)
                                    DetailRow(title: "Role", value: user.role.rawValue.capitalized)
                                    DetailRow(title: "User ID", value: user.id.uuidString.prefix(8) + "...")
                                }
                            }
                        )

                        // Library Information Card
                        if let library = library {
                            InfoCardView(
                                title: "Library Information",
                                icon: "books.vertical",
                                content: {
                                    VStack(spacing: 8) {
                                        DetailRow(title: "Library", value: library.name)
                                        DetailRow(title: "Location", value: "\(library.city), \(library.state)")
                                    }
                                }
                            )
                        } else {
                             // Optionally show a placeholder or message if library data is missing
                             InfoCardView(
                                 title: "Library Information",
                                 icon: "books.vertical",
                                 content: {
                                     Text("Library details not available.")
                                         .font(.subheadline)
                                         .foregroundColor(.gray)
                                 }
                             )
                        }

                        // Additional User Details Card
                        InfoCardView(
                            title: "Additional Details",
                            icon: "person.crop.rectangle.stack",
                            content: {
                                VStack(spacing: 8) {
                                    if let age = user.age {
                                        DetailRow(title: "Age", value: "\(age)")
                                    }
                                    if let phone = user.phone_number {
                                        DetailRow(title: "Phone", value: phone)
                                    }
                                    if let gender = user.gender {
                                        DetailRow(title: "Gender", value: gender.capitalized)
                                    }
                                    if let interests = user.interests, !interests.isEmpty {
                                        DetailRow(title: "Interests", value: interests.joined(separator: ", "))
                                    } else if user.interests != nil { // Handle empty array case
                                        DetailRow(title: "Interests", value: "N/A")
                                    }
                                    DetailRow(title: "Member Since", value: formatDate(user.created_at))
                                }
                            }
                        )

                        // Stats Card
                        StatsCardView(user: user)
                    }
                    .padding(.horizontal)

                    // Logout Button
                    LogoutButton(showLogoutAlert: $showLogoutAlert)
                        .padding(.top, 8)
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                }
            }
            // No need for ErrorView for initial load here
            // No need for LoadingView here
        }
        .navigationTitle("Profile") // Title for the sheet
        .navigationBarTitleDisplayMode(.inline) // Use inline for sheets usually
        .toolbar {
             ToolbarItem(placement: .navigationBarLeading) { // Add a Done button for sheets
                 Button("Done") {
                     dismiss()
                 }
             }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // Action for editing profile - Implement this later
                    print("Edit profile tapped")
                }) {
                    Label("Edit", systemImage: "pencil")
                        // .foregroundColor(.blue) // Use default accent color
                }
            }
        }
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                logout()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        // Remove .onAppear { loadUserProfile() }
    }

    // formatDate and logout functions remain the same
     private func formatDate(_ dateString: String) -> String {
         // Use ISO8601DateFormatter for robustness
         let formatter = ISO8601DateFormatter()
         formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds] // Match "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

         if let date = formatter.date(from: dateString) {
             let displayFormatter = DateFormatter()
             displayFormatter.dateStyle = .medium
             displayFormatter.timeStyle = .none
             return displayFormatter.string(from: date)
         }
         // Fallback for unexpected formats
         let fallbackFormatter = DateFormatter()
         fallbackFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ" // Try without fractional seconds
          if let date = fallbackFormatter.date(from: dateString) {
             let displayFormatter = DateFormatter()
             displayFormatter.dateStyle = .medium
             displayFormatter.timeStyle = .none
             return displayFormatter.string(from: date)
         }

         print("Warning: Could not parse date string: \(dateString)")
         // Return a portion of the original string as a fallback
         return String(dateString.prefix(10)) // Just the date part YYYY-MM-DD
     }

    private func logout() {
        Task {
            do {
                try await LoginManager.shared.signOut()
                // Dismiss the profile sheet after successful logout
                await MainActor.run {
                    dismiss()
                    // Optionally, post a notification or update shared state
                    // to trigger navigation to the login screen in the parent.
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = "Failed to log out: \(error.localizedDescription)"
                    self.showErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ProfileHeaderView: View {
    let user: User
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 16) {
            // Avatar circle with first letter of name
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                Text(String(user.name.prefix(1)).uppercased())
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(spacing: 6) {
                Text(user.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                
                Text(user.email)
                    .font(.subheadline)
                    .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                
                HStack {
                    Text(user.role.rawValue.capitalized)
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(20)
                    
                    if user.is_active {
                        Text("Active")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(20)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(.top, 30)
    }
}

struct InfoCardView<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Text(title)
                    .font(.headline)
                    .foregroundColor(colorScheme == .dark ? .white : .black)
            }
            
            Divider()
                .background(colorScheme == .dark ? Color.gray.opacity(0.3) : Color.gray.opacity(0.2))
            
            content()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(hex: "252525") : .white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

struct StatsCardView: View {
    let user: User
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 20) {
            StatItem(
                value: user.borrowed_book_ids.count,
                label: "Borrowed",
                iconName: "book.closed",
                color: .blue
            )
            
            StatItem(
                value: user.reserved_book_ids.count,
                label: "Reserved",
                iconName: "clock",
                color: .orange
            )
            
            StatItem(
                value: user.wishlist_book_ids.count,
                label: "Wishlist",
                iconName: "heart",
                color: .red
            )
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(hex: "252525") : .white)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
}

struct StatItem: View {
    let value: Int
    let label: String
    let iconName: String
    let color: Color
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.title2)
                .foregroundColor(color)
            
            Text("\(value)")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Text(label)
                .font(.caption)
                .foregroundColor(colorScheme == .dark ? .gray : .secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .gray : .secondary)
                .frame(width: 100, alignment: .leading)
            
            Text(value)
                .font(.subheadline)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
    }
}

struct LogoutButton: View {
    @Binding var showLogoutAlert: Bool
    
    var body: some View {
        Button {
            showLogoutAlert = true
        } label: {
            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                Text("Log Out")
                    .fontWeight(.medium)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.red.opacity(0.8), Color.red]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
            .shadow(color: Color.red.opacity(0.3), radius: 5, x: 0, y: 3)
        }
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
            
            Text("Loading profile...")
                .font(.headline)
                .foregroundColor(.gray)
        }
    }
}

struct ErrorView: View {
    let errorMessage: String
    let retryAction: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 60))
                .foregroundColor(.red.opacity(0.8))
            
            Text("Unable to load profile")
                .font(.headline)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            
            Text(errorMessage)
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                retryAction()
            } label: {
                Text("Try Again")
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                    .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
            }
        }
    }
}
//#Preview {
//    ProfileView(user: User, library: Library?)
//}
