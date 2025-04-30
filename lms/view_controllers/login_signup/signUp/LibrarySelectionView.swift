//
//  LibrarySelectionView.swift
//  lms
//
//  Created by Diptayan Jash on 24/04/25.
//

import Foundation
import SwiftUI

struct LibrarySelectionView: View {
    @ObservedObject var viewModel: SignupModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @State private var libraries: [Library] = []
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var searchText = ""
    @State private var showSuccessAlert = false

    var body: some View {
        scrollContent
            .onAppear {
                loadLibraries()
            }
            .fullScreenCover(item: $viewModel.destination) { destination in
                switch destination {
                case .admin: AdminTabbar()
                case .librarian: LibrarianTabbar()
                case .member: UserTabbar()
                }
            }
    }
    
    private var scrollContent: some View {
        ScrollView {
            VStack(spacing: 30) {
                headerSection
                searchBarSection
                librariesSection
                errorSection
                signupButton
                
                Spacer()
            }
            .padding(.top, 20)
            .padding(.bottom, 24)
        }
    }
    
    private var headerSection: some View {
        VStack {
            Text("Choose Library")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(Color.text(for: colorScheme))

            Text("Select your preferred library")
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                .padding(.bottom, 10)
        }
    }
    
    private var searchBarSection: some View {
        CustomTextField(
            text: $searchText,
            placeholder: "Search libraries",
            iconName: "magnifyingglass",
            isSecure: false,
            showSecureToggle: false,
            colorScheme: colorScheme,
            fieldType: .email
        )
        .padding(.horizontal, 24)
    }
    
    private var librariesSection: some View {
        Group {
            if isLoading {
                loadingView
            } else if !errorMessage.isEmpty {
                errorView
            } else if libraries.isEmpty {
                emptyView
            } else {
                libraryListView
            }
        }
        .padding(.horizontal, 24)
        
    }
    
    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.2)
            Spacer()
        }
    }
    
    private var errorView: some View {
        VStack {
            Spacer()
            Text(errorMessage)
                .foregroundColor(.red)
                .font(.system(size: 16))
                .padding()
            Spacer()
        }
    }
    
    private var emptyView: some View {
        VStack {
            Spacer()
            Text("No libraries available")
                .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                .font(.system(size: 16))
                .padding()
            Spacer()
        }
    }
    
    private var libraryListView: some View {
            LazyVStack(spacing: 16) {
                ForEach(filteredLibraries) { library in
                    LibraryCard(
                        library: library,
                        isSelected: viewModel.selectedLibraryId == library.id,
                        onSelect: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                viewModel.selectedLibraryId = library.id
                                viewModel.selectedLibraryName = library.name
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                        },
                        colorScheme: colorScheme
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    
    private var errorSection: some View {
        Group {
            if viewModel.showError {
                Text(viewModel.errorMessage)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundColor(.red)
                    .padding(.horizontal, 24)
            }
        }
    }
    
    private var signupButton: some View {
        Button {
            withAnimation {
                if viewModel.isStep4Valid {
                    viewModel.completeSignup { success in
                        if success {
                        }
                    }
                } else {
                    viewModel.errorMessage = "Please select a library."
                    viewModel.showError = true
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }
            }
        } label: {
            buttonContent
        }
        .disabled(viewModel.isLoading || !viewModel.isStep4Valid)
        .opacity(viewModel.isStep4Valid ? 1 : 0.7)
    }
    
    private var buttonContent: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary(for: colorScheme))
            
            if viewModel.isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
            } else {
                Text("Complete Signup")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .frame(height: 54)
        .padding(.horizontal, 24)
    }

    private var filteredLibraries: [Library] {
        if searchText.isEmpty {
            return libraries
        } else {
            return libraries.filter { library in
                library.name.lowercased().contains(searchText.lowercased()) ||
                    (library.city?.lowercased().contains(searchText.lowercased()) ?? false)
            }
        }
    }

    private func loadLibraries() {
        isLoading = true
        errorMessage = ""

        fetchLibraries { result in
            isLoading = false

            switch result {
            case let .success(loadedLibraries):
                self.libraries = loadedLibraries
            case let .failure(error):
                errorMessage = "Failed to load libraries: \(error.localizedDescription)"
            }
        }
    }
}

struct LibraryCard: View {
    let library: Library
    let isSelected: Bool
    let onSelect: () -> Void
    let colorScheme: ColorScheme

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "building.columns.fill")
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? Color.secondary(for: colorScheme) : Color.primary(for: colorScheme).opacity(0.7))
                    .frame(width: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text(library.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Color.text(for: colorScheme))

                    if let city = library.city, let state = library.state {
                        Text("\(city), \(state)")
                            .font(.system(size: 14))
                            .foregroundColor(Color.text(for: colorScheme).opacity(0.7))
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.secondary(for: colorScheme))
                        .font(.system(size: 20))
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.background(for: colorScheme))
                    .shadow(color: Color.primary(for: colorScheme).opacity(isSelected ? 0.2 : 0.08),
                            radius: isSelected ? 8 : 4,
                            x: 0,
                            y: isSelected ? 4 : 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.secondary(for: colorScheme) : Color.clear, lineWidth: 2)
                    )
            )
        }
    }
}
