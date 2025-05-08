//
//  HomeViewAdmin.swift
//  lms
//
//  Created by Diptayan Jash on 23/04/25.
//

import Charts
import NavigationBarLargeTitleItems
import SwiftUI

extension OverdueBooks {
    init(total: Int, byDuration: OverdueDuration, byCategory: [String: Int]) {
        self.total = total
        self.byDuration = byDuration
        self.byCategory = byCategory
    }
}

extension NewBooksDetail {
    init(total: Int, recent: [AnalyticsBookModel], byCategory: [String: Int]) {
        self.total = total
        self.recent = recent
        self.byCategory = byCategory
    }
}

struct HomeViewAdmin: View {
    @Environment(\.colorScheme) private var colorScheme
    @State private var lastHostingView: UIView! // This seems unused, consider removing if not needed
    @State private var isShowingProfile = false // This seems unused, consider removing if not needed
    @State private var prefetchedUser: User?
    @State private var prefetchedLibrary: Library?
    @State private var isPrefetchingProfile = false
    @State private var prefetchError: String? = nil
    @State private var library: Library?
    @State private var libraryName: String = "Library loading..." // This might be redundant if prefetchedLibrary.name is used for navigation title
    @State private var showProfileSheet = false
    @State private var analyticsRefreshID = UUID() // Used to trigger refresh in AdminAnalyticsView

    init(prefetchedUser: User? = nil, prefetchedLibrary: Library? = nil) {
        self.prefetchedUser = prefetchedUser
        self.prefetchedLibrary = prefetchedLibrary
        self.library = prefetchedLibrary

        // Try to get library name from keychain, for initial display if prefetchedLibrary is nil
        if prefetchedLibrary == nil, let name = try? KeychainManager.shared.getLibraryName() {
            _libraryName = State(initialValue: name)
        } else if let prefetchedName = prefetchedLibrary?.name {
            _libraryName = State(initialValue: prefetchedName)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                ReusableBackground(colorScheme: colorScheme)
                    .accessibilityHidden(true)

                ScrollView {
                    AdminAnalyticsView(refreshID: analyticsRefreshID)
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("Library Analytics Dashboard")
                }
                .refreshable {
                    // Pull to refresh: update the refreshID to trigger a refresh in AdminAnalyticsView
                    analyticsRefreshID = UUID()
                }
                // Use prefetchedLibrary.name if available, otherwise the state variable, then fallback
                .navigationTitle(prefetchedLibrary?.name ?? libraryName)
                .navigationBarLargeTitleItems(trailing: ProfileIcon(showProfileSheet: $showProfileSheet))
            }
            .task {
                await prefetchProfileData()
            }
        }
        .sheet(isPresented: $showProfileSheet) {
            NavigationView {
                if isPrefetchingProfile {
                    ProgressView("Loading Profile...")
                        .padding()
                        .accessibilityLabel("Loading profile information")
                } else if let _ = prefetchedUser { // Check if user is fetched, ProfileView likely uses its own data or environment
                    ProfileView() // Assuming ProfileView can access the user data via LoginManager or environment
                        .navigationBarItems(
                            trailing: Button("Done") {
                                showProfileSheet = false
                            }
                            .accessibilityLabel("Done")
                            .accessibilityHint("Closes the profile view")
                        )
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                            .accessibilityHidden(true)
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
                        .accessibilityLabel("Retry loading profile")
                    }
                    .padding()
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Profile loading failed. \(prefetchError ?? "")")
                }
            }
        }
    }

    private func prefetchProfileData() async {
        // Guard against multiple simultaneous fetches if already prefetching or if data is already there
        guard !isPrefetchingProfile else { return }
        if prefetchedUser != nil && prefetchedLibrary != nil {
            // If data is already prefetched and valid, update navigation title if needed and exit
            if let name = prefetchedLibrary?.name {
                self.libraryName = name
            }
            return
        }

        isPrefetchingProfile = true
        prefetchError = nil

        do {
            guard let currentUser = try await LoginManager.shared.getCurrentUser() else {
                throw NSError(
                    domain: "HomeView", code: 404,
                    userInfo: [NSLocalizedDescriptionKey: "No current user session found."])
            }

            let libraryData = try await fetchLibraryData(libraryId: currentUser.library_id)

            await MainActor.run {
                self.prefetchedUser = currentUser
                self.prefetchedLibrary = libraryData
                self.libraryName = libraryData.name
                self.library = libraryData // also update the local library state
                self.isPrefetchingProfile = false
            }
        } catch {
            await MainActor.run {
                self.prefetchError = error.localizedDescription
                self.isPrefetchingProfile = false
                self.prefetchedUser = nil
                self.prefetchedLibrary = nil
                // Potentially set libraryName to an error state or keep "loading..."
                // self.libraryName = "Error loading library"
            }
        }
    }

    private func fetchLibraryData(libraryId: String) async throws -> Library {
        guard let token = try? LoginManager.shared.getCurrentToken(),
              let url = URL(string: "https://lms-temp-be.vercel.app/api/v1/libraries/\(libraryId)")
        else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else {
            let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
            let errorBody = String(data: data, encoding: .utf8) ?? "No error body"
            print("Failed to fetch library data. Status: \(statusCode). Body: \(errorBody)")
            throw NSError(
                domain: "APIError", code: statusCode,
                userInfo: [NSLocalizedDescriptionKey: "Failed to fetch library data. Status code: \(statusCode)."])
        }

        do {
            let decoder = JSONDecoder()
            // Add any specific date decoding strategy if needed for Library model
            return try decoder.decode(Library.self, from: data)
        } catch {
            print("JSON Decoding Error for Library: \(error)")
            print("Raw data: \(String(data: data, encoding: .utf8) ?? "Invalid data")")
            throw error
        }
    }
}

