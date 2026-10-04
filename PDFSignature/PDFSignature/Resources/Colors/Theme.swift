//
//  Theme.swift
//  PDFSignature
//

import SwiftUI
import UIKit

enum Theme {
    // MARK: - Asset-backed Theme Colors
    static let primary = Color("Primary")
    static let button = Color("Button")
    static let secondary = Color("Secondary")
    static let lightBackground = Color("LightBackground")
    static let background = Color("Background")
    static let card = Color("Card")
    static let primaryText = Color("PrimaryText")
    static let secondaryText = Color("SecondaryText")
    static let border = Color("Border")
    static let success = Color("Success")
    static let pdfRed = Color("PDFRed")

    // MARK: - Global Accent
    static let accent = Color("AccentColor")

    // MARK: - Special & Surface Accents
    static let glassStroke = Color("Border")
    static let glassFill = Color("Card")
    static let cardShadow = Color.black.opacity(0.06)

    // MARK: - Premium Accent Colors
    static let premiumPurple = Color(red: 0.55, green: 0.32, blue: 0.98)
    static let premiumPink = Color(red: 0.98, green: 0.35, blue: 0.55)
    static let premiumCyan = Color("Secondary")

    // MARK: - Typography
    static let titleFont = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let headlineFont = Font.system(.title2, design: .rounded).weight(.semibold)
    static let bodyFont = Font.system(.body, design: .rounded)
    static let captionFont = Font.system(.caption, design: .rounded)

    // MARK: - Gradients
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [lightBackground.opacity(0.65), background],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [primary, secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [button, primary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var premiumBackground: LinearGradient {
        LinearGradient(
            colors: [
                background,
                lightBackground,
                Color(red: 0.06, green: 0.11, blue: 0.12)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var premiumAccentGradient: LinearGradient {
        LinearGradient(
            colors: [primary, button, secondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - SwiftUI Color Extensions
extension Color {
    static let appPrimary = Theme.primary
    static let appButton = Theme.button
    static let appSecondary = Theme.secondary
    static let appLightBackground = Theme.lightBackground
    static let appBackground = Theme.background
    static let appCard = Theme.card
    static let appPrimaryText = Theme.primaryText
    static let appSecondaryText = Theme.secondaryText
    static let appBorder = Theme.border
    static let appSuccess = Theme.success
    static let appPDFRed = Theme.pdfRed
}

// MARK: - UIKit UIColor Extensions
extension UIColor {
    static let appPrimary = UIColor(named: "Primary") ?? UIColor(red: 0.031, green: 0.498, blue: 0.549, alpha: 1.0)
    static let appButton = UIColor(named: "Button") ?? UIColor(red: 0.039, green: 0.624, blue: 0.651, alpha: 1.0)
    static let appSecondary = UIColor(named: "Secondary") ?? UIColor(red: 0.078, green: 0.722, blue: 0.651, alpha: 1.0)
    static let appLightBackground = UIColor(named: "LightBackground") ?? UIColor(red: 0.910, green: 0.969, blue: 0.969, alpha: 1.0)
    static let appBackground = UIColor(named: "Background") ?? UIColor(red: 0.973, green: 0.980, blue: 0.980, alpha: 1.0)
    static let appCard = UIColor(named: "Card") ?? UIColor.white
    static let appPrimaryText = UIColor(named: "PrimaryText") ?? UIColor(red: 0.090, green: 0.145, blue: 0.165, alpha: 1.0)
    static let appSecondaryText = UIColor(named: "SecondaryText") ?? UIColor(red: 0.376, green: 0.455, blue: 0.478, alpha: 1.0)
    static let appBorder = UIColor(named: "Border") ?? UIColor(red: 0.851, green: 0.906, blue: 0.910, alpha: 1.0)
    static let appSuccess = UIColor(named: "Success") ?? UIColor(red: 0.133, green: 0.627, blue: 0.420, alpha: 1.0)
    static let appPDFRed = UIColor(named: "PDFRed") ?? UIColor(red: 0.937, green: 0.267, blue: 0.267, alpha: 1.0)
}
