//
//  HomeView.swift
//  eSignPDF
//

import SwiftData
import SwiftUI
import ASKRatingKit
import AdsManagerKit


private struct PDFSignSession: Identifiable {
    let id = UUID()
    let url: URL
}

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: AppRouter
    @StateObject private var vm = HomeViewModel()

    @State private var showImporter = false
    @State private var pickedURL: URL?
    @State private var signSession: PDFSignSession?
    @State private var showSignatures = false
    @State private var showNewSignature = false
    @State private var nativeIsLoaded = false
    @State private var nativeHeight: CGFloat = AdType.MEDIUM.height

    var body: some View {
        NavigationStack(path: $router.homePath) {
            ZStack(alignment: .bottomTrailing) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        header

                        searchField

                        signaturesSection

                        NativeAdContainerView(
                            adType: .MEDIUM,
                            isLoaded: $nativeIsLoaded,
                            height: $nativeHeight
                        )
                        .frame(height: nativeHeight)
                        .opacity(nativeIsLoaded ? 1 : 0)
                        .cornerRadius(8)

                        recentSection
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 96)
                }

                fab
            }
            .background(Theme.primaryGradient.ignoresSafeArea())
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.light, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        appState.showPremiumPaywall = true
                    } label: {
                        Image(systemName: "crown.fill")
                            .symbolRenderingMode(.hierarchical)
                    }
                    .tint(Theme.primaryText)
                }
            }
            .navigationDestination(for: AppRoute.self) { route in
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
                }
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
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Hello")
                .font(.system(.title2, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.primaryText)
            Text("Import a PDF and sign in seconds.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 8)
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.secondaryText)
            TextField("Search signed documents", text: $vm.searchText)
                .textInputAutocapitalization(.never)
                .foregroundStyle(Theme.primaryText)
        }
        .padding(14)
        .glassCard(cornerRadius: 16)
    }

    private var signaturesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Signatures")
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                Button("See all") {
                    router.push(.signatureLibrary, on: .home)
                }
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.primaryText)
            }

            Button {
                router.push(.newSignature, on: .home)
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add New Signature")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    Spacer()
                }
                .foregroundStyle(Theme.primaryText)
                .padding(16)
                .glassCard(cornerRadius: 18)
            }
            .buttonStyle(.plain)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(vm.signatures) { sig in
                        SignatureChip(model: sig)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent signed")
                .font(.system(.headline, design: .rounded).weight(.semibold))
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
        VStack(spacing: 10) {
            Image(systemName: "tray")
                .font(.system(size: 36))
                .foregroundStyle(Theme.secondaryText)
            Text("No signed documents yet")
                .font(.system(.subheadline, design: .rounded).weight(.medium))
                .foregroundStyle(Theme.primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 28)
        .glassCard(cornerRadius: 20)
    }

    private var fab: some View {
        Button {
            showImporter = true
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.88))
                .frame(width: 58, height: 58)
                .background {
                    Circle().fill(Color.white.opacity(0.95))
                        .shadow(color: .black.opacity(0.2), radius: 16, x: 0, y: 10)
                }
        }
        .padding(.trailing, 22)
        .padding(.bottom, 24)
    }
}

private struct SignatureChip: View {
    let model: SignatureModel

    var body: some View {
        VStack(spacing: 8) {
            if let ui = model.loadImage() {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 44)
                    .padding(8)
            }
            Text(model.name)
                .font(.system(.caption2, design: .rounded).weight(.medium))
                .foregroundStyle(Theme.primaryText)
                .lineLimit(1)
        }
        .frame(width: 110, height: 96)
        .glassCard(cornerRadius: 16)
    }
}

private struct DocumentRowCard: View {
    let doc: SignedDocumentModel
    let onOpen: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.primary.opacity(0.08))
                        .frame(width: 48, height: 48)
                    Image(systemName: "doc.richtext")
                        .foregroundStyle(Theme.primaryText)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(doc.displayName)
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                    Text(doc.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Theme.secondaryText)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(Theme.secondaryText)
            }
            .padding(16)
            .glassCard(cornerRadius: 18)
        }
        .buttonStyle(.plain)
    }
}
