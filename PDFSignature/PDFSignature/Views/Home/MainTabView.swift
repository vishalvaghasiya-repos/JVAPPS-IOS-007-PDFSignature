//
//  MainTabView.swift
//  PDFSignature
//

import SwiftUI
import AdsManagerKit

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label(localization.localized("home"), systemImage: "house.fill")
                }
                .tag(AppState.MainTab.home)

            HistoryView()
                .tabItem {
                    Label(localization.localized("history"), systemImage: "clock.fill")
                }
                .tag(AppState.MainTab.history)

            SettingsView()
                .tabItem {
                    Label(localization.localized("settings"), systemImage: "gearshape.fill")
                }
                .tag(AppState.MainTab.settings)
        }
        .tint(Theme.primary)
        .onChange(of: appState.selectedTab) { _, _ in
            AdsManager.shared.showInterstitialIfAvailable()
        }
        .onAppear {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}
