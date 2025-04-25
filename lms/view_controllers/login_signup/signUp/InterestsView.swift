//
//  InterestsView.swift
//  lms
//
//  Created by Diptayan Jash on 24/04/25.
//

import Foundation
import SwiftUI

struct InterestsView: View {
    @ObservedObject var viewModel: SignupModel
    @Environment(\.colorScheme) private var colorScheme
    @State private var genres: [String] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    // Example genres - will be replaced with data from API
    private let sampleGenres = [
        "Fiction", "Non-Fiction", "Sci-Fi", "Fantasy",
        "Romance", "Mystery", "Thriller", "Horror",
        "Biography", "History", "Science", "Self-Help",
        "Philosophy", "Poetry", "Drama", "Adventure"
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 30) {
                Text("Select Interests")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(Color.text(for: colorScheme))
                
                Text("Choose up to 5 genres that interest you")
                    .font(.system(size: 16, weight: .medium, design: .rounded))
                    .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                    .padding(.bottom, 10)
                
                if viewModel.selectedGenres.count > 0 {
                    Text("\(viewModel.selectedGenres.count)/5 selected")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color.secondary(for: colorScheme))
                }
                
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .scaleEffect(1.2)
                        .padding()
                } else if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.system(size: 16))
                        .padding()
                } else {
                    // Genre selection grid
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 150))], spacing: 15) {
                        ForEach(displayedGenres, id: \.self) { genre in
                            GenreButton(
                                title: genre,
                                isSelected: viewModel.selectedGenres.contains(genre),
                                action: {
                                    toggleGenre(genre)
                                },
                                colorScheme: colorScheme
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                }
                
                if viewModel.showError {
                    Text(viewModel.errorMessage)
                        .font(.system(size: 14, design: .rounded))
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                }
                
                Button {
                    withAnimation {
                        if viewModel.isStep3Valid {
                            viewModel.nextStep()
                        } else {
                            viewModel.errorMessage = "Please select at least one genre."
                            viewModel.showError = true
                        }
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.secondary(for: colorScheme))
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                        } else {
                            Text("Continue")
                                .font(.system(size: 16, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(height: 54)
                    .padding(.horizontal, 24)
                }
                .disabled(viewModel.isLoading || !viewModel.isStep3Valid)
                .opacity(viewModel.isStep3Valid ? 1 : 0.7)
                
                Spacer()
            }
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
        .onAppear {
            loadGenres()
        }
    }
    
    private var displayedGenres: [String] {
        // Show loaded genres or sample genres if API call fails
        return genres.isEmpty ? sampleGenres : genres
    }
    
    private func toggleGenre(_ genre: String) {
        if viewModel.selectedGenres.contains(genre) {
            viewModel.selectedGenres.remove(genre)
        } else if viewModel.selectedGenres.count < 5 {
            viewModel.selectedGenres.insert(genre)
        }
    }
    
    private func loadGenres() {
        isLoading = true
        errorMessage = ""
        
        fetchGenres { result in
            isLoading = false
            
            switch result {
            case .success(let loadedGenres):
                self.genres = loadedGenres
            case .failure(let error):
                errorMessage = "Failed to load genres: \(error.localizedDescription)"
                // Use sample genres as fallback
            }
        }
    }
}

struct GenreButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    let colorScheme: ColorScheme
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(isSelected ? .white : Color.text(for: colorScheme))
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.secondary(for: colorScheme) : Color.background(for: colorScheme))
                        .shadow(color: Color.primary(for: colorScheme).opacity(0.08), radius: 4, x: 0, y: 2)
                )
        }
    }
}
