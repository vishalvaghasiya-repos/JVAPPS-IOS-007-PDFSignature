//
//  HistoryViewModel.swift
//  PDFSignature
//

import Combine
import Foundation
import SwiftData

@MainActor
final class HistoryViewModel: ObservableObject {
    @Published var searchText = ""
    @Published private(set) var documents: [SignedDocumentModel] = []
    @Published var errorMessage: String?

    private var modelContext: ModelContext?

    func attach(context: ModelContext) {
        modelContext = context
        reload()
    }

    func reload() {
        guard let modelContext else { return }
        do {
            documents = try StorageManager.fetchSignedDocuments(context: modelContext)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var filtered: [SignedDocumentModel] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return documents }
        return documents.filter { $0.displayName.localizedCaseInsensitiveContains(q) }
    }

    func delete(_ doc: SignedDocumentModel) {
        guard let modelContext else { return }
        do {
            try StorageManager.deleteSignedDocument(context: modelContext, id: doc.id)
            reload()
            HapticFeedback.light()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
