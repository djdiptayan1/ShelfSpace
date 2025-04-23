//
//  BookViewAdmin.swift
//  lms
//
//  Created by Diptayan Jash on 23/04/25.
//

import Foundation
import SwiftUI

struct BookViewAdmin: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        NavigationView {
            ZStack {
                ReusableBackground(colorScheme: colorScheme)

                Text("Book Screen Admin")
            }
            .navigationTitle("Books")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Button(action: {
                        // Action for search
                        print("Search tapped")
                    }) {
                        Image(systemName: "magnifyingglass")
                    }

                    Button(action: {
                        // Action for add
                        print("Add tapped")
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}
