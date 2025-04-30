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
    @State private var isLoading = false
    @State private var errorMessage = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Select Your Interests")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(Color.text(for: colorScheme))
                    
                    Text("Choose up to 5 genres that interest you")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                }
                .padding(.top, 30)
                .padding(.bottom, 16)
                
                // Selection counter with progress bar
                if !viewModel.selectedGenres.isEmpty {
                    VStack(spacing: 6) {
                        HStack {
                            Text("\(viewModel.selectedGenres.count)/5 selected")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(Color.secondary(for: colorScheme))
                            
                            Spacer()
                        }
                        
                        // Custom progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.background(for: colorScheme))
                                    .frame(height: 10)
                                
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.secondary(for: colorScheme))
                                    .frame(width: geometry.size.width * CGFloat(viewModel.selectedGenres.count) / 5, height: 10)
                                    .animation(.spring(), value: viewModel.selectedGenres.count)
                            }
                        }
                        .frame(height: 10)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
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
                    // Genre selection grid with improved layout
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 150, maximum: 180), spacing: 16)
                    ], spacing: 16) {
                        ForEach(BookGenre.allCases) { genre in
                            GenreButton(
                                genre: genre,
                                isSelected: viewModel.selectedGenres.contains(genre.rawValue),
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
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.red)
                        .padding(.horizontal, 24)
                        .padding(.top, 4)
                }
                
                Spacer(minLength: 36)
                
                // Continue button with improved visual style
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
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.secondary(for: colorScheme))
                            .shadow(color: Color.secondary(for: colorScheme).opacity(0.4), radius: 8, x: 0, y: 4)
                        
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                        } else {
                            Text("Continue")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(height: 60)
                    .padding(.horizontal, 24)
                }
                .disabled(viewModel.isLoading || !viewModel.isStep3Valid)
                .opacity(viewModel.isStep3Valid ? 1 : 0.7)
                .padding(.bottom, 24)
            }
            .padding(.bottom, 24)
        }
    }
    
    private func toggleGenre(_ genre: BookGenre) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if viewModel.selectedGenres.contains(genre.rawValue) {
                viewModel.selectedGenres.remove(genre.rawValue)
            } else if viewModel.selectedGenres.count < 5 {
                viewModel.selectedGenres.insert(genre.rawValue)
                hapticFeedback()
            }
        }
    }
    
    private func hapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
}

struct GenreButton: View {
    let genre: BookGenre
    let isSelected: Bool
    let action: () -> Void
    let colorScheme: ColorScheme
    
    var body: some View {
        Button(action: action) {
            genre.buttonStyle(isSelected: isSelected, colorScheme: colorScheme)
        }
    }
}
