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
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Theme.button)
                        .shadow(
                            color: Theme.button.opacity(colorScheme == .light ? 0.32 : 0.45),
                            radius: colorScheme == .light ? 8 : 6,
                            x: 0,
                            y: colorScheme == .light ? 4 : 2
                        )
                        .overlay {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    colorScheme == .light
                                        ? Color.white.opacity(0.25)
                                        : Color.white.opacity(0.15),
                                    lineWidth: 1
                                )
                        }
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Theme.button, lineWidth: 1.5)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Theme.lightBackground.opacity(0.45))
                        )
                }
            }
            .foregroundStyle(foregroundTint)
        }
        .buttonStyle(ScaleButtonStyle())
    }

    private var foregroundTint: Color {
        switch style {
        case .filled:
            return .white
        case .outline:
            return Theme.button
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
