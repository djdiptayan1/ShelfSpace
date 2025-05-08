//
//  BookDetailView.swift
//  lms
//
//  Created by Navdeep Lakhlan on 23/04/25.
//

import SwiftUI

// MARK: - Data Models
struct Book: Identifiable {
    let id = UUID()
    let imageName: String
    let title: String
    let author: String
    let genres: [String]
    let description: String
}

// MARK: - Main View
struct HomeView: View {
    // MARK: - Properties
    @State private var searchText = ""
    @State private var showSearchResults = false
    @State private var selectedGenres: Set<String> = []
    @State private var showProfileSheet = false
    @Environment(\.colorScheme) private var colorScheme

    @State private var prefetchedUser: User? = nil
    @State private var prefetchedLibrary: Library? = nil
    @State private var isPrefetchingProfile = false
    @State private var prefetchError: String? = nil
    @State private var isLoading = false

    // Sample data
    let categories = BookGenre.fictionGenres + BookGenre.nonFictionGenres
    // Combined books data for search
    var allBooks: [BookModel] {
        return newArrivals
    }

    // Filtered books based on search text or selected genres
    var filteredBooks: [BookModel] {
           if searchText.isEmpty && selectedGenres.isEmpty {
               return allBooks
           }
           
           return allBooks.filter { book in
               let matchesSearch = searchText.isEmpty ||
                   book.title.lowercased().contains(searchText.lowercased()) ||
                   (book.authorNames?.contains { $0.lowercased().contains(searchText.lowercased()) } ?? false) ||
                   (book.genreNames?.contains { $0.lowercased().contains(searchText.lowercased()) } ?? false)
               
               let matchesGenre = selectedGenres.isEmpty ||
                   !selectedGenres.isDisjoint(with: book.genreNames ?? [])
               
               return matchesSearch && matchesGenre
           }
       }


    @State private var newArrivals: [BookModel] = []

    @State private var topSelling: [BookModel] = []

    private var recommendations: [BookModel] {
        if prefetchedUser == nil {
            return allBooks
        }
        let selectedGenres = Set(prefetchedUser!.interests ?? [])
        print(prefetchedUser!)
        return allBooks.filter { book in
            
            let matchesGenre = selectedGenres.isEmpty ||
                !selectedGenres.isDisjoint(with: book.genreNames ?? [])

            return  matchesGenre
        }
    }