struct ProfileIcon: View {
    @Binding var showProfileSheet: Bool

    var body: some View {
        Button(action: {
            showProfileSheet = true
        }) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.teal)
                .frame(width: 44, height: 44)
        }
        .padding([.trailing], 20)
        .padding([.top], 5)
        .accessibilityLabel("Profile")
        .accessibilityHint("Double tap to open profile settings")
        .accessibilityAddTraits(.isButton)
    }
}

struct AdminAnalyticsView: View {
    struct CirculationData: Identifiable {
        let id = UUID()
        let day: String
        let value: Int
        var percentage: String? = nil
    }

    // Always initialize with cached data from disk (now guaranteed to be loaded during splash)
    @State private var analyticsData: LibraryAnalytics? = AnalyticsHandler.shared.getCachedAnalytics()
    // Never show loading state on first display - data should be prefetched
    @State private var isLoading = false
    @State private var error: Error?
    @State private var hasAttemptedInitialLoad = false
    let refreshID: UUID // Add this property to trigger refresh
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Never show loading indicator on initial view - either use cache or placeholder
            if let error = error, analyticsData == nil {
                // Show error view only if there's no data to display and an error occurred during refresh
                HStack {
                    Spacer()
                    VStack(spacing: 10) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 32))
                            .foregroundColor(.orange)
                            .accessibilityHidden(true)
                        Text("Failed to refresh analytics")
                            .font(.headline)
                        Text(error.localizedDescription)
                            .font(.caption)
                            .multilineTextAlignment(.center)
                        Button("Retry") {
                            fetchAnalytics(forceRefresh: true)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.teal)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .accessibilityLabel("Retry loading analytics")
                        .accessibilityHint("Attempts to reload the library analytics data")
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Error loading analytics. \(error.localizedDescription)")
                    Spacer()
                }
                .padding(.vertical, 30)
            } else {
                // Always show the analytics UI.
                // Use `analyticsData` if available, otherwise fallback to `placeholderAnalytics`.
                let analytics = analyticsData ?? placeholderAnalytics
                
                // Fine Reports Section
                Text("Fine reports")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                HStack(spacing: 16) {
                    NavigationLink(destination: TotalFinesDetailView()) {
                        FineBox(title: "Total fines", value: "₹\(analytics.dashboard.fineReports.totalFines)")
                            .foregroundColor(.teal)
                            .accessibilityLabel("Total fines, ₹\(analytics.dashboard.fineReports.totalFines)")
                            .accessibilityHint("Double tap to view details about total fines")
                    }
                    .accessibilityElement(children: .combine)
                    
                    NavigationLink(destination: OverdueBooksDetailView()) {
                        FineBox(title: "Overdue books", value: "\(analytics.dashboard.fineReports.overdueBooks)")
                            .foregroundColor(.teal)
                            .accessibilityLabel("Overdue books, \(analytics.dashboard.fineReports.overdueBooks) books")
                            .accessibilityHint("Double tap to view details about overdue books")
                    }
                    .accessibilityElement(children: .combine)
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Fine reports section")

                // Circulation Statistics Section
                VStack(alignment: .leading, spacing: 12) {
                    Text("Circulation statistics")
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)

                    NavigationLink(destination: CirculationStatsDetailView()) {
                        Chart {
                            // Ensure dailyCirculation is not empty to avoid chart errors
                            if analytics.dashboard.circulationStatistics.dailyCirculation.isEmpty {
                                // Provide a single data point or a message if you want to render something
                                // For now, it will render an empty chart, which is fine.
                            }
                            ForEach(analytics.dashboard.circulationStatistics.dailyCirculation, id: \.date) { item in
                                LineMark(
                                    x: .value("Day", item.dayOfWeek),
                                    y: .value("Value", item.count)
                                )
                                .foregroundStyle(Color.teal)

                                PointMark(
                                    x: .value("Day", item.dayOfWeek),
                                    y: .value("Value", item.count)
                                )
                                .foregroundStyle(Color.teal)
                            }
                        }
                        .frame(height: 150)
                        .accessibilityLabel("Circulation statistics chart")
                        .accessibilityValue("Shows daily circulation for the past week: \(analytics.dashboard.circulationStatistics.dailyCirculation.map { "\($0.dayOfWeek): \($0.count) circulations" }.joined(separator: ", "))")
                        .accessibilityHint("Double tap to view detailed circulation statistics")
                    }
                    .accessibilityElement(children: .combine)

                    // Most borrowed book info
                    if let mostBorrowedBook = analytics.dashboard.mostBorrowedBook {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Most borrowed:")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(mostBorrowedBook.borrowCount ?? 0) borrows")
                                    .font(.subheadline)
                                    .foregroundColor(.teal)
                            }

                            Text(mostBorrowedBook.title)
                                .font(.headline)
                                .foregroundColor(.teal)

                            HStack {
                                if !mostBorrowedBook.authorIds.isEmpty {
                                     // Placeholder, ideally you'd fetch author names if needed for display
                                     // For now, this is a simple placeholder.
                                    Text("by Author") // You'd need to resolve author names for a better display
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }

                                Spacer()

                                if let genre = mostBorrowedBook.genreNames?.first {
                                    Text(genre)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.teal.opacity(0.2))
                                        .cornerRadius(8)
                                }
                            }
                        }
                        .padding(12)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("Most borrowed book: \(mostBorrowedBook.title). Borrowed \(mostBorrowedBook.borrowCount ?? 0) times. Genre: \(mostBorrowedBook.genreNames?.first ?? "Unknown")")
                    }
                }
                .padding()
                .background(Color(.systemBackground)) // Adapts to light/dark mode
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Circulation statistics section")

                // Catalog Insights Section
                Text("Catalog insights")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)

                HStack(spacing: 16) {
                    NavigationLink(destination: TotalBooksDetailView()) {
                        CatalogInsightBox(title: "Total Books", value: "\(analytics.dashboard.catalogInsights.totalBooks)")
                            .foregroundColor(.teal)
                            .accessibilityLabel("Total books, \(analytics.dashboard.catalogInsights.totalBooks) books")
                            .accessibilityHint("Double tap to view details about total books")
                    }
                    .accessibilityElement(children: .combine)
                    
                    NavigationLink(destination: NewBooksDetailView()) {
                        CatalogInsightBox(title: "New books", value: "\(analytics.dashboard.catalogInsights.newBooks)")
                            .foregroundColor(.teal)
                            .accessibilityLabel("New books, \(analytics.dashboard.catalogInsights.newBooks) books")
                            .accessibilityHint("Double tap to view details about new books")
                    }
                    .accessibilityElement(children: .combine)
                    
                    NavigationLink(destination: BorrowedBooksDetailView()) {
                        CatalogInsightBox(title: "Borrowed", value: "\(analytics.dashboard.catalogInsights.borrowedBooks)")
                            .foregroundColor(.teal)
                            .accessibilityLabel("Borrowed books, \(analytics.dashboard.catalogInsights.borrowedBooks) books")
                            .accessibilityHint("Double tap to view details about borrowed books")
                    }
                    .accessibilityElement(children: .combine)
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Catalog insights section")

                Spacer() // Pushes content to the top
            }
        }
        .padding()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Library analytics dashboard")
        .onAppear {
            if !hasAttemptedInitialLoad {
                hasAttemptedInitialLoad = true
                fetchAnalytics()
            }
        }
        .onChange(of: refreshID) { _ in
            // When refreshID changes, force a refresh from the API
            fetchAnalytics(forceRefresh: true)
        }
    }
    
    private func fetchAnalytics(forceRefresh: Bool = false) {
        error = nil // Clear previous errors for a new fetch attempt
        Task {
            do {
                let freshAnalytics: LibraryAnalytics
                if forceRefresh {
                    freshAnalytics = try await AnalyticsHandler.shared.refreshAnalytics()
                } else {
                    freshAnalytics = try await AnalyticsHandler.shared.fetchLibraryAnalytics()
                }
                await MainActor.run {
                    self.analyticsData = freshAnalytics
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    print("Error fetching analytics: \(error.localizedDescription)")
                }
            }
        }
    }

    // Provide a placeholder analytics object for initial UI if cache is empty
    // and before network fetch completes.
    private var placeholderAnalytics: LibraryAnalytics {
        LibraryAnalytics(
            dashboard: DashboardData(
                fineReports: FineReports(totalFines: 0, overdueBooks: 0),
                circulationStatistics: CirculationStatistics(dailyCirculation: [], totalCirculation: 0),
                mostBorrowedBook: nil,
                catalogInsights: CatalogInsights(totalBooks: 0, newBooks: 0, borrowedBooks: 0)
            ),
            details: DetailsData(
                fines: FinesDetail(
                    totalFines: 0,
                    breakdown: FineBreakdown(collected: 0, pending: 0),
                    monthlyTrend: FineMonthlyTrend(currentMonth: 0, lastMonth: 0, twoMonthsAgo: 0, threeMonthsAgo: 0)
                ),
                overdueBooks: OverdueBooks(
                    total: 0,
                    byDuration: OverdueDuration(days1to7: 0, days8to14: 0, days15Plus: 0),
                    byCategory: [:]
                ),
                circulation: CirculationDetail(
                    total: 0,
                    daily: [],
                    mostBorrowedBook: nil,
                    monthlyTrends: MonthlyTrend(currentMonth: 0, lastMonth: 0, growthRate: "0%")
                ),
                books: BooksDetail(
                    total: 0,
                    byGenre: [:],
                    byStatus: BookStatusCounts(available: 0, borrowed: 0, reserved: 0),
                    growthTrend: GrowthTrend(currentMonth: 0, lastMonth: 0, twoMonthsAgo: 0, threeMonthsAgo: 0)
                ),
                newBooks: NewBooksDetail(
                    total: 0,
                    recent: [],
                    byCategory: [:]
                ),
                borrowedBooks: BorrowedBooksDetail(
                    total: 0,
                    dueDates: DueDates(overdue: 0, today: 0, thisWeek: 0, nextWeek: 0),
                    popularCategories: [:],
                    trend: BorrowTrend(currentMonth: 0, lastMonth: 0, twoMonthsAgo: 0, threeMonthsAgo: 0)
                )
            )
        )
    }
}

