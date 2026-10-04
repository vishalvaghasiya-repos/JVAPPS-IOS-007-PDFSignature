//
//  SignatureViewModel.swift
//  PDFSignature
//

import Combine
import Foundation
import SwiftData
import UIKit

@MainActor
final class SignatureViewModel: ObservableObject {
    @Published var signatures: [SignatureModel] = []
    @Published var renameTarget: SignatureModel?
    @Published var newName = ""
    @Published var errorMessage: String?

    private var modelContext: ModelContext?

    func attach(context: ModelContext) {
        modelContext = context
        reload()
    }

    func reload() {
        guard let modelContext else { return }
        do {
            signatures = try SignatureManager.fetchAll(context: modelContext)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveDrawing(name: String, image: UIImage) {
        guard let modelContext else { return }
        do {
            _ = try SignatureManager.saveNewSignature(context: modelContext, name: name, image: image)
            reload()
            HapticFeedback.success()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func rename() {
        guard let modelContext, let target = renameTarget else { return }
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        do {
            try SignatureManager.renameSignature(context: modelContext, id: target.id, newName: name)
            renameTarget = nil
            newName = ""
            reload()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func delete(_ model: SignatureModel) {
        guard let modelContext else { return }
        do {
            try SignatureManager.deleteSignature(context: modelContext, id: model.id)
            reload()
            HapticFeedback.light()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
