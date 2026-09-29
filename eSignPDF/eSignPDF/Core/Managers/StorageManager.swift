//
//  StorageManager.swift
//  eSignPDF
//

import Foundation
import PDFKit
import SwiftData

@MainActor
enum StorageManager {
    static func saveSignedDocument(
        context: ModelContext,
        displayName: String,
        pdfDocument: PDFDocument
    ) throws -> SignedDocumentModel {
        let fileName = "\(UUID().uuidString).pdf"
        let url = DocumentPaths.signedPDFDirectory.appendingPathComponent(fileName)
        guard pdfDocument.write(to: url) else {
            throw PDFManagerError.writeFailed
        }
        let record = SignedDocumentRecord(
            displayName: displayName,
            relativeFilePath: fileName,
            pageCount: pdfDocument.pageCount
        )
        context.insert(record)
        try context.save()
        CloudSyncStatus.shared.markLocalLibraryChange()
        return SignedDocumentModel(entity: record)
    }

    static func deleteSignedDocument(context: ModelContext, id: UUID) throws {
        let predicate = #Predicate<SignedDocumentRecord> { $0.id == id }
        var descriptor = FetchDescriptor<SignedDocumentRecord>(predicate: predicate)
        descriptor.fetchLimit = 1
        guard let record = try context.fetch(descriptor).first else { return }
        DocumentPaths.deleteFile(at: record.fileURL)
        context.delete(record)
        try context.save()
        CloudSyncStatus.shared.markLocalLibraryChange()
    }

    static func fetchSignedDocuments(context: ModelContext) throws -> [SignedDocumentModel] {
        let descriptor = FetchDescriptor<SignedDocumentRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map(SignedDocumentModel.init(entity:))
    }
}
