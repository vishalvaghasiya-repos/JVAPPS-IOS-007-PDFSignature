//
//  SignedDocumentModel.swift
//  PDFSignature
//

import Foundation

struct SignedDocumentModel: Identifiable, Hashable {
    let id: UUID
    var displayName: String
    var relativeFilePath: String
    var createdAt: Date
    var pageCount: Int

    var fileURL: URL {
        DocumentPaths.signedPDFDirectory.appendingPathComponent(relativeFilePath)
    }

    var fileSizeString: String? {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: fileURL.path),
              let bytes = attrs[.size] as? Int64, bytes > 0 else {
            return nil
        }
        return ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }

    var formattedPageCount: String {
        let key = pageCount == 1 ? "page" : "pages"
        let unit = LocalizationManager.shared.localized(key)
        return "\(pageCount) \(unit)"
    }
}

extension SignedDocumentModel {
    init(entity: SignedDocumentRecord) {
        self.init(
            id: entity.id,
            displayName: entity.displayName,
            relativeFilePath: entity.relativeFilePath,
            createdAt: entity.createdAt,
            pageCount: entity.pageCount
        )
    }
}
