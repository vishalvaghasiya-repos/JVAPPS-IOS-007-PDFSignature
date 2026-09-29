//
//  PremiumViewModel.swift
//  eSignPDF
//

import Combine
import Foundation

@MainActor
final class PremiumViewModel: ObservableObject {
    @Published var selectedPackageId: String?
    @Published var isPurchasing = false
    @Published var statusMessage: String?

    private let subscription = SubscriptionManager.shared

    var productsLoaded: Bool {
        !subscription.packageOptions.isEmpty
    }

    func load() async {
        await subscription.loadOfferings()
        if selectedPackageId == nil {
            selectedPackageId =
                subscription.packageOptions.first(where: { $0.title == "Yearly" })?.id
                ?? subscription.packageOptions.first?.id
        }
    }

    func purchase() async {
        guard let id = selectedPackageId ?? subscription.packageOptions.first?.id else {
            statusMessage = "Plans unavailable. Check RevenueCat offerings or Info.plist API key."
            return
        }
        isPurchasing = true
        statusMessage = nil
        do {
            try await subscription.purchase(packageId: id)
            statusMessage = "Welcome to Premium!"
            HapticFeedback.success()
        } catch {
            statusMessage = error.localizedDescription
        }
        isPurchasing = false
    }

    func restore() async {
        isPurchasing = true
        statusMessage = nil
        await subscription.restore()
        if subscription.isPremiumActive {
            statusMessage = "Purchases restored."
            HapticFeedback.success()
        } else {
            statusMessage = "No active subscription found."
        }
        isPurchasing = false
    }

    func displayRows() -> [PremiumPackageOption] {
        subscription.packageOptions
    }
}
