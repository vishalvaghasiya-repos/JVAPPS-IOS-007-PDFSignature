//
//  RootCoordinatorView.swift
//  eSignPDF
//

import SwiftUI

struct RootCoordinatorView: View {
    @EnvironmentObject private var appState: AppState
    @State private var showLaunch = true

    var body: some View {
        ZStack {
            if showLaunch {
                LaunchView {
                    withAnimation(.easeInOut(duration: 0.45)) {
                        showLaunch = false
                    }
                }
                .transition(.opacity)
            } else if !appState.hasCompletedOnboarding {
                OnboardingContainerView()
                    .transition(.opacity)
            } else if !appState.hasSeenWelcome {
                WelcomeView()
                    .transition(.opacity)
            } else {
                MainShellView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.35), value: appState.hasCompletedOnboarding)
        .animation(.easeInOut(duration: 0.35), value: appState.hasSeenWelcome)
        .preferredColorScheme(appState.preferredColorScheme)
    }
}
