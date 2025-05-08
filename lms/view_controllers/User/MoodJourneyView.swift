import SwiftUI

struct MoodJourneyFeatureView: View {
    let primaryMoods: [MoodChoice]
    @Binding var currentStep: Int
    @Binding var isLoading: Bool
    @Binding var showErrorAlert: Bool
    @Binding var errorMessage: String
    let colorScheme: ColorScheme

    // Internal state for the journey
    @State private var primaryMood: MoodChoice?
    @State private var subChoice: MoodChoice?
    @State private var subChoices: [MoodChoice] = []
    @State private var bookSuggestions: [BookSuggestion] = []

    var body: some View {
        ZStack {
            // Content layer
            ScrollView {
                VStack(spacing: 0) {
                    // Main content container
                    contentContainer
                        .padding(.horizontal)
                        .padding(.top, 24)
                        .padding(.bottom, 40)
                }
                .animation(.easeInOut, value: currentStep)
            }

            // Navigation controls (floating at bottom)
            if currentStep > 0 && currentStep <= 3 && !isLoading {
                VStack {
                    Spacer()
                    navigationControls
                        .padding()
                }
            }
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - Content Container

    private var contentContainer: some View {
        Group {
            if isLoading {
                loadingView
            } else {
                switch currentStep {
                case 1: mainMoodSelectionView
                case 2: subMoodSelectionView
                case 3: bookSuggestionsView
                default:
                    welcomeView
                }
            }
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .move(edge: .trailing)),
            removal: .opacity.combined(with: .move(edge: .leading))
        )
        )
    }

    // MARK: - Navigation Controls

    private var navigationControls: some View {
        HStack {
            if currentStep > 1 {
                Button(action: goBack) {
                    HStack {
                        Image(systemName: "arrow.left")
                        Text("Back")
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.primary(for: colorScheme).opacity(0.5))
                    .foregroundColor(Color.text(for: colorScheme))
                    .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle())
                .transition(.scale)
            }

            Spacer()

            if currentStep < 3 && (currentStep == 1 || (currentStep == 2 && !subChoices.isEmpty)) {
                Button(action: {
                    if currentStep == 1 && primaryMood != nil {
                        fetchSubChoices(for: primaryMood!)
                    } else if currentStep == 2 && subChoice != nil {
                        fetchBookSuggestions()
                    }
                }) {
                    HStack {
                        Text(currentStep == 1 ? "Continue" : "Get Recommendations")
                        Image(systemName: "arrow.right")
                    }
                    .font(.subheadline.weight(.medium))
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.primary(for: colorScheme).opacity(0.5))
                    .foregroundColor(Color.text(for: colorScheme))
                    .cornerRadius(20)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled((currentStep == 1 && primaryMood == nil) || (currentStep == 2 && subChoice == nil))
                .opacity((currentStep == 1 && primaryMood == nil) || (currentStep == 2 && subChoice == nil) ? 0.5 : 1)
            }
        }
        .padding(.horizontal, 8)
        .animation(.easeInOut, value: currentStep)
    }

    // MARK: - Step Views

    private var welcomeView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed.fill")
                .font(.system(size: 50))
                .foregroundColor(Color.accent(for: colorScheme))
                .padding(.top, 40)

            Text("Mood Reading Journey")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(Color.text(for: colorScheme))
                .multilineTextAlignment(.center)

