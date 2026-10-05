//
//  PDFPreviewViewModel.swift
//  PDFSignature
//

import Combine
import Foundation
import PDFKit
import SwiftData
import UIKit

@MainActor
final class PDFPreviewViewModel: ObservableObject {
    @Published var sourceURL: URL
    @Published var document: PDFDocument? {
        didSet {
            loadCurrentPageThumbnail()
        }
    }
    @Published var currentPageIndex: Int = 0 {
        didSet {
            loadCurrentPageThumbnail()
        }
    }
    @Published var currentPageThumbnail: UIImage?
    @Published var placements: [PDFSignaturePlacement] = []
    @Published var placementRotationByPage: [Int: Double] = [:]
    @Published var placementFlipByPage: [Int: Bool] = [:]
    @Published var selectedSignature: SignatureModel?
    @Published var signatureImage: UIImage?
    @Published var overlayNormalizedRect: CGRect = CGRect(x: 0.2, y: 0.65, width: 0.35, height: 0.12)
    @Published var isSaving = false
    @Published var lastSavedDocument: SignedDocumentModel?
    @Published var errorMessage: String?

    private var modelContext: ModelContext?

    init(url: URL) {
        sourceURL = url
        document = PDFManager.loadDocument(at: url)
        loadCurrentPageThumbnail()
    }

    func loadCurrentPageThumbnail() {
        guard let doc = document, pageCount > 0 else {
            currentPageThumbnail = nil
            return
        }
        let maxWidth = UIScreen.main.bounds.width - 40
        currentPageThumbnail = PDFManager.renderPageThumbnail(document: doc, pageIndex: currentPageIndex, maxWidth: maxWidth)
    }

    func attach(context: ModelContext) {
        modelContext = context
    }

    var pageCount: Int {
        document?.pageCount ?? 0
    }

    var currentPageAspectRatio: CGFloat {
        if let thumb = currentPageThumbnail, thumb.size.height > 0 {
            return thumb.size.width / thumb.size.height
        }
        if let page = document?.page(at: currentPageIndex) {
            let bounds = page.bounds(for: .mediaBox)
            if bounds.height > 0 {
                return bounds.width / bounds.height
            }
        }
        return 0.77
    }

    var signatureAspectRatio: CGFloat {
        guard let img = signatureImage, img.size.height > 0 else { return 2.5 }
        return img.size.width / img.size.height
    }

    func selectSignature(_ model: SignatureModel) {
        selectedSignature = model
        signatureImage = model.loadImage()
        normalizeOverlayToImageAspect()
    }

    func normalizeOverlayToImageAspect() {
        let baseW: CGFloat = 0.35
        let imgAspect = signatureAspectRatio
        let pageAspect = currentPageAspectRatio
        let targetH = min(max(baseW * pageAspect / imgAspect, 0.03), 0.55)
        let x = min(0.32, max(0, 1.0 - baseW))
        let y = min(0.65, max(0, 1.0 - targetH))
        overlayNormalizedRect = CGRect(x: x, y: y, width: baseW, height: targetH)
        placementRotationByPage[currentPageIndex] = 0
        placementFlipByPage[currentPageIndex] = false
    }

    func resetOverlayPosition() {
        if signatureImage != nil {
            normalizeOverlayToImageAspect()
        } else {
            overlayNormalizedRect = CGRect(x: 0.2, y: 0.65, width: 0.35, height: 0.12)
            placementRotationByPage[currentPageIndex] = 0
            placementFlipByPage[currentPageIndex] = false
        }
    }

    func selectCommittedStamp(id: UUID) {
        if selectedSignature != nil && signatureImage != nil {
            addPlacementFromOverlay()
        }
        guard let index = placements.firstIndex(where: { $0.id == id }) else { return }
        let placement = placements.remove(at: index)
        if let context = modelContext,
           let model = try? SignatureManager.signature(context: context, id: placement.signatureID) {
            selectedSignature = model
            signatureImage = model.loadImage()
            overlayNormalizedRect = placement.normalizedRect
            currentRotation = placement.rotationDegrees
            isFlippedHorizontally = placement.isFlippedHorizontally
            HapticFeedback.selection()
        }
    }

    func addPlacementFromOverlay() {
        guard let sig = selectedSignature, signatureImage != nil else { return }
        placements.append(
            PDFSignaturePlacement(
                signatureID: sig.id,
                pageIndex: currentPageIndex,
                normalizedRect: overlayNormalizedRect,
                rotationDegrees: currentRotation,
                isFlippedHorizontally: isFlippedHorizontally
            )
        )
        clearWorkingSignatureOnCurrentPage()
        HapticFeedback.light()
    }

    /// Previews locked stamps on the canvas for the current page (so multiple placements are visible before save).
    func committedStampPreviews(forPage pageIndex: Int) -> [CommittedStampPreview] {
        guard let context = modelContext else { return [] }
        return placements.compactMap { p in
            guard p.pageIndex == pageIndex,
                  let m = try? SignatureManager.signature(context: context, id: p.signatureID),
                  let img = m.loadImage()
            else { return nil }
            return CommittedStampPreview(
                id: p.id,
                normalizedRect: p.normalizedRect,
                rotationDegrees: p.rotationDegrees,
                isFlippedHorizontally: p.isFlippedHorizontally,
                image: img
            )
        }
    }

