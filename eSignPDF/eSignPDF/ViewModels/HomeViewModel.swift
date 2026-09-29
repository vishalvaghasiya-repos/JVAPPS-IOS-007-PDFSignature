//
//  HomeViewModel.swift
//  eSignPDF
//

import Combine
import Foundation
import SwiftData

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var searchText = ""
    @Published private(set) var documents: [SignedDocumentModel] = []
    @Published private(set) var signatures: [SignatureModel] = []
    @Published var errorMessage: String?

    private var modelContext: ModelContext?

    func attach(context: ModelContext) {
        modelContext = context
        refresh()
    }

    func refresh() {
        guard let modelContext else { return }
        do {
            documents = try StorageManager.fetchSignedDocuments(context: modelContext)
            signatures = try SignatureManager.fetchAll(context: modelContext)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    var filteredDocuments: [SignedDocumentModel] {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty { return documents }
        return documents.filter { $0.displayName.localizedCaseInsensitiveContains(q) }
    }

    var recentDocuments: [SignedDocumentModel] {
        Array(filteredDocuments.prefix(8))
    }
}