    // MARK: - MAIN BODY

    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ZStack {
                    // Background gradient
                    ReusableBackground(colorScheme: colorScheme)

                    VStack(spacing: 0) {
                        // Sticky header with search
                        VStack(spacing: 12) {
                            if !showSearchResults && selectedGenres.isEmpty {
                                headerSection
                            }

                            SearchBarUser(
                                text: $searchText,
                                onCommit: {
                                    withAnimation {
                                        showSearchResults = !searchText.isEmpty || !selectedGenres.isEmpty
                                    }
                                },
                                onClear: {
                                    withAnimation {
                                        searchText = ""
                                        showSearchResults = !selectedGenres.isEmpty
                                    }
                                }
                            )
                            .onChange(of: searchText) { _ in
                                // Real-time search as user types
                                withAnimation {
                                    showSearchResults = !searchText.isEmpty || !selectedGenres.isEmpty
                                }
                            }

                            // Remove the separate selected genres section and only show Clear All
                            if !selectedGenres.isEmpty {
                                HStack {
                                    Spacer()
                                    
                                    Button(action: {
                                        withAnimation {
                                            selectedGenres = []
                                            showSearchResults = !searchText.isEmpty
                                        }
                                    }) {
                                        Text("Clear All")
                                            .font(.system(size: 15))
                                            .foregroundColor(Color.primary(for: colorScheme))
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top)
                        .padding(.bottom, 8)
                        .background(
                            ReusableBackground(colorScheme: colorScheme)
                                .edgesIgnoringSafeArea(.top)
                                .shadow(
                                    color: Color.primary(for: colorScheme)
                                        .opacity(0.1), radius: 5, x: 0, y: 3)
                        )
                        .zIndex(1)

                        // Content based on search/filter state
                        if showSearchResults || !selectedGenres.isEmpty {
                            ScrollView {
                                VStack(spacing: 0) {
                                    // Always include the categories section in the scrollable area
                                    categoriesSection.padding(.top)
                                    
                                    // Search results view
                                    VStack {
                                        if filteredBooks.isEmpty {
                                            VStack(spacing: 16) {
                                                Image(systemName: "magnifyingglass")
                                                    .resizable()
                                                    .scaledToFit()
                                                    .frame(width: 60, height: 60)
                                                    .foregroundColor(Color.secondary(for: colorScheme))

                                                Text("No books found")
                                                    .font(.headline)
                                                    .foregroundColor(Color.text(for: colorScheme))

                                                Text(
                                                    "Try searching with different keywords or browse categories"
                                                )
                                                .font(.subheadline)
                                                .multilineTextAlignment(.center)
                                                .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                                                .padding(.horizontal)
                                            }
                                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                                            .padding()
                                        } else {
                                            VStack(alignment: .leading, spacing: 8) {
                                                Text("Search Results")
                                                    .font(.title2)
                                                    .fontWeight(.bold)
                                                    .padding(.horizontal)

                                                Text(
                                                    "Found \(filteredBooks.count) book\(filteredBooks.count > 1 ? "s" : "")"
                                                )
                                                .font(.subheadline)
                                                .foregroundColor(
                                                    Color.text(for: colorScheme).opacity(0.7)
                                                )
                                                .padding(.horizontal)

                                                LazyVStack(spacing: 16) {
                                                    ForEach(filteredBooks) { book in
                                                        NavigationLink(
                                                            destination: BookDetailView(book: book)
                                                        ) {
                                                            SearchResultCard(
                                                                book: book, colorScheme: colorScheme
                                                            )
                                                            .padding(.horizontal)
                                                        }
                                                        .buttonStyle(PlainButtonStyle())
                                                    }
                                                }
                                                .padding(.vertical)
                                            }
                                            .padding(.vertical)
                                        }
                                    }
                                }
                            }
                        } else {
                            // Regular home view content
                            ScrollView {
                                VStack(alignment: .leading, spacing: 24) {
                                    categoriesSection
                                    newArrivalsSection(geometry: geometry)
                                    recommendationsSection(geometry: geometry)
                                    topSellingSection(geometry: geometry)
                                    Spacer(minLength: 80)
                                }
                                .padding(.vertical)
                            }
                        }
                    }
                }
                .refreshable {
                    await loadBooks()
                }
                .task {
                    await loadBooks()
                }
                .navigationBarHidden(true)
            }
        }
        .foregroundColor(Color.text(for: colorScheme))
    }

    // MARK: - SECTION FOR VIEW COMPONENT

