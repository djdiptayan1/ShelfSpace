import SwiftUI

// MARK: - Review Model
struct Review: Identifiable {
    let id = UUID()
    let username: String
    let date: Date
    let rating: Int
    let comment: String
    let isVerified: Bool
}

// Add reviews property to Book model
extension Book {
    // This would normally be part of your Book model, adding here for reference
    var reviews: [Review] {
        get {
            // In a real app, this would be fetched from your database
            // For this example, we're returning mock data
            return [
                Review(
                    username: "BookLover42",
                    date: Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date(),
                    rating: 5,
                    comment: "Absolutely loved this book! The character development was incredible and the prose was beautiful. Couldn't put it down once I started reading.",
                    isVerified: true
                ),
                Review(
                    username: "ReadingEnthusiast",
                    date: Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date(),
                    rating: 4,
                    comment: "A compelling read with vivid descriptions. The story was engaging throughout, though I found the ending a bit rushed.",
                    isVerified: true
                ),
                Review(
                    username: "LiteraryExplorer",
                    date: Calendar.current.date(byAdding: .day, value: -45, to: Date()) ?? Date(),
                    rating: 3,
                    comment: "Well-written but not entirely my genre. The themes were interesting but some of the plot points felt predictable.",
                    isVerified: false
                )
            ]
        }
    }
}

// MARK: - Simplified Reviews Section
struct ReviewsSection: View {
    let book: BookModel
    @Environment(\.colorScheme) var colorScheme
    @State private var showingWriteReview = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with review count and write review button
            HStack {
                Button(action: {
                    showingWriteReview.toggle()
                }) {
                    HStack {
                        Image(systemName: "square.and.pencil")
                        Text("Write Review")
                        Spacer() // This will push content to the left
                    }
                    .foregroundColor(Color.text(for: colorScheme))
                    .padding(.horizontal)
                    .padding(.vertical)
                    .background(Color.accent(for: colorScheme))
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity) // Makes the button take full width
                .padding(.horizontal, 16) // Adds 16-point padding on both sides
                .sheet(isPresented: $showingWriteReview) {
                    WriteReviewView(book: book)
                }
            }
            
            // List of reviews
            if [].isEmpty {
                Text("No reviews yet. Be the first to review!")
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.7))
                    .cornerRadius(8)
                    .padding(.horizontal)
                    .padding(.vertical)
            } else {
//                VStack(spacing: 16) {
//                    ForEach(book.reviews) { review in
//                        ReviewItemView(review: review)
//                    }
//                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Individual Review Item
struct ReviewItemView: View {
    let review: Review
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Review header with username and date
            HStack {
                Text(review.username)
                    .font(.headline)
                
                if review.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 14))
                }
                
                Spacer()
                
                Text(review.date.formatted(.dateTime.day().month().year()))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
            
            // Star rating
            HStack(spacing: 4) {
                ForEach(1...5, id: \.self) { star in
                    Image(systemName: star <= review.rating ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                        .font(.system(size: 16))
                }
            }
            
            // Review content
            Text(review.comment)
                .font(.body)
                .lineSpacing(6)
            
            // Action buttons
            HStack(spacing: 20) {
                Button(action: {
                    // Helpful button action
                }) {
                    HStack {
                        Image(systemName: "hand.thumbsup")
                        Text("Helpful")
                    }
                    .font(.subheadline)
                    .foregroundColor(.gray)
                }
                
                Button(action: {
                    // Report button action
                }) {
                    HStack {
                        Image(systemName: "flag")
                        Text("Report")
                    }
                    .font(.subheadline)
                    .foregroundColor(.gray)
                }
            }
            .padding(.top, 4)
        }
        .padding()
        .background(Color.white.opacity(0.7))
        .cornerRadius(12)
    }
}

// MARK: - Write Review View
struct WriteReviewView: View {
    let book: BookModel
    @Environment(\.presentationMode) var presentationMode
    
    @State private var userRating: Int = 0
    @State private var reviewText: String = ""
    @State private var isSubmitting = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Rate this book")) {
                    HStack(spacing: 10) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= userRating ? "star.fill" : "star")
                                .foregroundColor(star <= userRating ? .yellow : .gray)
                                .font(.title)
                                .onTapGesture {
                                    userRating = star
                                }
                        }
                    }
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
                
                Section(header: Text("Write your review")) {
                    TextEditor(text: $reviewText)
                        .frame(height: 200)
                    
                    Text("\(reviewText.count)/500 characters")
                        .font(.caption)
                        .foregroundColor(reviewText.count > 500 ? .red : .gray)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
                
                Section {
                    Button(action: {
                        submitReview()
                    }) {
                        if isSubmitting {
                            ProgressView()
                        } else {
                            Text("Submit Review")
                                .frame(maxWidth: .infinity, alignment: .center)
                                .foregroundColor(.white)
                        }
                    }
                    .disabled(userRating == 0 || reviewText.isEmpty || reviewText.count > 500 || isSubmitting)
                    .listRowBackground(
                        (userRating == 0 || reviewText.isEmpty || reviewText.count > 500 || isSubmitting) ?
                            Color.gray : Color.blue
                    )
                }
            }
            .navigationTitle("Review \(book.title)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
    
    func submitReview() {
        // Simulating network request
        isSubmitting = true
        
        // In a real app, you would save the review to your backend
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSubmitting = false
            presentationMode.wrappedValue.dismiss()
            
            // You would typically handle the response from your API here
            // and update the UI accordingly
        }
    }
}

// MARK: - Preview
//struct ReviewsSection_Previews: PreviewProvider {
//    static var previews: some View {
//        ScrollView {
//            ReviewsSection(book: Book(
//                imageName: "book1",
//                title: "The Song of Achilles",
//                author: "Madeline Miller",
//                genres: ["Historical Fiction", "Fantasy"],
//                description: "A tale of gods, kings, immortal fame, and the human heart, The Song of Achilles is a dazzling literary feat that brilliantly reimagines Homer's enduring masterwork, The Iliad."
//            ))
//            .padding(.vertical)
//        }
//        .background(Color(red: 0.9, green: 0.95, blue: 1.0))
//    }
//}
