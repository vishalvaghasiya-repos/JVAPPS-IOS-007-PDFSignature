//
//  HistoryView.swift
//  eSignPDF
//

import SwiftData
import SwiftUI
import AdsManagerKit


struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: AppRouter
    @StateObject private var vm = HistoryViewModel()

    @State private var pendingDeleteDoc: SignedDocumentModel?
    @State private var bannerIsLoaded = false
    @State private var bannerHeight: CGFloat = 0

    var body: some View {
        NavigationStack(path: $router.historyPath) {
            ZStack {
                Theme.primaryGradient
                    .ignoresSafeArea()

                if vm.filtered.isEmpty {
                    empty
                } else {
                    ScrollView {
                        VStack(spacing: 14) {
                            searchField
                            LazyVStack(spacing: 14) {
                                ForEach(vm.filtered) { doc in
                                    HistoryRow(doc: doc) {
                                        router.push(.pdfPreview(doc), on: .history)
                                    } onDelete: {
                                        pendingDeleteDoc = doc
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
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
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.light, for: .navigationBar)
            .navigationDestination(for: AppRoute.self) { route in
                switch route {
                case .pdfPreview(let doc):
                    SignedPDFPreviewView(document: doc)
                default:
                    EmptyView()
                }
            }
        }
        .onAppear { vm.attach(context: modelContext) }
        .onChange(of: appState.selectedTab) { _, tab in
            if tab == .history {
                vm.reload()
            }
        }
        .alert("Delete Signed PDF?", isPresented: Binding(
            get: { pendingDeleteDoc != nil },
            set: { if !$0 { pendingDeleteDoc = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingDeleteDoc = nil }
            Button("Delete", role: .destructive) {
                if let doc = pendingDeleteDoc {
                    vm.delete(doc)
                }
                pendingDeleteDoc = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(Theme.primaryText.opacity(0.75))
            TextField("Search signed PDFs", text: $vm.searchText)
                .textInputAutocapitalization(.never)
                .foregroundStyle(Theme.primaryText)
        }
        .padding(14)
        .glassCard(cornerRadius: 16)
    }

    private var empty: some View {
        VStack(spacing: 16) {
            searchField
                .padding(.horizontal, 20)
                .padding(.top, 12)

            Image(systemName: "clock.badge.questionmark")
                .font(.system(size: 48, weight: .medium))
                .foregroundStyle(Theme.secondaryText)
            Text("No history yet")
                .font(.system(.title3, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.primaryText)
            Text("Signed documents will appear here in a beautiful timeline.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct HistoryRow: View {
    let doc: SignedDocumentModel
    let onOpen: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onOpen) {
            HStack(alignment: .top, spacing: 14) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 52, height: 52)
                    .overlay {
                        Image(systemName: "doc.richtext")
                            .foregroundStyle(Theme.primaryText)
                    }

                VStack(alignment: .leading, spacing: 6) {
                    Text(doc.displayName)
                        .font(.system(.headline, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.primaryText)
                        .lineLimit(2)

                    HStack(spacing: 8) {
                        Label(doc.createdAt.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                        Text("•")
                        Text("\(doc.pageCount) pages")
                    }
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Theme.secondaryText)
                }

                Spacer(minLength: 0)

                Menu {
                    Button("Delete", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Theme.primaryText)
                        .padding(.top, 4)
                }
            }
            .padding(16)
            .glassCard(cornerRadius: 20)
        }
        .buttonStyle(.plain)
    }
}
