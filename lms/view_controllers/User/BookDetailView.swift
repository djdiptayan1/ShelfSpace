import SwiftUI

struct BookDetailView: View {
    let book: Book
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    // State to track book status (you might want to move this to your Book model)
    @State private var bookStatus: BookStatus = .available
    
    // Add rating state
    @State private var userRating: Int = 0
    
    // Add bookmark state
    @State private var isBookmarked: Bool = false
    
    // Add tab selection state
    @State private var selectedTab: TabSection = .details
    
    enum TabSection: String, CaseIterable {
        case details = "Details"
        case reviews = "Reviews"
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background - light blue background like in the image
            Color(red: 0.9, green: 0.95, blue: 1.0)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Fixed header with back button, title, and bookmark
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(.black)
                    }
                    
                    Spacer()
                    
                    // Navigation title
                    Text("Book Details")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                    
                    Spacer()
                    
                    // Bookmark button moved to navigation bar
                    Button(action: {
                        isBookmarked.toggle()
                    }) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                            .font(.system(size: 22))
                            .foregroundColor(isBookmarked ? .black : .gray)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(red: 0.9, green: 0.95, blue: 1.0))
                
                // Main content
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Book cover and details layout similar to the provided image
                        HStack(alignment: .top, spacing: 20) {
                            // Book Cover Image
                            Image(book.imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 170, height: 240)
                                .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 3)
                                .padding(.leading)
                            
                            VStack(alignment: .leading, spacing: 10) {
                                // Title in larger font like the image
                                Text(book.title)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.black)
                                    .padding(.top, 5)
                                
                                // Author with "by" prefix as shown in the image
                                Text("by \(book.author)")
                                    .font(.system(size: 20))
                                    .foregroundColor(.gray)
                                
                                // Status badge - made to look like the blue button in the image
                                Text(bookStatus.displayText)
                                    .font(.system(size: 16))
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(Color(red: 0.7, green: 0.85, blue: 1.0))
                                    .foregroundColor(.black)
                                    .cornerRadius(20)
                                    .padding(.top, 10)
                            }
                            .padding(.trailing)
                        }
                        .padding(.vertical)
                        
                        // Genre tags in a horizontal scroll - styling similar to the teal buttons in the image
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(book.genres, id: \.self) { genre in
                                    Text(genre)
                                        .font(.system(size: 16))
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 12)
                                        .background(Color(red: 0.7, green: 0.9, blue: 0.9))
                                        .foregroundColor(.black)
                                        .cornerRadius(20)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Tab selector for Details and Reviews
                        HStack(spacing: 0) {
                            ForEach(TabSection.allCases, id: \.self) { tab in
                                Button(action: {
                                    selectedTab = tab
                                }) {
                                    VStack(spacing: 8) {
                                        Text(tab.rawValue)
                                            .font(.system(size: 16, weight: selectedTab == tab ? .bold : .medium))
                                            .foregroundColor(selectedTab == tab ? .black : .gray)
                                        
                                        // Indicator line
                                        Rectangle()
                                            .frame(height: 3)
                                            .foregroundColor(selectedTab == tab ? .blue : .clear)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(.horizontal)
                        .background(Color.white.opacity(0.8))
                        
                        // Content based on selected tab
                        switch selectedTab {
                        case .details:
                            detailsSection
                        case .reviews:
                            reviewsSectionContent()
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    // MARK: - Details Section
    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Cards section
            HStack(spacing: 16) {
                // Card 1
                CardView(topText: "0", bottomText: "Fine", colorScheme: colorScheme)
                
                // Card 2
                CardView(topText: "Yes", bottomText: "Available", colorScheme: colorScheme)
                
                // Card 3
                CardView(topText: "4+", bottomText: "Rating", colorScheme: colorScheme)
            }
            .padding()
            
            Divider()
                .padding(.horizontal)
            
            // Description
            VStack(alignment: .leading, spacing: 10) {
                Text("Description")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                
                Text(book.description)
                    .font(.body)
                    .lineSpacing(6)
                    .foregroundColor(.black)
            }
            .padding(.horizontal)
            
            // Add Rating Section after description
            VStack(alignment: .leading, spacing: 10) {
                Text("Your Rating")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                
                HStack {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= userRating ? "star.fill" : "star")
                            .foregroundColor(star <= userRating ? .yellow : .gray)
                            .font(.title)
                            .onTapGesture {
                                userRating = star
                            }
                    }
                    
                    Spacer()
                    
                    if userRating > 0 {
                        Button(action: {
                            // Submit rating logic here
                            print("Rating submitted: \(userRating)")
                        }) {
                            Text("Submit")
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue.opacity(0.6))
                                .foregroundColor(.white)
                                .cornerRadius(8)
                        }
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer(minLength: 30)
            
            // Action Button based on status
            actionButton
                .padding()
        }
    }
    
    // MARK: - Reviews Section Content
    // Using a method instead of a computed property to avoid naming conflicts
    private func reviewsSectionContent() -> some View {
        VStack(alignment: .leading, spacing: 24) {
            ReviewsSection(book: book)
        }
    }
    
    // Action button based on status
    private var actionButton: some View {
        Button(action: {
            // Action based on current status
            switch bookStatus {
            case .available:
                bookStatus = .reading
            case .reading:
                bookStatus = .available
            case .requested:
                bookStatus = .available
            case .completed:
                bookStatus = .available
            }
        }) {
            Text(actionButtonText)
                .frame(maxWidth: .infinity)
                .padding()
                .background(actionButtonColor)
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
    
    private var actionButtonText: String {
        switch bookStatus {
        case .available:
            return "Borrow"
        case .reading:
            return "Return Book"
        case .requested:
            return "Cancel Request"
        case .completed:
            return "Return Now"
        }
    }
    
    private var actionButtonColor: Color {
        switch bookStatus {
        case .available:
            return .blue
        case .reading:
            return .green
        case .requested:
            return .gray
        case .completed:
            return .red
        }
    }
}

// MARK: - CARD VIEW
struct CardView: View {
    let topText: String
    let bottomText: String
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            // Circular background for top text
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 60, height: 60)
                Text(topText)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
            }
            
            Text(bottomText)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black)
        }
        .frame(width: 100, height: 110)
        .background(Color.white.opacity(0.8))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.blue.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Book status enum to handle different states
enum BookStatus {
    case available
    case reading
    case requested
    case completed(dueDate: Date)
    
    var displayText: String {
        switch self {
        case .available:
            return "Available"
        case .reading:
            return "Reading"
        case .requested:
            return "Requested"
        case .completed(let dueDate):
            if dueDate < Date() {
                return "Overdue"
            } else {
                return "Due \(dueDate.formatted(.dateTime.day().month()))"
            }
        }
    }
}

struct BookDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Available book
            BookDetailView(book: Book(
                imageName: "book1",
                title: "The Song of Achilles",
                author: "Madeline Miller",
                genres: ["Historical Fiction", "Fantasy"],
                description: "A tale of gods, kings, immortal fame, and the human heart, The Song of Achilles is a dazzling literary feat that brilliantly reimagines Homer's enduring masterwork, The Iliad."
            ))
            .previewDisplayName("Available")
            
            // Requested book with dark mode
            BookDetailView(book: Book(
                imageName: "book1",
                title: "The Song of Achilles",
                author: "Madeline Miller",
                genres: ["Historical Fiction", "Fantasy"],
                description: "A tale of gods, kings, immortal fame, and the human heart, The Song of Achilles is a dazzling literary feat that brilliantly reimagines Homer's enduring masterwork, The Iliad."
            ))
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
        }
    }
}
