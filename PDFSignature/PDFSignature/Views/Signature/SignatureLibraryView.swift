//
//  SignatureLibraryView.swift
//  PDFSignature
//

import SwiftData
import SwiftUI
import AdsManagerKit

struct SignatureLibraryView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: AppRouter
    @ObservedObject private var localization = LocalizationManager.shared

    @StateObject private var vm = SignatureViewModel()
    @State private var renameText = ""
    @State private var previewTarget: SignatureModel?
    @State private var bannerIsLoaded = false
    @State private var bannerHeight: CGFloat = 50

    var body: some View {
        ZStack {
            Theme.primaryGradient.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    if vm.signatures.isEmpty {
                        ContentUnavailableView(
                            localization.localized("no_signatures_yet"),
                            systemImage: "signature",
                            description: Text(localization.localized("create_signature_desc"))
                        )
                        .padding(.top, 48)
                    }

                    ForEach(vm.signatures) { sig in
                        SignatureLibraryRow(
                            sig: sig,
                            onPreview: {
                                previewTarget = sig
                                HapticFeedback.light()
                            },
                            onRename: {
                                vm.renameTarget = sig
                                renameText = sig.name
                            },
                            onDelete: {
                                vm.delete(sig)
                            }
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden)
        }
        .safeAreaInset(edge: .bottom) {
            BannerAdView(
                adType: .adaptive,
                isLoaded: $bannerIsLoaded,
                height: $bannerHeight
            )
            .frame(height: bannerIsLoaded ? bannerHeight : 0)
            .opacity(bannerIsLoaded ? 1 : 0)
            .clipped()
        }
        .navigationTitle(localization.localized("signatures"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .tint(Theme.primary)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(localization.localized("signatures"))
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.titleText)
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.push(.newSignature, on: appState.selectedTab)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                }
                .tint(Theme.primary)
            }
        }
        .alert(localization.localized("rename_signature"), isPresented: Binding(
            get: { vm.renameTarget != nil },
            set: { if !$0 { vm.renameTarget = nil } }
        )) {
            TextField(localization.localized("signature_name"), text: $renameText)
            Button(localization.localized("cancel"), role: .cancel) { vm.renameTarget = nil }
            Button(localization.localized("save")) {
                vm.newName = renameText
                vm.rename()
            }
        } message: {
            Text(localization.localized("rename_signature_desc"))
        }
        .alert(localization.localized("error"), isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button(localization.localized("ok"), role: .cancel) { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .fullScreenCover(item: $previewTarget) { sig in
            SignatureDetailPreviewView(signature: sig) {
                vm.reload()
            }
        }
        .onAppear { vm.attach(context: modelContext) }
    }
}

private struct SignatureLibraryRow: View {
    let sig: SignatureModel
    let onPreview: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onPreview) {
            HStack(spacing: 14) {
                SignatureThumbnailBox(model: sig)

                VStack(alignment: .leading, spacing: 4) {
                    Text(sig.name)
                        .font(.system(.body, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.primaryText)
                    Text(sig.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Theme.secondaryText)
                }

                Spacer()

                SignatureRowMenu(
                    onPreview: onPreview,
                    onRename: onRename,
                    onDelete: onDelete
                )
            }
            .padding(14)
            .glassCard(cornerRadius: 18, hasShadow: false)
        }
        .buttonStyle(.plain)
    }
}

private struct SignatureThumbnailBox: View {
    let model: SignatureModel

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.lightBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Theme.border, lineWidth: 0.8)
                )

            if let img = model.loadImage() {
                Image(uiImage: img)
                    .resizable()
                    .scaledToFit()
                    .padding(6)
            }
        }
        .frame(width: 64, height: 50)
    }
}

private struct SignatureRowMenu: View {
    let onPreview: () -> Void
    let onRename: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Menu {
            Button(action: onPreview) {
                Label(LocalizationManager.shared.localized("preview_signature"), systemImage: "eye")
            }

            Button(action: onRename) {
                Label(LocalizationManager.shared.localized("rename"), systemImage: "pencil")
            }

            Button(role: .destructive, action: onDelete) {
                Label(LocalizationManager.shared.localized("delete"), systemImage: "trash")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Theme.secondaryText)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Theme.lightBackground))
        }
    }
}