// MARK: - Reusable Components

struct CirculationStatsDetailView: View {
    @State private var analyticsData: LibraryAnalytics?
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading details...")
                    .onAppear {
                        fetchAnalytics()
                    }
                    .accessibilityLabel("Loading circulation statistics details")
            } else if let error = error {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                        .accessibilityHidden(true)
                    Text("Error loading data")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.caption)
                    Button("Retry") {
                        fetchAnalytics()
                    }
                    .padding()
                    .accessibilityLabel("Retry loading circulation statistics")
                    .accessibilityHint("Attempts to reload the circulation data")
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Error loading circulation statistics. \(error.localizedDescription)")
            } else if let analytics = analyticsData {
                DetailViewTemplate(title: "Circulation Stats", value: "\(analytics.details.circulation.total)") {
                    SectionHeaderView(title: "Daily Circulation")

                    Chart {
                        ForEach(analytics.details.circulation.daily, id: \.date) { data in
                            BarMark(
                                x: .value("Day", data.dayOfWeek),
                                y: .value("Books", data.count)
                            )
                            .foregroundStyle(Color.teal)
                        }
                    }
                    .frame(height: 200)
                    .accessibilityLabel("Daily circulation chart")
                    .accessibilityValue("Shows circulation by day: \(analytics.details.circulation.daily.map { "\($0.dayOfWeek): \($0.count) books" }.joined(separator: ", "))")

                    // Most Borrowed Book Section
                    if let mostBorrowedBook = analytics.details.circulation.mostBorrowedBook {
                        SectionHeaderView(title: "Most Borrowed Book")

                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(mostBorrowedBook.title)
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.teal)
                                    
                                    if let isbn = mostBorrowedBook.isbn {
                                        Text("ISBN: \(isbn)")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                    }

                                    if let description = mostBorrowedBook.description {
                                        Text(description)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .padding(.top, 4)
                                            .lineLimit(4)
                                    }
                                }

                                Spacer()

                                VStack(alignment: .trailing, spacing: 8) {
                                    Text("\(mostBorrowedBook.borrowCount ?? 0) borrows")
                                        .font(.headline)
                                        .foregroundColor(.teal)

                                    if let genres = mostBorrowedBook.genreNames, !genres.isEmpty {
                                        ForEach(genres.prefix(2), id: \.self) { genre in
                                            Text(genre)
                                                .font(.caption)
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 4)
                                                .background(Color.teal.opacity(0.2))
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Most borrowed book: \(mostBorrowedBook.title). Borrowed \(mostBorrowedBook.borrowCount ?? 0) times. \(mostBorrowedBook.description ?? ""). Genres: \(mostBorrowedBook.genreNames?.joined(separator: ", ") ?? "None")")
                        }
                    }

                    SectionHeaderView(title: "Weekly Breakdown")

                    VStack(spacing: 12) {
                        ForEach(analytics.details.circulation.daily, id: \.date) { item in
                            DetailItemView(title: item.dayOfWeek, value: "\(item.count)")
                        }
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Weekly circulation breakdown")

                    SectionHeaderView(title: "Monthly Trends")

                    VStack(spacing: 12) {
                        DetailItemView(title: "This Month", value: "\(analytics.details.circulation.monthlyTrends.currentMonth)")
                        DetailItemView(title: "Last Month", value: "\(analytics.details.circulation.monthlyTrends.lastMonth)")
                        DetailItemView(title: "Growth", value: "\(analytics.details.circulation.monthlyTrends.growthRate)")
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Monthly trends: This month \(analytics.details.circulation.monthlyTrends.currentMonth), Last month \(analytics.details.circulation.monthlyTrends.lastMonth), Growth \(analytics.details.circulation.monthlyTrends.growthRate)")
                }
            } else {
                Text("No data available") // Should ideally not be reached if placeholder logic is robust
                    .onAppear {
                        fetchAnalytics() // Fetch if we somehow land here with no data
                    }
                    .accessibilityLabel("No circulation data available")
            }
        }
        .navigationTitle("Circulation Details")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityElement(children: .contain)
    }
    
    private func fetchAnalytics() {
        isLoading = true
        error = nil
        
        Task {
            do {
                // For detail views, it's okay to use fetchLibraryAnalytics which might return cache first
                // if the data is very fresh, or if you prefer them to always hit network, use refreshAnalytics.
                let analytics = try await AnalyticsHandler.shared.fetchLibraryAnalytics()
                await MainActor.run {
                    self.analyticsData = analytics
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
}

struct TotalBooksDetailView: View {
    @State private var analyticsData: LibraryAnalytics?
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading book details...")
                    .onAppear {
                        fetchAnalytics()
                    }
                    .accessibilityLabel("Loading total books details")
            } else if let error = error {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                        .accessibilityHidden(true)
                    Text("Error loading data")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.caption)
                    Button("Retry") {
                        fetchAnalytics()
                    }
                    .padding()
                    .accessibilityLabel("Retry loading book details")
                    .accessibilityHint("Attempts to reload the book data")
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Error loading book details. \(error.localizedDescription)")
            } else if let analytics = analyticsData {
                DetailViewTemplate(title: "Total Books", value: "\(analytics.details.books.total)") {
                    SectionHeaderView(title: "Collection Breakdown")

                    VStack(spacing: 12) {
                        // Ensure byGenre is not nil and handle empty case
                        let sortedGenres = Array(analytics.details.books.byGenre.prefix(5)).sorted(by: { $0.value > $1.value })
                        if sortedGenres.isEmpty {
                            Text("No genre data available.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .accessibilityLabel("No genre data available")
                        } else {
                            ForEach(sortedGenres, id: \.key) { genre, count in
                                DetailItemView(title: genre, value: "\(count)")
                            }
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("Books by genre: \(sortedGenres.map { "\($0.key): \($0.value) books" }.joined(separator: ", "))")
                        }
                    }

                    SectionHeaderView(title: "Book Status")

                    VStack(spacing: 12) {
                        DetailItemView(title: "Available", value: "\(analytics.details.books.byStatus.available)")
                        DetailItemView(title: "Checked Out", value: "\(analytics.details.books.byStatus.borrowed)")
                        DetailItemView(title: "Reserved", value: "\(analytics.details.books.byStatus.reserved)")
                    }
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("Book status: Available \(analytics.details.books.byStatus.available), Checked out \(analytics.details.books.byStatus.borrowed), Reserved \(analytics.details.books.byStatus.reserved)")

                    SectionHeaderView(title: "Collection Growth")

                    let growthData = [
                        AdminAnalyticsView.CirculationData(day: "Current", value: analytics.details.books.growthTrend.currentMonth),
                        AdminAnalyticsView.CirculationData(day: "Last", value: analytics.details.books.growthTrend.lastMonth),
                        AdminAnalyticsView.CirculationData(day: "2 mo ago", value: analytics.details.books.growthTrend.twoMonthsAgo),
                        AdminAnalyticsView.CirculationData(day: "3 mo ago", value: analytics.details.books.growthTrend.threeMonthsAgo)
                    ].filter { $0.value >= 0 } // Filter out potential negative placeholder if not applicable

                    if growthData.isEmpty {
                        Text("No growth data available for chart.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .accessibilityLabel("No growth data available")
                    } else {
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
                        .accessibilityLabel("Collection growth chart")
                        
                    }
                }
            } else {
                Text("No data available")
                    .onAppear {
                        fetchAnalytics()
                    }
                    .accessibilityLabel("No book data available")
            }
        }
        .navigationTitle("Total Books Details")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityElement(children: .contain)
    }
    
    private func fetchAnalytics() {
        isLoading = true
        error = nil
        Task {
            do {
                let analytics = try await AnalyticsHandler.shared.fetchLibraryAnalytics()
                await MainActor.run {
                    self.analyticsData = analytics
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
}

struct NewBooksDetailView: View {
    @State private var analyticsData: LibraryAnalytics?
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading new books...")
                    .onAppear {
                        fetchAnalytics()
                    }
                    .accessibilityLabel("Loading new books details")
            } else if let error = error {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                        .accessibilityHidden(true)
                    Text("Error loading data")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.caption)
                    Button("Retry") {
                        fetchAnalytics()
                    }
                    .padding()
                    .accessibilityLabel("Retry loading new books")
                    .accessibilityHint("Attempts to reload the new books data")
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Error loading new books. \(error.localizedDescription)")
            } else if let analytics = analyticsData {
                DetailViewTemplate(title: "New Books", value: "\(analytics.details.newBooks.total)") {
                    SectionHeaderView(title: "Recent Additions")
                    
                    if analytics.details.newBooks.recent.isEmpty {
                        Text("No recent additions found.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                            .accessibilityLabel("No recent book additions")
                    } else {
                        VStack(spacing: 12) {
                            ForEach(analytics.details.newBooks.recent.prefix(5), id: \.bookId) { book in
                                NewBookItemView(
                                    title: book.title,
                                    // Consider fetching actual author names if IDs are not user-friendly
                                    author: book.authorIds.first.map { "Author ID: \($0.uuidString.prefix(8))" } ?? "N/A",
                                    category: book.genreNames?.first ?? "Uncategorized"
                                )
                            }
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("Recent additions: \(analytics.details.newBooks.recent.prefix(5).map { $0.title }.joined(separator: ", "))")
                    }

                    SectionHeaderView(title: "Categories")
                    
                    let sortedCategories = Array(analytics.details.newBooks.byCategory.prefix(5)).sorted(by: { $0.value > $1.value })
                    if sortedCategories.isEmpty {
                         Text("No category data for new books.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding()
                            .accessibilityLabel("No category data for new books")
                    } else {
                        VStack(spacing: 12) {
                            ForEach(sortedCategories, id: \.key) { category, count in
                                DetailItemView(title: category.isEmpty ? "Uncategorized" : category, value: "\(count)")
                            }
                        }
                        .accessibilityElement(children: .contain)
                        .accessibilityLabel("New books by category: \(sortedCategories.map { "\($0.key.isEmpty ? "Uncategorized" : $0.key): \($0.value) books" }.joined(separator: ", "))")
                    }
                }
            } else {
                Text("No data available")
                    .onAppear {
                        fetchAnalytics()
                    }
                    .accessibilityLabel("No new books data available")
            }
        }
        .navigationTitle("New Books Details")
        .navigationBarTitleDisplayMode(.inline)
        .accessibilityElement(children: .contain)
    }
    
    private func fetchAnalytics() {
        isLoading = true
        error = nil
        Task {
            do {
                let analytics = try await AnalyticsHandler.shared.fetchLibraryAnalytics()
                await MainActor.run {
                    self.analyticsData = analytics
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
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
                .lineLimit(2)

            HStack {
                Text(author)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)

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
        .shadow(color: Color.black.opacity(0.05), radius: 2)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Book: \(title), Author: \(author), Category: \(category)")
    }
}

struct BorrowedBooksDetailView: View {
    @State private var analyticsData: LibraryAnalytics?
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading borrowed books...")
                    .onAppear {
                        fetchAnalytics()
                    }
            } else if let error = error {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                        .accessibilityHidden(true)
                    Text("Error loading data")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.caption)
                    Button("Retry") {
                        fetchAnalytics()
                    }
                    .padding()
                    .accessibilityLabel("Retry")
                    .accessibilityHint("Attempts to reload the data")
                }
            } else if let analytics = analyticsData {
                DetailViewTemplate(title: "Borrowed Books", value: "\(analytics.details.borrowedBooks.total)") {
                    SectionHeaderView(title: "Due Date Breakdown")

                    VStack(spacing: 12) {
                        DetailItemView(title: "Overdue", value: "\(analytics.details.borrowedBooks.dueDates.overdue)")
                        DetailItemView(title: "Due Today", value: "\(analytics.details.borrowedBooks.dueDates.today)")
                        DetailItemView(title: "Due This Week", value: "\(analytics.details.borrowedBooks.dueDates.thisWeek)")
                        DetailItemView(title: "Due Next Week", value: "\(analytics.details.borrowedBooks.dueDates.nextWeek)")
                    }

                    SectionHeaderView(title: "Popular Categories")
                    let sortedPopularCategories = Array(analytics.details.borrowedBooks.popularCategories.prefix(5)).sorted(by: { $0.value > $1.value })
                    if sortedPopularCategories.isEmpty {
                        Text("No popular categories for borrowed books.")
                           .font(.caption)
                           .foregroundColor(.secondary)
                           .padding()
                    } else {
                        VStack(spacing: 12) {
                            ForEach(sortedPopularCategories, id: \.key) { category, count in
                                DetailItemView(title: category, value: "\(count)")
                            }
                        }
                    }


                    SectionHeaderView(title: "Borrowing Trend")

                    let trendData = [
                        AdminAnalyticsView.CirculationData(day: "Current", value: analytics.details.borrowedBooks.trend.currentMonth),
                        AdminAnalyticsView.CirculationData(day: "Last", value: analytics.details.borrowedBooks.trend.lastMonth),
                        AdminAnalyticsView.CirculationData(day: "2 mo ago", value: analytics.details.borrowedBooks.trend.twoMonthsAgo),
                        AdminAnalyticsView.CirculationData(day: "3 mo ago", value: analytics.details.borrowedBooks.trend.threeMonthsAgo)
                    ].filter { $0.value >= 0 }

                    if trendData.isEmpty {
                        Text("No borrowing trend data for chart.")
                           .font(.caption)
                           .foregroundColor(.secondary)
                    } else {
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
            } else {
                Text("No data available")
                    .onAppear {
                        fetchAnalytics()
                    }
            }
        }
        .navigationTitle("Borrowed Books Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func fetchAnalytics() {
        isLoading = true
        error = nil
        Task {
            do {
                let analytics = try await AnalyticsHandler.shared.fetchLibraryAnalytics()
                await MainActor.run {
                    self.analyticsData = analytics
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
}

struct TotalFinesDetailView: View {
    @State private var analyticsData: LibraryAnalytics?
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading fine details...")
                    .onAppear {
                        fetchAnalytics()
                    }
            } else if let error = error {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                        .accessibilityHidden(true)
                    Text("Error loading data")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.caption)
                    Button("Retry") {
                        fetchAnalytics()
                    }
                    .padding()
                    .accessibilityLabel("Retry")
                    .accessibilityHint("Attempts to reload the data")
                }
            } else if let analytics = analyticsData {
                DetailViewTemplate(title: "Total Fines", value: "₹\(analytics.details.fines.totalFines)", color: .teal) {
                    SectionHeaderView(title: "Fine Breakdown")

                    VStack(spacing: 12) {
                        DetailItemView(title: "Collected", value: "₹\(analytics.details.fines.breakdown.collected)")
                        DetailItemView(title: "Pending", value: "₹\(analytics.details.fines.breakdown.pending)")
                    }

                    SectionHeaderView(title: "Monthly Collection")

                    let fineData = [
                        AdminAnalyticsView.CirculationData(day: "Current", value: analytics.details.fines.monthlyTrend.currentMonth),
                        AdminAnalyticsView.CirculationData(day: "Last", value: analytics.details.fines.monthlyTrend.lastMonth),
                        AdminAnalyticsView.CirculationData(day: "2 mo ago", value: analytics.details.fines.monthlyTrend.twoMonthsAgo),
                        AdminAnalyticsView.CirculationData(day: "3 mo ago", value: analytics.details.fines.monthlyTrend.threeMonthsAgo)
                    ].filter { $0.value >= 0 } // Assuming fines cannot be negative

                    if fineData.isEmpty {
                        Text("No monthly collection data for chart.")
                           .font(.caption)
                           .foregroundColor(.secondary)
                    } else {
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
            } else {
                Text("No data available")
                    .onAppear {
                        fetchAnalytics()
                    }
            }
        }
        .navigationTitle("Total Fines Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func fetchAnalytics() {
        isLoading = true
        error = nil
        Task {
            do {
                let analytics = try await AnalyticsHandler.shared.fetchLibraryAnalytics()
                await MainActor.run {
                    self.analyticsData = analytics
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
        }
    }
}

struct OverdueBooksDetailView: View {
    @State private var analyticsData: LibraryAnalytics?
    @State private var isLoading = true
    @State private var error: Error?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading overdue books...")
                    .onAppear {
                        fetchAnalytics()
                    }
            } else if let error = error {
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 32))
                        .foregroundColor(.orange)
                        .accessibilityHidden(true)
                    Text("Error loading data")
                        .font(.headline)
                    Text(error.localizedDescription)
                        .font(.caption)
                    Button("Retry") {
                        fetchAnalytics()
                    }
                    .padding()
                    .accessibilityLabel("Retry")
                    .accessibilityHint("Attempts to reload the data")
                }
            } else if let analytics = analyticsData {
                DetailViewTemplate(title: "Overdue Books", value: "\(analytics.details.overdueBooks.total)", color: .teal) {
                    SectionHeaderView(title: "Overdue Breakdown")

                    VStack(spacing: 12) {
                        DetailItemView(title: "1-7 days", value: "\(analytics.details.overdueBooks.byDuration.days1to7)")
                        DetailItemView(title: "8-14 days", value: "\(analytics.details.overdueBooks.byDuration.days8to14)")
                        DetailItemView(title: "15+ days", value: "\(analytics.details.overdueBooks.byDuration.days15Plus)")
                    }

                    SectionHeaderView(title: "Overdue By Category")
                    let sortedOverdueCategories = Array(analytics.details.overdueBooks.byCategory.prefix(5)).sorted(by: { $0.value > $1.value })
                    if sortedOverdueCategories.isEmpty {
                        Text("No overdue books by category.")
                           .font(.caption)
                           .foregroundColor(.secondary)
                           .padding()
                    } else {
                        VStack(spacing: 12) {
                            ForEach(sortedOverdueCategories, id: \.key) { category, count in
                                DetailItemView(title: category.isEmpty ? "Uncategorized" : category, value: "\(count)")
                            }
                        }
                    }
                }
            } else {
                Text("No data available")
                    .onAppear {
                        fetchAnalytics()
                    }
            }
        }
        .navigationTitle("Overdue Books Details")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func fetchAnalytics() {
        isLoading = true
        error = nil
        Task {
            do {
                let analytics = try await AnalyticsHandler.shared.fetchLibraryAnalytics()
                await MainActor.run {
                    self.analyticsData = analytics
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.isLoading = false
                }
            }
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
        .shadow(color: Color.black.opacity(0.05), radius: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(value)")
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
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(value)")
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
        // Using a Group to avoid ZStack if Color is not always needed, or use ZStack conditionally
        // For simplicity, sticking to ZStack as per original.
        ZStack {
            Color(.systemGray6) // Background for the whole scrollable area
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) { // Increased spacing for sections
                    DetailHeaderBox(title: title, value: value, color: color)
                    
                    // Group content to apply consistent padding or background if needed
                    VStack(alignment: .leading, spacing: 16) {
                        content()
                    }
                    .padding(.horizontal) // Horizontal padding for content sections
                    
                }
                .padding(.vertical) // Vertical padding for the entire scroll content
            }
        }
        // .navigationTitle(title) // This is already set by the caller view
        // .navigationBarTitleDisplayMode(.inline)
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
        .shadow(color: Color.black.opacity(0.05), radius: 4)
        .padding(.horizontal) // Added horizontal padding to the header box
    }
}

struct SectionHeaderView: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.title2.weight(.semibold))
            .padding(.vertical, 8)
            .accessibilityAddTraits(.isHeader)
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
                .foregroundColor(.primary)

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
        .background(Color(.secondarySystemBackground))
        .cornerRadius(10)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(percentage != nil ? "\(title), \(value), \(percentage!)" : "\(title), \(value)")
    }
}
