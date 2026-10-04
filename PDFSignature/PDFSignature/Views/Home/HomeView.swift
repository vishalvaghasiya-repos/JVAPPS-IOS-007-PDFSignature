//
//  HomeView.swift
//  PDFSignature
//

import SwiftData
import SwiftUI
import ASKRatingKit
import AdsManagerKit
import GoogleMobileAds
private struct PDFSignSession: Identifiable {
    let id = UUID()
    let url: URL
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: AppRouter
    @ObservedObject private var localization = LocalizationManager.shared
    @StateObject private var vm = HomeViewModel()

    @State private var showImporter = false
    @State private var pickedURL: URL?
    @State private var selectedSignatureForPreview: SignatureModel?
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
        NavigationStack(path: $router.homePath) {
            ZStack(alignment: .bottomTrailing) {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 22) {
                        quickSignHeroCard
                            .padding(.top, 8)

                        signaturesSection

                        NativeAdContainerView(
                            adView: nativeAdView,
                            height: nativeHeight,
                            isLoaded: $nativeIsLoaded,
                            resolvedHeight: $nativeHeight
                        )
                        .frame(height: nativeHeight)
                        .cornerRadius(12)

                        recentSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 96)
                }
                .scrollIndicators(.hidden)

                fab
            }
            .background(Theme.primaryGradient.ignoresSafeArea())
            .navigationTitle(AppConstants.appDisplayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        router.push(.newSignature, on: .home)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .bold))
                            Text(localization.localized("new_signature"))
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        }
                        .foregroundStyle(Theme.button)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(Color.clear)
                    }
                }
            }
            .toolbar(router.homePath.isEmpty ? .visible : .hidden, for: .tabBar)
            .navigationDestination(for: AppRoute.self) { route in
                Group {
                    switch route {
                    case .signatureLibrary:
                        SignatureLibraryView()
                    case .newSignature:
                        NewSignatureView()
                    case .pdfSigning(let url):
                        PDFSigningView(sourceURL: url) {
                            router.pop(on: .home)
                        }
                    case .pdfPreview(let doc):
                        SignedPDFPreviewView(document: doc)
                    case .webView(let url, let title):
                        AppWebViewScreen(url: url, title: title)
                    case .languageSelection:
                        LanguageSelectionView()
                    }
                }
                .toolbar(.hidden, for: .tabBar)
            }
        }
        .onAppear {
            vm.attach(context: modelContext)
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                ASKRatingKit.shared.requestRatingIfNeeded()
            }
        }
        .onChange(of: appState.selectedTab) { _, tab in
            if tab == .home {
                vm.refresh()
            }
        }
        .onChange(of: router.homePath) { _, path in
            if path.isEmpty {
                vm.refresh()
            }
        }
        .onChange(of: pickedURL) { _, url in
            guard let url else { return }
            router.push(.pdfSigning(url), on: .home)
            pickedURL = nil
        }
        .sheet(isPresented: $showImporter) {
            DocumentPicker(pickedURL: $pickedURL)
        }
        .fullScreenCover(item: $selectedSignatureForPreview) { sig in
            SignatureDetailPreviewView(signature: sig) {
                vm.refresh()
            }
        }
    }


    // MARK: - Quick Sign Hero Card
    private var quickSignHeroCard: some View {
        Button {
            showImporter = true
            HapticFeedback.light()
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(.white)
                        Text(localization.localized("quick_sign_banner_title"))
                            .font(.system(.caption, design: .rounded).weight(.bold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.2)))

                    Text(localization.localized("quick_sign_banner_subtitle"))
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Text(localization.localized("import_pdf"))
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 16))
                    }
                    .foregroundStyle(Theme.primary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(.white))
                    .padding(.top, 4)
                }

                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(systemName: "doc.badge.plus")
                        .font(.system(size: 40, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Theme.buttonGradient)
                    .shadow(color: Theme.button.opacity(0.35), radius: 12, x: 0, y: 6)
            }
        }
        .buttonStyle(.plain)
    }


    // MARK: - Signatures Section
    private var signaturesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(localization.localized("signatures"))
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Button(localization.localized("see_all")) {
                    router.push(.signatureLibrary, on: .home)
                }
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.primary)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    // Quick Add Card
                    Button {
                        router.push(.newSignature, on: .home)
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Theme.primary.opacity(0.12))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundStyle(Theme.primary)
                            }
                            Text(localization.localized("new_signature"))
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundStyle(Theme.primaryText)
                        }
                        .frame(width: 110, height: 110)
                        .glassCard(cornerRadius: 18)
                        .overlay {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(
                                    Theme.primary.opacity(0.35),
                                    style: StrokeStyle(lineWidth: 1.2, dash: [4])
                                )
                        }
                    }
                    .buttonStyle(.plain)

                    // Existing Signatures
                    ForEach(vm.signatures) { sig in
                        SignatureChip(model: sig) {
                            selectedSignatureForPreview = sig
                            HapticFeedback.light()
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: - Recent Section
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(localization.localized("recent_signed"))
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.primaryText)

            if vm.recentDocuments.isEmpty {
                emptyRecent
            } else {
                ForEach(vm.recentDocuments) { doc in
                    DocumentRowCard(doc: doc) {
                        router.push(.pdfPreview(doc), on: .home)
                    }
                }
            }
        }
    }

    private var emptyRecent: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Theme.lightBackground)
                    .frame(width: 42, height: 42)
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.secondaryText)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(localization.localized("no_signed_docs"))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.primaryText)

                Text(localization.localized("sign_first_doc"))
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.secondaryText)
            }

            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
    }

    // MARK: - FAB
    private var fab: some View {
        Button {
            showImporter = true
            HapticFeedback.light()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 58, height: 58)
                .background {
                    Circle()
                        .fill(Theme.buttonGradient)
                        .shadow(color: Theme.button.opacity(0.4), radius: 12, x: 0, y: 6)
                }
        }
        .padding(.trailing, 22)
        .padding(.bottom, 24)
    }
}