    /// Removes the most recently added placement (works across pages).
    func removeLastPlacement() {
        guard !placements.isEmpty else { return }
        placements.removeLast()
        HapticFeedback.light()
    }

    func removeLatestPlacementOnCurrentPage() {
        guard let index = placements.lastIndex(where: { $0.pageIndex == currentPageIndex }) else { return }
        placements.remove(at: index)
    }

    func clearWorkingSignatureOnCurrentPage() {
        resetOverlayPosition()
        selectedSignature = nil
        signatureImage = nil
    }

    var currentRotation: Double {
        get { placementRotationByPage[currentPageIndex] ?? 0 }
        set { placementRotationByPage[currentPageIndex] = newValue }
    }

    var isFlippedHorizontally: Bool {
        get { placementFlipByPage[currentPageIndex] ?? false }
        set { placementFlipByPage[currentPageIndex] = newValue }
    }

    func rotateSignatureClockwise() {
        currentRotation = (currentRotation + 90).truncatingRemainder(dividingBy: 360)
        HapticFeedback.selection()
    }

    func toggleFlipHorizontal() {
        isFlippedHorizontally.toggle()
        HapticFeedback.selection()
    }

    func goToPage(_ index: Int) {
        currentPageIndex = min(max(index, 0), max(pageCount - 1, 0))
        resetOverlayPosition()
    }

    func clearPlacements() {
        placements.removeAll()
    }

    /// Generates an in-memory PDF document with all current committed stamps and live overlay signature.
    func buildPreviewDocument() -> PDFDocument? {
        guard let document else { return nil }

        let baseDoc: PDFDocument
        if let docFromURL = PDFDocument(url: sourceURL) {
            baseDoc = docFromURL
        } else if let copy = document.copy() as? PDFDocument {
            baseDoc = copy
        } else if let data = document.dataRepresentation(), let docFromData = PDFDocument(data: data) {
            baseDoc = docFromData
        } else {
            baseDoc = document
        }

        var stamped: [(placement: PDFSignaturePlacement, image: UIImage)] = []
        if let context = modelContext {
            for placement in placements {
                if let model = try? SignatureManager.signature(context: context, id: placement.signatureID),
                   let img = model.loadImage() {
                    stamped.append((placement: placement, image: img))
                }
            }
        }

        if let sig = selectedSignature, let img = signatureImage {
            let activePlacement = PDFSignaturePlacement(
                signatureID: sig.id,
                pageIndex: currentPageIndex,
                normalizedRect: overlayNormalizedRect,
                rotationDegrees: currentRotation
            )
            stamped.append((placement: activePlacement, image: img))
        }

        guard !stamped.isEmpty else { return baseDoc }

        do {
            return try PDFManager.applyStampedSignatures(document: baseDoc, stampedPlacements: stamped)
        } catch {
            return baseDoc
        }
    }

    /// Builds (placement, image) pairs: either explicit `placements` or a single stamp from the current overlay.
    private func resolveStampedPlacementsForSave() throws -> [(placement: PDFSignaturePlacement, image: UIImage)] {
        guard let context = modelContext else {
            throw NSError(
                domain: "eSignPDFApp",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Missing storage context."]
            )
        }
        if placements.isEmpty {
            guard let sig = selectedSignature, let img = signatureImage else {
                throw NSError(
                    domain: "eSignPDFApp",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Choose a signature or add at least one placement."]
                )
            }
            let placement = PDFSignaturePlacement(
                signatureID: sig.id,
                pageIndex: currentPageIndex,
                normalizedRect: overlayNormalizedRect,
                rotationDegrees: currentRotation,
                isFlippedHorizontally: isFlippedHorizontally
            )
            return [(placement: placement, image: img)]
        }
        var stamped: [(placement: PDFSignaturePlacement, image: UIImage)] = []
        stamped.reserveCapacity(placements.count + (signatureImage != nil ? 1 : 0))
        for placement in placements {
            guard let model = try SignatureManager.signature(context: context, id: placement.signatureID) else {
                throw NSError(
                    domain: "eSignPDFApp",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "A saved signature was removed. Undo placements that use it or add them again."]
                )
            }
            guard let img = model.loadImage() else {
                throw NSError(
                    domain: "eSignPDFApp",
                    code: 0,
                    userInfo: [NSLocalizedDescriptionKey: "Could not load a signature image."]
                )
            }
            stamped.append((placement: placement, image: img))
        }
        if let sig = selectedSignature, let img = signatureImage {
            let activePlacement = PDFSignaturePlacement(
                signatureID: sig.id,
                pageIndex: currentPageIndex,
                normalizedRect: overlayNormalizedRect,
                rotationDegrees: currentRotation,
                isFlippedHorizontally: isFlippedHorizontally
            )
            stamped.append((placement: activePlacement, image: img))
        }
        return stamped
    }

    func saveSignedPDF(
        displayName: String,
        recordUsage: (() -> Void)? = nil
    ) async {
        guard let modelContext, let document else {
            errorMessage = "Missing document."
            return
        }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        do {
            let stamped = try resolveStampedPlacementsForSave()
            let signed = try PDFManager.applyStampedSignatures(document: document, stampedPlacements: stamped)
            let saved = try StorageManager.saveSignedDocument(
                context: modelContext,
                displayName: displayName,
                pdfDocument: signed
            )
            lastSavedDocument = saved
            recordUsage?()
            HapticFeedback.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticFeedback.warning()
        }
    }
}
