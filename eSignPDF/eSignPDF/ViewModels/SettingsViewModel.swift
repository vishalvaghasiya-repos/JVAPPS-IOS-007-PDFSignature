//
//  SettingsViewModel.swift
//  eSignPDF
//

import Combine
import Foundation
import SwiftUI
import UIKit

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var restoreMessage: String?
    @Published var iCloudSyncBusy = false
    @Published var iCloudSyncError: String?

    var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    func shareApp() {
        let text = "Sign PDFs beautifully with \(AppConstants.appDisplayName)"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        present(av)
    }

    func rateApp() {
        UIApplication.shared.open(AppConstants.URLs.appStoreReview)
    }

    func openPrivacy() {
        UIApplication.shared.open(AppConstants.URLs.privacy)
    }

    func openTerms() {
        UIApplication.shared.open(AppConstants.URLs.terms)
    }

    func contactSupport() {
        UIApplication.shared.open(AppConstants.URLs.support)
    }

    func restorePurchases() async {
        await SubscriptionManager.shared.restore()
        if SubscriptionManager.shared.isPremiumActive {
            restoreMessage = "Purchases restored."
            HapticFeedback.success()
        } else {
            restoreMessage = "No active subscription found."
        }
    }

    /// `true` when the app can open an iCloud Drive file container (not the same as “signed into iCloud”).
    var iCloudContainerReachable: Bool {
        DocumentPaths.ubiquitousContainerBaseURL() != nil
    }

    /// User is signed into iCloud; file container can still be nil if iCloud Drive is off or capabilities are wrong.
    var iCloudUserSignedIn: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    func applyICloudLibrarySync(_ enabled: Bool) async {
        guard enabled != DocumentPaths.isICloudLibrarySyncEnabled else { return }
        guard iCloudContainerReachable else {
            iCloudSyncError = CloudLibraryMigratorError.iCloudUnavailable.localizedDescription
            return
        }
        iCloudSyncBusy = true
        iCloudSyncError = nil
        defer { iCloudSyncBusy = false }
        do {
            if enabled {
                try CloudLibraryMigrator.migrateToICloudIfNeeded()
                DocumentPaths.setICloudLibrarySyncEnabled(true)
            } else {
                try CloudLibraryMigrator.migrateToLocalIfNeeded()
                DocumentPaths.setICloudLibrarySyncEnabled(false)
            }
            CloudSyncStatus.shared.recordRemoteChange()
            HapticFeedback.light()
        } catch {
            iCloudSyncError = error.localizedDescription
        }
    }

    private func present(_ controller: UIViewController) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.keyWindow?.rootViewController
        else { return }
        root.present(controller, animated: true)
    }
}

private extension UIWindowScene {
    var keyWindow: UIWindow? { windows.first { $0.isKeyWindow } }
}
