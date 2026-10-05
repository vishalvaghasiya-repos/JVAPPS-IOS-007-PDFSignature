//
//  PageSigningCanvas.swift
//  PDFSignature
//

import SwiftUI
import UIKit

/// Locked stamps already placed on this page (shown under the live sticker).
struct CommittedStampPreview: Identifiable {
    let id: UUID
    let normalizedRect: CGRect
    let rotationDegrees: Double
    let isFlippedHorizontally: Bool
    let image: UIImage
}

/// PDF page canvas with plain simple document styling and smooth 1:1 draggable signature overlay.
/// `normalizedRect` uses top-left origin, normalized 0...1 relative to the actual page bounds.
struct PageSigningCanvas: View {
    let thumbnail: UIImage
    @Binding var normalizedRect: CGRect
    let signature: UIImage?
    @Binding var rotationDegrees: Double
    @Binding var isFlippedHorizontally: Bool
    /// Placements already confirmed via "Apply to page" for this page (drawn behind the live sticker).
    var committedStamps: [CommittedStampPreview] = []
    var onCancel: (() -> Void)?
    var onSelectStamp: ((UUID) -> Void)? = nil

    @State private var dragTranslation: CGSize = .zero
    @State private var resizeTranslation: CGSize = .zero
    @State private var pinchScale: CGFloat = 1.0

    var body: some View {
        GeometryReader { geo in
            let containerSize = geo.size
            let imageSize = thumbnail.size

            if containerSize.width > 10 && containerSize.height > 10 && imageSize.width > 0 && imageSize.height > 0 {
                let scale = min(containerSize.width / imageSize.width, containerSize.height / imageSize.height)
                let fittedW = max(imageSize.width * scale, 1)
                let fittedH = max(imageSize.height * scale, 1)

                ZStack {
                    // Clean white paper sheet with subtle document drop shadow
                    ZStack(alignment: .topLeading) {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .interpolation(.high)
                            .frame(width: fittedW, height: fittedH)
                            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))

                        // Committed stamps on this page
                        ForEach(committedStamps) { stamp in
                            committedStampView(stamp: stamp, pageWidth: fittedW, pageHeight: fittedH)
                        }

                        // Active signature sticker overlay with interactive move, resize handle, and pinch
                        if let signature {
                            liveSignatureOverlay(signature: signature, pageWidth: fittedW, pageHeight: fittedH)
                        }
                    }
                    .frame(width: fittedW, height: fittedH)
                    .coordinateSpace(name: "pageCanvas")
                    .background(
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.16), radius: 8, x: 0, y: 3)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .stroke(Color.black.opacity(0.10), lineWidth: 0.8)
                            .allowsHitTesting(false)
                    )
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

