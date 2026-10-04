//
//  PersistenceModels.swift
//  PDFSignature
//
//  SwiftData models (persistence layer).
//  CloudKit requires: no `.unique` constraints, and every stored property must be optional or have a default.
//

import Foundation
import SwiftData

@Model
final class SignatureRecord {
    var id: UUID = UUID()
    var name: String = ""
    var createdAt: Date = Date()
    var imageFileName: String = ""

    init(id: UUID = UUID(), name: String, createdAt: Date = Date(), imageFileName: String) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.imageFileName = imageFileName
    }
}

@Model
final class SignedDocumentRecord {
    var id: UUID = UUID()
    var displayName: String = ""
    var relativeFilePath: String = ""
    var createdAt: Date = Date()
    var pageCount: Int = 0

    init(
        id: UUID = UUID(),
        displayName: String,
        relativeFilePath: String,
        createdAt: Date = Date(),
        pageCount: Int
    ) {
        self.id = id
        self.displayName = displayName
        self.relativeFilePath = relativeFilePath
        self.createdAt = createdAt
        self.pageCount = pageCount
    }

    var fileURL: URL {
        DocumentPaths.signedPDFDirectory.appendingPathComponent(relativeFilePath)
    }
}
