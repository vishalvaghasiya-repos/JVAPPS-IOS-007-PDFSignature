//
//  UserSubscription.swift
//  eSignPDF
//

import Foundation

/// Row shown on the Premium paywall (backed by RevenueCat offerings).
struct PremiumPackageOption: Identifiable, Equatable {
    let id: String
    let title: String
    let displayPrice: String
    let subtitle: String
    let badge: String?
    let sortIndex: Int
}
