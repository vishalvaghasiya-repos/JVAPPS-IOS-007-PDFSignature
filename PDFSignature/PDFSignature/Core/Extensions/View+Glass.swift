//
//  View+Glass.swift
//  PDFSignature
//

import SwiftUI

struct GlassBackground: ViewModifier {
    var cornerRadius: CGFloat = 12
    var hasShadow: Bool = false
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background {
                let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                if hasShadow {
                    shape
                        .fill(Theme.card)
                        .overlay {
                            shape.stroke(Theme.border, lineWidth: 1)
                        }
                        .shadow(
                            color: colorScheme == .dark ? Color.black.opacity(0.35) : Theme.cardShadow,
                            radius: colorScheme == .dark ? 8 : 10,
                            x: 0,
                            y: colorScheme == .dark ? 3 : 4
                        )
                } else {
                    shape
                        .fill(Theme.card)
                        .overlay {
                            shape.stroke(Theme.border, lineWidth: 1)
                        }
                }
            }
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 12, hasShadow: Bool = false) -> some View {
        modifier(GlassBackground(cornerRadius: cornerRadius, hasShadow: hasShadow))
    }
}
