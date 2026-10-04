//
//  WelcomeView.swift
//  PDFSignature
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var localization = LocalizationManager.shared
    @State private var animate = false

    var body: some View {
        ZStack {
            Theme.primaryGradient
                .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                VStack(spacing: 18) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .fill(Theme.buttonGradient)
                            .frame(width: 110, height: 110)
                            .shadow(color: Theme.button.opacity(0.35), radius: 16, x: 0, y: 8)

                        Image(systemName: "signature")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundStyle(.white)
                    }
                    .scaleEffect(animate ? 1 : 0.88)
                    .opacity(animate ? 1 : 0.75)

                    VStack(spacing: 8) {
                        Text(AppConstants.appDisplayName)
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundStyle(Theme.primaryText)
                            .multilineTextAlignment(.center)

                        Text("A calm, modern workspace to sign PDFs, manage signatures, and export with confidence.")
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 12)
                    }
                    .offset(y: animate ? 0 : 10)
                    .opacity(animate ? 1 : 0)
                }
                .padding(24)
                .glassCard(cornerRadius: 28)
                .padding(.horizontal, 20)

                Spacer()

                VStack(spacing: 14) {
                    PrimaryButton(title: localization.localized("get_started"), systemImage: "arrow.right.circle.fill") {
                        withAnimation(.spring()) {
                            appState.hasSeenWelcome = true
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 36)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.85)) {
                animate = true
            }
        }
    }
}