    // Header Section
    private func loadBooks() async {
        isLoading = true
        self.newArrivals = BookHandler.shared.getCachedData() ?? []
        self.topSelling = BookHandler.shared.getCachedData() ?? []
        fetchBooks { result in
            defer { isLoading = false }

            switch result {
            case let .success(fetchedBooks):
                self.newArrivals = fetchedBooks
                self.topSelling = fetchedBooks
                for book in fetchedBooks where book.coverImageUrl != nil {
                    self.preloadBookCover(for: book)
                }
            case .failure(_):
                //                    self.errorMessage = error.localizedDescription
                //                    self.showError = true
                break
            }
        }
    }
    private func preloadBookCover(for book: BookModel) {
        guard let urlString = book.coverImageUrl,
            let url = URL(string: urlString)
        else {
            return
        }

        URLSession.shared.dataTask(with: url) { data, response, error in
            // Log for debugging
            if let error = error {
                print(
                    "Error preloading image for \(book.title): \(error.localizedDescription)"
                )
                return
            }

            if let httpResponse = response as? HTTPURLResponse,
                !(200...299).contains(httpResponse.statusCode)
            {
                print(
                    "HTTP Error \(httpResponse.statusCode) preloading image for \(book.title)"
                )
                return
            }

            if let data = data, UIImage(data: data) != nil {
                print("Successfully preloaded image for \(book.title)")
                // In a real application, you might want to store this in a cache
            } else {
                print("Invalid image data for \(book.title)")
            }
        }.resume()
    }
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Welcome, " + (prefetchedUser != nil ? prefetchedUser!.name : "loading"))
                    .font(.headline)
                    .foregroundColor(Color.text(for: colorScheme))
                Text((prefetchedLibrary?.name ?? "loading"))
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(Color.text(for: colorScheme))
            }

            Spacer()

            Button(action: { showProfileSheet = true }) {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 44, height: 44)
                    .foregroundColor(
                        Color.primary(for: colorScheme).opacity(0.8))
            }
        }
        .onAppear(){
            Task{
                await prefetchProfileData()
            }
        }
        .onAppear(){
            Task{
                guard
                    let currentUser = try await LoginManager.shared.getCurrentUser()
                        
                else {
                    throw NSError(
                        domain: "HomeView", code: 404,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "No current user session found."
                        ])
                }
                self.prefetchedUser = currentUser
                if let newUser = await LoginManager.shared.FetchUser(){
                    self.prefetchedUser = newUser
                    UserCacheManager.shared.cacheUser(newUser)
                }
            }

        }
        .padding(.horizontal)
        .sheet(isPresented: $showProfileSheet) {
            NavigationView {
                if isPrefetchingProfile {
                    ProgressView("Loading Profile...")
                        .padding()
                } else if let user = prefetchedUser {
                    ProfileView()
                        .navigationBarItems(
                            trailing: Button("Done") {
                                showProfileSheet = false
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

        do {
            guard
                let currentUser = try await LoginManager.shared.getCurrentUser()
                    
            else {
                throw NSError(
                    domain: "HomeView", code: 404,
                    userInfo: [
                        NSLocalizedDescriptionKey:
                            "No current user session found."
                    ])
            }
            let libraryData = try await fetchLibraryData(
                libraryId: currentUser.library_id)

            await MainActor.run {
                self.prefetchedLibrary = libraryData
                self.isPrefetchingProfile = false
            }
        } catch {
            await MainActor.run {
                self.prefetchError = error.localizedDescription
                self.isPrefetchingProfile = false
                self.prefetchedUser = nil
                self.prefetchedLibrary = nil
            }
        }
    }

    private func fetchLibraryData(libraryId: String) async throws -> Library {
        guard let token = try? LoginManager.shared.getCurrentToken(),
            let url = URL(
                string:
                    "https://lms-temp-be.vercel.app/api/v1/libraries/\(libraryId)"
            )
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
            throw NSError(
                domain: "APIError", code: statusCode,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Failed to fetch library data. Status code: \(statusCode)"
                ])
        }

        do {
            return try JSONDecoder().decode(Library.self, from: data)
        } catch {
            print("JSON Decoding Error for Library: \(error)")
            print(
                "Raw data: \(String(data: data, encoding: .utf8) ?? "Invalid data")"
            )
            throw error
        }
    }

    // MARK: - SECTION FOR CATEGORIES

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // First show selected genres
                    ForEach(categories.filter { selectedGenres.contains($0.displayName) }, id: \.self) { category in
                        genreButton(for: category)
                    }
                    
                    // Then show unselected genres
                    ForEach(categories.filter { !selectedGenres.contains($0.displayName) }, id: \.self) { category in
                        genreButton(for: category)
                    }
                }
               .padding(.horizontal)
            }
            .scrollDisabled(false) // Ensure horizontal scroll is enabled
            .frame(height:60) // Fixed height to prevent vertical stretching
        }
    }
    
    // Helper method to create consistent genre buttons
    private func genreButton(for category: BookGenre) -> some View {
        Button(action: {
            withAnimation {
                if selectedGenres.contains(category.displayName) {
                    selectedGenres.remove(category.displayName)
                } else {
                    selectedGenres.insert(category.displayName)
                }
                
                // Don't change the view, just update the filter
                // Only show search results if we have filters active
                showSearchResults = !selectedGenres.isEmpty || !searchText.isEmpty
            }
        }) {
            VStack(spacing: 5) {
                Image(systemName: category.iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
                    .foregroundColor(
                        selectedGenres.contains(category.displayName) ?
                            Color.primary(for: colorScheme) :
                            Color.primary(for: colorScheme).opacity(0.7))

                Text(category.displayName)
                    .font(.system(size: 14))
                    .foregroundColor(
                        selectedGenres.contains(category.displayName) ?
                            Color.text(for: colorScheme) :
                            Color.text(for: colorScheme).opacity(0.8))
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 15)
            .background(
                selectedGenres.contains(category.displayName) ?
                    Color.primary(for: colorScheme).opacity(0.15) :
                    Color.clear
            )
            .cornerRadius(8)
        }
    }

    // MARK: - SECTION FOR NEW ARRIVAL

    private func newArrivalsSection(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading) {
            sectionHeader(title: "New Arrivals", seeMoreAction: {})

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(newArrivals) { book in
                        NavigationLink(destination: BookDetailView(book: book))
                        {
                            NewArrivalCard(book: book, colorScheme: colorScheme)
                                .frame(width: geometry.size.width - 30)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
//                .padding([.top, .horizontal])
                .padding(.horizontal)
               .padding(.bottom,12)
               .padding(.top,12)
            }
        }
    }

    // MARK: - SECTION FOR RECOMENDATION

    private func recommendationsSection(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading) {
            sectionHeader(title: "Recommendations", seeMoreAction: {})

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(recommendations) { book in
                        NavigationLink(destination: BookDetailView(book: book))
                        {
                            RecommendationCard(
                                book: book, colorScheme: colorScheme
                            )
                            .frame(width: 160)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
//                .padding([.top, .horizontal])
//                .padding(.bottom, 18)
                .padding(.horizontal)
                .padding(.bottom,8)
                .padding(.top,8)
            }
        }
    }

    // MARK: - SECTION FOR TOP SELLING
    private func topSellingSection(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading) {
            sectionHeader(title: "Top Borrowing", seeMoreAction: {})

            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(Array(topSelling.enumerated()), id: \.element.id) {
                        index, book in
                        NavigationLink(destination: BookDetailView(book: book))
                        {
                            TopSellingCard(
                                index: index + 1, book: book,
                                colorScheme: colorScheme
                            )
                            .frame(width: 160)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
//                    .padding([.bottom, .top, .horizontal])
                    .padding(.horizontal)
                    .padding(.bottom,8)
                    .padding(.top,8)
                }
            }
        }
    }

    // MARK: - HELPER FUNCTION
    private func sectionHeader(
        title: String, seeMoreAction: @escaping () -> Void
    ) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 19.5))
                .fontWeight(.bold)
                .foregroundColor(Color.text(for: colorScheme))

            Spacer()
        }
        .padding(.horizontal)
    }

    private func iconForCategory(_ category: String) -> String {
        switch category.lowercased() {
        case "romance": return "heart"
        case "fiction": return "book"
        case "thriller": return "theatermasks"
        case "action": return "bolt"
        case "sci-fi": return "atom"
        case "mystery": return "questionmark.circle"
        default: return "bookmark"
        }
    }
}

