//
//  ReusableBackground.swift
//  lms
//
//  Created by Diptayan Jash on 18/04/25.
//

import Foundation
import SwiftUI

struct ReusableBackground: View {
    @ObservedObject var themeManager = ThemeManager.shared
    let colorScheme: ColorScheme

    var body: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color.background(for: colorScheme).opacity(0.3),
                Color.background(for: colorScheme).opacity(0.1)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
