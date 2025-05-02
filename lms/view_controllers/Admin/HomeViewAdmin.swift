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
    @State private var prefetchedUser: User?
    @State private var prefetchedLibrary: Library?
    @State private var isPrefetchingProfile = false
    @State private var prefetchError: String? = nil
    @State private var library: Library?
    @State private var libraryName: String = "Library"
    
    init(prefetchedUser: User? = nil, prefetchedLibrary: Library? = nil) {
        self.prefetchedUser = prefetchedUser
        self.prefetchedLibrary = prefetchedLibrary
        self.library = prefetchedLibrary
        
        // Try to get library name from keychain
        if let name = try? KeychainManager.shared.getLibraryName() {
            _libraryName = State(initialValue: name)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                ReusableBackground(colorScheme: colorScheme)
                
                ScrollView {
                    AdminAnalyticsView()
                }
                .navigationTitle(libraryName)
                .navigationBarLargeTitleItems(trailing: ProfileIcon(isShowingProfile: $isShowingProfile))
            }
            .task {
                if library == nil {
                    await prefetchProfileData()
                }
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

    private func prefetchProfileData() async {
        guard !isPrefetchingProfile else { return }
        
        isPrefetchingProfile = true
        prefetchError = nil
        print("Prefetching profile data...")

        do {
            if let cachedUser = UserCacheManager.shared.getCachedUser() {
                print("Using cached user data")
                let libraryData = try await fetchLibraryData(libraryId: cachedUser.library_id)
                
                await MainActor.run {
                    self.prefetchedUser = cachedUser
                    self.prefetchedLibrary = libraryData
                    self.library = libraryData
                    self.libraryName = libraryData.name
                    try? KeychainManager.shared.saveLibraryName(libraryData.name)
                    self.isPrefetchingProfile = false
                }
                return
            }
            
            guard let currentUser = try await LoginManager.shared.getCurrentUser() else {
                throw NSError(domain: "HomeViewAdmin", code: 404, userInfo: [NSLocalizedDescriptionKey: "No current user session found."])
            }

            let libraryData = try await fetchLibraryData(libraryId: currentUser.library_id)

            await MainActor.run {
                self.prefetchedUser = currentUser
                self.prefetchedLibrary = libraryData
                self.library = libraryData
                self.libraryName = libraryData.name
                try? KeychainManager.shared.saveLibraryName(libraryData.name)
                self.isPrefetchingProfile = false
                print("Profile data prefetched successfully.")
            }
        } catch {
            await MainActor.run {
                self.prefetchError = error.localizedDescription
                self.isPrefetchingProfile = false
                self.prefetchedUser = nil
                self.prefetchedLibrary = nil
                self.library = nil
                print("Error prefetching profile data: \(error.localizedDescription)")
            }
        }
    }

    private func fetchLibraryData(libraryId: String) async throws -> Library {
        guard let token = try? LoginManager.shared.getCurrentToken(),
              let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/libraries/\(libraryId)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            throw NSError(domain: "APIError", code: statusCode, userInfo: [NSLocalizedDescriptionKey: "Failed to fetch library data. Status code: \(statusCode)"])
        }
         
        do {
            return try JSONDecoder().decode(Library.self, from: data)
        } catch {
            print("JSON Decoding Error for Library: \(error)")
            print("Raw data: \(String(data: data, encoding: .utf8) ?? "Invalid data")")
            throw error
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
                .foregroundColor(.teal)
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
        var percentage: String? = nil
    }
    
    let circulationStats = [
        CirculationData(day: "Mon", value: 9, percentage: "19.6%"),
        CirculationData(day: "Tue", value: 10, percentage: "21.7%"),
        CirculationData(day: "Wed", value: 15, percentage: "32.6%"),
        CirculationData(day: "Thu", value: 12, percentage: "26.1%")
    ]
    
    // Sample most borrowed book data
    let mostBorrowedBook = (
        title: "Computer Science Fundamentals",
        author: "David Lee",
        borrowCount: 42,
        category: "Science"
    )

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Fine Reports Section
            Text("Fine reports")
                .font(.headline)

            HStack(spacing: 16) {
                NavigationLink(destination: TotalFinesDetailView()) {
                    FineBox(title: "Total fines", value: "₹640")
                        .foregroundColor(.teal)
                }
                NavigationLink(destination: OverdueBooksDetailView()) {
                    FineBox(title: "Overdue books", value: "60")
                        .foregroundColor(.teal)
                }
            }

            // Circulation Statistics Section (now with most borrowed book)
            VStack(alignment: .leading, spacing: 12) {
                Text("Circulation statistics")
                    .font(.headline)
                
                // Chart
                NavigationLink(destination: CirculationStatsDetailView()) {
                    Chart {
                        ForEach(circulationStats) { stat in
                            LineMark(
                                x: .value("Day", stat.day),
                                y: .value("Value", stat.value)
                            )
                            .foregroundStyle(Color.teal)
                            
                            PointMark(
                                x: .value("Day", stat.day),
                                y: .value("Value", stat.value)
                            )
                            .foregroundStyle(Color.teal)
                        }
                    }
                    .frame(height: 150)
                }
                
                // Most borrowed book info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Most borrowed:")
                            .font(.subheadline)
//                            .foregroundColor(.black)
                        Spacer()
                        Text("\(mostBorrowedBook.borrowCount) borrows")
                            .font(.subheadline)
                            .foregroundColor(.teal)
                    }
                    
                    Text(mostBorrowedBook.title)
                        .font(.headline)
                        .foregroundColor(.teal)
                    
                    HStack {
                        Text("by \(mostBorrowedBook.author)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(mostBorrowedBook.category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.teal.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .padding(12)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 4)

            // Catalog Insights Section
            Text("Catalog insights")
                .font(.headline)

            HStack(spacing: 16) {
                NavigationLink(destination: TotalBooksDetailView()) {
                    CatalogInsightBox(title: "Total Books", value: "2000")
                        .foregroundColor(.teal)
                }
                NavigationLink(destination: NewBooksDetailView()) {
                    CatalogInsightBox(title: "New books", value: "5")
                        .foregroundColor(.teal)
                }
                NavigationLink(destination: BorrowedBooksDetailView()) {
                    CatalogInsightBox(title: "Borrowed", value: "350")
                        .foregroundColor(.teal)
                }
            }

            Spacer()
        }
        .padding()
    }
}
// MARK: - Reusable Components

struct CirculationStatsDetailView: View {
    // Sample most borrowed book data
    let mostBorrowedBook = (
        title: "Computer Science Fundamentals",
        author: "David Lee",
        borrowCount: 42,
        category: "Science",
        description: "Comprehensive guide to core computer science concepts including algorithms, data structures, and computational theory."
    )
    
    var body: some View {
        DetailViewTemplate(title: "Circulation Stats", value: "46") {
            SectionHeaderView(title: "Daily Circulation")

            let circulationData: [AdminAnalyticsView.CirculationData] = [
                AdminAnalyticsView.CirculationData(day: "Mon", value: 9),
                AdminAnalyticsView.CirculationData(day: "Tue", value: 10),
                AdminAnalyticsView.CirculationData(day: "Wed", value: 15),
                AdminAnalyticsView.CirculationData(day: "Thu", value: 12)
            ]
            
            Chart {
                ForEach(circulationData) { data in
                    BarMark(
                        x: .value("Day", data.day),
                        y: .value("Books", data.value)
                    )
                    .foregroundStyle(Color.teal)
                }
            }
            .frame(height: 200)
            
            // Most Borrowed Book Section
            SectionHeaderView(title: "Most Borrowed Book")
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(mostBorrowedBook.title)
                            .font(.title3)
                            .bold()
                            .foregroundColor(.teal)
                        
                        Text("by \(mostBorrowedBook.author)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Text(mostBorrowedBook.description)
                            .font(.body)
                            .foregroundColor(.primary)
                            .padding(.top, 4)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Text("\(mostBorrowedBook.borrowCount) borrows")
                            .font(.headline)
                            .foregroundColor(.teal)
                        
                        Text(mostBorrowedBook.category)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.teal.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(12)
            }
            
            SectionHeaderView(title: "Weekly Breakdown")
            
            VStack(spacing: 12) {
                DetailItemView(title: "Monday", value: "9")
                DetailItemView(title: "Tuesday", value: "10")
                DetailItemView(title: "Wednesday", value: "15")
                DetailItemView(title: "Thursday", value: "12")
            }
            
            SectionHeaderView(title: "Monthly Trends")
            
            VStack(spacing: 12) {
                DetailItemView(title: "This Month", value: "120")
                DetailItemView(title: "Last Month", value: "150")
                DetailItemView(title: "Growth", value: "-20%")
            }
        }
    }
}

struct TotalBooksDetailView: View {
    var body: some View {
        DetailViewTemplate(title: "Total Books", value: "2000") {
            SectionHeaderView(title: "Collection Breakdown")
            
            VStack(spacing: 12) {
                DetailItemView(title: "Fiction", value: "800")
                DetailItemView(title: "Non-Fiction", value: "1000")
                DetailItemView(title: "Reference", value: "200")
            }
            
            SectionHeaderView(title: "Book Status")
            
            VStack(spacing: 12) {
                DetailItemView(title: "Available", value: "1650")
                DetailItemView(title: "Checked Out", value: "350")
                DetailItemView(title: "Reserved", value: "50")
            }
            
            SectionHeaderView(title: "Collection Growth")
            
            let growthData: [AdminAnalyticsView.CirculationData] = [
                AdminAnalyticsView.CirculationData(day: "Jan", value: 1850),
                AdminAnalyticsView.CirculationData(day: "Feb", value: 1900),
                AdminAnalyticsView.CirculationData(day: "Mar", value: 1950),
                AdminAnalyticsView.CirculationData(day: "Apr", value: 2000)
            ]
            
            Chart {
                ForEach(growthData) { data in
                    LineMark(
                        x: .value("Month", data.day),
                        y: .value("Books", data.value)
                    )
                    .foregroundStyle(Color.teal)
                }
            }
            .frame(height: 200)
        }
    }
}

struct NewBooksDetailView: View {
    var body: some View {
        DetailViewTemplate(title: "New Books", value: "5") {
            SectionHeaderView(title: "Recent Additions")
            
            VStack(spacing: 12) {
                NewBookItemView(title: "Computer Science Fundamentals", author: "David Lee", category: "Science")
                NewBookItemView(title: "Modern History", author: "Sarah Johnson", category: "Humanities")
                NewBookItemView(title: "Advanced Mathematics", author: "Michael Chen", category: "Science")
                NewBookItemView(title: "Classic Literature", author: "Emma Roberts", category: "Humanities")
                NewBookItemView(title: "Physics Made Simple", author: "Robert Adams", category: "Science")
            }
            
            SectionHeaderView(title: "Categories")
            
            VStack(spacing: 12) {
                DetailItemView(title: "Science", value: "3")
                DetailItemView(title: "Humanities", value: "2")
            }
        }
    }
}
struct NewBookItemView: View {
    let title: String
    let author: String
    let category: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.teal)
            
            HStack {
                Text("Author: \(author)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(category)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.teal.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2)
    }
}

struct BorrowedBooksDetailView: View {
    var body: some View {
        DetailViewTemplate(title: "Borrowed Books", value: "350") {
            SectionHeaderView(title: "Due Date Breakdown")
            
            VStack(spacing: 12) {
                DetailItemView(title: "Overdue", value: "60")
                DetailItemView(title: "Due Today", value: "15")
                DetailItemView(title: "Due This Week", value: "120")
                DetailItemView(title: "Due Next Week", value: "155")
            }
            
            SectionHeaderView(title: "Popular Categories")
            
            VStack(spacing: 12) {
                DetailItemView(title: "Fiction", value: "158")
                DetailItemView(title: "Science", value: "105")
                DetailItemView(title: "History", value: "52")
                DetailItemView(title: "Other", value: "35")
            }
            
            SectionHeaderView(title: "Borrowing Trend")
            
            let trendData: [AdminAnalyticsView.CirculationData] = [
                AdminAnalyticsView.CirculationData(day: "Jan", value: 280),
                AdminAnalyticsView.CirculationData(day: "Feb", value: 310),
                AdminAnalyticsView.CirculationData(day: "Mar", value: 330),
                AdminAnalyticsView.CirculationData(day: "Apr", value: 350)
            ]
            
            Chart {
                ForEach(trendData) { data in
                    LineMark(
                        x: .value("Month", data.day),
                        y: .value("Books", data.value)
                    )
                    .foregroundStyle(Color.teal)
                }
            }
            .frame(height: 200)
        }
    }
}

struct TotalFinesDetailView: View {
    var body: some View {
        DetailViewTemplate(title: "Total Fines", value: "₹640", color: .teal) {
            SectionHeaderView(title: "Fine Breakdown")
            
            VStack(spacing: 12) {
                DetailItemView(title: "Collected", value: "₹540")
                DetailItemView(title: "Pending", value: "₹100")
            }
            
            SectionHeaderView(title: "Monthly Collection")
            
            let fineData: [AdminAnalyticsView.CirculationData] = [
                AdminAnalyticsView.CirculationData(day: "Jan", value: 580),
                AdminAnalyticsView.CirculationData(day: "Feb", value: 620),
                AdminAnalyticsView.CirculationData(day: "Mar", value: 590),
                AdminAnalyticsView.CirculationData(day: "Apr", value: 640)
            ]
            
            Chart {
                ForEach(fineData) { data in
                    BarMark(
                        x: .value("Month", data.day),
                        y: .value("Fines (₹)", data.value)
                    )
                    .foregroundStyle(Color.teal)
                }
            }
            .frame(height: 200)
        }
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
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}
struct DetailViewTemplate<Content: View>: View {
    let title: String
    let value: String
    let color: Color
    let content: () -> Content
    
    init(title: String, value: String, color: Color = .teal, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.value = value
        self.color = color
        self.content = content
    }
    
    var body: some View {
        ZStack {
            Color(.systemGray6)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    DetailHeaderBox(title: title, value: value, color: color)
                    content()
                }
                .padding()
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
struct DetailHeaderBox: View {
    let title: String
    let value: String
    let color: Color
    
    init(title: String, value: String, color: Color = .teal) {
        self.title = title
        self.value = value
        self.color = color
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.system(size: 48, weight: .bold))
                .foregroundColor(color)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 4)
    }
}

struct SectionHeaderView: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }
}
struct DetailItemView: View {
    let title: String
    let value: String
    let percentage: String?
    
