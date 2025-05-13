//
//  GeminiView.swift
//  lms
//
//  Created by Diptayan Jash on 09/05/25.
//

import Foundation
import SwiftUI

enum AppFeature {
    case moodJourney, bookChat
}

struct FolioView: View {
    @State private var selectedFeature: AppFeature = .moodJourney
    @ObservedObject var themeManager = ThemeManager.shared


    // Shared error handling state
    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    // State for Mood Journey's toolbar (Back button visibility)
    // These will be bound to MoodJourneyFeatureView
    @State private var journeyCurrentStep = 1
    @State private var journeyIsLoading = false


    @Environment(\.colorScheme) private var colorScheme

    let primaryMoods: [MoodChoice] = [ // Passed to MoodJourneyFeatureView
        MoodChoice(name: "Uplifting", icon: "sun.max.fill"),
        MoodChoice(name: "Intriguing", icon: "puzzlepiece.fill"),
        MoodChoice(name: "Relaxing", icon: "leaf.fill"),
        MoodChoice(name: "Exciting", icon: "sparkles"),
        MoodChoice(name: "Thoughtful", icon: "brain.head.profile"),
        MoodChoice(name: "Dramatic", icon: "theatermasks.fill"),
       
    ]

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                Picker("Feature", selection: $selectedFeature) {
                    Text("Mood Journey").tag(AppFeature.moodJourney)
                    Text("Book Chat").tag(AppFeature.bookChat)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 15)

                // Switch between feature views
                Group {
                    if selectedFeature == .moodJourney {
                        MoodJourneyFeatureView(
                            primaryMoods: primaryMoods,
                            currentStep: $journeyCurrentStep,
                            isLoading: $journeyIsLoading,
                            showErrorAlert: $showErrorAlert,
                            errorMessage: $errorMessage,
                            colorScheme: colorScheme
                        )
                    } else {
                        BookChatFeatureView(
                            showErrorAlert: $showErrorAlert,
                            errorMessage: $errorMessage,
                            colorScheme: colorScheme
                        )
                    }
                }
                Spacer() // Pushes content up if it's not filling the screen
            }
            .background(ReusableBackground(colorScheme: colorScheme)) // Apply background to the VStack
            .navigationTitle(selectedFeature == .bookChat ? "Folio" : "Folio")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // Toolbar for Mood Journey's back button
                if selectedFeature == .moodJourney && journeyCurrentStep > 1 && !journeyIsLoading {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            // This action needs to be handled by MoodJourneyFeatureView
                            // We can use a Notification, a shared ObservableObject, or pass a closure
                            // For simplicity here, we'll assume MoodJourneyFeatureView handles its own back logic
                            // and this button would trigger that logic via a binding or callback.
                            // The `goBack` action will be internal to MoodJourneyFeatureView.
                            // This toolbar item's *display* is controlled here, but action is internal to child.
                            // A better way is for MoodJourneyFeatureView to expose a `canGoBack` and `goBackAction`.
                            // For now, we'll let MoodJourneyFeatureView manage its own back button if it needs to.
                            // OR, MoodJourneyFeatureView could use .toolbar modifier itself.
                            // Given current structure, this toolbar item is better placed inside MoodJourneyFeatureView itself using its local state.
                            // Let's remove this toolbar item from here and let MoodJourneyFeatureView handle its own.
                        }) {
                            // Content removed, will be handled by MoodJourneyFeatureView
                        }
                    }
                }
            }
            .alert(isPresented: $showErrorAlert) {
                Alert(
                    title: Text("Oops!"),
                    message: Text(errorMessage),
                    dismissButton: .default(Text("Try Again"))
                )
            }
        }
        .animation(.easeInOut, value: selectedFeature)
    }
}

// MARK: - Preview for MainAppView
struct GeminiView_Previews: PreviewProvider {
    static var previews: some View {
        FolioView()
            .preferredColorScheme(.light)
        FolioView()
            .preferredColorScheme(.dark)
    }
}
