//
//  HomeViewAdmin.swift
//  lms
//
//  Created by Diptayan Jash on 23/04/25.
//

import SwiftUI
import Charts
import NavigationBarLargeTitleItems

struct HomeViewAdmin: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var lastHostingView: UIView!
    @State private var isShowingProfile = false
    
    @State private var prefetchedUser: User? = nil
    @State private var prefetchedLibrary: Library? = nil
    @State private var isPrefetchingProfile = false
    @State private var prefetchError: String? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                ReusableBackground(colorScheme: colorScheme)
                
                ScrollView {
                    //                    VStack() {
                    //                        headerSection
                    AdminAnalyticsView()
                    //                    }
                    //                    .padding()
                }
                .navigationTitle("Library Name")
                .navigationBarLargeTitleItems(trailing: ProfileIcon(isShowingProfile: $isShowingProfile))}
            .task {
                await prefetchProfileData()
            }
        }
        .sheet(isPresented: $isShowingProfile) {
            Group {
                if isPrefetchingProfile {
                    ProgressView("Loading Profile...")
                        .padding()
                } else if let user = prefetchedUser, let library = prefetchedLibrary {
                    ProfileView(prefetchedUser: user, prefetchedLibrary: library)
                        .navigationBarItems(trailing: Button("Done") {
                            isShowingProfile = false
                        })
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text("Could Not Load Profile")
                            .font(.headline)
                        if let errorMsg = prefetchError {
                            Text(errorMsg)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                        }
                        Button("Retry") {
                            Task { await prefetchProfileData() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
            }
        }
    }
    

    // MARK: - Header
//    private var headerSection: some View {
//        HStack {
//            VStack(alignment: .leading, spacing: 4) {
//                Text("Welcome Navdeep!")
//                    .font(.title2)
//                    .foregroundColor(Color.text(for: colorScheme))
//
//                Text("Library Name")
//                    .font(.largeTitle)
//                    .fontWeight(.bold)
//                    .foregroundColor(Color.text(for: colorScheme))
//            }
//
//            Spacer()
//
//            Button(action: {
//                // Profile action
//            }) {
//                Image(systemName: "person.circle.fill")
//                    .resizable()
//                    .frame(width: 44, height: 44)
//                    .foregroundColor(Color.primary(for: colorScheme).opacity(0.9))
//            }
//        }
//    }
    private func prefetchProfileData() async {
        // Avoid redundant fetches if already loading or data exists
        guard !isPrefetchingProfile else { return }
        
        isPrefetchingProfile = true
        prefetchError = nil
        print("Prefetching profile data...") // Debug log

        do {
            // First try to get from cache
            if let cachedUser = UserCacheManager.shared.getCachedUser() {
                print("Using cached user data")
                let libraryData = try await fetchLibraryData(libraryId: cachedUser.library_id)
                
                await MainActor.run {
                    self.prefetchedUser = cachedUser
                    self.prefetchedLibrary = libraryData
                    self.isPrefetchingProfile = false
                }
                return
            }
            
            // If no cache, fetch from server
            guard let currentUser = try await LoginManager.shared.getCurrentUser() else {
                throw NSError(domain: "HomeViewAdmin", code: 404, userInfo: [NSLocalizedDescriptionKey: "No current user session found."])
            }

            // Fetch library details
            let libraryData = try await fetchLibraryData(libraryId: currentUser.library_id)

            // Update state on the main thread
            await MainActor.run {
                self.prefetchedUser = currentUser
                self.prefetchedLibrary = libraryData
                self.isPrefetchingProfile = false
                print("Profile data prefetched successfully.") // Debug log
            }
        } catch {
            // Update state on the main thread
            await MainActor.run {
                self.prefetchError = error.localizedDescription
                self.isPrefetchingProfile = false
                self.prefetchedUser = nil
                self.prefetchedLibrary = nil
                print("Error prefetching profile data: \(error.localizedDescription)") // Debug log
            }
        }
    }
    private func fetchLibraryData(libraryId: String) async throws -> Library {
             guard let token = try? LoginManager.shared.getCurrentToken(), // Make sure LoginManager is accessible
                   let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/libraries/\(libraryId)") else {
                 throw URLError(.badURL)
             }

             var request = URLRequest(url: url)
             request.httpMethod = "GET"
             request.setValue("application/json", forHTTPHeaderField: "Accept")
             request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

             let (data, response) = try await URLSession.shared.data(for: request)

             guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                  // Improved error handling based on status code
                  let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                  throw NSError(domain: "APIError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch library data. Status code: \(statusCode)"])
             }
             
             do {
                 return try JSONDecoder().decode(Library.self, from: data)
             } catch {
                print("JSON Decoding Error for Library: \(error)")
                print("Raw data: \(String(data: data, encoding: .utf8) ?? "Invalid data")")
                throw error // Re-throw the decoding error
             }
         }
}
struct ProfileIcon: View {
    @Binding var isShowingProfile: Bool
    
