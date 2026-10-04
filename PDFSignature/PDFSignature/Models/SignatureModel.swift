//
//  SignatureModel.swift
//  PDFSignature
//

import Foundation
import UIKit

struct SignatureModel: Identifiable, Hashable {
    let id: UUID
    var name: String
    var createdAt: Date
    var imageFileName: String

    init(id: UUID = UUID(), name: String, createdAt: Date = Date(), imageFileName: String) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.imageFileName = imageFileName
    }

    var imageURL: URL {
        DocumentPaths.signaturesDirectory.appendingPathComponent(imageFileName)
    }

    func loadImage() -> UIImage? {
        guard let data = try? Data(contentsOf: imageURL) else { return nil }
        return UIImage(data: data)
    }
}

extension SignatureModel {
    init(entity: SignatureRecord) {
        self.init(
            id: entity.id,
            name: entity.name,
            createdAt: entity.createdAt,
            imageFileName: entity.imageFileName
        )
    }
}
