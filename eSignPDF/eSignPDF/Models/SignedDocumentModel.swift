//
//  SignedDocumentModel.swift
//  eSignPDF
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
