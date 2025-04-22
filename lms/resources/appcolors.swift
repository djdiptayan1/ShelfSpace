//
//  appcolors.swift
//  lms
//
//  Created by Diptayan Jash on 17/04/25.
//

import Foundation
import SwiftUI

// MARK: - Color Extensions
extension Color {
    // Theme-aware colors
    static func text(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: ColorConstants.darkText) : Color(hex: ColorConstants.lightText)
    }
    
    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: ColorConstants.darkBackground1) : Color(hex: ColorConstants.lightBackground1)
    }
    
    static func TabbarBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: ColorConstants.darkBackground) : Color(hex: ColorConstants.lightBackground)
    }
    
    static func primary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: ColorConstants.darkPrimary) : Color(hex: ColorConstants.lightPrimary)
    }
    
    static func secondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: ColorConstants.darkSecondary) : Color(hex: ColorConstants.lightSecondary)
    }
    
    static func accent(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? Color(hex: ColorConstants.darkAccent) : Color(hex: ColorConstants.lightAccent)
    }
}

// MARK: - Color Initialization from Hex
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