        return Button {
            HapticFeedback.light()
            onSelectStamp?(stamp.id)
        } label: {
            Image(uiImage: stamp.image)
                .resizable()
                .scaledToFit()
                .frame(width: w, height: h)
                .scaleEffect(x: stamp.isFlippedHorizontally ? -1 : 1, y: 1)
                .rotationEffect(.degrees(stamp.rotationDegrees))
                .opacity(0.95)
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(Theme.primary.opacity(0.6), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .offset(x: x, y: y)
    }

    // MARK: - Live Draggable & Resizable Signature Overlay
    private func liveSignatureOverlay(signature: UIImage, pageWidth: CGFloat, pageHeight: CGFloat) -> some View {
        let imgSize = signature.size
        let imageAspect = max(imgSize.width, 1) / max(imgSize.height, 1)
        let pageAspect = max(pageWidth, 1) / max(pageHeight, 1)

        let baseW = max(36, min(normalizedRect.width * pageWidth, pageWidth))
        let baseH = max(baseW / imageAspect, 16)

        let baseOriginX = normalizedRect.minX * pageWidth
        let baseOriginY = normalizedRect.minY * pageHeight

        var activeW = baseW
        var activeH = baseH
        var currentOriginX = baseOriginX
        var currentOriginY = baseOriginY

        if resizeTranslation != .zero {
            let diagonalDelta = (resizeTranslation.width + resizeTranslation.height * pageAspect) / 2
            activeW = min(max(baseW + diagonalDelta, 40), pageWidth * 0.95)
            activeH = activeW / imageAspect
            if currentOriginX + activeW > pageWidth {
                currentOriginX = max(0, pageWidth - activeW)
            }
            if currentOriginY + activeH > pageHeight {
                currentOriginY = max(0, pageHeight - activeH)
            }
        } else if pinchScale != 1.0 {
            activeW = min(max(baseW * pinchScale, 40), pageWidth * 0.95)
            activeH = activeW / imageAspect
            let baseCenterX = baseOriginX + baseW / 2
            let baseCenterY = baseOriginY + baseH / 2
            currentOriginX = min(max(baseCenterX - activeW / 2, 0), pageWidth - activeW)
            currentOriginY = min(max(baseCenterY - activeH / 2, 0), pageHeight - activeH)
        } else if dragTranslation != .zero {
            currentOriginX = min(max(baseOriginX + dragTranslation.width, 0), max(pageWidth - baseW, 0))
            currentOriginY = min(max(baseOriginY + dragTranslation.height, 0), max(pageHeight - baseH, 0))
        }

        return ZStack(alignment: .center) {
            // Signature image with smooth mirror flip & rotation
            Image(uiImage: signature)
                .resizable()
                .scaledToFit()
                .scaleEffect(x: isFlippedHorizontally ? -1 : 1, y: 1)
                .frame(width: activeW, height: activeH)
                .rotationEffect(.degrees(rotationDegrees))

            // Selection Bounding Box & Corner Guides
            SimpleSignatureBorder()
                .frame(width: activeW + 12, height: activeH + 12)
                .rotationEffect(.degrees(rotationDegrees))
                .allowsHitTesting(false)
        }
        .frame(width: activeW, height: activeH)
        .contentShape(Rectangle())
        // Smooth 1:1 drag gesture relative to the fixed page canvas
        .gesture(
            DragGesture(minimumDistance: 1, coordinateSpace: .named("pageCanvas"))
                .onChanged { value in
                    dragTranslation = value.translation
                }
                .onEnded { value in
                    let finalX = min(max(baseOriginX + value.translation.width, 0), max(pageWidth - baseW, 0))
                    let finalY = min(max(baseOriginY + value.translation.height, 0), max(pageHeight - baseH, 0))
                    normalizedRect.origin.x = finalX / pageWidth
                    normalizedRect.origin.y = finalY / pageHeight
                    dragTranslation = .zero
                    HapticFeedback.selection()
                }
        )
        .simultaneousGesture(
            MagnificationGesture()
                .onChanged { scale in
                    pinchScale = scale
                }
                .onEnded { scale in
                    let finalW = min(max(baseW * scale, 40), pageWidth * 0.95)
                    let finalH = finalW / imageAspect
                    let baseCenterX = baseOriginX + baseW / 2
                    let baseCenterY = baseOriginY + baseH / 2
                    let finalX = min(max(baseCenterX - finalW / 2, 0), pageWidth - finalW)
                    let finalY = min(max(baseCenterY - finalH / 2, 0), pageHeight - finalH)
                    normalizedRect = CGRect(
                        x: finalX / pageWidth,
                        y: finalY / pageHeight,
                        width: finalW / pageWidth,
                        height: finalH / pageHeight
                    )
                    pinchScale = 1.0
                    HapticFeedback.selection()
                }
        )
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
                        .overlay(Circle().stroke(Color.white.opacity(0.8), lineWidth: 1))
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)

                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .offset(x: 14, y: -14)
        }
        // Dedicated Interactive Resize Icon Handle at bottom-right
        .overlay(alignment: .bottomTrailing) {
            SignatureResizeHandle(isDragging: resizeTranslation != .zero)
                .offset(x: 14, y: 14)
                .gesture(
                    DragGesture(minimumDistance: 1, coordinateSpace: .named("pageCanvas"))
                        .onChanged { value in
                            resizeTranslation = value.translation
                        }
                        .onEnded { value in
                            let diagonalDelta = (value.translation.width + value.translation.height * pageAspect) / 2
                            var finalW = min(max(baseW + diagonalDelta, 40), pageWidth * 0.95)
                            var finalH = finalW / imageAspect
                            var finalOriginX = baseOriginX
                            var finalOriginY = baseOriginY

                            if finalOriginX + finalW > pageWidth {
                                finalOriginX = max(0, pageWidth - finalW)
                            }
                            if finalOriginY + finalH > pageHeight {
                                finalOriginY = max(0, pageHeight - finalH)
                            }
                            if finalOriginX + finalW > pageWidth {
                                finalW = pageWidth - finalOriginX
                                finalH = finalW / imageAspect
                            }
                            if finalOriginY + finalH > pageHeight {
                                finalH = pageHeight - finalOriginY
                                finalW = finalH * imageAspect
                            }

                            normalizedRect = CGRect(
                                x: finalOriginX / pageWidth,
                                y: finalOriginY / pageHeight,
                                width: finalW / pageWidth,
                                height: finalH / pageHeight
                            )
                            resizeTranslation = .zero
                            HapticFeedback.selection()
                        }
                )
        }
        .offset(x: currentOriginX, y: currentOriginY)
    }
}

// MARK: - Interactive Resize Icon Handle (Clean Icon without solid box)
struct SignatureResizeHandle: View {
    var isDragging: Bool = false

    var body: some View {
        ZStack {
            Image(systemName: "arrow.up.left.and.arrow.down.right")
                .font(.system(size: 16, weight: .black))
                .foregroundStyle(Theme.primary)
                .shadow(color: Color.black.opacity(0.35), radius: 3, x: 0, y: 1)
                .scaleEffect(isDragging ? 1.3 : 1.0)
                .animation(.spring(response: 0.25), value: isDragging)
        }
        .frame(width: 44, height: 44)
        .contentShape(Rectangle())
    }
}

// MARK: - Plain Simple Selection Border
struct SimpleSignatureBorder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 6, style: .continuous)
            .strokeBorder(
                Theme.primary,
                style: StrokeStyle(lineWidth: 1.5, dash: [5, 3])
            )
            .shadow(color: Theme.primary.opacity(0.25), radius: 2, x: 0, y: 1)
    }
}