            Text("Discover books that match exactly how you want to feel")
                .font(.subheadline)
                .foregroundColor(Color.secondary(for: colorScheme))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Button("Begin") {
                withAnimation { currentStep = 1 }
            }
            .buttonStyle(PrimaryButtonStyle(colorScheme: colorScheme))
            .padding(.top, 20)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 400)
    }

    private var loadingView: some View {
        VStack(spacing: 20) {
            Spacer()

            ProgressView()
                .scaleEffect(1.5)
                .progressViewStyle(CircularProgressViewStyle(tint: Color.accent(for: colorScheme)))
                .padding()

            Text("Finding perfect books for you...")
                .font(.subheadline)
                .foregroundColor(Color.secondary(for: colorScheme))

            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 300)
        .padding()
    }

    private var mainMoodSelectionView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("How do you want to feel?")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.text(for: colorScheme))

                Text("Select your primary mood")
                    .font(.subheadline)
                    .foregroundColor(Color.secondary(for: colorScheme))
            }

            moodGrid(moods: primaryMoods) { mood in
                self.primaryMood = mood
            }
        }
    }

    private var subMoodSelectionView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("More specifically...")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.text(for: colorScheme))

                if let primaryMood = primaryMood {
                    Text("What kind of \(primaryMood.name.lowercased()) are you looking for?")
                        .font(.subheadline)
                        .foregroundColor(Color.secondary(for: colorScheme))
                }
            }

            if subChoices.isEmpty && isLoading {
                HStack {
                    Spacer()
                    ProgressView().padding(.vertical, 40)
                    Spacer()
                }
            } else if subChoices.isEmpty && !isLoading {
                VStack {
                    Text("No subcategories found for \(primaryMood?.name ?? "this mood").")
                        .foregroundColor(Color.secondary(for: colorScheme))
                        .padding()

                    Button("Try Different Mood") {
                        withAnimation { currentStep = 1 }
                    }
                    .buttonStyle(SecondaryButtonStyle(colorScheme: colorScheme))
                }
            } else {
                moodGrid(moods: subChoices) { mood in
                    self.subChoice = mood
                }
            }
        }
    }

    private var bookSuggestionsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Recommended For You")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(Color.text(for: colorScheme))

                if let primaryMood = primaryMood, let subChoice = subChoice {
                    Text("\(primaryMood.name) • \(subChoice.name)")
                        .font(.subheadline)
                        .foregroundColor(Color.secondary(for: colorScheme))
                }
            }

            if bookSuggestions.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "books.vertical.fill")
                        .font(.system(size: 40))
                        .foregroundColor(Color.secondary(for: colorScheme).opacity(0.7))
                        .padding(.top, 20)

                    Text("No books found for this combination")
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.secondary(for: colorScheme))

                    Button("Try Different Mood") { resetJourney() }
                        .buttonStyle(PrimaryButtonStyle(colorScheme: colorScheme))
                        .padding(.top)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(bookSuggestions) { suggestion in
                        bookCard(for: suggestion)
                    }
                }
            }
        }
    }

    // MARK: - Helper Views

    private func moodGrid(moods: [MoodChoice], action: @escaping (MoodChoice) -> Void) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10),
            ],
            spacing: 10
        ) {
            ForEach(moods) { mood in
                MoodCardView(
                    mood: mood,
                    isSelected: (currentStep == 1 && mood == primaryMood) || (currentStep == 2 && mood == subChoice),
                    colorScheme: colorScheme,
                    action: { action(mood) }
                )
            }
        }
    }

    private func bookCard(for suggestion: BookSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                // Book image
                Image(systemName: "book.closed.fill")
                    .font(.system(size: 28))
                    .foregroundColor(Color.accent(for: colorScheme))
                    .frame(width: 45, height: 60)
                    .background(Color.secondary(for: colorScheme).opacity(0.1))
                    .cornerRadius(6)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(suggestion.title)
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(Color.text(for: colorScheme))
                        .lineLimit(2)
                    
                    Text(suggestion.author!)
                        .font(.footnote)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.secondary(for: colorScheme))
                        .lineLimit(1)

                    Text(suggestion.reason)
                        .font(.footnote)
                        .foregroundColor(Color.text(for: colorScheme))
                        .lineLimit(8)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(12)
        .background(Color.accent(for: colorScheme).opacity(0.35))
        .cornerRadius(12)
    }

    // MARK: - Actions

    private func resetJourney() {
        withAnimation {
            currentStep = 1
            primaryMood = nil
            subChoice = nil
            subChoices = []
            bookSuggestions = []
        }
    }

    private func goBack() {
        withAnimation {
            if currentStep > 1 {
                currentStep -= 1
                if currentStep == 1 {
                    subChoice = nil
                    subChoices = []
                    bookSuggestions = []
                } else if currentStep == 2 {
                    bookSuggestions = []
                }
            }
        }
    }

    // MARK: - API Calls

    private func fetchSubChoices(for mood: MoodChoice) {
        isLoading = true
        Task {
            do {
                let choices = try await FolioService.shared.generateSubChoices(for: mood.name)
                await MainActor.run {
                    isLoading = false
                    subChoices = choices
                    if !choices.isEmpty {
                        withAnimation { currentStep = 2 }
                    } else {
                        errorMessage = "No further options found for \(mood.name)."
                        showErrorAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to get mood options: \(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
        }
    }

    private func fetchBookSuggestions() {
        guard let primaryMood = primaryMood, let subChoice = subChoice else {
            errorMessage = "Please select mood options first"
            showErrorAlert = true
            return
        }

        isLoading = true
        Task {
            do {
                let suggestions = try await FolioService.shared.generateBookSuggestions(
                    primaryMood: primaryMood.name, subChoice: subChoice.name)
                await MainActor.run {
                    isLoading = false
                    bookSuggestions = suggestions
                    withAnimation { currentStep = 3 }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to get book suggestions: \(error.localizedDescription)"
                    showErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct MoodCardView: View {
    let mood: MoodChoice
    var isSelected: Bool = false
    let colorScheme: ColorScheme
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: mood.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(isSelected ? .white : Color.primary(for: colorScheme))
                    .frame(height: 28)

                Text(mood.name)
                    .font(.footnote.weight(.medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(isSelected ? .white : Color.text(for: colorScheme))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 100)
            .padding(12)
            .background(
                isSelected ?
                Color.primary(for: colorScheme).opacity(0.65) :
                    Color.primary(for: colorScheme).opacity(0.2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    let colorScheme: ColorScheme
    @Environment(\.isEnabled) private var isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.accent(for: colorScheme))
                    .opacity(isEnabled ? (configuration.isPressed ? 0.85 : 1) : 0.5)
            )
            .foregroundColor(.white)
            .font(.subheadline.weight(.medium))
            .scaleEffect(isEnabled && configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    let colorScheme: ColorScheme
    @Environment(\.isEnabled) private var isEnabled: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 24)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.accent(for: colorScheme), lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.background(for: colorScheme))
                    )
            )
            .foregroundColor(Color.accent(for: colorScheme))
            .font(.subheadline.weight(.medium))
            .scaleEffect(isEnabled && configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}
