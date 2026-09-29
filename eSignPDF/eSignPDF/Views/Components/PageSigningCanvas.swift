//
//  PageSigningCanvas.swift
//  eSignPDF
//

import SwiftUI
import UIKit

/// Locked stamps already placed on this page (shown under the live sticker).
struct CommittedStampPreview: Identifiable {
    let id: UUID
    let normalizedRect: CGRect
    let rotationDegrees: Double
    let image: UIImage
}

/// PDF page canvas with plain simple document styling and smooth 1:1 draggable signature overlay.
/// `normalizedRect` uses top-left origin, normalized 0...1 relative to the actual page bounds.
struct PageSigningCanvas: View {
    let thumbnail: UIImage
    @Binding var normalizedRect: CGRect
    let signature: UIImage?
    @Binding var rotationDegrees: Double
    /// Placements already confirmed via "Apply to page" for this page (drawn behind the live sticker).
    var committedStamps: [CommittedStampPreview] = []
    var onCancel: (() -> Void)?

    @GestureState private var dragTranslation: CGSize = .zero
    @State private var liveScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geo in
            let containerSize = geo.size
            let imageSize = thumbnail.size

            if containerSize.width > 10 && containerSize.height > 10 && imageSize.width > 0 && imageSize.height > 0 {
                let scale = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
                let fittedW = max(imageSize.width * scale, 1)
                let fittedH = max(imageSize.height * scale, 1)

                ZStack {
                    // Plain simple design: clean white paper sheet with subtle document drop shadow
                    ZStack(alignment: .topLeading) {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .interpolation(.high)
                            .frame(width: fittedW, height: fittedH)

                        // Committed stamps on this page
                        ForEach(committedStamps) { stamp in
                            committedStampView(stamp: stamp, pageWidth: fittedW, pageHeight: fittedH)
                        }

                        // Active signature sticker overlay
                        if let signature {
                            liveSignatureOverlay(signature: signature, pageWidth: fittedW, pageHeight: fittedH)
                        }
                    }
                    .frame(width: fittedW, height: fittedH)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .stroke(Color.black.opacity(0.10), lineWidth: 0.8)
                    )
                    .shadow(color: Color.black.opacity(0.16), radius: 8, x: 0, y: 3)
                }
                .frame(width: containerSize.width, height: containerSize.height, alignment: .center)
            }
        }
    }

    // MARK: - Committed Stamp
    private func committedStampView(stamp: CommittedStampPreview, pageWidth: CGFloat, pageHeight: CGFloat) -> some View {
        let w = max(24, stamp.normalizedRect.width * pageWidth)
        let h = max(16, stamp.normalizedRect.height * pageHeight)
        let x = stamp.normalizedRect.minX * pageWidth
        let y = stamp.normalizedRect.minY * pageHeight

        return Image(uiImage: stamp.image)
            .resizable()
            .scaledToFit()
            .frame(width: w, height: h)
            .opacity(0.95)
            .rotationEffect(.degrees(stamp.rotationDegrees))
            .overlay(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .stroke(Theme.button.opacity(0.6), lineWidth: 1)
            )
            .position(x: x + w / 2, y: y + h / 2)
            .allowsHitTesting(false)
    }

    // MARK: - Live Draggable Signature Overlay
    private func liveSignatureOverlay(signature: UIImage, pageWidth: CGFloat, pageHeight: CGFloat) -> some View {
        let w = max(32, min(normalizedRect.width * pageWidth, pageWidth))
        let h = max(18, min(normalizedRect.height * pageHeight, pageHeight))

        // Active drag origin with strict clamping to page bounds
        let baseOriginX = normalizedRect.minX * pageWidth
        let baseOriginY = normalizedRect.minY * pageHeight
        let activeOriginX = min(max(baseOriginX + dragTranslation.width, 0), max(pageWidth - w, 0))
        let activeOriginY = min(max(baseOriginY + dragTranslation.height, 0), max(pageHeight - h, 0))

        let centerX = activeOriginX + w / 2
        let centerY = activeOriginY + h / 2

        return ZStack(alignment: .center) {
            Image(uiImage: signature)
                .resizable()
                .scaledToFit()
                .frame(width: w, height: h)
                .rotationEffect(.degrees(rotationDegrees))
                .scaleEffect(liveScale)
                .contentShape(Rectangle())

            // Selection Bounding Box
            SimpleSignatureBorder()
                .frame(width: w + 8, height: h + 8)
                .rotationEffect(.degrees(rotationDegrees))
        }
        .frame(width: w, height: h)
        // Close / Cancel Button at top-right
        .overlay(alignment: .topTrailing) {
            Button {
                HapticFeedback.light()
                onCancel?()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.75))
                        .frame(width: 22, height: 22)
                        .overlay(Circle().stroke(Color.white.opacity(0.3), lineWidth: 1))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 36, height: 36)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .offset(x: 14, y: -14)
        }
        .position(x: centerX, y: centerY)
        // High priority smooth 1:1 dragging gesture
        .highPriorityGesture(
            DragGesture(minimumDistance: 1)
                .updating($dragTranslation) { value, state, _ in
                    state = value.translation
                }
                .onEnded { value in
                    let finalOriginX = min(max(baseOriginX + value.translation.width, 0), max(pageWidth - w, 0))
                    let finalOriginY = min(max(baseOriginY + value.translation.height, 0), max(pageHeight - h, 0))
                    normalizedRect.origin.x = finalOriginX / pageWidth
                    normalizedRect.origin.y = finalOriginY / pageHeight
                    HapticFeedback.selection()
                }
        )
    }
}

// MARK: - Plain Simple Selection Border
struct SimpleSignatureBorder: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(
                    Theme.button,
                    style: StrokeStyle(lineWidth: 1.5, dash: [5, 3])
                )
                .shadow(color: Theme.button.opacity(0.3), radius: 3, x: 0, y: 1)

            VStack {
                HStack {
                    cornerHandle
                    Spacer()
                    cornerHandle
                }
                Spacer()
                HStack {
                    cornerHandle
                    Spacer()
                    cornerHandle
                }
            }
            .padding(-4)
        }
    }

    private var cornerHandle: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(Theme.button, lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.2), radius: 1, x: 0, y: 0.5)
    }
}
