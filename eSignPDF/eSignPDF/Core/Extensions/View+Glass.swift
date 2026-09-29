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
                    .fill(colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.04))
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(colorScheme == .dark ? Color.white.opacity(0.22) : Color.black.opacity(0.08), lineWidth: 1)
                    }
                    .shadow(color: Theme.cardShadow, radius: 12, x: 0, y: 6)
            }
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20) -> some View {
        modifier(GlassBackground(cornerRadius: cornerRadius))
    }
}
