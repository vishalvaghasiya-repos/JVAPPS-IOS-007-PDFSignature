//
//  HistoryView.swift
//  eSignPDF
//

import PDFKit
import SwiftData
import SwiftUI
import AdsManagerKit

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: AppRouter
    @ObservedObject private var localization = LocalizationManager.shared
    @StateObject private var vm = HistoryViewModel()

    @State private var pendingDeleteDoc: SignedDocumentModel?
    @State private var bannerIsLoaded = false
    @State private var bannerHeight: CGFloat = 50

    var body: some View {
        NavigationStack(path: $router.historyPath) {
            ZStack {
                Theme.primaryGradient
                    .ignoresSafeArea()

                if vm.filtered.isEmpty {
                    empty
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 12) {
                            ForEach(vm.filtered) { doc in
                                HistoryRow(doc: doc) {
                                    router.push(.pdfPreview(doc), on: .history)
                                } onDelete: {
                                    pendingDeleteDoc = doc
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                    .scrollIndicators(.hidden)
                }
            }
            .safeAreaInset(edge: .bottom) {
                BannerAdView(
                    adType: .collapsed(position: .bottom),
                    isLoaded: $bannerIsLoaded,
                    height: $bannerHeight
                )
                .frame(height: bannerIsLoaded ? bannerHeight : 50)
            }
            .navigationTitle(localization.localized("history"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .searchable(
                text: $vm.searchText,
                placement: .navigationBarDrawer(displayMode: .automatic),
                prompt: localization.localized("search_signed_pdfs")
            )
            .toolbar(router.historyPath.isEmpty ? .visible : .hidden, for: .tabBar)
            .navigationDestination(for: AppRoute.self) { route in
                Group {
                    switch route {
                    case .pdfPreview(let doc):
                        SignedPDFPreviewView(document: doc)
                    default:
                        EmptyView()
                    }
                }
                .toolbar(.hidden, for: .tabBar)
            }
        }
        .onAppear { vm.attach(context: modelContext) }
        .onChange(of: appState.selectedTab) { _, tab in
            if tab == .history {
                vm.reload()
            }
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

    private var empty: some View {
        VStack(spacing: 18) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Theme.lightBackground)
                    .frame(width: 80, height: 80)
                Image(systemName: vm.documents.isEmpty ? "clock.badge.questionmark" : "magnifyingglass")
                    .font(.system(size: 38, weight: .medium))
                    .foregroundStyle(Theme.primary)
            }

            VStack(spacing: 6) {
                Text(vm.documents.isEmpty ? localization.localized("no_history_yet") : localization.localized("search"))
                    .font(.system(.title3, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.primaryText)
                Text(vm.documents.isEmpty ? localization.localized("history_empty_subtitle") : localization.localized("no_signed_docs"))
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
}

private struct HistoryRow: View {
    let doc: SignedDocumentModel
    let onOpen: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .center, spacing: 14) {
                PDFDocumentThumbnailView(doc: doc)

                VStack(alignment: .leading, spacing: 6) {
                    Text(doc.displayName)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(1)
                        .truncationMode(.middle)

                    HStack(spacing: 5) {
                        Image(systemName: "calendar")
                            .font(.system(size: 11, weight: .medium))
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
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
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
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3.5)
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
            .padding(14)
            .glassCard(cornerRadius: 18)
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

private struct PDFDocumentThumbnailView: View {
    let doc: SignedDocumentModel
    @State private var thumbnail: UIImage?

    private static let cache = NSCache<NSURL, UIImage>()

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Theme.pdfRed.opacity(0.14), Theme.pdfRed.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.pdfRed.opacity(0.22), lineWidth: 0.8)
                }

            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 52, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Theme.border.opacity(0.5), lineWidth: 0.5)
                    }
            } else {
                VStack(spacing: 3) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(Theme.pdfRed)

                    Text("PDF")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.pdfRed)
                        .tracking(0.6)
                }
            }
        }
        .frame(width: 52, height: 60)
        .task(id: doc.id) {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        let url = doc.fileURL
        let nsURL = url as NSURL
        if let cached = Self.cache.object(forKey: nsURL) {
            self.thumbnail = cached
            return
        }

        Task.detached(priority: .userInitiated) {
            guard FileManager.default.fileExists(atPath: url.path),
                  let pdf = PDFDocument(url: url),
                  let rendered = PDFManager.renderPageThumbnail(document: pdf, pageIndex: 0, maxWidth: 120) else {
                return
            }
            Self.cache.setObject(rendered, forKey: nsURL)
            await MainActor.run {
                self.thumbnail = rendered
            }
        }
    }
}