private struct SignatureChip: View {
    let model: SignatureModel
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 6) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.lightBackground.opacity(0.8))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Theme.border, lineWidth: 0.8)
                        }

                    if let ui = model.loadImage() {
                        Image(uiImage: ui)
                            .resizable()
                            .scaledToFit()
                            .padding(8)
                    }
                }
                .frame(height: 60)

                Text(model.name)
                    .font(.system(.caption2, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.primaryText)
                    .lineLimit(1)
            }
            .padding(8)
            .frame(width: 110, height: 110)
            .glassCard(cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }
}

private struct DocumentRowCard: View {
    let doc: SignedDocumentModel
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Theme.pdfRed.opacity(0.14), Theme.pdfRed.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 54)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Theme.pdfRed.opacity(0.22), lineWidth: 0.8)
                        }

                    VStack(spacing: 2) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(Theme.pdfRed)
                        Text("PDF")
                            .font(.system(size: 8, weight: .heavy, design: .rounded))
                            .foregroundStyle(Theme.pdfRed)
                            .tracking(0.5)
                    }
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(doc.displayName)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 10, weight: .medium))
                        Text(doc.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.system(.caption, design: .rounded))
                    }
                    .foregroundStyle(Theme.secondaryText)

                    HStack(spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.text.fill")
                                .font(.system(size: 9))
                            Text(doc.formattedPageCount)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .foregroundStyle(Theme.primary)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Theme.primary.opacity(0.1))
                        )

                        if let size = doc.fileSizeString {
                            HStack(spacing: 4) {
                                Image(systemName: "internaldrive")
                                    .font(.system(size: 9))
                                Text(size)
                                    .font(.system(size: 11, weight: .medium, design: .rounded))
                            }
                            .foregroundStyle(Theme.secondaryText)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(Theme.lightBackground)
                            )
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.secondaryText.opacity(0.6))
            }
            .padding(14)
            .glassCard(cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }
}