// MARK: - SEARCH RESULTS VIEW

struct SearchResultsView: View {
    let books: [BookModel]
    let geometry: GeometryProxy
    let colorScheme: ColorScheme
    let showCategories: Bool

    var body: some View {
        VStack {
            if books.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "magnifyingglass")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(Color.secondary(for: colorScheme))

                    Text("No books found")
                        .font(.headline)
                        .foregroundColor(Color.text(for: colorScheme))

                    Text(
                        "Try searching with different keywords or browse categories"
                    )
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                    .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Search Results")
                            .font(.title2)
                            .fontWeight(.bold)
                            .padding(.horizontal)

                        Text(
                            "Found \(books.count) book\(books.count > 1 ? "s" : "")"
                        )
                        .font(.subheadline)
                        .foregroundColor(
                            Color.text(for: colorScheme).opacity(0.7)
                        )
                        .padding(.horizontal)

                        LazyVStack(spacing: 16) {
                            ForEach(books) { book in
                                NavigationLink(
                                    destination: BookDetailView(book: book)
                                ) {
                                    SearchResultCard(
                                        book: book, colorScheme: colorScheme
                                    )
                                    .padding(.horizontal)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.vertical)
                    }
                    .padding(.vertical)
                }
            }
        }
    }
}

// MARK: - SEARCH RESULT CARD

