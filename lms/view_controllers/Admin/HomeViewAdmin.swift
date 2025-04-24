//
//  HomeViewAdmin.swift
//  lms
//
//  Created by Diptayan Jash on 23/04/25.
//

import Foundation
import SwiftUI

struct HomeViewAdmin: View {
    @Environment(\.colorScheme) private var colorScheme
    var body: some View {
        NavigationView {
            ZStack{
                ReusableBackground(colorScheme: colorScheme)
                Text("Home Screen Admin")
                    .navigationTitle("Home")
            }
        }
    }
}
