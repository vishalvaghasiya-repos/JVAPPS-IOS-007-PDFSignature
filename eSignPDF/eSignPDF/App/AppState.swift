//
//  AppState.swift
//  eSignPDF
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var currentScreen: AppScreen = .launch
    @Published var launchFinished = false
    @Published var selectedTab: MainTab = .home
    @AppStorage("appAppearanceMode") var appAppearanceModeRaw: String = AppAppearanceMode.system.rawValue

    private static let onboardingKey = "hasCompletedOnboarding"
    private static let welcomeKey = "hasSeenWelcome"

    var hasCompletedOnboarding: Bool {
        get {
            UserDefaults.standard.bool(forKey: Self.onboardingKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.onboardingKey)
            withAnimation(.easeInOut(duration: 0.35)) {
                if !hasSeenWelcome {
                    currentScreen = .welcome
                } else {
                    currentScreen = .mainTabBar
                }
            }
        }
    }

    var hasSeenWelcome: Bool {
        get {
            UserDefaults.standard.bool(forKey: Self.welcomeKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.welcomeKey)
            withAnimation(.easeInOut(duration: 0.35)) {
                currentScreen = .mainTabBar
            }
        }
    }

    enum AppScreen: Hashable {
        case launch
        case onboarding
        case welcome
        case mainTabBar
    }

    enum LaunchDestination: Hashable {
        case onboarding
        case welcome
        case mainTabBar
    }

    var nextScreenAfterLaunch: LaunchDestination {
        if !hasCompletedOnboarding {
            return .onboarding
        } else if !hasSeenWelcome {
            return .welcome
        } else {
            return .mainTabBar
        }
    }

    func completeLaunch() {
        launchFinished = true
        withAnimation(.easeInOut(duration: 0.45)) {
            switch nextScreenAfterLaunch {
            case .onboarding:
                currentScreen = .onboarding
            case .welcome:
                currentScreen = .welcome
            case .mainTabBar:
                currentScreen = .mainTabBar
            }
        }
    }

    func resetOnboardingAndWelcome() {
        UserDefaults.standard.set(false, forKey: Self.onboardingKey)
        UserDefaults.standard.set(false, forKey: Self.welcomeKey)
        withAnimation(.easeInOut(duration: 0.35)) {
            currentScreen = .onboarding
        }
    }

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
}
