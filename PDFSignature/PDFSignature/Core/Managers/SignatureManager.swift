//
//  SignatureManager.swift
//  PDFSignature
//

import Foundation
import SwiftData
import UIKit

@MainActor
enum SignatureManager {
    static func saveNewSignature(
        context: ModelContext,
        name: String,
        image: UIImage
    ) throws -> SignatureModel {
        let fileName = "\(UUID().uuidString).png"
        let url = DocumentPaths.signaturesDirectory.appendingPathComponent(fileName)
        guard let data = image.pngData() else {
            throw NSError(domain: "Signature", code: 1, userInfo: [NSLocalizedDescriptionKey: "PNG encode failed"])
        }
        try data.write(to: url)
        let record = SignatureRecord(name: name, imageFileName: fileName)
        context.insert(record)
        try context.save()
        CloudSyncStatus.shared.markLocalLibraryChange()
        return SignatureModel(entity: record)
    }

    static func renameSignature(context: ModelContext, id: UUID, newName: String) throws {
        let predicate = #Predicate<SignatureRecord> { $0.id == id }
        var descriptor = FetchDescriptor<SignatureRecord>(predicate: predicate)
        descriptor.fetchLimit = 1
        guard let record = try context.fetch(descriptor).first else { return }
        record.name = newName
        try context.save()
        CloudSyncStatus.shared.markLocalLibraryChange()
    }

    static func deleteSignature(context: ModelContext, id: UUID) throws {
        let predicate = #Predicate<SignatureRecord> { $0.id == id }
        var descriptor = FetchDescriptor<SignatureRecord>(predicate: predicate)
        descriptor.fetchLimit = 1
        guard let record = try context.fetch(descriptor).first else { return }
        let url = DocumentPaths.signaturesDirectory.appendingPathComponent(record.imageFileName)
        DocumentPaths.deleteFile(at: url)
        context.delete(record)
        try context.save()
        CloudSyncStatus.shared.markLocalLibraryChange()
    }

    static func fetchAll(context: ModelContext) throws -> [SignatureModel] {
        let descriptor = FetchDescriptor<SignatureRecord>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map(SignatureModel.init(entity:))
    }

    static func signature(context: ModelContext, id: UUID) throws -> SignatureModel? {
        let predicate = #Predicate<SignatureRecord> { $0.id == id }
        var descriptor = FetchDescriptor<SignatureRecord>(predicate: predicate)
        descriptor.fetchLimit = 1
        guard let record = try context.fetch(descriptor).first else { return nil }
        return SignatureModel(entity: record)
    }
}
