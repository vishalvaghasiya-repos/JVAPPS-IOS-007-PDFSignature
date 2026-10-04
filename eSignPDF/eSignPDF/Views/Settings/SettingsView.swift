//
//  SettingsView.swift
//  eSignPDF
//

import SwiftData
import SwiftUI
import AdsManagerKit
import GoogleMobileAds
struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: AppRouter
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var cloudSync = CloudSyncStatus.shared
    @ObservedObject private var localization = LocalizationManager.shared
    @StateObject private var vm = SettingsViewModel()

    @State private var iCloudSyncToggle = false
    @State private var bannerIsLoaded = false
    @State private var bannerHeight: CGFloat = 50

    @State private var nativeIsLoaded = false
    @State private var nativeHeight: CGFloat = 170
    private let nativeAdView: NativeAdView = {
        let bundle = Bundle(for: NativeAdView.self)
        guard let adView = bundle.loadNibNamed("NativeAdsMedium", owner: nil, options: nil)?.first as? NativeAdView else {
            fatalError("Could not load NativeAdsMedium.xib")
        }
        return adView
    }()
    
    var body: some View {
        NavigationStack(path: $router.settingsPath) {
            ZStack {
                Theme.primaryGradient
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Preferences (Language & Appearance)
                        settingsGroup(title: localization.localized("preferences")) {
                            // Language Selection Row
                            Button {
                                router.push(.languageSelection, on: .settings)
                            } label: {
                                HStack(spacing: 14) {
                                    settingIconView(systemName: "globe", color: .orange)

                                    Text(localization.localized("language"))
                                        .font(.system(.body, design: .rounded).weight(.medium))
                                        .foregroundStyle(Theme.primaryText)

                                    Spacer()

                                    HStack(spacing: 6) {
                                        Text(localization.currentLanguage.flag)
                                        Text(localization.currentLanguage.nativeTitle)
                                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                            .foregroundStyle(Theme.secondaryText)
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Theme.lightBackground))

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(Theme.secondaryText.opacity(0.6))
                                }
                                .padding(.vertical, 10)
                            }
                            .buttonStyle(.plain)

                            Divider()
                                .padding(.leading, 46)

                            // Appearance Picker
                            VStack(alignment: .leading, spacing: 10) {
                                HStack(spacing: 14) {
                                    settingIconView(systemName: "circle.righthalf.filled", color: .purple)

                                    Text(localization.localized("appearance"))
                                        .font(.system(.body, design: .rounded).weight(.medium))
                                        .foregroundStyle(Theme.primaryText)

                                    Spacer()
                                }

                                Picker("Theme", selection: Binding(
                                    get: { appState.appAppearanceMode },
                                    set: { appState.appAppearanceMode = $0 }
                                )) {
                                    Text(localization.localized("theme_system")).tag(AppState.AppAppearanceMode.system)
                                    Text(localization.localized("theme_light")).tag(AppState.AppAppearanceMode.light)
                                    Text(localization.localized("theme_dark")).tag(AppState.AppAppearanceMode.dark)
                                }
                                .pickerStyle(.segmented)
                                .padding(.top, 4)
                            }
                            .padding(.vertical, 10)
                        }
                        
                        NativeAdContainerView(
                            adView: nativeAdView,
                            height: nativeHeight,
                            isLoaded: $nativeIsLoaded,
                            resolvedHeight: $nativeHeight
                        )
                        .frame(height: nativeHeight)
                        .cornerRadius(12)

                        // iCloud Library
                        settingsGroup(title: localization.localized("icloud_library")) {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 14) {
                                    settingIconView(systemName: "icloud.fill", color: .blue)

                                    Toggle(localization.localized("sync_with_icloud"), isOn: $iCloudSyncToggle)
                                        .font(.system(.body, design: .rounded).weight(.medium))
                                        .foregroundStyle(Theme.primaryText)
                                        .tint(Theme.button)
                                        .disabled(vm.iCloudSyncBusy || !vm.iCloudContainerReachable)
                                        .onChange(of: iCloudSyncToggle) { _, newValue in
                                            Task {
                                                await vm.applyICloudLibrarySync(newValue)
                                                iCloudSyncToggle = DocumentPaths.isICloudLibrarySyncEnabled
                                            }
                                        }
                                }

                                if !vm.iCloudContainerReachable {
                                    Text("Sign in to iCloud in Settings, turn on iCloud Drive, then return here. Library files use iCloud Documents.")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(Theme.secondaryText)
                                        .padding(.leading, 46)
                                }

                                if let last = cloudSync.lastCloudActivity {
                                    Text(localization.localized("last_icloud_activity", last.formatted(date: .abbreviated, time: .shortened)))
                                        .font(.system(.caption, design: .rounded).weight(.semibold))
                                        .foregroundStyle(Theme.secondaryText)
                                        .padding(.leading, 46)
                                }

                                if cloudSync.pendingSync, DocumentPaths.isICloudLibrarySyncEnabled {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .scaleEffect(0.85)
                                        Text(localization.localized("sync_pending"))
                                            .font(.system(.caption, design: .rounded).weight(.semibold))
                                            .foregroundStyle(Theme.secondaryText)
                                    }
                                    .padding(.leading, 46)
                                }

                                PrimaryButton(title: localization.localized("sync_now"), systemImage: "arrow.triangle.2.circlepath") {
                                    try? modelContext.save()
                                    cloudSync.requestSyncNow()
                                    HapticFeedback.light()
                                }
                                .disabled(!DocumentPaths.isICloudLibrarySyncEnabled || vm.iCloudSyncBusy)
                                .padding(.top, 4)

                                if vm.iCloudSyncBusy {
                                    ProgressView()
                                        .font(.system(.caption, design: .rounded))
                                }
                            }
                            .padding(.vertical, 8)
                        }

                        // Spread the word
                        settingsGroup(title: localization.localized("spread_word")) {
                            row(
                                localization.localized("share_app"),
                                systemImage: "square.and.arrow.up.fill",
                                iconColor: .green
                            ) {
                                vm.shareApp()
                            }

                            Divider()
                                .padding(.leading, 46)

                            row(
                                localization.localized("rate_app"),
                                systemImage: "star.fill",
                                iconColor: .yellow
                            ) {
                                vm.rateApp()
                            }
                        }

                        // Support & Legal
                        settingsGroup(title: localization.localized("support")) {
                            row(
                                localization.localized("privacy_policy"),
                                systemImage: "hand.raised.fill",
                                iconColor: .blue
                            ) {
                                router.push(.webView(url: AppConstants.URLs.privacy, title: localization.localized("privacy_policy")), on: .settings)
                            }

                            Divider()
                                .padding(.leading, 46)

                            row(
                                localization.localized("terms_of_use"),
                                systemImage: "doc.text.fill",
                                iconColor: .indigo
                            ) {
                                router.push(.webView(url: AppConstants.URLs.terms, title: localization.localized("terms_of_use")), on: .settings)
                            }

                            Divider()
                                .padding(.leading, 46)

                            row(
                                localization.localized("contact_support"),
                                systemImage: "envelope.fill",
                                iconColor: .teal
                            ) {
                                vm.contactSupport()
                            }

                            Divider()
                                .padding(.leading, 46)

                            row(
                                localization.localized("feedback"),
                                systemImage: "bubble.left.and.bubble.right.fill",
                                iconColor: .purple
                            ) {
                                router.push(.webView(url: AppConstants.URLs.feedback, title: localization.localized("feedback")), on: .settings)
                            }
                        }

                        // Version & Info
                        settingsGroup(title: localization.localized("about")) {
                            HStack(spacing: 14) {
                                settingIconView(systemName: "signature", color: Theme.primary)

                                Text(AppConstants.appDisplayName)
                                    .font(.system(.body, design: .rounded).weight(.medium))
                                    .foregroundStyle(Theme.primaryText)

                                Spacer()

                                Text(localization.localized("tagline"))
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(Theme.secondaryText)
                            }
                            .padding(.vertical, 8)

                            Divider()
                                .padding(.leading, 46)

                            HStack(spacing: 14) {
                                settingIconView(systemName: "info.circle.fill", color: .gray)

                                Text(localization.localized("version"))
                                    .font(.system(.body, design: .rounded).weight(.medium))
                                    .foregroundStyle(Theme.primaryText)

                                Spacer()

                                Text(vm.appVersion)
                                    .font(.system(.subheadline, design: .rounded).monospacedDigit())
                                    .foregroundStyle(Theme.secondaryText)
                            }
                            .padding(.vertical, 8)
                        }

                        // Footer
                        VStack(spacing: 4) {
                            Text("Sign documents with ease & precision")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(Theme.secondaryText.opacity(0.7))
                        }
                        .padding(.top, 4)
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .scrollIndicators(.hidden)
            }
            .safeAreaInset(edge: .bottom) {
                BannerAdView(
                    adType: .regular,
                    isLoaded: $bannerIsLoaded,
                    height: $bannerHeight
                )
                .frame(height: bannerIsLoaded ? bannerHeight : 50)
            }
            .navigationTitle(localization.localized("settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .onAppear {
                iCloudSyncToggle = DocumentPaths.isICloudLibrarySyncEnabled
            }
            .alert("iCloud", isPresented: Binding(
                get: { vm.iCloudSyncError != nil },
                set: { if !$0 { vm.iCloudSyncError = nil } }
            )) {
                Button(localization.localized("ok"), role: .cancel) { vm.iCloudSyncError = nil }
            } message: {
                Text(vm.iCloudSyncError ?? "")
            }
            .toolbar(router.settingsPath.isEmpty ? .visible : .hidden, for: .tabBar)
            .navigationDestination(for: AppRoute.self) { route in
                Group {
                    switch route {
                    case .languageSelection:
                        LanguageSelectionView()
                    case .webView(let url, let title):
                        AppWebViewScreen(url: url, title: title)
                    default:
                        EmptyView()
                    }
                }
                .toolbar(.hidden, for: .tabBar)
            }
        }
    }

    // MARK: - Settings Components
    private func settingsGroup<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title.uppercased())
                .font(.system(.caption2, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.secondaryText)
                .padding(.leading, 6)

            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .glassCard(cornerRadius: 20)
        }
    }

    private func settingIconView(systemName: String, color: Color) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(color.gradient)
                .frame(width: 32, height: 32)

            Image(systemName: systemName)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)
        }
    }

    private func row(_ title: String, systemImage: String, iconColor: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                settingIconView(systemName: systemImage, color: iconColor)

                Text(title)
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundStyle(Theme.primaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.secondaryText.opacity(0.6))
            }
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}