struct SearchResultCard: View {
    let book: BookModel
    let colorScheme: ColorScheme
    @State private var loadedImage: UIImage? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 140)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .clipped()
                    .shadow(
                        color: Color.primary(for: colorScheme).opacity(0.2),
                        radius: 6, x: 0, y: 3)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "A1C4FD"), Color(hex: "C2E9FB"),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: "book.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.7))
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(book.title)
                    .font(.headline)
                    .foregroundColor(Color.text(for: colorScheme))
                    .lineLimit(2)

                Text(book.authorNames!.isEmpty ? "" : book.authorNames![0])
                    .font(.subheadline)
                    .foregroundColor(Color.text(for: colorScheme).opacity(0.8))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(book.genreNames!, id: \.self) { genre in
                            Text(genre)
                                .font(.system(size: 14))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Color.gray.opacity(0.2)
                                )
                                .foregroundColor(Color.text(for: colorScheme))
                                .cornerRadius(6)
                        }
                    }
                }

                if !book.description!.isEmpty {
                    Text(book.description!)
                        .font(.footnote)
                        .foregroundColor(
                            Color.text(for: colorScheme).opacity(0.6)
                        )
                        .lineLimit(2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onAppear {
            loadCoverImage()
        }
        .padding()
        .background(Color.TabbarBackground(for: colorScheme))
        .cornerRadius(12)
        .shadow(
            color: Color.primary(for: colorScheme).opacity(0.1), radius: 8,
            x: 0, y: 4)
    }
    private func loadCoverImage() {
        // Set loading state
        isLoading = true

        // First try to load from local data
        if let imageData = book.coverImageData {
            loadedImage = UIImage(data: imageData)
            isLoading = false
            return
        }

        // If no local data, try to load from URL
        guard var urlString = book.coverImageUrl, !urlString.isEmpty else {
            isLoading = false
            return
        }
        if urlString.hasPrefix("http://") {
            urlString = urlString.replacingOccurrences(
                of: "http://", with: "https://")
        }
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }

        print("Loading image from URL: \(urlString)")

        URLSession.shared.dataTask(with: url) { data, response, error in
            // Always reset loading state when completed
            DispatchQueue.main.async {
                isLoading = false
            }

            // Check for errors
            if let error = error {
                print("Error loading image: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    loadError = true
                }
                return
            }

            // Check for valid HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                DispatchQueue.main.async {
                    loadError = true
                }
                return
            }

            // Check for success status code
            guard (200...299).contains(httpResponse.statusCode) else {
                print("HTTP Error: \(httpResponse.statusCode)")
                DispatchQueue.main.async {
                    loadError = true
                }
                return
            }

            // Check for valid image data
            guard let data = data, let image = UIImage(data: data) else {
                print("Invalid image data")
                DispatchQueue.main.async {
                    loadError = true
                }
                return
            }

            // Update UI with loaded image
            DispatchQueue.main.async {
                print("Image loaded successfully")
                loadedImage = image
            }
        }.resume()
    }

}

// MARK: - CARD STRUCTURES FOR NEW ARRIVAL CARD

struct NewArrivalCard: View {
    let book: BookModel
    let colorScheme: ColorScheme
    @State private var loadedImage: UIImage? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 18) {
                if let image = loadedImage {
                    Image(uiImage: image)
                        .resizable()
                        .background(Color.gray.opacity(0.2))
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 140)
                        .cornerRadius(10)
                        .clipped()
                        .shadow(
                            color: Color.primary(for: colorScheme).opacity(0.3),
                            radius: 12, x: 0, y: 6)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(hex: "A1C4FD"), Color(hex: "C2E9FB"),
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100,height: 140)

                    Image(systemName: "book.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.7))
                }

                VStack(alignment: .leading, spacing: 20) {
                    Text(book.title)
                        .font(.system(size:16))
                        .fontWeight(.semibold)
                        .lineLimit(3)
                        .minimumScaleFactor(0.9)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(Color.text(for: colorScheme))

                    Text(book.authorNames!.isEmpty ? "" : book.authorNames![0])
                        .font(.system(size: 13))
                        .foregroundColor(
                            Color.text(for: colorScheme).opacity(0.7)
                        )
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        ForEach(book.genreNames!.prefix(2), id: \.self) {
                            genre in
                            Text(genre)
                                .font(.system(size: 13, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Color.gray.opacity(0.2)
                                )
                                .foregroundColor(Color.text(for: colorScheme))
                                .cornerRadius(8)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Text(book.description!)
                .lineLimit(3)
                .foregroundColor(Color.text(for: colorScheme).opacity(0.8))
                .font(.system(size: 13.5, weight: .bold, design: .default))
        }
        .onAppear {
            loadCoverImage()
        }
        .padding(10)
        .background(Color.TabbarBackground(for: colorScheme))
        .cornerRadius(12)
        .shadow(
            color: Color.primary(for: colorScheme).opacity(0.15), radius: 15,
            x: 0, y: 8)
    }
    
    private func loadCoverImage() {
        // Set loading state
        isLoading = true

        // First try to load from local data
        if let imageData = book.coverImageData {
            loadedImage = UIImage(data: imageData)
            isLoading = false
            return
        }

        // If no local data, try to load from URL
        guard var urlString = book.coverImageUrl, !urlString.isEmpty else {
            isLoading = false
            return
        }
        if urlString.hasPrefix("http://") {
            urlString = urlString.replacingOccurrences(
                of: "http://", with: "https://")
        }
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }

        print("Loading image from URL: \(urlString)")

        URLSession.shared.dataTask(with: url) { data, response, error in
            // Always reset loading state when completed
            DispatchQueue.main.async {
                isLoading = false
            }

            // Check for errors
            if let error = error {
                print("Error loading image: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    loadError = true
                }
                return
            }

            // Check for valid HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                DispatchQueue.main.async {
                    loadError = true
                }
                return
            }

            // Check for success status code
            guard (200...299).contains(httpResponse.statusCode) else {
                print("HTTP Error: \(httpResponse.statusCode)")
                DispatchQueue.main.async {
                    loadError = true
                }
                return
            }

            // Check for valid image data
            guard let data = data, let image = UIImage(data: data) else {
                print("Invalid image data")
                DispatchQueue.main.async {
                    loadError = true
                }
                return
            }

            // Update UI with loaded image
            DispatchQueue.main.async {
                print("Image loaded successfully")
                loadedImage = image
            }
        }.resume()
    }

}

