//
//  EmptyStateView 2.swift
//  lms
//
//  Created by Diptayan Jash on 25/04/25.
//

import SwiftUI

struct EmptyStateView: View {
    let type: String // e.g., "Librarians" or "Members"
    let colorScheme: ColorScheme

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: type == "Librarians" ? "person.text.rectangle" : "person.2")
                .font(.system(size: 60))
                // Use primary color for librarian icon, accent for member? Or just one?
                .foregroundColor(Color.secondary) // Use system secondary color
                .opacity(0.7)
                .padding(.top, 60)

            Text("No Active \(type) Yet")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(Color.text(for: colorScheme)) // Use color helper

            Text("Tap the + button to add a new \(type.dropLast().lowercased()) or pull down to refresh.")
                .font(.subheadline)
                .foregroundColor(Color.text(for: colorScheme).opacity(0.7)) // Use color helper
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity) // Allow it to fill the space
    }
}
