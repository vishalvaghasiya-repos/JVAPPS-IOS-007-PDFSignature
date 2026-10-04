//
//  SignatureCanvasView.swift
//  PDFSignature
//

import PencilKit
import SwiftUI

struct SignatureCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    var inkColor: UIColor = .black

    func makeUIView(context: Context) -> PKCanvasView {
        let canvas = FixedCanvasView()
        canvas.drawingPolicy = .anyInput
        canvas.overrideUserInterfaceStyle = .light
        canvas.alwaysBounceVertical = false
        canvas.alwaysBounceHorizontal = false
        canvas.bounces = false
        canvas.bouncesZoom = false
        canvas.minimumZoomScale = 1
        canvas.maximumZoomScale = 1
        canvas.isScrollEnabled = false
        canvas.backgroundColor = UIColor(white: 0.97, alpha: 1)
        canvas.isOpaque = true
        canvas.tool = makeTool()
        canvas.drawing = drawing
        canvas.delegate = context.coordinator
        return canvas
    }

    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        uiView.overrideUserInterfaceStyle = .light
        uiView.tool = makeTool()
        if uiView.drawing != drawing {
            uiView.drawing = drawing
        }
    }

    private func makeTool() -> PKInkingTool {
        let fixed = inkColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        return PKInkingTool(.pen, color: fixed, width: 4.5)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: SignatureCanvasView

        init(_ parent: SignatureCanvasView) {
            self.parent = parent
        }

        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            parent.drawing = canvasView.drawing
        }
    }
}

private final class FixedCanvasView: PKCanvasView {
    override func layoutSubviews() {
        super.layoutSubviews()
        contentInset = .zero
        contentSize = bounds.size
    }
}
