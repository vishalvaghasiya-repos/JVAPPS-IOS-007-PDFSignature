//
//  PDFSignaturePlacement.swift
//  eSignPDF
//

import CoreGraphics
import Foundation

/// Normalized rect on the page preview (origin top-left, 0...1).
struct PDFSignaturePlacement: Identifiable, Hashable {
    var id: UUID
    /// Saved signature used for this stamp (supports multiple different signatures on one PDF).
    var signatureID: UUID
    var pageIndex: Int
    var normalizedRect: CGRect
    var rotationDegrees: Double

    init(
        id: UUID = UUID(),
        signatureID: UUID,
        pageIndex: Int,
        normalizedRect: CGRect,
        rotationDegrees: Double = 0
    ) {
        self.id = id
        self.signatureID = signatureID
        self.pageIndex = pageIndex
        self.normalizedRect = normalizedRect
        self.rotationDegrees = rotationDegrees
    }
}
