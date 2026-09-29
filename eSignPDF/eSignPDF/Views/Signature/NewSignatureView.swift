//
//  NewSignatureView.swift
//  eSignPDF
//

import PencilKit
import SwiftData
import SwiftUI
import UIKit
import AdsManagerKit

struct NewSignatureView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm = SignatureViewModel()
    @State private var drawing = PKDrawing()
    @State private var name = "My signature"
    @State private var signatureColor: Color = .black
    @State private var signatureUIColor: UIColor = .black
    @State private var bannerIsLoaded = false
    @State private var bannerHeight: CGFloat = 0

    private let colorPresets: [(color: Color, ui: UIColor)] = [
        (.black, .black),
        (.blue, .systemBlue),
        (.purple, .systemPurple),
        (.red, .systemRed),
        (.green, .systemGreen),
    ]

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(white: 0.97))
                    SignatureCanvasView(
                        drawing: $drawing,
                        inkColor: signatureUIColor
                    )
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .frame(maxWidth: .infinity)
                .frame(height: min(UIScreen.main.bounds.height * 0.56, 520))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.secondary.opacity(0.25), lineWidth: 1)
                }

                signatureColorPicker

                TextField("Signature name", text: $name)
                    .textFieldStyle(.roundedBorder)

                HStack(spacing: 12) {
                    Button("Clear") {
                        drawing = PKDrawing()
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))

                    Spacer()
                }
            }
            .padding(20)
        }
        .safeAreaInset(edge: .bottom) {
            BannerAdView(
                adType: .ADAPTIVE,
                isLoaded: $bannerIsLoaded,
                height: $bannerHeight
            )
            .frame(height: bannerHeight)
        }
        .navigationTitle("New signature")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(colorScheme == .dark ? Color.black.opacity(0.92) : Color(uiColor: .systemBackground), for: .navigationBar)
        .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
        .tint(.primary)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") { save() }
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
        }
        .onAppear { vm.attach(context: modelContext) }
        .onChange(of: signatureColor) { _, newValue in
            signatureUIColor = resolvedInkColor(from: newValue)
        }
    }

    private var signatureColorPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Signature color")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                Spacer()
                ColorPicker("", selection: $signatureColor, supportsOpacity: false)
                    .labelsHidden()
            }

            HStack(spacing: 10) {
                ForEach(Array(colorPresets.enumerated()), id: \.offset) { _, preset in
                    Button {
                        signatureColor = preset.color
                        signatureUIColor = preset.ui.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
                    } label: {
                        Circle()
                            .fill(preset.color)
                            .frame(width: 26, height: 26)
                            .overlay {
                                Circle()
                                    .stroke(
                                        preset.color == signatureColor ? Color.primary : Color.clear,
                                        lineWidth: 2
                                    )
                             }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func save() {
        let bounds = drawing.bounds.insetBy(dx: -12, dy: -12)
        guard bounds.width > 1, bounds.height > 1 else { return }
        let raw = drawing.image(from: bounds, scale: UIScreen.main.scale)
        let image = normalizedSignatureImage(from: raw, inkColor: signatureUIColor)
        vm.saveDrawing(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Signature" : name,
            image: image
        )
        AdsManager.shared.showInterstitialIfAvailable()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            dismiss()
        }
    }

    private func resolvedInkColor(from color: Color) -> UIColor {
        UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    }

    private func normalizedSignatureImage(from source: UIImage, inkColor: UIColor) -> UIImage {
        let fixed = inkColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = source.scale
        let renderer = UIGraphicsImageRenderer(size: source.size, format: format)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: source.size)
            source.draw(in: rect)
            ctx.cgContext.setBlendMode(.sourceIn)
            fixed.setFill()
            ctx.cgContext.fill(rect)
        }
    }
}
