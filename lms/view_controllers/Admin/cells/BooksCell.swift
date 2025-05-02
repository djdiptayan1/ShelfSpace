//
//  BooksCell.swift
//  lms
//
//  Created by Diptayan Jash on 23/04/25.
//

import Foundation
import SwiftUI

struct BooksCell: View {
    @Environment(\.colorScheme) private var colorScheme
    let book: BookModel
    @State private var loadedImage: UIImage? = nil
    @State private var isLoading: Bool = false
    @State private var loadError: Bool = false

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Book cover with shadow and gradient placeholder
            ZStack {
                if let image = loadedImage {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 70, height: 100)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(hex: "A1C4FD"), Color(hex: "C2E9FB")]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Image(systemName: "book.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .frame(width: 70, height: 100)
            .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
            .onAppear {
                loadCoverImage()
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(book.title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .lineLimit(2)
                    .foregroundColor(colorScheme == .dark ? .white : Color(hex: "2C3E50"))

                Text(book.authorNames?.joined(separator: ", ") ?? "Unknown Author")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(Color(hex: "7F8C8D"))
                    .lineLimit(1)

                Spacer(minLength: 6)

                HStack {
                    // Book availability indicator with custom styling
                    HStack(spacing: 4) {
                        Image(systemName: "book")
                            .font(.system(size: 13))

                        Text("\(book.availableCopies)/\(book.totalCopies)")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(book.availableCopies > 0 ?
                                (colorScheme == .dark ? Color.green.opacity(0.2) : Color.green.opacity(0.1)) :
                                (colorScheme == .dark ? Color.red.opacity(0.2) : Color.red.opacity(0.1)))
                    )
                    .foregroundColor(book.availableCopies > 0 ?
                        (colorScheme == .dark ? Color.green : Color.green.opacity(0.8)) :
                        (colorScheme == .dark ? Color.red : Color.red.opacity(0.8)))

                    Spacer()

                    // Published date with nice formatting
                    if let publishedDate = book.publishedDate {
                        Text(formatDate(publishedDate))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(hex: "95A5A6"))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(colorScheme == .dark ? Color(hex: "2A2A2A") : Color(hex: "EEF1F5"))
                            )
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(hex: "1E1E1E") : .white)
                .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.08), radius: 10, x: 0, y: 4)
        )
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy"
        return formatter.string(from: date)
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
    urlString = urlString.replacingOccurrences(of: "http://", with: "https://")
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
