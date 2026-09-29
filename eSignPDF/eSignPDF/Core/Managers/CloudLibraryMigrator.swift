//
//  CloudLibraryMigrator.swift
//  eSignPDF
//

import Foundation

enum CloudLibraryMigratorError: LocalizedError {
    case iCloudUnavailable
    case migrationFailed(String)

    var errorDescription: String? {
        switch self {
        case .iCloudUnavailable:
            return "Sign in to iCloud in Settings and ensure iCloud Drive is on."
        case .migrationFailed(let message):
            return message
        }
    }
}

enum CloudLibraryMigrator {
    /// Copies signature images and signed PDFs between local Documents and the iCloud container when toggling sync.
    static func migrateToICloudIfNeeded() throws {
        guard let cloudRoot = DocumentPaths.ubiquitousLibraryRoot(createIfNeeded: true) else {
            throw CloudLibraryMigratorError.iCloudUnavailable
        }
        let localSig = DocumentPaths.localSignaturesDirectory
        let localPDF = DocumentPaths.localSignedPDFDirectory
        let cloudSig = cloudRoot.appendingPathComponent("Signatures", isDirectory: true)
        let cloudPDF = cloudRoot.appendingPathComponent("SignedPDFs", isDirectory: true)
        try FileManager.default.createDirectory(at: cloudSig, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: cloudPDF, withIntermediateDirectories: true)
        try mergeCopy(from: localSig, to: cloudSig)
        try mergeCopy(from: localPDF, to: cloudPDF)
    }

    static func migrateToLocalIfNeeded() throws {
        guard let cloudRoot = DocumentPaths.ubiquitousLibraryRoot(createIfNeeded: false) else {
            throw CloudLibraryMigratorError.iCloudUnavailable
        }
        let localSig = DocumentPaths.localSignaturesDirectory
        let localPDF = DocumentPaths.localSignedPDFDirectory
        let cloudSig = cloudRoot.appendingPathComponent("Signatures", isDirectory: true)
        let cloudPDF = cloudRoot.appendingPathComponent("SignedPDFs", isDirectory: true)
        try FileManager.default.createDirectory(at: localSig, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: localPDF, withIntermediateDirectories: true)
        if FileManager.default.fileExists(atPath: cloudSig.path) {
            try mergeCopy(from: cloudSig, to: localSig)
        }
        if FileManager.default.fileExists(atPath: cloudPDF.path) {
            try mergeCopy(from: cloudPDF, to: localPDF)
        }
    }

    private static func mergeCopy(from source: URL, to dest: URL) throws {
        let fm = FileManager.default
        guard let names = try? fm.contentsOfDirectory(atPath: source.path) else { return }
        for name in names where !name.hasPrefix(".") {
            let s = source.appendingPathComponent(name)
            var isDir: ObjCBool = false
            guard fm.fileExists(atPath: s.path, isDirectory: &isDir), !isDir.boolValue else { continue }
            let d = dest.appendingPathComponent(name)
            if fm.fileExists(atPath: d.path) { continue }
            try fm.copyItem(at: s, to: d)
        }
    }
}