    var body: some View {
        Button(action: {
            isShowingProfile = true
        }) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.red)
                .frame(width: 36, height: 36)
        }
        .padding([.trailing], 20)
        .padding([.top], 5)
    }
}

struct AdminAnalyticsView: View {
    struct CirculationData: Identifiable {
        let id = UUID()
        let day: String
        let value: Int
        let percentage: String
    }

    let circulationStats = [
        CirculationData(day: "Mon", value: 9, percentage: "19.6%"),
        CirculationData(day: "Tue", value: 10, percentage: "21.7%"),
        CirculationData(day: "Wed", value: 15, percentage: "32.6%"),
        CirculationData(day: "Thu", value: 12, percentage: "26.1%")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // User Analytics Grid (only Active Users and Librarian Login)
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                NavigationLink(destination: ActiveUsersDetailView()) {
                    MetricBox(title: "Active users", value: "240")
                }
                NavigationLink(destination: LibrarianLoginsDetailView()) {
                    MetricBox(title: "Librarian login", value: "50")
                }
            }

            Text("Circulation statistics")
                .font(.headline)

            NavigationLink(destination: CirculationStatsDetailView()) {
                Chart {
                    ForEach(circulationStats) { stat in
                        LineMark(
                            x: .value("Day", stat.day),
                            y: .value("Value", stat.value)
                        )
                        PointMark(
                            x: .value("Day", stat.day),
                            y: .value("Value", stat.value)
                        )
                    }
                }
                .frame(height: 150)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
            }
            .buttonStyle(PlainButtonStyle())

            Text("Catalog insights")
                .font(.headline)

            HStack(spacing: 16) {
                NavigationLink(destination: TotalBooksDetailView()) {
                    CatalogInsightBox(title: "Total Books", value: "2000")
                }
                NavigationLink(destination: NewBooksDetailView()) {
                    CatalogInsightBox(title: "New books", value: "5")
                }
                NavigationLink(destination: BorrowedBooksDetailView()) {
                    CatalogInsightBox(title: "Borrowed", value: "350")
                }
            }

            Text("Fine reports")
                .font(.headline)

            HStack(spacing: 16) {
                NavigationLink(destination: TotalFinesDetailView()) {
                    FineBox(title: "Total fines", value: "₹640")
                }
                NavigationLink(destination: OverdueBooksDetailView()) {
                    FineBox(title: "Overdue books", value: "60")
                }
            }

            Spacer()
        }
        .padding()
    }
}

// MARK: - Reusable Components

struct MetricBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack {
            Text(value)
                .font(.title3).bold()
            Text(title)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }
}

struct CatalogInsightBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3).bold()
            Text(title)
                .font(.footnote)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }
}

struct FineBox: View {
    let title: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3).bold()
            Text(title)
                .font(.footnote)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.blue.opacity(0.2))
        .cornerRadius(12)
    }
}

