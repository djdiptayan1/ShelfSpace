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
    @State private var selectedGenre: String? = nil
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

    // Filtered books based on search text or selected genre
    var filteredBooks: [BookModel] {
        if searchText.isEmpty && selectedGenre == nil {
            return allBooks
        }

        return allBooks.filter { book in
            let matchesSearch =
                searchText.isEmpty
                || book.title.lowercased().contains(searchText.lowercased())

            let matchesGenre =
                selectedGenre == nil
                || book.genreNames!.contains { $0 == selectedGenre }

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
                        VStack(spacing: 16) {
                            if !showSearchResults && selectedGenre == nil {
                                headerSection
                            }

                            SearchBarUser(
                                text: $searchText,
                                onCommit: {
                                    withAnimation {
                                        showSearchResults = !searchText.isEmpty
                                    }
                                },
                                onClear: {
                                    withAnimation {
                                        searchText = ""
                                        showSearchResults = false
                                        selectedGenre = nil
                                    }
                                }
                            )

                            // Display selected genre as chip if any
                            if let genre = selectedGenre {
                                HStack {
                                    Text("Filtering by: ")
                                        .foregroundColor(
                                            Color.text(for: colorScheme))

                                    Text(genre)
                                        .font(.subheadline)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(
                                            Color.primary(for: colorScheme)
                                                .opacity(0.2)
                                        )
                                        .foregroundColor(
                                            Color.text(for: colorScheme)
                                        )
                                        .cornerRadius(8)

                                    Button(action: {
                                        withAnimation {
                                            selectedGenre = nil
                                            showSearchResults = false
                                            searchText = ""
                                        }
                                    }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(
                                                Color.secondary(
                                                    for: colorScheme
                                                ).opacity(0.7))
                                    }

                                    Spacer()
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
                        if showSearchResults || selectedGenre != nil {
                            SearchResultsView(
                                books: filteredBooks, geometry: geometry,
                                colorScheme: colorScheme)
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
        fetchBooks { result in
            defer { isLoading = false }

            switch result {
            case let .success(fetchedBooks):
                self.newArrivals = fetchedBooks
                self.topSelling = fetchedBooks
                for book in fetchedBooks where book.coverImageUrl != nil {
                    self.preloadBookCover(for: book)
                }
            case let .failure(_):
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
                Text("Welcome " + (prefetchedUser != nil ? prefetchedUser!.name : "loading..."))
                    .font(.headline)
                    .foregroundColor(Color.text(for: colorScheme))
                Text((prefetchedLibrary?.name ?? "loading..."))
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
        .task{
            await prefetchProfileData()
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
                self.prefetchedUser = currentUser
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
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        withAnimation {
                            selectedGenre = category.displayName
                            showSearchResults = true
                        }
                    }) {
                        VStack(spacing: 5) {
                            Image(systemName: category.iconName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 25, height: 25)
                                .foregroundColor(
                                    Color.primary(for: colorScheme))

                            Text(category.displayName)
                                .font(.subheadline)
                                .foregroundColor(Color.text(for: colorScheme))
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 18)
                    }
                }
            }
            .padding(.horizontal)
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
                .padding([.top, .horizontal])
                .padding(.bottom, 18)
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
                            .frame(width: (geometry.size.width - 180))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding([.top, .horizontal])
                .padding(.bottom, 18)
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
                            .frame(width: (geometry.size.width - 210))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .padding([.bottom, .top, .horizontal])
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
                .font(.title2)
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
                                    Color.primary(for: colorScheme).opacity(
                                        0.15)
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
                        .frame(width: 130, height: 180)
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
                        .frame(width: 130,height: 180)

                    Image(systemName: "book.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.7))
                }

                VStack(alignment: .leading, spacing: 20) {
                    Text(book.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .lineLimit(3)
                        .minimumScaleFactor(0.9)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundColor(Color.text(for: colorScheme))

                    Text(book.authorNames!.isEmpty ? "" : book.authorNames![0])
                        .font(.headline)
                        .foregroundColor(
                            Color.text(for: colorScheme).opacity(0.7)
                        )
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        ForEach(book.genreNames!.prefix(2), id: \.self) {
                            genre in
                            Text(genre)
                                .font(.system(size: 16, weight: .medium))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Color.primary(for: colorScheme).opacity(0.2)
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
                .foregroundColor(Color.text(for: colorScheme).opacity(0.6))
                .font(.system(size: 17, weight: .bold, design: .default))
        }
        .onAppear {
            loadCoverImage()
        }
        .padding(16)
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
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 190, height: 200)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(16)
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

            VStack(alignment: .leading, spacing: 12) {
                Text(book.title.count < 20 ? book.title + "\n" : book.title)
                    .font(.headline)
                    .lineLimit(2)
                    .foregroundColor(Color.text(for: colorScheme))

                Text(book.authorNames!.isEmpty ? "" : book.authorNames![0])
                    .font(.subheadline)
                    .foregroundColor(Color.text(for: colorScheme).opacity(0.8))

                HStack(spacing: 6) {
                    ForEach(book.genreNames!.prefix(2), id: \.self) { genre in
                        Text(genre)
                            .font(.system(size: 16, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .lineLimit(1)
                            .background(
                                Color.primary(for: colorScheme).opacity(0.2)
                            )
                            .foregroundColor(Color.text(for: colorScheme))
                            .cornerRadius(8)
                    }
                }
            }
        }
        .onAppear {
            loadCoverImage()
        }
        .padding(12)
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
            Text("\(index)")
                .font(.title3)
                .fontWeight(.bold)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.primary(for: colorScheme)))
                .shadow(
                    color: Color.primary(for: colorScheme).opacity(0.3),
                    radius: 4, x: 0, y: 2
                )
                .foregroundColor(Color.TabbarBackground(for: colorScheme))
            //                .foregroundColor(Color.TabbarBackground(for: colorScheme)))

            if let image = loadedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 180, height: 180)
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
                .font(.headline)
                .lineLimit(2)
                .foregroundColor(Color.text(for: colorScheme))

            Text(book.authorNames!.isEmpty ? "" : book.authorNames![0])
                .font(.subheadline)
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
