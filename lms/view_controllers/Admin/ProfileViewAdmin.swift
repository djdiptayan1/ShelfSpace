import SwiftUI

struct ProfileViewAdmin: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var user: User?
    @State private var isLoading = true
    @State private var showLogoutAlert = false
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                ReusableBackground(colorScheme: colorScheme)
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                } else if let user = user {
                    ScrollView {
                        VStack(spacing: 24) {
                            // Profile Header
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.primary(for: colorScheme).opacity(0.1))
                                        .frame(width: 120, height: 120)
                                    
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(Color.primary(for: colorScheme))
                                }
                                
                                VStack(spacing: 4) {
                                    Text(user.name)
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(Color.text(for: colorScheme))
                                    
                                    Text(user.email)
                                        .font(.subheadline)
                                        .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                                }
                            }
                            .padding(.top, 32)
                            
                            // User Details Card
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Account Details")
                                    .font(.headline)
                                    .foregroundColor(Color.text(for: colorScheme))
                                
                                DetailRow(title: "Role", value: user.role.rawValue.capitalized)
                                DetailRow(title: "User ID", value: user.id.uuidString)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
                                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                            )
                            .padding(.horizontal)
                            
                            Spacer()
                            
                            // Logout Button
                            Button {
                                showLogoutAlert = true
                            } label: {
                                HStack {
                                    Image(systemName: "rectangle.portrait.and.arrow.right")
                                    Text("Log Out")
                                }
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 32)
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("Unable to load profile")
                            .font(.headline)
                            .foregroundColor(Color.text(for: colorScheme))
                        
                        Button {
                            loadUserProfile()
                        } label: {
                            Text("Try Again")
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
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
        }
        .onAppear {
            loadUserProfile()
        }
    }
    
    private func loadUserProfile() {
        isLoading = true
        Task {
            do {
                if let currentUser = try await LoginManager.shared.getCurrentUser() {
                    await MainActor.run {
                        self.user = currentUser
                        self.isLoading = false
                    }
                } else {
                    await MainActor.run {
                        self.isLoading = false
                        self.errorMessage = "No user found. Please log in again."
                        self.showErrorAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                    self.showErrorAlert = true
                }
            }
        }
    }
    
    private func logout() {
        Task {
            do {
                try await LoginManager.shared.signOut()
                // Clear any other user data if needed
                await MainActor.run {
                    // You might want to navigate to login screen here
                    // or handle the navigation in the parent view
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

struct DetailRow: View {
    let title: String
    let value: String
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
            Spacer()
            Text(value)
                .foregroundColor(Color.text(for: colorScheme))
        }
    }
}

#Preview {
    ProfileViewAdmin()
} 
