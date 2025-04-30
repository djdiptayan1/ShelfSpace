//import SwiftUI
//
//struct GenreSelectorView: View {
//    @Binding var selectedGenres: Set<BookGenre>
//    let maxSelections: Int
//    @Environment(\.colorScheme) private var colorScheme
//    @State private var showAllGenres = false
//    @State private var searchText = ""
//    
//    private var filteredGenres: [BookGenre] {
//        if searchText.isEmpty {
//            return Array(BookGenre.allCases)
//        } else {
//            return BookGenre.allCases.filter {
//                $0.displayName.lowercased().contains(searchText.lowercased())
//            }
//        }
//    }
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 16) {
//            // Header and selected count
//            HStack {
//                Text("Categories")
//                    .font(.headline)
//                    .foregroundColor(Color.text(for: colorScheme))
//                
//                Spacer()
//                
//                Text("\(selectedGenres.count)/\(maxSelections)")
//                    .font(.subheadline)
//                    .foregroundColor(selectedGenres.count >= maxSelections ? .orange : .secondary)
//            }
//            
//            // Search bar
//            HStack {
//                Image(systemName: "magnifyingglass")
//                    .foregroundColor(.secondary)
//                
//                TextField("Search genres", text: $searchText)
//                
//                if !searchText.isEmpty {
//                    Button(action: {
//                        searchText = ""
//                    }) {
//                        Image(systemName: "xmark.circle.fill")
//                            .foregroundColor(.secondary)
//                    }
//                }
//            }
//            .padding(10)
//            .background(Color.gray.opacity(0.1))
//            .cornerRadius(10)
//            
//            // Selected genres chips
//            if !selectedGenres.isEmpty {
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("Selected")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                    
//                    ScrollView(.horizontal, showsIndicators: false) {
//                        HStack(spacing: 8) {
//                            ForEach(Array(selectedGenres), id: \.self) { genre in
//                                HStack(spacing: 4) {
//                                    Image(systemName: genre.iconName)
//                                        .font(.system(size: 12))
//                                    
//                                    Text(genre.displayName)
//                                        .font(.system(size: 14, weight: .medium))
//                                    
//                                    Button(action: {
//                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                                            selectedGenres.remove(genre)
//                                        }
//                                    }) {
//                                        Image(systemName: "xmark.circle.fill")
//                                            .font(.system(size: 14))
//                                    }
//                                }
//                                .padding(.vertical, 6)
//                                .padding(.horizontal, 12)
//                                .background(
//                                    Capsule()
//                                        .fill(genre.themeColor.opacity(0.15))
//                                )
//                                .foregroundColor(genre.themeColor)
//                            }
//                        }
//                    }
//                }
//            }
//            
//            Divider()
//                .padding(.vertical, 8)
//            
//            // Available genres with sections
//            if showAllGenres {
//                List {
//                    // Fiction section
//                    if !searchText.isEmpty || BookGenre.fictionGenres.contains(where: { filteredGenres.contains($0) }) {
//                        Section(header: Text("Fiction")) {
//                            ForEach(BookGenre.fictionGenres.filter { filteredGenres.contains($0) }, id: \.self) { genre in
//                                genreRow(genre)
//                            }
//                        }
//                    }
//                    
//                    // Non-fiction section
//                    if !searchText.isEmpty || BookGenre.nonFictionGenres.contains(where: { filteredGenres.contains($0) }) {
//                        Section(header: Text("Non-Fiction")) {
//                            ForEach(BookGenre.nonFictionGenres.filter { filteredGenres.contains($0) }, id: \.self) { genre in
//                                genreRow(genre)
//                            }
//                        }
//                    }
//                }
//                .listStyle(InsetGroupedListStyle())
//                .frame(height: 300)
//                .cornerRadius(12)
//            }
//            
//            // Show more/less button
//            Button(action: {
//                withAnimation(.spring()) {
//                    showAllGenres.toggle()
//                }
//            }) {
//                HStack {
//                    Text(showAllGenres ? "Show Less" : "Show All Genres")
//                    Image(systemName: showAllGenres ? "chevron.up" : "chevron.down")
//                }
//                .font(.system(size: 14, weight: .medium))
//                .foregroundColor(.blue)
//                .padding(.vertical, 8)
//                .frame(maxWidth: .infinity)
//                .background(Color.blue.opacity(0.1))
//                .cornerRadius(10)
//            }
//        }
//        .padding(16)
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(colorScheme == .dark ? Color.black.opacity(0.3) : Color.white)
//                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
//        )
//    }
//    
//    @ViewBuilder
//    private func genreRow(_ genre: BookGenre) -> some View {
//        HStack {
//            Image(systemName: genre.iconName)
//                .foregroundColor(genre.themeColor)
//                .frame(width: 24)
//            
//            Text(genre.displayName)
//                .foregroundColor(Color.text(for: colorScheme))
//            
//            Spacer()
//            
//            if selectedGenres.contains(genre) {
//                Image(systemName: "checkmark.circle.fill")
//                    .foregroundColor(.blue)
//                    .transition(.scale.combined(with: .opacity))
//            }
//        }
//        .contentShape(Rectangle())
//        .onTapGesture {
//            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
//                if selectedGenres.contains(genre) {
//                    selectedGenres.remove(genre)
//                } else if selectedGenres.count < maxSelections {
//                    selectedGenres.insert(genre)
//                    hapticFeedback()
//                } else {
//                    // Optionally provide feedback that max selections reached
//                    notificationFeedback(.warning)
//                }
//            }
//        }
//    }
//    
//    private func hapticFeedback() {
//        let generator = UIImpactFeedbackGenerator(style: .light)
//        generator.impactOccurred()
//    }
//    
//    private func notificationFeedback(_ type: UINotificationFeedbackGenerator.FeedbackType) {
//        let generator = UINotificationFeedbackGenerator()
//        generator.notificationOccurred(type)
//    }
//}
//
//// MARK: - Preview
//struct GenreSelectorView_Previews: PreviewProvider {
//    static var previews: some View {
//        ScrollView {
//            VStack {
//                GenreSelectorView(
//                    selectedGenres: .constant([.fantasy, .scienceFiction]),
//                    maxSelections: 5
//                )
//                .padding()
//            }
//        }
//        .previewLayout(.sizeThatFits)
//    }
//}