// MARK: - Detail Views

struct ActiveUsersDetailView: View {
    var body: some View {
        List {
            Section(header: Text("Active Users Breakdown")) {
                Text("Students: 180")
                Text("Faculty: 45")
                Text("Staff: 15")
            }
            Section(header: Text("Activity Levels")) {
                Text("Highly Active: 120")
                Text("Moderately Active: 80")
                Text("Rarely Active: 40")
            }
        }
        .navigationTitle("Active Users")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct LibrarianLoginsDetailView: View {
    var body: some View {
        List {
            Section(header: Text("Librarian Activity")) {
                Text("Today's Logins: 12")
                Text("Weekly Average: 50")
                Text("Most Active: John Doe (25)")
            }
            Section(header: Text("Login Times")) {
                Text("Morning (8-12): 35%")
                Text("Afternoon (12-4): 45%")
                Text("Evening (4-8): 20%")
            }
        }
        .navigationTitle("Librarian Logins")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TotalBooksDetailView: View {
    var body: some View {
        List {
            Section(header: Text("Collection Breakdown")) {
                Text("Fiction: 800")
                Text("Non-Fiction: 1000")
                Text("Reference: 200")
            }
            Section(header: Text("Availability")) {
                Text("Available: 1650")
                Text("Checked Out: 350")
                Text("Reserved: 50")
            }
        }
        .navigationTitle("Total Books")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct CirculationStatsDetailView: View {
    var body: some View {
        List {
            Section(header: Text("Weekly Circulation")) {
                Text("Monday: 19.6% (9)")
                Text("Tuesday: 21.7% (10)")
                Text("Wednesday: 32.6% (15)")
                Text("Thursday: 26.1% (12)")
            }
            Section(header: Text("Monthly Trends")) {
                Text("This Month: 120")
                Text("Last Month: 150")
                Text("Average: 135")
            }
        }
        .navigationTitle("Circulation Stats")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NewBooksDetailView: View {
    var body: some View {
        List {
            Section(header: Text("New Additions This Week")) {
                Text("Title 1: Computer Science")
                Text("Title 2: Modern History")
                Text("Title 3: Advanced Mathematics")
                Text("Title 4: Literature")
                Text("Title 5: Physics")
            }
            Section(header: Text("Categories")) {
                Text("Science: 2")
                Text("Humanities: 2")
                Text("Other: 1")
            }
        }
        .navigationTitle("New Books")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct BorrowedBooksDetailView: View {
    var body: some View {
        List {
            Section(header: Text("Currently Borrowed")) {
                Text("Overdue: 60")
                Text("Due Today: 15")
                Text("Due This Week: 120")
                Text("Due Next Week: 155")
            }
            Section(header: Text("Popular Categories")) {
                Text("Fiction: 45%")
                Text("Science: 30%")
                Text("History: 15%")
                Text("Other: 10%")
            }
        }
        .navigationTitle("Borrowed Books")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TotalFinesDetailView: View {
    var body: some View {
        List {
            Section(header: Text("Fine Breakdown")) {
                Text("Collected: ₹540")
                Text("Pending: ₹100")
                Text("Waived: ₹50")
            }
            Section(header: Text("By User Type")) {
                Text("Students: ₹520")
                Text("Faculty: ₹80")
                Text("Staff: ₹40")
            }
        }
        .navigationTitle("Total Fines")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct OverdueBooksDetailView: View {
    var body: some View {
        List {
            Section(header: Text("Overdue Books")) {
                Text("1-7 days: 35")
                Text("8-14 days: 15")
                Text("15+ days: 10")
            }
            Section(header: Text("Overdue By Category")) {
                Text("Fiction: 40")
                Text("Non-Fiction: 15")
                Text("Reference: 5")
            }
        }
        .navigationTitle("Overdue Books")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct HomeViewAdmin_Previews: PreviewProvider {
    static var previews: some View {
        HomeViewAdmin()
    }
}
