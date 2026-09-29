//
//  PurchasesBootstrap.swift
//  eSignPDF
//

import Foundation
import RevenueCatKit

enum PurchasesBootstrap {
    /// Call once at launch. Reads `RevenueCatAPIKey` and optional `RevenueCatEntitlementID` from Info.plist.
    static func configureIfPossible() {
        let key = Bundle.main.object(forInfoDictionaryKey: "RevenueCatAPIKey") as? String ?? ""
        let entitlement =
            Bundle.main.object(forInfoDictionaryKey: "RevenueCatEntitlementID") as? String
            ?? AppConstants.defaultRevenueCatEntitlementID
        guard !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            #if DEBUG
            print("SignFlow: Add RevenueCatAPIKey to Info.plist (public SDK key from RevenueCat).")
            #endif
            return
        }
        RevenueCatManager.shared.configureRevenueCat(apiKey: key, entitlementID: entitlement)
        SubscriptionManager.shared.markRevenueCatConfigured()
        Task { @MainActor in
            await SubscriptionManager.shared.loadOfferings()
        }
    }
}
