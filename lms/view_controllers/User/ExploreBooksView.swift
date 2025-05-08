//
//  ExploreBooksView.swift
//  lms
//
//  Created by Navdeep Lakhlan on 03/05/25.
//
import SwiftUI

struct ExploreBooksView: View {
    // MARK: - Properties
    @State private var searchText = ""
    @State private var selectedGenres: Set<String> = []
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var allBooks: [BookModel] = []
    @State private var isLoading = false
    @State private var isLoadingMore = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    // Updated to use BookGenre structure from HomeView
    let categories = BookGenre.fictionGenres + BookGenre.nonFictionGenres
    
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

    // MARK: - Main Body
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                ZStack {
                    // Background gradient
                    ReusableBackground(colorScheme: colorScheme)
                    
                    VStack(spacing: 0) {
                        // Sticky header with search
                        VStack(spacing: 16) {
                            SearchBarUser(
                                text: $searchText,
                                onCommit: {},
                                onClear: {
                                    searchText = ""
                                    selectedGenres = []
                                }
                            )
                            .onChange(of: searchText) { _ in
                                // Real-time search as user types
                            }
                            
                            // Genre chips - updated to use the BookGenre structure
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(categories, id: \.displayName) { category in
                                        GenreChipk(
                                            genre: category.displayName,
                                            isSelected: selectedGenres.contains(category.displayName),
                                            colorScheme: colorScheme,
                                            iconName: category.iconName
                                        ) {
                                            if selectedGenres.contains(category.displayName) {
                                                selectedGenres.remove(category.displayName)
                                            } else {
                                                selectedGenres.insert(category.displayName)
                                            }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding(.top)
                        .padding(.bottom, 8)
                        .background(ReusableBackground(colorScheme : colorScheme)
//                            ReusableBackground(colorScheme: colorScheme)
//                                .edgesIgnoringSafeArea(.top)
//                                .shadow(
//                                    color: Color.primary(for: colorScheme)
//                                        .opacity(0.4), radius: 5, x: 0, y: 3)
                        )
                        .zIndex(1)
                        
                        // IMPROVED BOOK GRID
                        ScrollView {
                            LazyVGrid(
                                columns: [
                                    GridItem(.flexible(), spacing: 16),
                                    GridItem(.flexible(), spacing: 16)
                                ],
                                spacing: 20
                            ) {
                                ForEach(filteredBooks) { book in
                                    NavigationLink(destination: BookDetailView(book: book)) {
                                        ImprovedBookCard(book: book, colorScheme: colorScheme)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                
                                // Add pagination loader at the bottom
                                if !isFiltering {
                                    HStack {
                                        Spacer()
                                        if isLoadingMore {
                                            ProgressView()
                                                .padding()
                                        }
                                        Spacer()
                                    }
                                    .id("BottomLoader")
                                    .onAppear {
                                        loadMoreBooks()
                                    }
                                    .gridCellColumns(2) // Take up full width in grid
                                }
                            }
                            .padding()
                        }
                    }
                }
                .navigationBarTitle("Explore Books", displayMode: .inline)
                .navigationBarHidden(true)
                .alert("Error", isPresented: $showError) {
                    Button("OK", role: .cancel) { }
                } message: {
                    Text(errorMessage ?? "An unknown error occurred")
                }
            }
        }
        .foregroundColor(Color.text(for: colorScheme))
        .task {
            await loadBooks()
        }
    }
    
    // Helper to check if filtering is active
    var isFiltering: Bool {
        return !searchText.isEmpty || !selectedGenres.isEmpty
    }
    
    // MARK: - Helper Methods
    
    private func loadBooks() async {
        isLoading = true
        self.allBooks = BookHandler.shared.getCachedData() ?? []
        fetchBooks { result in
            isLoading = false
            
            switch result {
            case let .success(fetchedBooks):
                self.allBooks = fetchedBooks
                for book in fetchedBooks where book.coverImageUrl != nil {
                    self.preloadBookCover(for: book)
                }
            case let .failure(error):
                self.errorMessage = error.localizedDescription
                self.showError = true
            }
        }
    }
    
    private func loadMoreBooks() {
        guard !isFiltering && !isLoadingMore else { return }
        
        isLoadingMore = true
        lms.loadMoreBooks { result in
            self.isLoadingMore = false
            
            switch result {
            case .success(let allBooks):
                withAnimation {
                    self.allBooks = allBooks
                }
                print("[DEBUG] (ExploreBooksView) Loaded more books. Total count: \(allBooks.count)")
            case .failure(let error):
                self.errorMessage = "Failed to load more books: \(error.localizedDescription)"
                self.showError = true
                print("[ERROR] (ExploreBooksView) Failed to load more books: \(error)")
            }
        }
    }
    
    private func preloadBookCover(for book: BookModel) {
        guard let urlString = book.coverImageUrl,
              let url = URL(string: urlString) else {
            return
        }
        
        URLSession.shared.dataTask(with: url).resume()
    }
}

// MARK: - Improved Book Card
struct ImprovedBookCard: View {
    let book: BookModel
    let colorScheme: ColorScheme
    @State private var loadedImage: UIImage? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Book Cover Container - Fixed size with proper constraints
            ZStack {
                // Background for when image is loading or missing
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
                
                // Placeholder icon when no image is available
                if loadedImage == nil {
                    Image(systemName: "book.fill")
                        .font(.system(size: 30))
                        .foregroundColor(.white.opacity(0.7))
                }
                
                // The actual book cover image
                if let image = loadedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: UIScreen.main.bounds.width / 2.5, height: 200)
                        .clipped()
                        .cornerRadius(8)
                }
            }
            .frame(width: UIScreen.main.bounds.width / 2.5, height: 200)
            .cornerRadius(8)
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
            .padding(.bottom, 8)
            
