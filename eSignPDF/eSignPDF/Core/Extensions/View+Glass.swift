//
//  View+Glass.swift
//  eSignPDF
//

import SwiftUI

struct GlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 20
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Theme.card)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Theme.border, lineWidth: 1)
                    }
                    .shadow(
                        color: colorScheme == .dark ? Color.black.opacity(0.35) : Theme.cardShadow,
                        radius: colorScheme == .dark ? 8 : 10,
                        x: 0,
                        y: colorScheme == .dark ? 3 : 4
                    )
            }
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassBackground(cornerRadius: cornerRadius))
    }
}
