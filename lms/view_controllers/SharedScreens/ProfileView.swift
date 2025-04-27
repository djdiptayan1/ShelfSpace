import SwiftUI

struct ProfileView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    
    // Add parameters for prefetched data
    let prefetchedUser: User?
    let prefetchedLibrary: Library?
    
    @State private var user: User?
    @State private var library: Library?
    
    // State for data management
    @State private var isLoading = false
    @State private var showLogoutAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    init(prefetchedUser: User? = nil, prefetchedLibrary: Library? = nil) {
        self.prefetchedUser = prefetchedUser
        self.prefetchedLibrary = prefetchedLibrary
    }
    
    var body: some View {
        ZStack {
            ReusableBackground(colorScheme: colorScheme)
            
            if isLoading {
                LoadingView()
            } else if let user = user {
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
                                            if let city = library.city, let state = library.state {
                                                DetailRow(title: "Location", value: "\(city), \(state)")
                                            }
                                        }
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
            } else {
                ErrorView(
                    errorMessage: errorMessage,
                    retryAction: {
                        loadUserData()
                    }
                )
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Done") {
                    dismiss()
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
        .onAppear {
            // Use prefetched data if available
            if let prefetchedUser = prefetchedUser {
                self.user = prefetchedUser
                self.library = prefetchedLibrary
            } else {
                loadUserData()
            }
        }
    }
    
    private func loadUserData(forceRefresh: Bool = false) {
        // If we have prefetched data, use it
        if let prefetchedUser = prefetchedUser {
            self.user = prefetchedUser
            self.library = prefetchedLibrary
            return
        }
        
        isLoading = true
        errorMessage = ""
        
        Task {
            do {
                // First try to get from cache if not forcing refresh
                if !forceRefresh, let cachedUser = UserCacheManager.shared.getCachedUser() {
                    await MainActor.run {
                        self.user = cachedUser
                        self.isLoading = false
                    }
                    
                    // Load library data in background
                    loadLibraryData(libraryId: cachedUser.library_id)
                    return
                }
                
                // If no cache or force refresh, fetch from server
                if let currentUser = try await LoginManager.shared.getCurrentUser() {
                    await MainActor.run {
                        self.user = currentUser
                        self.isLoading = false
                    }
                    
                    // Load library data in background
                    loadLibraryData(libraryId: currentUser.library_id)
                } else {
                    // If no user found, check if we're logged in
                    if appState.isLoggedIn {
                        // If we're logged in but can't get user data, show error
                        throw NSError(domain: "ProfileError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to load user data. Please try again."])
                    } else {
                        // If we're not logged in, don't show error
                        await MainActor.run {
                            self.isLoading = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    if appState.isLoggedIn {
                        self.errorMessage = error.localizedDescription
                        self.showErrorAlert = true
                    }
                }
            }
        }
    }
    
    private func loadLibraryData(libraryId: String) {
        Task {
            do {
                let libraryData = try await LoginManager.shared.fetchLibraryData(libraryId: libraryId)
                await MainActor.run {
                    self.library = libraryData
                }
            } catch {
                print("Failed to load library data:")
                error.logDetails()
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        // First try to parse the date string directly
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        
        if let date = dateFormatter.date(from: dateString) {
            let outputFormatter = DateFormatter()
            outputFormatter.dateStyle = .medium
            outputFormatter.timeStyle = .none
            return outputFormatter.string(from: date)
        }
        
        // If direct parsing fails, try to extract just the date part
        let components = dateString.split(separator: "T")
        if let datePart = components.first {
            return String(datePart)
        }
        
        // If all else fails, return the original string
        return dateString
    }
    
    private func logout() {
        Task {
            do {
                // First reset the app state
                await MainActor.run {
                    appState.resetState()
                }
                
                // Then perform the logout operations
                try await LoginManager.shared.signOut()
                UserCacheManager.shared.clearCache()
                
                // Finally dismiss the view
                await MainActor.run {
                    dismiss()
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
