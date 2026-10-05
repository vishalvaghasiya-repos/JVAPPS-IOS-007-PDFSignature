//
//  Theme.swift
//  PDFSignature
//

import SwiftUI
import UIKit

enum Theme {
    // MARK: - Core Theme Palette (Asset-backed for automatic Light/Dark support)
    static let primary = Color("Primary")
    static let primaryDark = Color("PrimaryDark")
    static let onPrimary = Color("OnPrimary")

    static let background = Color("Background")
    static let onBackground = Color("OnBackground")

    static let card = Color("Card")
    static let onCard = Color("OnCard")

    static let secondary = Color("Secondary")
    static let accent = Color("AccentColor")

    static let titleText = Color("TitleText")
    static let secondaryText = Color("SecondaryText")
    static let placeholder = Color("Placeholder")

    static let border = Color("Border")
    static let divider = Color("Divider")

    static let success = Color("Success")
    static let warning = Color("Warning")
    static let error = Color("Error")

    // MARK: - Backward Compatible Aliases
    static let button = Color("Button")
    static let primaryText = Color("PrimaryText")
    static let lightBackground = Color("LightBackground")
    static let pdfRed = Color("PDFRed")

    // MARK: - Special & Surface Accents
    static let glassStroke = Color("Border")
    static let glassFill = Color("Card")
    static let cardShadow = Color.black.opacity(0.08)

    // MARK: - Premium Accent Colors
    static let premiumPurple = Color(red: 0.55, green: 0.32, blue: 0.98)
    static let premiumPink = Color(red: 0.98, green: 0.35, blue: 0.55)
    static let premiumCyan = Color("AccentColor")

    // MARK: - Typography
    static let titleFont = Font.system(.largeTitle, design: .rounded).weight(.bold)
    static let headlineFont = Font.system(.title2, design: .rounded).weight(.semibold)
    static let bodyFont = Font.system(.body, design: .rounded)
    static let captionFont = Font.system(.caption, design: .rounded)

    // MARK: - Gradients
    static var primaryGradient: LinearGradient {
        LinearGradient(
            colors: [
                background,
                background
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var brandGradient: LinearGradient {
        LinearGradient(
            colors: [primary, primaryDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var buttonGradient: LinearGradient {
        LinearGradient(
            colors: [primary, primaryDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var premiumBackground: LinearGradient {
        LinearGradient(
            colors: [
                background,
                secondary
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    static var premiumAccentGradient: LinearGradient {
        LinearGradient(
            colors: [primary, accent, primaryDark],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Hex Initializer Extensions
extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255.0,
            green: Double((hex >> 8) & 0xff) / 255.0,
            blue: Double(hex & 0xff) / 255.0,
            opacity: alpha
        )
    }
}

extension UIColor {
    convenience init(hex: UInt, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((hex >> 16) & 0xff) / 255.0,
            green: CGFloat((hex >> 8) & 0xff) / 255.0,
            blue: CGFloat(hex & 0xff) / 255.0,
            alpha: alpha
        )
    }

    static func dynamic(light: UInt, dark: UInt) -> UIColor {
        UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light)
        }
    }
}

// MARK: - SwiftUI Color Extensions
extension Color {
    static let appPrimary = Theme.primary
    static let appPrimaryDark = Theme.primaryDark
    static let appOnPrimary = Theme.onPrimary
    static let appBackground = Theme.background
    static let appOnBackground = Theme.onBackground
    static let appCard = Theme.card
    static let appOnCard = Theme.onCard
    static let appSecondary = Theme.secondary
    static let appAccent = Theme.accent
    static let appTitleText = Theme.titleText
    static let appSecondaryText = Theme.secondaryText
    static let appPlaceholder = Theme.placeholder
    static let appBorder = Theme.border
    static let appDivider = Theme.divider
    static let appSuccess = Theme.success
    static let appWarning = Theme.warning
    static let appError = Theme.error
    static let appButton = Theme.button
    static let appPrimaryText = Theme.primaryText
    static let appLightBackground = Theme.lightBackground
    static let appPDFRed = Theme.pdfRed
}

// MARK: - UIKit UIColor Extensions
extension UIColor {
    static let appPrimary = UIColor(named: "Primary") ?? UIColor.dynamic(light: 0xED772C, dark: 0xFF8A4C)
    static let appPrimaryDark = UIColor(named: "PrimaryDark") ?? UIColor.dynamic(light: 0xFF5E00, dark: 0xFF6B1A)
    static let appOnPrimary = UIColor(named: "OnPrimary") ?? UIColor(hex: 0xFFFFFF)
    static let appBackground = UIColor(named: "Background") ?? UIColor.dynamic(light: 0xFFFFFF, dark: 0x121212)
    static let appOnBackground = UIColor(named: "OnBackground") ?? UIColor.dynamic(light: 0x171717, dark: 0xF5F5F5)
    static let appCard = UIColor(named: "Card") ?? UIColor.dynamic(light: 0xFFFFFF, dark: 0x1C1C1E)
    static let appOnCard = UIColor(named: "OnCard") ?? UIColor.dynamic(light: 0x171717, dark: 0xF5F5F5)
    static let appSecondary = UIColor(named: "Secondary") ?? UIColor.dynamic(light: 0xFFF0E7, dark: 0x3A2418)
    static let appAccent = UIColor(named: "AccentColor") ?? UIColor.dynamic(light: 0xFF8A3D, dark: 0xFF9A5C)
    static let appTitleText = UIColor(named: "TitleText") ?? UIColor.dynamic(light: 0x171717, dark: 0xF5F5F5)
    static let appPrimaryText = UIColor(named: "PrimaryText") ?? UIColor.dynamic(light: 0x171717, dark: 0xF5F5F5)
    static let appSecondaryText = UIColor(named: "SecondaryText") ?? UIColor.dynamic(light: 0x666666, dark: 0xB3B3B3)
    static let appPlaceholder = UIColor(named: "Placeholder") ?? UIColor.dynamic(light: 0x999999, dark: 0x8E8E93)
    static let appBorder = UIColor(named: "Border") ?? UIColor.dynamic(light: 0xE5E5E5, dark: 0x38383A)
    static let appDivider = UIColor(named: "Divider") ?? UIColor.dynamic(light: 0xEEEEEE, dark: 0x2C2C2E)
    static let appSuccess = UIColor(named: "Success") ?? UIColor.dynamic(light: 0x22A06B, dark: 0x4ADE80)
    static let appWarning = UIColor(named: "Warning") ?? UIColor.dynamic(light: 0xF59E0B, dark: 0xFBBF24)
    static let appError = UIColor(named: "Error") ?? UIColor.dynamic(light: 0xD64545, dark: 0xFF6B6B)
    static let appButton = UIColor(named: "Button") ?? UIColor.dynamic(light: 0xFF5E00, dark: 0xFF6B1A)
    static let appLightBackground = UIColor(named: "LightBackground") ?? UIColor.dynamic(light: 0xFFF0E7, dark: 0x242426)
    static let appPDFRed = UIColor(named: "PDFRed") ?? UIColor.dynamic(light: 0xD64545, dark: 0xFF6B6B)
}
