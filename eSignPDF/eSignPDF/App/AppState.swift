//
//  AppState.swift
//  eSignPDF
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding = false
    @AppStorage("hasSeenWelcome") var hasSeenWelcome = false
    @AppStorage("freeSignCount") var freeSignCount: Int = 0
    @AppStorage("appAppearanceMode") var appAppearanceModeRaw: String = AppAppearanceMode.system.rawValue

    @Published var launchFinished = false
    @Published var selectedTab: MainTab = .home
    @Published var showPremiumPaywall = false

    enum MainTab: Hashable {
        case home
        case history
        case settings
    }

    enum AppAppearanceMode: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var title: String {
            switch self {
            case .system: "System"
            case .light: "Light"
            case .dark: "Dark"
            }
        }

        var colorScheme: ColorScheme? {
            switch self {
            case .system: nil
            case .light: .light
            case .dark: .dark
            }
        }
    }

    var appAppearanceMode: AppAppearanceMode {
        get { AppAppearanceMode(rawValue: appAppearanceModeRaw) ?? .system }
        set {
            appAppearanceModeRaw = newValue.rawValue
            objectWillChange.send()
        }
    }

    var preferredColorScheme: ColorScheme? {
        appAppearanceMode.colorScheme
    }

    var canSignFreely: Bool {
        SubscriptionManager.shared.isPremiumActive || freeSignCount < AppConstants.freeSignLimit
    }

    func recordFreeSignIfNeeded() {
        guard !SubscriptionManager.shared.isPremiumActive else { return }
        freeSignCount += 1
    }

    func requirePremiumOrAllow(action: () -> Void) {
        if canSignFreely {
            action()
        } else {
            showPremiumPaywall = true
        }
    }
}
