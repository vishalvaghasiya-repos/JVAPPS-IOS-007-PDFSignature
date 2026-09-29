//
//  Theme.swift
//  eSignPDF
//

import SwiftUI

enum Theme {
    static let accent = Color("AccentColor")

    static let gradientTop = Color(uiColor: .systemBackground)
    static let gradientMid = Color(uiColor: .secondarySystemBackground)
    static let gradientBottom = Color(uiColor: .tertiarySystemBackground)

    static let premiumPurple = Color(red: 0.55, green: 0.32, blue: 0.98)
    static let premiumPink = Color(red: 0.98, green: 0.35, blue: 0.55)
    static let premiumCyan = Color(red: 0.25, green: 0.85, blue: 0.95)

    static let glassStroke = Color.white.opacity(0.35)
    static let glassFill = Color.white.opacity(0.12)

    static let cardShadow = Color.black.opacity(0.08)

    static let titleFont = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let headlineFont = Font.system(.title2, design: .rounded).weight(.semibold)
    static let bodyFont = Font.system(.body, design: .rounded)
    static let captionFont = Font.system(.caption, design: .rounded)

    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [gradientTop, gradientMid, gradientBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var primaryText: Color { Color(uiColor: .label) }
    static var secondaryText: Color { Color(uiColor: .secondaryLabel) }

    static var premiumBackground: LinearGradient {
        LinearGradient(
            colors: [
                Color.black,
                Color(red: 0.08, green: 0.06, blue: 0.14),
                Color(red: 0.12, green: 0.05, blue: 0.22),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var premiumAccentGradient: LinearGradient {
        LinearGradient(
            colors: [premiumPurple, premiumPink, premiumCyan.opacity(0.85)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
