//
//  CloudSyncStatus.swift
//  eSignPDF
//

import Combine
import CoreData
import Foundation

/// Tracks iCloud / CloudKit sync UX (last activity, pending local changes heuristic).
@MainActor
final class CloudSyncStatus: ObservableObject {
    static let shared = CloudSyncStatus()

    @Published private(set) var lastCloudActivity: Date?
    @Published private(set) var pendingSync: Bool = false

    private var localChangeResetTask: Task<Void, Never>?
    private var remoteObserver: NSObjectProtocol?

    private init() {
        lastCloudActivity = UserDefaults.standard.object(forKey: Keys.lastCloudActivity) as? Date
        remoteObserver = NotificationCenter.default.addObserver(
            forName: .NSPersistentStoreRemoteChange,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.recordRemoteChange()
            }
        }
    }

    deinit {
        if let remoteObserver {
            NotificationCenter.default.removeObserver(remoteObserver)
        }
    }

    func markLocalLibraryChange() {
        guard DocumentPaths.isICloudLibrarySyncEnabled else { return }
        pendingSync = true
        localChangeResetTask?.cancel()
        localChangeResetTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            guard !Task.isCancelled else { return }
            pendingSync = false
        }
    }

    func recordRemoteChange() {
        guard DocumentPaths.isICloudLibrarySyncEnabled else { return }
        let now = Date()
        lastCloudActivity = now
        UserDefaults.standard.set(now, forKey: Keys.lastCloudActivity)
        pendingSync = false
    }

    /// User-initiated; triggers save and relies on CloudKit to process in the background.
    func requestSyncNow() {
        guard DocumentPaths.isICloudLibrarySyncEnabled else { return }
        pendingSync = true
        let now = Date()
        lastCloudActivity = now
        UserDefaults.standard.set(now, forKey: Keys.lastCloudActivity)
        localChangeResetTask?.cancel()
        localChangeResetTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            guard !Task.isCancelled else { return }
            pendingSync = false
        }
    }

    private enum Keys {
        static let lastCloudActivity = "cloudSyncLastActivity"
    }
}
