
import SwiftUI

struct BookDetailView: View {
    let book: Book
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    
    // State to track book status (you might want to move this to your Book model)
    @State private var bookStatus: BookStatus = .available
    
    // Add rating state
    @State private var userRating: Int = 0
    
    var body: some View {
        ZStack(alignment: .top) {
            // Background
            ReusableBackground(colorScheme: colorScheme)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 0) {
                // Fixed header with back button and title
                HStack {
                    Button(action: {
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.title2)
                            .foregroundColor(Color.primary(for: colorScheme))
                    }
                    
                    Spacer()
                    
                    // Navigation title
                    Text("Book Details")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.text(for: colorScheme))
                    
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(ReusableBackground(colorScheme: colorScheme))
                
                ////////////
                // Scrollable content
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Add spacing for the fixed header
                        HStack{
                            // Book Cover Image
                            Image(book.imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width:130 ,height: 240)
                                .shadow(color: Color.primary(for: colorScheme).opacity(0.3), radius: 10, x: 0, y: 5)
                                .padding(.horizontal)
                                .padding()
                            
                            VStack(alignment:.leading, spacing:12){
                                // Book Title
                                Text(book.title)
                                    .font(.system(size: 22))
                                    .fontWeight(.bold)
                                    .foregroundColor(Color.text(for: colorScheme))
                                    .padding(.horizontal)
            
                                // Author
                                Text("by \(book.author)")
                                    .font(.headline)
                                    .foregroundColor(Color.gray.opacity(0.8))
                                    .padding(.horizontal)
                               
                                // Status indicator
                                statusBadge
                                    .padding(.top)
                            }
                        }
                        
                        // MARK: - GENRE AND OTHER
                        // Genres
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack {
                                ForEach(book.genres, id: \.self) { genre in
                                    Text(genre)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical,14)
                                        .background(Color.primary(for: colorScheme).opacity(0.3))
                                        .foregroundColor(Color.text(for: colorScheme))
                                        .cornerRadius(10)
                                        .padding(.trailing,6)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        //CARD FINE AVAILABLE
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
                            .background(Color.secondary(for: colorScheme))
                        
                        // Description
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Description")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.text(for: colorScheme))
                            
                            Text(book.description)
                                .font(.body)
                                .lineSpacing(6)
                                .foregroundColor(Color.text(for: colorScheme))
                        }
                        .padding(.horizontal)
                        
                        // Add Rating Section after description
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Your Rating")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(Color.text(for: colorScheme))
                            
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
                                        // For now just print the rating
                                        print("Rating submitted: \(userRating)")
                                    }) {
                                        Text("Submit")
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 8)
                                            .background(Color.primary(for: colorScheme).opacity(0.6))
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
                    .padding(.vertical)
                }
            }
            .navigationBarHidden(true)
        }
    }
    
// MARK: - Status badge view
    private var statusBadge: some View {
        Group {
            switch bookStatus {
            case .available:
                Text("Available")
                    .font(.system(size: 22))
                    .padding(22)
                    .padding(.horizontal)
                    .background(Color.secondary(for: colorScheme).opacity(0.5))
                    .foregroundColor(Color.text(for: colorScheme))
                    .cornerRadius(8)
                    
            case .reading:
                Text("Reading")
                    .font(.system(size: 22))
                    .padding(22)
                    .padding(.horizontal)
                    .background(Color.secondary(for: colorScheme))
                    .foregroundColor(Color.text(for: colorScheme))
                    .cornerRadius(8)
            case .requested:
                Text("Requested")
                    .font(.system(size: 22))
                    .padding(22)
                    .padding(.horizontal)
                    .background(Color.primary(for: colorScheme))
                    .foregroundColor(Color.text(for: colorScheme))
                    .cornerRadius(8)
            case .completed(let dueDate):
                if dueDate < Date() {
                    Text("Overdue")
                        .font(.system(size: 22))
                        .padding(22)
                        .padding(.horizontal)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                } else {
                    Text("Due \(dueDate.formatted(.dateTime.day().month().year()))")
                        .font(.system(size: 22))
                        .padding(22)
                        .padding(.horizontal)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }.padding()
    }
    
    // MARK: - Action button based on status
    private var actionButton: some View {
        Group {
            switch bookStatus {
            case .available:
                Button(action: {
                    // Borrow action
                    bookStatus = .reading
                }) {
                    Text("Borrow")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.primary(for: colorScheme).opacity(0.6))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
            case .reading:
                Button(action: {
                    // Return action
                    bookStatus = .available
                }) {
                    Text("Return Book")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
            case .requested:
                Button(action: {
                    // Cancel request action
                    bookStatus = .available
                }) {
                    Text("Cancel Request")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                
            case .completed(let dueDate):
                if dueDate < Date() {
                    Button(action: {
                        // Return overdue book action
                        bookStatus = .available
                    }) {
                        Text("Return Now")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                } else {
                    Button(action: {
                        // Renew action
                        // You might want to add renewal logic here
                    }) {
                        Text("Renew")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
            }
        }
    }
}


// MARK: - CARD VIEW FINE RATING

struct CardView: View {
    let topText: String
    let bottomText: String
    let colorScheme: ColorScheme
    
    var body: some View {
        VStack(spacing: 12) {
            // Circular background for top text
            ZStack {
                Circle()
                    .fill(Color.accent(for: colorScheme).opacity(0.25))
                    .frame(width: 60, height: 60)
                Text(topText)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(Color.text(for: colorScheme))
            }
            
            Text(bottomText)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color.text(for: colorScheme))
        }
        .frame(width: 110, height: 110)
        .background(Color.TabbarBackground(for: colorScheme).opacity(0.8))
        .cornerRadius(12)
        .shadow(color: Color.primary(for: colorScheme).opacity(0.2), radius: 5, x: 0, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accent(for: colorScheme).opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 1)
    }
}



// MARK: - Book status enum to handle different states
enum BookStatus {
    case available
    case reading
    case requested
    case completed(dueDate: Date)
}




struct BookDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Available book
            BookDetailView(book: Book(
                imageName: "book1",
                title: "Create Your Own Business",
                author: "Alex Michaelides",
                genres: ["Thriller", "Mystery","Horror","Serious"],
                description: "A psychological thriller about a woman who shoots her husband and then stops speakingA psychological thriller about a woman who shoots her husband and then stops speakingA psychological thriller about a woman who shoots her husband and then stops speakingA psychological thriller about a woman who shoots her husband and then stops speakingA psychological thriller about a woman who shoots her husband and then stops speaking."
            ))
            .previewDisplayName("Available")
            
            // Requested book
            BookDetailView(book: Book(
                imageName: "book1",
                title: "Create Your Own Business",
                author: "Alex Michaelides",
                genres: ["Thriller", "Mystery"],
                description: "A psychological thriller about a woman who shoots her husband and then stops speaking."
            ))
            .previewDisplayName("Requested")
            
            // Rented book with due date
            BookDetailView(book: Book(
                imageName: "book1",
                title: "Create Your Own Business",
                author: "Alex Michaelides",
                genres: ["Thriller", "Mystery"],
                description: "A psychological thriller about a woman who shoots her husband and then stops speaking."
            ))
            .previewDisplayName("Rented")
            
            // Overdue book
            BookDetailView(book: Book(
                imageName: "book1",
                title: "Create Your Own Business",
                author: "Alex Michaelides",
                genres: ["Thriller", "Mystery"],
                description: "A psychological thriller about a woman who shoots her husband and then stops speaking."
            ))
            .previewDisplayName("Overdue")
        }
        
    }
}
