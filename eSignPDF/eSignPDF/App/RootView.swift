//
//  RootView.swift
//  eSignPDF
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: AppRouter
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        ZStack {
            switch appState.currentScreen {
            case .launch:
                LaunchView()
                    .transition(.opacity)

            case .onboarding:
                OnboardingContainerView()
                    .transition(.opacity)

            case .welcome:
                WelcomeView()
                    .transition(.opacity)

            case .mainTabBar:
                MainTabView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appState.currentScreen)
        .preferredColorScheme(appState.preferredColorScheme)
        .environment(\.layoutDirection, localization.currentLanguage.layoutDirection)
        .id(localization.currentLanguage.code)
    }
}

#Preview {
    RootView()
        .environmentObject(AppState())
        .environmentObject(AppRouter())
}
