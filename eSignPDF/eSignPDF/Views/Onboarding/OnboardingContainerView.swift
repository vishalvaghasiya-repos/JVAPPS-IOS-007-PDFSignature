//
//  OnboardingContainerView.swift
//  eSignPDF
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
                        Text("Skip")
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
                            .fill(i == pageIndex ? Theme.accent : Theme.accent.opacity(0.24))
                            .frame(width: i == pageIndex ? 22 : 8, height: 8)
                            .animation(.spring(response: 0.35), value: pageIndex)
                    }
                }
                .padding(.bottom, 24)

                PrimaryButton(title: pageIndex == pages.count - 1 ? "Get Started" : "Continue") {
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
        colorScheme == .light ? Color.primary.opacity(0.9) : Color.white.opacity(0.95)
    }

    private var skipBackground: Color {
        colorScheme == .light
            ? Color(uiColor: .systemGray6)
            : Color.white.opacity(0.16)
    }

    private var skipStroke: Color {
        colorScheme == .light
            ? Color.black.opacity(0.1)
            : Color.white.opacity(0.22)
    }

    private var skipShadowColor: Color {
        Color.black.opacity(0.1)
    }

    private var screenBackground: some View {
        LinearGradient(
            colors: colorScheme == .light
                ? [
                    Color(red: 0.94, green: 0.91, blue: 0.98),
                    Color(red: 0.91, green: 0.93, blue: 0.98),
                    Color(red: 0.97, green: 0.95, blue: 0.98)
                  ]
                : [
                    Color(red: 0.06, green: 0.05, blue: 0.12),
                    Color(red: 0.09, green: 0.07, blue: 0.16),
                    Color(red: 0.03, green: 0.02, blue: 0.06)
                  ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
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
                            ? Color.white.opacity(0.55)
                            : Color.white.opacity(0.06)
                    )
                    .frame(height: 340)
                    .overlay {
                        RoundedRectangle(cornerRadius: 32, style: .continuous)
                            .stroke(
                                colorScheme == .light
                                    ? Color.white.opacity(0.7)
                                    : Color.white.opacity(0.15),
                                lineWidth: 1.5
                            )
                    }
                    .shadow(
                        color: colorScheme == .light
                            ? Color.black.opacity(0.05)
                            : Color.black.opacity(0.25),
                        radius: 20,
                        x: 0,
                        y: 10
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
