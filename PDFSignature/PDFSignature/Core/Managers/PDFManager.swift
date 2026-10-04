//
//  PDFManager.swift
//  PDFSignature
//

import Foundation
import PDFKit
import UIKit

enum PDFManagerError: Error {
    case invalidDocument
    case invalidPage
    case writeFailed
}

enum PDFManager {
    static func loadDocument(at url: URL) -> PDFDocument? {
        PDFDocument(url: url)
    }

    static func pageCount(for document: PDFDocument) -> Int {
        document.pageCount
    }

    /// Applies each placement with its own signature image (multiple different signatures on one document).
    static func applyStampedSignatures(
        document: PDFDocument,
        stampedPlacements: [(placement: PDFSignaturePlacement, image: UIImage)]
    ) throws -> PDFDocument {
        let output: PDFDocument
        if let copy = document.copy() as? PDFDocument {
            output = copy
        } else if let data = document.dataRepresentation(), let fallback = PDFDocument(data: data) {
            output = fallback
        } else {
            throw PDFManagerError.invalidDocument
        }

        for item in stampedPlacements {
            let placement = item.placement
            let image = item.image
            guard let page = output.page(at: placement.pageIndex) else { continue }
            let bounds = page.bounds(for: .mediaBox)
            let n = placement.normalizedRect
            let pdfRect = CGRect(
                x: n.minX * bounds.width,
                y: (1 - n.maxY) * bounds.height,
                width: n.width * bounds.width,
                height: n.height * bounds.height
            )
            let annotation = SignaturePDFAnnotation(bounds: pdfRect, image: image, rotationDegrees: placement.rotationDegrees)
            page.addAnnotation(annotation)
        }

        return output
    }

    /// Applies one image at every placement (convenience for a single signature repeated).
    static func applySignature(
        document: PDFDocument,
        image: UIImage,
        placements: [PDFSignaturePlacement]
    ) throws -> PDFDocument {
        try applyStampedSignatures(
            document: document,
            stampedPlacements: placements.map { (placement: $0, image: image) }
        )
    }

    static func write(document: PDFDocument, to url: URL) throws {
        guard document.write(to: url) else {
            throw PDFManagerError.writeFailed
        }
    }

    static func renderPageThumbnail(document: PDFDocument, pageIndex: Int, maxWidth: CGFloat) -> UIImage? {
        guard let page = document.page(at: pageIndex) else { return nil }
        let pageRect = page.bounds(for: .mediaBox)
        let scale = maxWidth / pageRect.width
        let size = CGSize(width: maxWidth, height: pageRect.height * scale)
        return page.thumbnail(of: size, for: .mediaBox)
    }
}

private final class SignaturePDFAnnotation: PDFAnnotation {
    private let signatureImage: UIImage
    private let rotationDegrees: Double

    init(bounds: CGRect, image: UIImage, rotationDegrees: Double) {
        self.signatureImage = image
        self.rotationDegrees = rotationDegrees
        super.init(bounds: bounds, forType: .stamp, withProperties: nil)
    }

    required init?(coder: NSCoder) {
        nil
    }

    override func draw(with box: PDFDisplayBox, in context: CGContext) {
        context.saveGState()
        context.translateBy(x: bounds.midX, y: bounds.midY)
        context.rotate(by: CGFloat(rotationDegrees * .pi / 180))
        context.translateBy(x: -bounds.width / 2, y: -bounds.height / 2)
        if let cgImage = signatureImage.cgImage {
            context.draw(cgImage, in: CGRect(origin: .zero, size: bounds.size))
        } else {
            signatureImage.draw(in: CGRect(origin: .zero, size: bounds.size))
        }
        context.restoreGState()
    }
}
