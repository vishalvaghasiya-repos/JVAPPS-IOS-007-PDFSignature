//
//  SubscriptionManager.swift
//  eSignPDF
//

import Combine
import Foundation
import RevenueCatKit
internal import RevenueCat
import AdsManagerKit


@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published private(set) var isPremiumActive = false {
        didSet {
            AdsManager.setToPremium(isPremiumActive)
        }
    }
    @Published private(set) var packageOptions: [PremiumPackageOption] = []
    /// Human-readable lines for Settings (active plans).
    @Published private(set) var planDetailLines: [String] = []
    /// Primary expiration / renewal line for Settings.
    @Published private(set) var planExpirationSummary: String?

    private var revenueCatConfigured = false

    private init() {}

    func markRevenueCatConfigured() {
        revenueCatConfigured = true
    }

    /// Refresh entitlement + expiration UI from RevenueCat (no offerings fetch).
    func refreshPremiumState() {
        guard revenueCatConfigured else { return }
        RevenueCatManager.shared.isUserSubscribed { [weak self] active in
            Task { @MainActor in
                guard let self else { return }
                self.isPremiumActive = active
            }
        }
        RevenueCatManager.shared.getCurrentPlanStatus { [weak self] statuses in
            Task { @MainActor in
                self?.applyPlanStatuses(statuses)
            }
        }
    }

    private func applyPlanStatuses(_ statuses: [PlanStatus]) {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none

        if let first = statuses.first {
            if let exp = first.expirationDate {
                planExpirationSummary = exp > Date()
                    ? "Renews or expires \(df.string(from: exp))"
                    : "Expired \(df.string(from: exp))"
            } else {
                planExpirationSummary = "Premium active"
            }
            planDetailLines = statuses.map { s in
                var line = "\(s.planDuration)"
                if !s.productPrice.isEmpty {
                    line += " · \(s.productPrice)"
                }
                line += " · \(s.billType)"
                if let exp = s.expirationDate {
                    line += " · \(df.string(from: exp))"
                }
                return line
            }
        } else {
            planExpirationSummary = nil
            planDetailLines = []
        }
    }

    func loadOfferings() async {
        guard revenueCatConfigured else { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            RevenueCatManager.shared.fetchOfferings { packages in
                Task { @MainActor in
                    let mapped: [PremiumPackageOption] = packages.map { pkg in
                        let title: String
                        let sortIndex: Int
                        let badge: String?
                        switch pkg.packageType {
                        case .annual:
                            title = "Yearly"
                            sortIndex = 0
                            badge = "Best value"
                        case .monthly:
                            title = "Monthly"
                            sortIndex = 1
                            badge = "Popular"
                        case .weekly:
                            title = "Weekly"
                            sortIndex = 2
                            badge = nil
                        case .lifetime:
                            title = "Lifetime"
                            sortIndex = -1
                            badge = nil
                        default:
                            title = pkg.storeProduct.localizedTitle
                            sortIndex = 5
                            badge = nil
                        }
                        let subtitle: String
                        switch pkg.packageType {
                        case .annual: subtitle = "Save more annually"
                        case .monthly: subtitle = "Flexible billing"
                        case .weekly: subtitle = "Try short-term"
                        default: subtitle = pkg.storeProduct.localizedDescription
                        }
                        return PremiumPackageOption(
                            id: pkg.identifier,
                            title: title,
                            displayPrice: pkg.storeProduct.localizedPriceString,
                            subtitle: subtitle,
                            badge: badge,
                            sortIndex: sortIndex
                        )
                    }
                    .sorted { $0.sortIndex < $1.sortIndex }
                    self.packageOptions = mapped
                    continuation.resume()
                }
            }
        }
        refreshPremiumState()
    }

    func purchase(packageId: String) async throws {
        guard revenueCatConfigured else {
            throw NSError(
                domain: "eSignPDFApp",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Purchases are not configured. Add RevenueCatAPIKey to Info.plist."]
            )
        }
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            RevenueCatManager.shared.fetchOfferings { packages in
                guard let pkg = packages.first(where: { $0.identifier == packageId }) else {
                    Task { @MainActor in
                        continuation.resume(
                            throwing: NSError(
                                domain: "eSignPDFApp",
                                code: 0,
                                userInfo: [NSLocalizedDescriptionKey: "That plan is not available right now."]
                            )
                        )
                    }
                    return
                }
                RevenueCatManager.shared.purchase(package: pkg) { success in
                    Task { @MainActor in
                        if success {
                            self.isPremiumActive = true
                            self.refreshPremiumState()
                            continuation.resume()
                        } else {
                            continuation.resume(
                                throwing: NSError(
                                    domain: "eSignPDFApp",
                                    code: 0,
                                    userInfo: [NSLocalizedDescriptionKey: "Purchase did not complete."]
                                )
                            )
                        }
                    }
                }
            }
        }
    }

    func restore() async {
        guard revenueCatConfigured else { return }
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            RevenueCatManager.shared.restorePurchases { _ in
                Task { @MainActor in
                    self.refreshPremiumState()
                    continuation.resume()
                }
            }
        }
    }
}
