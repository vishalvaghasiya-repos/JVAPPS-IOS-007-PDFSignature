//
//  FileManager.swift
//  eSignPDF
//  Application document paths and file helpers.
//

import Foundation

enum DocumentPaths {
    private static let fm = Foundation.FileManager.default
    private static let iCloudSyncKey = "iCloudLibrarySyncEnabled"

    /// When true, signature PNGs and exported PDFs live in the iCloud container (survive reinstall on the same Apple ID).
    static var isICloudLibrarySyncEnabled: Bool {
        UserDefaults.standard.bool(forKey: iCloudSyncKey)
    }

    static func setICloudLibrarySyncEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: iCloudSyncKey)
    }

    static var documentsDirectory: URL {
        fm.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    static var localSignaturesDirectory: URL {
        let url = documentsDirectory.appendingPathComponent("Signatures", isDirectory: true)
        try? fm.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    static var localSignedPDFDirectory: URL {
        let url = documentsDirectory.appendingPathComponent("SignedPDFs", isDirectory: true)
        try? fm.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }

    /// First container URL from entitlements (`nil` = use default container in the plist).
    static func ubiquitousContainerBaseURL() -> URL? {
        if let url = fm.url(forUbiquityContainerIdentifier: AppConstants.iCloudContainerIdentifier) {
            return url
        }
        return fm.url(forUbiquityContainerIdentifier: nil)
    }

    /// iCloud `Documents/Library` root for this app (requires iCloud + **Cloud Documents** in entitlements, and iCloud Drive on for the Apple ID).
    static func ubiquitousLibraryRoot(createIfNeeded: Bool) -> URL? {
        guard let base = ubiquitousContainerBaseURL() else {
            return nil
        }
        let root = base
            .appendingPathComponent("Documents", isDirectory: true)
            .appendingPathComponent("Library", isDirectory: true)
        if createIfNeeded {
            try? fm.createDirectory(at: root, withIntermediateDirectories: true)
        }
        return root
    }

    static var signaturesDirectory: URL {
        if isICloudLibrarySyncEnabled, let cloud = ubiquitousLibraryRoot(createIfNeeded: true) {
            let url = cloud.appendingPathComponent("Signatures", isDirectory: true)
            try? fm.createDirectory(at: url, withIntermediateDirectories: true)
            return url
        }
        return localSignaturesDirectory
    }

    static var signedPDFDirectory: URL {
        if isICloudLibrarySyncEnabled, let cloud = ubiquitousLibraryRoot(createIfNeeded: true) {
            let url = cloud.appendingPathComponent("SignedPDFs", isDirectory: true)
            try? fm.createDirectory(at: url, withIntermediateDirectories: true)
            return url
        }
        return localSignedPDFDirectory
    }

    static func uniqueFileURL(in directory: URL, extension ext: String) -> URL {
        directory.appendingPathComponent(UUID().uuidString).appendingPathExtension(ext)
    }

    @discardableResult
    static func copyFileToDocuments(from source: URL) throws -> URL {
        let dest = uniqueFileURL(in: documentsDirectory, extension: source.pathExtension)
        if fm.fileExists(atPath: dest.path) {
            try fm.removeItem(at: dest)
        }
        try fm.copyItem(at: source, to: dest)
        return dest
    }

    static func deleteFile(at url: URL) {
        try? fm.removeItem(at: url)
    }
}
