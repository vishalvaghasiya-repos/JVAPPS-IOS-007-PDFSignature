//
//  GradientBackground.swift
//  PDFSignature
//

import SwiftUI

struct GradientBackground: View {
    var style: Style = .app

    enum Style {
        case app
        case premium
    }

    var body: some View {
        Group {
            switch style {
            case .app:
                Theme.primaryGradient
                    .ignoresSafeArea()
            case .premium:
                Theme.premiumBackground
                    .ignoresSafeArea()
            }
        }
    }
}