// MARK: - CARD STRUCTURES FOR RECOMENDATION

struct RecommendationCard: View {
    let book: BookModel
    let colorScheme: ColorScheme
    @State private var loadedImage: UIImage? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height:140)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    .clipped()
                    .shadow(
                        color: Color.primary(for: colorScheme).opacity(0.25),
                        radius: 10, x: 0, y: 5)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "A1C4FD"), Color(hex: "C2E9FB"),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: "book.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.7))
            }

            VStack(alignment: .leading, spacing:8) {
                Text(book.title.count < 20 ? book.title + "\n" : book.title)
                    .font(.system(size: 14).bold())
                    .lineLimit(2)
                    .foregroundColor(Color.text(for: colorScheme))
                    .frame(width: 140)

                Text(book.authorNames!.isEmpty ? "" : book.authorNames![0])
                    .font(.system(size: 12))
                    .foregroundColor(Color.text(for: colorScheme).opacity(0.8))

                HStack(spacing: 6) {
                    ForEach(book.genreNames!.prefix(2), id: \.self) { genre in
                        Text(genre)
                            .font(.system(size: 12, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .lineLimit(1)
                            .background(
                                Color.gray.opacity(0.2)
                            )
                            .foregroundColor(Color.text(for: colorScheme))
                        
                            .cornerRadius(4)
                    }
                }
            }                    .frame(width: 140)

        }
        .onAppear {
            loadCoverImage()
        }
        .padding(10)
        .background(Color.TabbarBackground(for: colorScheme))
        .cornerRadius(18)
        .shadow(
            color: Color.primary(for: colorScheme).opacity(0.15), radius: 12,
            x: 0, y: 6)
    }
    private func loadCoverImage() {
        // Set loading state
        isLoading = true

        // First try to load from local data
        if let imageData = book.coverImageData {
            loadedImage = UIImage(data: imageData)
            isLoading = false
            return
        }

        // If no local data, try to load from URL
        guard var urlString = book.coverImageUrl, !urlString.isEmpty else {
            isLoading = false
            return
        }
        if urlString.hasPrefix("http://") {
            urlString = urlString.replacingOccurrences(
                of: "http://", with: "https://")
        }
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }

        print("Loading image from URL: \(urlString)")

        URLSession.shared.dataTask(with: url) { data, response, error in
            // Always reset loading state when completed
            DispatchQueue.main.async {
                isLoading = false
            }

            // Check for errors
            if let error = error {
                print("Error loading image: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    loadError = true
                }
                return
            }

            // Check for valid HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                DispatchQueue.main.async {
                    loadError = true
                }
                return
            }

            // Check for success status code
            guard (200...299).contains(httpResponse.statusCode) else {
                print("HTTP Error: \(httpResponse.statusCode)")
                DispatchQueue.main.async {
                    loadError = true
                }
                return
            }

            // Check for valid image data
            guard let data = data, let image = UIImage(data: data) else {
                print("Invalid image data")
                DispatchQueue.main.async {
                    loadError = true
                }
                return
            }

            // Update UI with loaded image
            DispatchQueue.main.async {
                print("Image loaded successfully")
                loadedImage = image
            }
        }.resume()
    }

}

