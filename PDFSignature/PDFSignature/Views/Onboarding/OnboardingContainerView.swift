//
//  OnboardingContainerView.swift
//  PDFSignature
//

import SwiftUI

struct OnboardingContainerView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var pageIndex = 0

    private let pages = OnboardingPage.pages

    var body: some View {
        ZStack {
            screenBackground
                .ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Button {
                        withAnimation(.spring()) {
                            appState.hasCompletedOnboarding = true
                        }
                    } label: {
                        Text(LocalizationManager.shared.localized("skip"))
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundStyle(skipForeground)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background {
                                Capsule()
                                    .fill(skipBackground)
                                    .shadow(color: skipShadowColor, radius: colorScheme == .light ? 6 : 0, x: 0, y: colorScheme == .light ? 3 : 0)
                                    .overlay {
                                        Capsule()
                                            .stroke(skipStroke, lineWidth: 1)
                                    }
                            }
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                TabView(selection: $pageIndex) {
                    ForEach(Array(pages.enumerated()), id: \.offset) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                            .padding(.horizontal, 24)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: pageIndex)

                HStack(spacing: 8) {
                    ForEach(0 ..< pages.count, id: \.self) { i in
                        Capsule()
                            .fill(i == pageIndex ? Theme.primary : Theme.primary.opacity(0.25))
                            .frame(width: i == pageIndex ? 22 : 8, height: 8)
                            .animation(.spring(response: 0.35), value: pageIndex)
                    }
                }
                .padding(.bottom, 24)

                PrimaryButton(title: pageIndex == pages.count - 1 ? LocalizationManager.shared.localized("get_started") : LocalizationManager.shared.localized("continue")) {
                    if pageIndex < pages.count - 1 {
                        withAnimation(.spring()) {
                            pageIndex += 1
                        }
                    } else {
                        withAnimation(.spring()) {
                            appState.hasCompletedOnboarding = true
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 34)
            }
        }
    }

    private var skipForeground: Color {
        Theme.secondaryText
    }

    private var skipBackground: Color {
        Theme.card
    }

    private var skipStroke: Color {
        Theme.border
    }

    private var skipShadowColor: Color {
        Theme.cardShadow
    }

    private var screenBackground: some View {
        Theme.primaryGradient
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    @Environment(\.colorScheme) private var colorScheme
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        colorScheme == .light
                            ? Theme.card.opacity(0.85)
                            : Theme.card
                    )
                    .frame(height: 340)
                    .overlay {
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(Theme.border, lineWidth: 1.2)
                    }
                    .shadow(
                        color: colorScheme == .light
                            ? Theme.cardShadow
                            : Color.black.opacity(0.35),
                        radius: 16,
                        x: 0,
                        y: 8
                    )

                Image(page.imageName)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 4/00)
                    .padding(16)
                    .scaleEffect(appeared ? 1 : 0.88)
                    .opacity(appeared ? 1 : 0)
            }

            Spacer()

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(.title, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.primaryText)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)

                Text(page.subtitle)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
                    .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 8)
            .offset(y: appeared ? 0 : 12)
            .opacity(appeared ? 1 : 0)

            Spacer()
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.82).delay(0.05)) {
                appeared = true
            }
        }
        .onDisappear {
            appeared = false
        }
    }
}

#Preview("Light") {
    OnboardingContainerView()
        .environmentObject(AppState())
}

#Preview("Dark") {
    OnboardingContainerView()
        .environmentObject(AppState())
        .preferredColorScheme(.dark)
}
