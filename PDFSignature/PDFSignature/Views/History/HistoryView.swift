//
//  HistoryView.swift
//  PDFSignature
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
    @State private var isSearchVisible = false

    var body: some View {
        NavigationStack(path: $router.historyPath) {
            ZStack {
                Theme.primaryGradient
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Toggled in-screen search bar (hidden by default)
                    if isSearchVisible {
                        HStack(spacing: 10) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Theme.secondaryText)

                            TextField(localization.localized("search_signed_pdfs"), text: $vm.searchText)
                                .textFieldStyle(.plain)
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(Theme.primaryText)

                            if !vm.searchText.isEmpty {
                                Button {
                                    vm.searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(Theme.secondaryText)
                                }
                            }
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(Theme.card)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Theme.border.opacity(0.6), lineWidth: 0.8)
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, 6)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    if vm.filtered.isEmpty {
                        empty
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 10) {
                                ForEach(vm.filtered) { doc in
                                    DocumentRowCard(
                                        doc: doc,
                                        onOpen: {
                                            router.push(.pdfPreview(doc), on: .history)
                                        },
                                        onDelete: {
                                            pendingDeleteDoc = doc
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .scrollIndicators(.hidden)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                BannerAdView(
                    adType: .collapsed(position: .bottom),
                    isLoaded: $bannerIsLoaded,
                    height: $bannerHeight
                )
                .frame(height: bannerIsLoaded ? bannerHeight : 0)
                .opacity(bannerIsLoaded ? 1 : 0)
                .clipped()
            }
            .navigationTitle(localization.localized("history"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(localization.localized("history"))
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.titleText)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            isSearchVisible.toggle()
                            if !isSearchVisible {
                                vm.searchText = ""
                            }
                        }
                    } label: {
                        Image(systemName: isSearchVisible ? "xmark" : "magnifyingglass")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Theme.primary)
                            .frame(width: 32, height: 32)
                    }
                }
            }
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