// MARK: - CARD STRUCTURES FOR TOP SELLING

struct TopSellingCard: View {
    let index: Int
    let book: BookModel
    let colorScheme: ColorScheme
    @State private var loadedImage: UIImage? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false

    var body: some View {
        VStack(spacing: 5) {
            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 140, height: 140)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                    .clipped()
                    .shadow(
                        color: Color.primary(for: colorScheme).opacity(0.2),
                        radius: 8, x: 0, y: 4)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(hex: "A1C4FD"), Color(hex: "C2E9FB"),
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Image(systemName: "book.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.white.opacity(0.7))
            }

            Text(book.title.count < 20 ? book.title + "\n" : book.title)
                .font(.system(size: 14).bold())
                .lineLimit(2)
                .foregroundColor(Color.text(for: colorScheme))
                .frame(width: 140)

            Text(book.authorNames!.isEmpty ? "" : book.authorNames![0])
                .font(.system(size: 12))
                .foregroundColor(Color.text(for: colorScheme).opacity(0.8))
        }
        .onAppear {
            loadCoverImage()
        }
        .padding(12)
        .background(Color.TabbarBackground(for: colorScheme))
        .cornerRadius(16)
        .shadow(
            color: Color.primary(for: colorScheme).opacity(0.1), radius: 8,
            x: 0, y: 4)
    }
    private func loadCoverImage() {
        // Set loading state
        isLoading = true

        // First try to load from local data
        if let imageData = book.coverImageData {
            loadedImage = UIImage(data: imageData)
            isLoading = false
            return
        }

        // If no local data, try to load from URL
        guard var urlString = book.coverImageUrl, !urlString.isEmpty else {
            isLoading = false
            return
        }
        if urlString.hasPrefix("http://") {
            urlString = urlString.replacingOccurrences(
                of: "http://", with: "https://")
        }
        guard let url = URL(string: urlString) else {
            isLoading = false
            return
        }

        print("Loading image from URL: \(urlString)")

        URLSession.shared.dataTask(with: url) { data, response, error in
            // Always reset loading state when completed
            DispatchQueue.main.async {
                isLoading = false
            }

            // Check for errors
            if let error = error {
                print("Error loading image: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    loadError = true
                }
                return
            }

            // Check for valid HTTP response
            guard let httpResponse = response as? HTTPURLResponse else {
                print("Invalid response")
                DispatchQueue.main.async {
                    loadError = true
                }
                return
            }

            // Check for success status code
            guard (200...299).contains(httpResponse.statusCode) else {
                print("HTTP Error: \(httpResponse.statusCode)")
                DispatchQueue.main.async {
                    loadError = true
                }
                return
            }

            // Check for valid image data
            guard let data = data, let image = UIImage(data: data) else {
                print("Invalid image data")
                DispatchQueue.main.async {
                    loadError = true
                }
                return
            }

            // Update UI with loaded image
            DispatchQueue.main.async {
                print("Image loaded successfully")
                loadedImage = image
            }
        }.resume()
    }

}

// MARK: - Search Bar
struct SearchBarUser: View {
    @Binding var text: String
    var onCommit: () -> Void
    var onClear: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack {
            TextField(
                "Search books, authors, or genres", text: $text,
                onCommit: onCommit
            )
            .padding(12)
            .padding(.horizontal, 28)
            .background(Color.TabbarBackground(for: colorScheme))
            .cornerRadius(12)
            .overlay(
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(Color.primary(for: colorScheme))
                        .frame(
                            minWidth: 0, maxWidth: .infinity,
                            alignment: .leading
                        )
                        .padding(.leading, 12)

                    if !text.isEmpty {
                        Button(action: {
                            text = ""
                            onClear()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(
                                    Color.secondary(for: colorScheme).opacity(
                                        0.7)
                                )
                                .padding(.trailing, 12)
                        }
                    }
                }
            )
            .shadow(
                color: Color.primary(for: colorScheme).opacity(0.1), radius: 5,
                x: 0, y: 2)
        }
        .padding(.horizontal)
    }
}

// MARK: - Preview
struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            HomeView()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")

            HomeView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}

