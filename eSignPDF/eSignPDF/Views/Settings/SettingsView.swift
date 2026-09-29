//
//  SettingsView.swift
//  eSignPDF
//

import SwiftData
import SwiftUI
import AdsManagerKit


struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: AppRouter
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var subscription = SubscriptionManager.shared
    @ObservedObject private var cloudSync = CloudSyncStatus.shared
    @StateObject private var vm = SettingsViewModel()
    @State private var showRestoreAlert = false
    @State private var iCloudSyncToggle = false
    @State private var bannerIsLoaded = false
    @State private var bannerHeight: CGFloat = 0
    @State private var activeWebViewItem: WebViewItem? = nil

    var body: some View {
        NavigationStack(path: $router.settingsPath) {
            ZStack {
                Theme.primaryGradient
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        planStatusSection()

                        settingsCard(title: "iCloud library") {
                            VStack(alignment: .leading, spacing: 12) {
                                Toggle("Sync library with iCloud", isOn: $iCloudSyncToggle)
                                    .font(.system(.body, design: .rounded).weight(.medium))
                                    .foregroundStyle(Theme.primaryText)
                                    .tint(Theme.accent)
                                    .disabled(vm.iCloudSyncBusy || !vm.iCloudContainerReachable)
                                    .onChange(of: iCloudSyncToggle) { _, newValue in
                                        Task {
                                            await vm.applyICloudLibrarySync(newValue)
                                            iCloudSyncToggle = DocumentPaths.isICloudLibrarySyncEnabled
                                        }
                                    }

                                if !vm.iCloudContainerReachable {
                                    VStack(alignment: .leading, spacing: 6) {
                                        if vm.iCloudUserSignedIn {
                                            Text("This Apple ID is signed into iCloud, but the app still can’t open an iCloud Documents folder. Turn on iCloud Drive under Settings → Apple ID → iCloud, then restart the app. On Simulator, enable iCloud → Cloud Documents for this target and rebuild.")
                                                .font(.system(.caption, design: .rounded))
                                                .foregroundStyle(Theme.secondaryText)
                                        } else {
                                            Text("Sign in to iCloud in Settings, turn on iCloud Drive, then return here. Library files use iCloud Documents, not only your Apple ID sign-in.")
                                                .font(.system(.caption, design: .rounded))
                                                .foregroundStyle(Theme.secondaryText)
                                        }
                                    }
                                } else {
                                    Text("Stores signature images and exported PDFs in your iCloud container. SwiftData also syncs your library metadata when iCloud is available.")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(Theme.secondaryText)
                                }

                                if let last = cloudSync.lastCloudActivity {
                                    Text("Last iCloud activity: \(last.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.system(.caption, design: .rounded).weight(.semibold))
                                        .foregroundStyle(Theme.primaryText.opacity(0.9))
                                } else {
                                    Text("Last iCloud activity: —")
                                        .font(.system(.caption, design: .rounded))
                                        .foregroundStyle(Theme.secondaryText)
                                }

                                if cloudSync.pendingSync, DocumentPaths.isICloudLibrarySyncEnabled {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .scaleEffect(0.85)
                                        Text("Sync pending…")
                                            .font(.system(.caption, design: .rounded).weight(.semibold))
                                            .foregroundStyle(Theme.secondaryText)
                                    }
                                }

                                PrimaryButton(title: "Sync now", systemImage: "arrow.triangle.2.circlepath") {
                                    try? modelContext.save()
                                    cloudSync.requestSyncNow()
                                    HapticFeedback.light()
                                }
                                .disabled(!DocumentPaths.isICloudLibrarySyncEnabled || vm.iCloudSyncBusy)

                                if vm.iCloudSyncBusy {
                                    ProgressView("Updating library location…")
                                        .font(.system(.caption, design: .rounded))
                                }
                            }
                            .padding(.vertical, 4)
                        }

                        settingsCard(title: "Appearance") {
                            HStack {
                                Label("Light", systemImage: "sun.max.fill")
                                    .font(.system(.caption, design: .rounded).weight(.semibold))
                                    .foregroundStyle(Theme.secondaryText)
                                Spacer()
                                Label("Dark", systemImage: "moon.fill")
                                    .font(.system(.caption, design: .rounded).weight(.semibold))
                                    .foregroundStyle(Theme.secondaryText)
                            }
                            .padding(.top, 2)

                            Picker("Theme", selection: Binding(
                                get: { appState.appAppearanceMode },
                                set: { appState.appAppearanceMode = $0 }
                            )) {
                                ForEach(AppState.AppAppearanceMode.allCases) { mode in
                                    Text(mode.title).tag(mode)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.vertical, 6)
                        }

                        settingsCard(title: "Spread the word") {
                            row("Share App", systemImage: "square.and.arrow.up") { vm.shareApp() }
                        }

                        settingsCard(title: "Support") {
                             row("Rate App", systemImage: "star.fill") { vm.rateApp() }
                             row("Privacy Policy", systemImage: "hand.raised.fill") {
                                 router.push(.webView(url: AppConstants.URLs.privacy, title: "Privacy Policy"), on: .settings)
                             }
                             row("Terms of Use", systemImage: "doc.text") {
                                 router.push(.webView(url: AppConstants.URLs.terms, title: "Terms of Use"), on: .settings)
                             }
                             row("Contact Support", systemImage: "envelope.fill") { vm.contactSupport() }
                             row("Feedback", systemImage: "bubble.left.and.bubble.right.fill") {
                                 router.push(.webView(url: AppConstants.URLs.feedback, title: "Feedback"), on: .settings)
                             }
                            row("Restore Purchases", systemImage: "arrow.clockwise.circle") {
                                Task {
                                    await vm.restorePurchases()
                                    showRestoreAlert = true
                                }
                            }
                        }

                        settingsCard(title: "About") {
                            HStack {
                                Text("Version")
                                    .foregroundStyle(Theme.primaryText)
                                Spacer()
                                Text(vm.appVersion)
                                    .foregroundStyle(Theme.secondaryText)
                                    .font(.system(.subheadline, design: .rounded).monospacedDigit())
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 18)
                }
            }
            .safeAreaInset(edge: .bottom) {
                BannerAdView(
                    adType: .ADAPTIVE,
                    isLoaded: $bannerIsLoaded,
                    height: $bannerHeight
                )
                .frame(height: bannerHeight)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.light, for: .navigationBar)
            .alert("Restore Purchases", isPresented: $showRestoreAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.restoreMessage ?? "Done")
            }
            .onAppear {
                subscription.refreshPremiumState()
                iCloudSyncToggle = DocumentPaths.isICloudLibrarySyncEnabled
            }
            .alert("iCloud", isPresented: Binding(
                get: { vm.iCloudSyncError != nil },
                set: { if !$0 { vm.iCloudSyncError = nil } }
            )) {
                Button("OK", role: .cancel) { vm.iCloudSyncError = nil }
            } message: {
                Text(vm.iCloudSyncError ?? "")
            }
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .webView(let url, let title):
                    AppWebViewScreen(url: url, title: title)
                default:
                    EmptyView()
                }
            }
        }
    }

    private func settingsCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title.uppercased())
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.secondaryText)

            VStack(spacing: 0) {
                content()
            }
            .padding(14)
            .glassCard(cornerRadius: 20)
        }
    }

    private func row(_ title: String, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .frame(width: 26)
                Text(title)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Theme.secondaryText.opacity(0.65))
            }
            .font(.system(.body, design: .rounded).weight(.medium))
            .foregroundStyle(Theme.primaryText)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func planStatusSection() -> some View {
        if subscription.isPremiumActive {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.white)
                            .font(.system(size: 20, weight: .bold))
                        Text("PDFSignature Premium")
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                    }
                    Spacer()
                    Text("PRO")
                        .font(.system(.caption2, design: .rounded).weight(.black))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.24)))
                        .foregroundStyle(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    if let summary = subscription.planExpirationSummary {
                        Text(summary)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.white.opacity(0.95))
                    }
                    
                    ForEach(subscription.planDetailLines, id: \.self) { line in
                        Text(line)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.white.opacity(0.85))
                    }
                }
                
                Divider()
                    .background(Color.white.opacity(0.3))
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text("Unlimited document signing")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text("iCloud synchronization active")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                    }
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                        Text("Zero advertisements")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                    }
                }
                .foregroundStyle(.white.opacity(0.95))
            }
            .padding(18)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.premiumAccentGradient)
                    .shadow(color: Theme.premiumPurple.opacity(0.3), radius: 12, x: 0, y: 6)
            }
        } else {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(Theme.accent)
                            .font(.system(size: 18))
                        Text("Free Plan")
                            .font(.system(.headline, design: .rounded).weight(.bold))
                            .foregroundStyle(Theme.primaryText)
                    }
                    Spacer()
                    Text("ACTIVE")
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Theme.accent.opacity(0.12)))
                        .foregroundStyle(Theme.accent)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Document Sign Limit")
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(Theme.primaryText)
                        Spacer()
                        let signaturesLeft = max(0, AppConstants.freeSignLimit - appState.freeSignCount)
                        Text("\(signaturesLeft) of \(AppConstants.freeSignLimit) left")
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundStyle(signaturesLeft == 0 ? .red : Theme.secondaryText)
                    }
                    
                    let limit = max(1, AppConstants.freeSignLimit)
                    let progress = CGFloat(appState.freeSignCount) / CGFloat(limit)
                    
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.primary.opacity(0.08))
                                .frame(height: 10)
                            
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Theme.accent, Theme.accent.opacity(0.75)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: max(0, min(geometry.size.width, geometry.size.width * progress)), height: 10)
                        }
                    }
                    .frame(height: 10)
                    
                    Text("Signed \(appState.freeSignCount) out of \(AppConstants.freeSignLimit) documents.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Theme.secondaryText)
                }
                
                Divider()
                    .background(Color.primary.opacity(0.06))
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("Unlock unlimited document signing, secure iCloud library sync, and remove all ads.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Theme.secondaryText)
                        .multilineTextAlignment(.leading)
                        .lineSpacing(2)
                    
                    Button {
                        appState.showPremiumPaywall = true
                        HapticFeedback.light()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 16, weight: .bold))
                            Text("Upgrade to Premium")
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background {
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Theme.premiumAccentGradient)
                                .shadow(color: Theme.premiumPurple.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
            .glassCard(cornerRadius: 22)
        }
    }
}
