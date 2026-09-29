//
//  WelcomeView.swift
//  eSignPDF
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
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
                            .fill(.ultraThinMaterial)
                            .frame(width: 120, height: 120)
                            .overlay {
                                RoundedRectangle(cornerRadius: 32, style: .continuous)
                                    .stroke(
                                        colorScheme == .dark ? Color.white.opacity(0.35) : Color.primary.opacity(0.15),
                                        lineWidth: 1
                                    )
                            }

                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 48, weight: .medium))
                            .foregroundStyle(colorScheme == .dark ? Color.white : Color.primary)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .scaleEffect(animate ? 1 : 0.88)
                    .opacity(animate ? 1 : 0.75)

                    VStack(spacing: 8) {
                        Text(AppConstants.appDisplayName)
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .foregroundStyle(Theme.primaryText)
                            .multilineTextAlignment(.center)

                        Text("A calm, premium workspace to sign PDFs, manage signatures, and export with confidence.")
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
                    PrimaryButton(title: "Get Started") {
                        withAnimation(.spring()) {
                            appState.hasSeenWelcome = true
                        }
                    }

                    Button {
                        Task {
                            await SubscriptionManager.shared.restore()
                        }
                    } label: {
                        Text("Restore Purchase")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(Theme.primaryText.opacity(0.88))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.65, dampingFraction: 0.85)) {
                animate = true
            }
        }
    }
}