            // Text content container - Separated from image
            VStack(alignment: .leading, spacing: 4) {
                // Title with fixed height to ensure consistent spacing
                Text(book.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(Color.text(for: colorScheme))
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height:35)
                
               
                // Genre tags in a fixed height container
                if let genres = book.genreNames, !genres.isEmpty {
                    HStack(spacing: 4) {
                        ForEach(genres.prefix(2), id: \.self) { genre in
                            Text(genre)
                                .font(.system(size: 10, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.gray.opacity(0.15))/*primary(for: colorScheme).opacity(0.1))*/
                                .foregroundColor(Color.text(for: colorScheme).opacity(0.8))
                                .cornerRadius(4)
                        }
                    }
                    .frame(height: 20, alignment: .leading)
                } else {
                    Spacer()
                        .frame(height: 20)
                }
            }
            .padding(.horizontal, 4)
            .frame(width: UIScreen.main.bounds.width / 2.5)
            .padding(.bottom, 8)
        }
        .frame(width: UIScreen.main.bounds.width / 2.5)
        .padding(.vertical, 6)
        .background(Color.clear)
        .onAppear {
            loadCoverImage()
        }
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
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            DispatchQueue.main.async {
                isLoading = false
                
                if let error = error {
                    print("Error loading image: \(error.localizedDescription)")
                    loadError = true
                    return
                }
                
                guard let data = data, let image = UIImage(data: data) else {
                    loadError = true
                    return
                }
                
                loadedImage = image
            }
        }.resume()
    }
}

// MARK: - Genre Chip View
struct GenreChipk: View {
    let genre: String
    let isSelected: Bool
    let colorScheme: ColorScheme
    let iconName: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: iconName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)
                
                Text(genre)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected ?
                    Color.primary(for: colorScheme).opacity(0.5) :
                    Color.primary(for: colorScheme).opacity(0.2)
            )
            .foregroundColor(
                isSelected ?
                    Color.text(for: colorScheme) :
                    Color.text(for: colorScheme).opacity(0.8)
            )
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(
                        isSelected ?
                            Color.primary(for: colorScheme) :
                            Color.clear,
                        lineWidth: 1
                    )
            )
        }
    }
}

// MARK: - Preview
struct ExploreBooksView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ExploreBooksView()
                .preferredColorScheme(.light)
                .previewDisplayName("Light Mode")
            
            ExploreBooksView()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
