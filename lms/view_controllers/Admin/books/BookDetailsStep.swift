//
//  BookDetailsStep.swift
//  lms
//
//  Created by Diptayan Jash on 24/04/25.
//

import Foundation
import SwiftUI

struct BookDetailsStep: View {
    @Binding var bookData: BookData
    @Binding var showImagePicker: Bool
    @Binding var isLoading: Bool
    let onSave: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    @State private var focusedField: String?
    @State private var showSuccess = false
    @State private var errorMessage = ""
    @State private var showError = false
    @State private var successMessage = ""
    
    @State private var selectedGenres: Set<BookGenre> = []
    
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                HStack(alignment: .top, spacing: 30) {
                    // Book cover
                    VStack(spacing: 12) {
                        if let cover = bookData.bookCover {
                            Image(uiImage: cover)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 130, height: 195)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .shadow(color: Color.black.opacity(0.3), radius: 10, x: 0, y: 5)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                                )
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.gray.opacity(0.15))
                                    .frame(width: 130, height: 195)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 0.5)
                                    )

                                VStack(spacing: 10) {
                                    Image(systemName: "book.closed")
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 40, height: 40)
                                        .foregroundColor(.gray.opacity(0.6))

                                    Text("No Cover")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                            }
                        }

                        Button(action: {
                            showImagePicker = true
                        }) {
                            HStack {
                                Image(systemName: bookData.bookCover == nil ? "plus.circle.fill" : "arrow.triangle.2.circlepath")
                                    .font(.system(size: 14))
                                Text(bookData.bookCover == nil ? "Add Cover" : "Change")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundColor(.blue)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 14)
                            .background(Color.blue.opacity(0.15))
                            .cornerRadius(20)
                        }
                    }
                    .padding(.top, 5)

                    // Basic Info Quick Entry
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.leading, 4)
                            
                            TextField("Book Title", text: $bookData.bookTitle)
                                .font(.headline)
                                .padding(12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.gray.opacity(0.08))
                                        .shadow(color: Color.black.opacity(0.03), radius: 3, x: 0, y: 1)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }

                        VStack(alignment: .leading, spacing: 5) {
                            Text("ISBN")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.leading, 4)
                            
                            HStack {
                                Image(systemName: "barcode")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16))
                                Text(bookData.isbn)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color.gray.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.15), lineWidth: 1)
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                // Divider
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 1)
                    .padding(.horizontal)

                // Form Fields in Cards
                VStack(spacing: 20) {
                    // Book Details Card
                    DetailCard(title: "Book Details") {
                        VStack(spacing: 16) {
                            FormTextEditor(title: "Description", text: $bookData.description)
                            
                            FormDatePicker(title: "Published Date", date: $bookData.publishedDate)
                            
                            FormTextField(title: "Publisher", placeholder: "Enter publisher", text: $bookData.publisher)
                            
//                            FormTextField(title: "Language", placeholder: "Enter language", text: $bookData.language)
                            
                            // Categories Section
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Genres")
                                    .font(.subheadline)
                                    .foregroundColor(Color.text(for: colorScheme))
                                
                                // Fiction section
                                Text("Fiction")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                                    .padding(.top, 4)
                                    .padding(.leading, 4)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(BookGenre.fictionGenres, id: \.self) { genre in
                                            GenreChip(
                                                genre: genre,
                                                isSelected: selectedGenres.contains(genre),
                                                onToggle: {
                                                    toggleGenre(genre)
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                                
                                // Non-fiction section
                                Text("Non-Fiction")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(.gray)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 8) {
                                        ForEach(BookGenre.nonFictionGenres, id: \.self) { genre in
                                            GenreChip(
                                                genre: genre,
                                                isSelected: selectedGenres.contains(genre),
                                                onToggle: {
                                                    toggleGenre(genre)
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                    }

                    // Authors Card
                    DetailCard(title: "Authors") {
                        VStack(spacing: 12) {
                            ForEach(0 ..< bookData.authorNames.count, id: \.self) { index in
                                HStack {
                                    TextField("Author name", text: $bookData.authorNames[index])
                                        .padding()
                                        .background(Color.gray.opacity(0.05))
                                        .cornerRadius(10)

                                    if bookData.authorNames.count > 1 {
                                        Button(action: {
                                            bookData.authorNames.remove(at: index)
                                        }) {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                                .padding(8)
                                                .background(Color.red.opacity(0.1))
                                                .cornerRadius(8)
                                        }
                                    }
                                }
                            }

                            Button(action: {
                                bookData.authorNames.append("")
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Author")
                                }
                                .foregroundColor(.blue)
                                .padding(.vertical, 10)
                                .frame(maxWidth: .infinity)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(10)
                            }
                        }
                    }

                    // Copy Management Card
                    DetailCard(title: "Copy Management") {
                        VStack(spacing: 20) {
                            CopyManagementStepper(title: "Total Copies", value: $bookData.totalCopies, range: 1 ... 100)
                            CopyManagementStepper(title: "Available Copies", value: $bookData.availableCopies, range: 0 ... bookData.totalCopies)
                            CopyManagementStepper(title: "Reserved Copies", value: $bookData.reservedCopies, range: 0 ... bookData.totalCopies)
                        }
                    }
                }
                .padding(.horizontal)

                // Save Button
                Button(action: {
                    onSave()
                }) {
                    Text(isLoading ? "Saving Book..." : "Save Book")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                }
                .background(
                    LinearGradient(
                        gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.blue.opacity(0.3), radius: 5, x: 0, y: 3)
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .disabled(bookData.bookTitle.isEmpty || isLoading)
                .opacity(bookData.bookTitle.isEmpty || isLoading ? 0.6 : 1.0)
            }
            .padding(.bottom, 32)
        }
        .onTapGesture {
            focusedField = nil
        }
    }
    private func toggleGenre(_ genre: BookGenre) {
        if selectedGenres.contains(genre) {
            selectedGenres.remove(genre)
        } else {
            selectedGenres.insert(genre)
        }
        // Update bookData.genreIds with the selected genres
        bookData.genreNames = Array(selectedGenres).map { $0.rawValue }
        
        // Also update categories for display purposes
        bookData.categories = Array(selectedGenres).map { $0.displayName }
    }
    
    private func resetForm() {
        bookData = BookData() // or your default initializer
    }
}

struct GenreChip: View {
    let genre: BookGenre
    let isSelected: Bool
    let onToggle: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 6) {
                Image(systemName: genre.iconName)
                    .font(.system(size: 10))
                
                Text(genre.displayName)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? genre.themeColor.opacity(0.2) : Color.gray.opacity(0.1))
            .foregroundColor(isSelected ? genre.themeColor : Color.gray)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? genre.themeColor.opacity(0.3) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct DetailCard<Content: View>: View {
    let title: String
    let content: Content
    @Environment(\.colorScheme) private var colorScheme

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .foregroundColor(Color.text(for: colorScheme))
                .padding(.leading, 4)

            VStack(spacing: 16) {
                content
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
                    .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
            )
        }
    }
}

struct CopyManagementStepper: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.text(for: colorScheme))

            HStack {
                Spacer()
                
                Button(action: {
                    if value > range.lowerBound {
                        value -= 1
                    }
                }) {
                    Image(systemName: "minus")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 20, height: 20)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(value > range.lowerBound ? Color.blue : Color.gray.opacity(0.5))
                        )
                }
                .disabled(value <= range.lowerBound)
                
                Text("\(value)")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .frame(minWidth: 50)
                    .frame(height: 40)
                    .padding(.horizontal, 15)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )

                Button(action: {
                    if value < range.upperBound {
                        value += 1
                    }
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .medium))
                        .frame(width: 20, height: 20)
                        .padding(10)
                        .background(
                            Circle()
                                .fill(value < range.upperBound ? Color.blue : Color.gray.opacity(0.5))
                        )
                }
                .disabled(value >= range.upperBound)
                
                Spacer()
            }
            .padding(.vertical, 6)
        }
        .padding(.vertical, 4)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.03))
        )
        .padding(.vertical, 4)
    }
}

struct FormTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color.text(for: colorScheme))

            TextField(placeholder, text: $text)
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(10)
        }
    }
}

struct FormTextEditor: View {
    let title: String
    @Binding var text: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color.text(for: colorScheme))

            TextEditor(text: $text)
                .frame(height: 100)
                .padding(10)
                .background(Color.gray.opacity(0.05))
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

struct FormDatePicker: View {
    let title: String
    @Binding var date: Date
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(Color.text(for: colorScheme))

            DatePicker("", selection: $date, displayedComponents: .date)
                .datePickerStyle(WheelDatePickerStyle())
//                .datePickerStyle(DefaultDatePickerStyle())
                .labelsHidden() // Hide built-in label
                .frame(maxWidth: .infinity, alignment: .leading) // Make it left-aligned and full width
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.08)) 
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
        }
    }
}

// Preview
struct BookDetailsStep_Previews: PreviewProvider {
    static var previews: some View {
        BookDetailsStep(
            bookData: .constant(BookData()),
            showImagePicker: .constant(false),
            isLoading: .constant(false),
            onSave: {}
        )
    }
}
