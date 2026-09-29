//
//  PDFSigningView.swift
//  eSignPDF
//

import PDFKit
import SwiftData
import SwiftUI
import AdsManagerKit

struct PDFSigningView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: AppRouter

    @StateObject private var vm: PDFPreviewViewModel
    @State private var showSignaturePicker = false
    @State private var signatureSize: Double = 1.0
    @State private var displayName: String

    let onClose: () -> Void

    init(sourceURL: URL, onClose: @escaping () -> Void) {
        _vm = StateObject(wrappedValue: PDFPreviewViewModel(url: sourceURL))
        self.onClose = onClose
        _displayName = State(initialValue: sourceURL.deletingPathExtension().lastPathComponent)
    }

    var body: some View {
        ZStack {
            Theme.primaryGradient
                .ignoresSafeArea()

            VStack(spacing: 16) {
                pageControls

                if let thumb = vm.currentPageThumbnail {
                    PageSigningCanvas(
                        thumbnail: thumb,
                        normalizedRect: $vm.overlayNormalizedRect,
                        signature: vm.signatureImage,
                        rotationDegrees: Binding(
                            get: { vm.currentRotation },
                            set: { vm.currentRotation = $0 }
                        ),
                        committedStamps: vm.committedStampPreviews(forPage: vm.currentPageIndex),
                        onCancel: {
                            vm.clearWorkingSignatureOnCurrentPage()
                        }
                    )
                    .id(vm.currentPageIndex)
                    .frame(height: min(420, UIScreen.main.bounds.height * 0.48))
                    .glassCard(cornerRadius: 22)
                } else {
                    Text("Could not load PDF preview.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Theme.primaryText)
                    Spacer()
                }

                ScrollView {
                    controls
                }
            }
            .padding(.horizontal, 20)
        }
        .navigationTitle("Sign PDF")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(colorScheme == .dark ? Color.black.opacity(0.9) : Color(uiColor: .systemBackground), for: .navigationBar)
        .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Open preview") {
                    if let doc = vm.lastSavedDocument {
                        router.push(.pdfPreview(doc), on: appState.selectedTab)
                    }
                }
                .disabled(vm.lastSavedDocument == nil)
                .foregroundStyle(.primary.opacity(vm.lastSavedDocument == nil ? 0.45 : 1))
            }
        }
        .onAppear {
            vm.attach(context: modelContext)
            applySignatureScale()
        }
        .onChange(of: signatureSize) { _, _ in
            applySignatureScale()
        }
        .onChange(of: vm.currentPageIndex) { _, _ in
            vm.resetOverlayPosition()
            applySignatureScale()
        }
        .sheet(isPresented: $showSignaturePicker) {
            SignaturePickerView { model in
                vm.selectSignature(model)
                vm.resetOverlayPosition()
                applySignatureScale()
                showSignaturePicker = false
            }
        }
        .alert("Error", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    private var pageControls: some View {
        HStack {
            Text("Page \(vm.currentPageIndex + 1) / \(max(vm.pageCount, 1))")
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.primaryText)
            Spacer()
            Button {
                vm.goToPage(vm.currentPageIndex - 1)
            } label: {
                Image(systemName: "chevron.left.circle.fill")
            }
            .disabled(vm.currentPageIndex == 0)
            .tint(Theme.primaryText)

            Button {
                vm.goToPage(vm.currentPageIndex + 1)
            } label: {
                Image(systemName: "chevron.right.circle.fill")
            }
            .disabled(vm.currentPageIndex >= vm.pageCount - 1)
            .tint(Theme.primaryText)
        }
        .padding(.horizontal, 4)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    showSignaturePicker = true
                } label: {
                    Label(vm.selectedSignature?.name ?? "Choose Signature Sticker", systemImage: "signature")
                        .font(.system(.subheadline, design: .rounded).weight(.semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(colorScheme == .light ? Theme.premiumPurple : Color.white.opacity(0.28))

                Spacer()

                Button("Undo last") {
                    vm.removeLastPlacement()
                }
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.primaryText)
                .disabled(vm.placements.isEmpty)
                .opacity(vm.placements.isEmpty ? 0.45 : 1)

                Button("Apply to page") {
                    if vm.signatureImage == nil {
                        showSignaturePicker = true
                    } else {
                        vm.addPlacementFromOverlay()
                    }
                }
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.primaryText)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Signature size")
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.secondaryText)
                Slider(value: $signatureSize, in: 0.15 ... 1.50, step: 0.05)
                    .tint(Theme.primaryText)
            }

            TextField("Signed Document Title", text: $displayName)
                .textFieldStyle(.roundedBorder)

            Text("Position the sticker, then tap Apply to page to lock it on this page preview. Repeat for multiple stamps or pages. Undo last removes the last applied stamp. X clears the live sticker without applying.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(Theme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)

            PrimaryButton(title: vm.isSaving ? "Saving…" : "Save signed PDF") {
                appState.requirePremiumOrAllow {
                    Task {
                        await vm.saveSignedPDF(displayName: displayName) {
                            appState.recordFreeSignIfNeeded()
                        }
                        if let saved = vm.lastSavedDocument {
                            AdsManager.shared.showInterstitialIfAvailable()
                            let currentTab = appState.selectedTab
                            if currentTab == .home {
                                if !router.homePath.isEmpty { router.homePath.removeLast() }
                                router.push(.pdfPreview(saved), on: .home)
                            } else if currentTab == .history {
                                if !router.historyPath.isEmpty { router.historyPath.removeLast() }
                                router.push(.pdfPreview(saved), on: .history)
                            }
                        }
                    }
                }
            }
            .disabled(vm.isSaving || vm.document == nil || (vm.placements.isEmpty && vm.signatureImage == nil))
            .opacity((vm.placements.isEmpty && vm.signatureImage == nil) ? 0.55 : 1)
        }
        .padding(.bottom, 18)
    }

    private func applySignatureScale() {
        guard vm.signatureImage != nil else { return }
        let v = CGFloat(signatureSize)
        let w = clamp(0.32 * v, min: 0.04, max: 0.78)
        let h = clamp(w * 0.38, min: 0.015, max: 0.5)
        var r = vm.overlayNormalizedRect
        let c = CGPoint(x: r.midX, y: r.midY)
        r.size = CGSize(width: w, height: h)
        r.origin.x = c.x - w / 2
        r.origin.y = c.y - h / 2
        r.origin.x = clamp(r.origin.x, min: 0, max: 1 - w)
        r.origin.y = clamp(r.origin.y, min: 0, max: 1 - h)
        vm.overlayNormalizedRect = r
    }

    private func clamp<T: Comparable>(_ value: T, min minimum: T, max maximum: T) -> T {
        min(max(value, minimum), maximum)
    }
}
