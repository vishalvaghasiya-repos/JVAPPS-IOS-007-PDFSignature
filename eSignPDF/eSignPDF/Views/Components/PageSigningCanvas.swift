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

/// PDF page thumbnail with a draggable signature overlay. `normalizedRect` uses top-left origin, 0...1.
struct PageSigningCanvas: View {
    let thumbnail: UIImage
    @Binding var normalizedRect: CGRect
    let signature: UIImage?
    @Binding var rotationDegrees: Double
    /// Placements already confirmed via "Apply to page" for this page (drawn behind the live sticker).
    var committedStamps: [CommittedStampPreview] = []
    var onCancel: (() -> Void)?

    @State private var dragOffset: CGSize = .zero
    @State private var liveScale: CGFloat = 1
    @State private var liveRotation: Angle = .zero

    private let stickerBorder = RoundedRectangle(cornerRadius: 6, style: .continuous)

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack(alignment: .topLeading) {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size.width, height: size.height)
                    .clipped()

                ForEach(committedStamps) { stamp in
                    committedStampView(stamp: stamp, canvasSize: size)
                }

                if let signature {
                    liveSignatureOverlay(signature: signature, canvasSize: size)
                }
            }
        }
    }

    private func committedStampView(stamp: CommittedStampPreview, canvasSize: CGSize) -> some View {
        let w = max(36, stamp.normalizedRect.width * canvasSize.width)
        let h = max(24, stamp.normalizedRect.height * canvasSize.height)
        let x = stamp.normalizedRect.minX * canvasSize.width
        let y = stamp.normalizedRect.minY * canvasSize.height
        return Image(uiImage: stamp.image)
            .resizable()
            .scaledToFit()
            .frame(width: w, height: h)
            .opacity(0.92)
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
            .rotationEffect(.degrees(stamp.rotationDegrees))
            .overlay {
                stickerBorder
                    .stroke(Color.cyan.opacity(0.85), lineWidth: 2)
            }
            .position(x: x + w / 2, y: y + h / 2)
            .allowsHitTesting(false)
    }

    private func liveSignatureOverlay(signature: UIImage, canvasSize: CGSize) -> some View {
        let w = max(36, normalizedRect.width * canvasSize.width)
        let h = max(24, normalizedRect.height * canvasSize.height)
        let cx = normalizedRect.midX * canvasSize.width
        let cy = normalizedRect.midY * canvasSize.height

        return ZStack(alignment: .center) {
            Image(uiImage: signature)
                .resizable()
                .scaledToFit()
                .frame(width: w, height: h)
                .contentShape(Rectangle())
                .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 4)
                .rotationEffect(.degrees(rotationDegrees) + liveRotation)
                .scaleEffect(liveScale)
                .overlay {
                    PremiumSelectionBorder()
                        .rotationEffect(.degrees(rotationDegrees) + liveRotation)
                        .scaleEffect(liveScale)
                }
                .simultaneousGesture(dragGesture(canvasSize: canvasSize))
                .simultaneousGesture(magnificationGesture())
                .simultaneousGesture(rotationGesture())
        }
        .frame(width: w, height: h)
        .overlay(alignment: .topTrailing) {
            Button {
                onCancel?()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.72))
                        .frame(width: 22, height: 22)
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.3), radius: 2.5, x: 0, y: 1.5)
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .offset(x: 18, y: -18)
        }
        .position(x: cx, y: cy)
        .offset(dragOffset)
        .transaction { txn in
            txn.animation = nil
            txn.disablesAnimations = true
        }
    }

    private func dragGesture(canvasSize: CGSize) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                dragOffset = value.translation
            }
            .onEnded { value in
                let dx = value.translation.width / max(canvasSize.width, 1)
                let dy = value.translation.height / max(canvasSize.height, 1)
                var next = normalizedRect
                next.origin.x = clamp(next.origin.x + dx, min: 0, max: 1 - next.width)
                next.origin.y = clamp(next.origin.y + dy, min: 0, max: 1 - next.height)
                withAnimation(.interactiveSpring(response: 0.28, dampingFraction: 0.82, blendDuration: 0)) {
                    normalizedRect = next
                    dragOffset = .zero
                }
            }
    }

    private func magnificationGesture() -> some Gesture {
        MagnificationGesture()
            .onChanged { value in
                liveScale = value
            }
            .onEnded { value in
                let clamped = clamp(value, min: 0.5, max: 2.0)
                var next = normalizedRect
                next.size.width = clamp(next.width * clamped, min: 0.05, max: 0.9)
                next.size.height = clamp(next.height * clamped, min: 0.02, max: 0.6)
                next.origin.x = clamp(next.origin.x, min: 0, max: 1 - next.width)
                next.origin.y = clamp(next.origin.y, min: 0, max: 1 - next.height)
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    normalizedRect = next
                    liveScale = 1
                }
            }
    }

    private func rotationGesture() -> some Gesture {
        RotationGesture()
            .onChanged { value in
                liveRotation = value
            }
            .onEnded { value in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    rotationDegrees += value.degrees
                    liveRotation = .zero
                }
            }
    }

    private func clamp(_ v: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        Swift.min(Swift.max(v, min), max)
    }
}

struct PremiumSelectionBorder: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Theme.premiumPurple, Theme.premiumPink, Theme.premiumCyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.8
                )
                .shadow(color: Theme.premiumPurple.opacity(0.3), radius: 3, x: 0, y: 1.5)
            
            VStack {
                HStack {
                    handleDot
                    Spacer()
                    handleDot
                }
                Spacer()
                HStack {
                    handleDot
                    Spacer()
                    handleDot
                }
            }
            .padding(-4)
        }
    }
    
    private var handleDot: some View {
        Circle()
            .fill(Color.white)
            .frame(width: 8, height: 8)
            .overlay(
                Circle()
                    .stroke(Theme.premiumPurple, lineWidth: 1.5)
            )
            .shadow(color: .black.opacity(0.18), radius: 1, x: 0, y: 0.5)
    }
}
