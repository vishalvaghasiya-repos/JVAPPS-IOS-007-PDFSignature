//
//  HomeView.swift
//  PDFSignature
//

import SwiftData
import SwiftUI
import ASKRatingKit
import AdsManagerKit
import GoogleMobileAds

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: AppRouter
    @ObservedObject private var localization = LocalizationManager.shared
    @StateObject private var vm = HomeViewModel()

    @State private var showImporter = false
    @State private var pickedURL: URL?
    @State private var pendingDeleteDoc: SignedDocumentModel?
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
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    quickSignHeroCard
                        .padding(.top, 6)

                    if nativeIsLoaded {
                        NativeAdContainerView(
                            adView: nativeAdView,
                            height: nativeHeight,
                            isLoaded: $nativeIsLoaded,
                            resolvedHeight: $nativeHeight
                        )
                        .frame(height: nativeHeight)
                        .cornerRadius(12)
                    }

                    recentSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
            .scrollIndicators(.hidden)
            .background(Theme.primaryGradient.ignoresSafeArea())
            .background {
                if !nativeIsLoaded {
                    NativeAdContainerView(
                        adView: nativeAdView,
                        height: nativeHeight,
                        isLoaded: $nativeIsLoaded,
                        resolvedHeight: $nativeHeight
                    )
                    .frame(height: 0)
                    .opacity(0)
                    .allowsHitTesting(false)
                }
            }
            .navigationTitle(AppConstants.appDisplayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(AppConstants.appDisplayName)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.titleText)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        router.push(.signatureLibrary, on: .home)
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: "signature")
                                .font(.system(size: 13, weight: .bold))
                            Text(localization.localized("signatures"))
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        }
                        .foregroundStyle(Theme.primary)
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
        .alert(localization.localized("delete_pdf_title"), isPresented: Binding(
            get: { pendingDeleteDoc != nil },
            set: { if !$0 { pendingDeleteDoc = nil } }
        )) {
            Button(localization.localized("cancel"), role: .cancel) { pendingDeleteDoc = nil }
            Button(localization.localized("delete"), role: .destructive) {
                if let doc = pendingDeleteDoc {
                    vm.delete(doc)
                }
                pendingDeleteDoc = nil
            }
        } message: {
            Text(localization.localized("delete_pdf_message"))
        }
    }

    // MARK: - Quick Sign Hero Card (Plain & Sleek Design)
    private var quickSignHeroCard: some View {
        Button {
            showImporter = true
            HapticFeedback.light()
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .bold))
                        Text(localization.localized("quick_sign_banner_title"))
                            .font(.system(.caption2, design: .rounded).weight(.bold))
                            .tracking(0.5)
                    }
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.18)))

                    Text(localization.localized("quick_sign_banner_subtitle"))
                        .font(.system(.title3, design: .rounded).weight(.bold))
                        .foregroundStyle(.white)
                        .lineLimit(2)

                    HStack(spacing: 6) {
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 13, weight: .bold))
                        Text(localization.localized("import_pdf"))
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
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
                        .fill(Color.white.opacity(0.14))
                        .frame(width: 74, height: 74)

                    Image(systemName: "signature")
                        .font(.system(size: 34, weight: .medium))
                        .foregroundStyle(.white)
                }
            }
            .padding(20)
            .background {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.buttonGradient)
                    .shadow(color: Theme.button.opacity(0.28), radius: 10, x: 0, y: 5)
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Recent Section (Clean Cards)
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Text(localization.localized("recent"))
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.primaryText)

                if !vm.documents.isEmpty {
                    Text("(\(vm.documents.count))")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.secondaryText)
                }

                Spacer()

                if vm.documents.count > 5 {
                    Button {
                        appState.selectedTab = .history
                    } label: {
                        HStack(spacing: 4) {
                            Text(localization.localized("see_more"))
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(Theme.primary)
                    }
                }
            }

            if vm.recentDocuments.isEmpty {
                emptyRecent
            } else {
                VStack(spacing: 10) {
                    ForEach(vm.recentDocuments) { doc in
                        DocumentRowCard(
                            doc: doc,
                            onOpen: {
                                router.push(.pdfPreview(doc), on: .home)
                            },
                            onDelete: {
                                pendingDeleteDoc = doc
                            }
                        )
                    }
                }
            }
        }
    }

    private var emptyRecent: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.lightBackground)
                    .frame(width: 44, height: 44)
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 20))
                    .foregroundStyle(Theme.secondaryText)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(localization.localized("no_signed_docs"))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.primaryText)

                Text(localization.localized("sign_first_doc"))
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.secondaryText)
            }

            Spacer()
        }
        .padding(16)
        .glassCard(cornerRadius: 16)
    }
}

// MARK: - Document Row Card (Plain Clean Design with More Menu)
struct DocumentRowCard: View {
    let doc: SignedDocumentModel
    let onOpen: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 12) {
                PDFDocumentThumbnailView(doc: doc, width: 48, height: 56, cornerRadius: 10)

                VStack(alignment: .leading, spacing: 5) {
                    Text(doc.displayName)
                        .font(.system(.body, design: .rounded).weight(.semibold))
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

                Spacer(minLength: 4)

                Menu {
                    Button(action: onOpen) {
                        Label(LocalizationManager.shared.localized("open_preview"), systemImage: "eye")
                    }

                    ShareLink(item: doc.fileURL) {
                        Label(LocalizationManager.shared.localized("share"), systemImage: "square.and.arrow.up")
                    }

                    Divider()

                    Button(role: .destructive, action: onDelete) {
                        Label(LocalizationManager.shared.localized("delete"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Theme.secondaryText)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(Theme.lightBackground)
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .glassCard(cornerRadius: 16)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: onOpen) {
                Label(LocalizationManager.shared.localized("open_preview"), systemImage: "eye")
            }

            ShareLink(item: doc.fileURL) {
                Label(LocalizationManager.shared.localized("share"), systemImage: "square.and.arrow.up")
            }

            Divider()

            Button(role: .destructive, action: onDelete) {
                Label(LocalizationManager.shared.localized("delete"), systemImage: "trash")
            }
        }
    }
}