    init(title: String, value: String, percentage: String? = nil) {
        self.title = title
        self.value = value
        self.percentage = percentage
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.body)
            
            Spacer()
            
            HStack(spacing: 12) {
                Text(value)
                    .font(.headline)
                    .foregroundColor(.teal)
                
                if let percentage = percentage {
                    Text(percentage)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2)
    }
}

struct OverdueBooksDetailView: View {
    var body: some View {
        DetailViewTemplate(title: "Overdue Books", value: "60", color: .teal) {
            SectionHeaderView(title: "Overdue Breakdown")
            
            VStack(spacing: 12) {
                DetailItemView(title: "1-7 days", value: "35")
                DetailItemView(title: "8-14 days", value: "15")
                DetailItemView(title: "15+ days", value: "10")
            }
            
            SectionHeaderView(title: "Overdue By Category")
            
            VStack(spacing: 12) {
                DetailItemView(title: "Fiction", value: "40")
                DetailItemView(title: "Non-Fiction", value: "15")
                DetailItemView(title: "Reference", value: "5")
            }
        }
    }
}

// MARK: - Detail View Components (keep all existing detail views)
// ... [Keep all the existing Detail View implementations] ...

struct HomeViewAdmin_Previews: PreviewProvider {
    static var previews: some View {
        HomeViewAdmin()
    }
}
