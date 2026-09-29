//
//  PrimaryButton.swift
//  eSignPDF
//

import SwiftUI

struct PrimaryButton: View {
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    var systemImage: String? = nil
    var style: Style = .filled
    var action: () -> Void

    enum Style {
        case filled
        case outline
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 17, weight: .semibold))
                }
                Text(title)
                    .font(.system(.headline, design: .rounded).weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
                .background {
                    if style == .filled {
                        Group {
                            if colorScheme == .light {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(filledFill)
                                    .shadow(color: filledShadowColor, radius: 8, x: 0, y: 4)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(filledStroke, lineWidth: 1)
                                    }
                            } else {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(filledFill)
                                    .shadow(color: filledShadowColor, radius: 4, x: 0, y: 2)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .stroke(filledStroke, lineWidth: 1)
                                    }
                            }
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(outlineStroke, lineWidth: 1.5)
                    }
                }
                .foregroundStyle(foregroundTint)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var filledFill: Color {
        Color(red: 0.35, green: 0.34, blue: 0.84)
    }

    private var filledStroke: Color {
        colorScheme == .light
            ? Color.black.opacity(0.08)
            : Color.white.opacity(0.12)
    }

    private var filledShadowColor: Color {
        Color(red: 0.35, green: 0.34, blue: 0.84).opacity(colorScheme == .light ? 0.3 : 0.45)
    }

    private var outlineStroke: Color {
        colorScheme == .light
            ? Color(red: 0.35, green: 0.34, blue: 0.84)
            : Color.white.opacity(0.7)
    }

    private var foregroundTint: Color {
        switch style {
        case .filled:
            return .white
        case .outline:
            return colorScheme == .light ? Color(red: 0.35, green: 0.34, blue: 0.84) : .white
        }
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
