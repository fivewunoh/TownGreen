//
//  TownGreenTheme.swift
//  TownGreen
//
//  Created by Chris Solis on 2/21/26.
//

import SwiftUI

// MARK: - Color extension

extension Color {
    /// Rich forest green
    static let primaryGreen = Color(hex: "2D6A4F")
    /// Softer sage green
    static let lightGreen = Color(hex: "74C69D")
    /// Deep dark green
    static let darkGreen = Color(hex: "1B4332")
    /// Warm off-white (light mode background)
    static let backgroundLight = Color(hex: "F8F5F0")
    /// Dark earth tone (dark mode background)
    static let backgroundDark = Color(hex: "1A1A1A")
    /// Pure white (light mode cards)
    static let cardLight = Color.white
    /// Dark gray (dark mode cards)
    static let cardDark = Color(hex: "2C2C2C")

    /// Background color that adapts to color scheme
    static func townGreenBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? backgroundDark : backgroundLight
    }

    /// Card color that adapts to color scheme
    static func townGreenCard(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? cardDark : cardLight
    }

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
            (a, r, g, b) = (255, 0, 0, 0)
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

// MARK: - Font extension (TownGreenFonts)

extension Font {
    /// SF Pro–based typography for TownGreen (Apple system font).
    enum TownGreenFonts {
        /// Headers/titles: navigation titles, screen titles, listing titles
        static let title = Font.system(size: 24, weight: .bold, design: .rounded)
        /// Section headers
        static let sectionHeader = Font.system(size: 18, weight: .semibold, design: .rounded)
        /// Body text: descriptions, labels
        static let body = Font.system(size: 15, weight: .light, design: .default)
        /// Captions: category, location, small labels
        static let caption = Font.system(size: 13, weight: .light, design: .default)
        /// Price text
        static let price = Font.system(size: 20, weight: .bold, design: .rounded)
        /// Buttons
        static let button = Font.system(size: 16, weight: .semibold, design: .rounded)
    }
}
