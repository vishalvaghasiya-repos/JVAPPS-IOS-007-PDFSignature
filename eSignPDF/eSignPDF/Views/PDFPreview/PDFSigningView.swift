//
//  PDFSigningView.swift
//  eSignPDF
//

import PDFKit
import SwiftData
import SwiftUI
import AdsManagerKit

private struct PDFPreviewItem: Identifiable {
    let id = UUID()
    let document: PDFDocument
}

struct PDFSigningView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var router: AppRouter
    @ObservedObject private var localization = LocalizationManager.shared

    @StateObject private var vm: PDFPreviewViewModel
    @State private var showSignaturePicker = false
    @State private var previewItem: PDFPreviewItem?
    @State private var showSizeSlider = false
    @State private var showRenameAlert = false
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

            VStack(spacing: 8) {
                // Compact Page Switcher Pill
                pageNavigationPill
                    .padding(.top, 4)

                // PDF Page Canvas - expanded to fill screen workspace
                ZStack {
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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                    } else {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Loading PDF…")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(Theme.secondaryText)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Popover Size Slider (when toggled)
                if showSizeSlider {
                    sizeSliderBar
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.horizontal, 20)
                }

                // Sleek Floating Bottom Control Dock
                bottomControlsDock
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
            }
        }
        .navigationTitle(displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .tint(Theme.primary)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    onClose()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Theme.primaryText)
                }
            }

            ToolbarItemGroup(placement: .topBarTrailing) {
                // Open Full Screen Preview
                Button {
                    openFullScreenPreview()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 13))
                        Text(localization.localized("preview"))
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                    }
                    .foregroundStyle(Theme.button)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Theme.button.opacity(0.12)))
                }

                // Save signed PDF Button
                Button {
                    saveDocument()
                } label: {
                    if vm.isSaving {
                        ProgressView()
                            .tint(Theme.button)
                    } else {
                        Text(localization.localized("save"))
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Theme.buttonGradient))
                    }
                }
                .disabled(vm.isSaving || vm.document == nil || (vm.placements.isEmpty && vm.signatureImage == nil))
                .opacity((vm.placements.isEmpty && vm.signatureImage == nil) ? 0.45 : 1.0)
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
        .fullScreenCover(item: $previewItem) { item in
            FullScreenPDFPreviewSheet(
                document: item.document,
                displayName: displayName,
                onSave: (vm.placements.isEmpty && vm.signatureImage == nil) ? nil : {
                    saveDocument()
                }
            )
        }
        .alert(localization.localized("document_title"), isPresented: $showRenameAlert) {
            TextField(localization.localized("document_title"), text: $displayName)
            Button(localization.localized("cancel"), role: .cancel) {}
            Button(localization.localized("ok")) {}
        }
        .alert(localization.localized("error"), isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button(localization.localized("ok"), role: .cancel) { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
    }

    // MARK: - Compact Page Navigation Pill
    private var pageNavigationPill: some View {
        HStack(spacing: 12) {
            Button {
                vm.goToPage(vm.currentPageIndex - 1)
                HapticFeedback.selection()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(vm.currentPageIndex > 0 ? Theme.primaryText : Theme.secondaryText.opacity(0.3))
            }
            .disabled(vm.currentPageIndex == 0)

            Text(localization.localized("page_x_of_y", vm.currentPageIndex + 1, max(vm.pageCount, 1)))
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.primaryText)

            Button {
                vm.goToPage(vm.currentPageIndex + 1)
                HapticFeedback.selection()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(vm.currentPageIndex < vm.pageCount - 1 ? Theme.primaryText : Theme.secondaryText.opacity(0.3))
            }
            .disabled(vm.currentPageIndex >= vm.pageCount - 1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Capsule().fill(.ultraThinMaterial))
        .overlay(Capsule().stroke(Theme.border, lineWidth: 0.8))
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }

    // MARK: - Bottom Controls Dock
    private var bottomControlsDock: some View {
        HStack(spacing: 8) {
            // 1. Choose Signature Sticker Button
            Button {
                showSignaturePicker = true
                HapticFeedback.light()
            } label: {
                HStack(spacing: 6) {
                    if let img = vm.signatureImage {
                        Image(uiImage: img)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 18)
                    } else {
                        Image(systemName: "signature")
                            .font(.system(size: 14, weight: .bold))
                    }
                    Text(vm.selectedSignature?.name ?? localization.localized("choose_signature_picker"))
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .lineLimit(1)
                }
                .foregroundStyle(Theme.button)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Theme.button.opacity(0.12))
                )
            }
            .buttonStyle(.plain)

            // 2. Size Button
            Button {
                withAnimation(.spring(response: 0.3)) {
                    showSizeSlider.toggle()
                }
                HapticFeedback.light()
            } label: {
                Image(systemName: showSizeSlider ? "slider.horizontal.2.square.on.square" : "slider.horizontal.3")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(showSizeSlider ? Theme.button : Theme.primaryText)
                    .frame(width: 38, height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(showSizeSlider ? Theme.button.opacity(0.15) : Theme.lightBackground)
                    )
            }
            .buttonStyle(.plain)

            // 3. Undo Last Button
            Button {
                vm.removeLastPlacement()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 13, weight: .semibold))
                    Text(localization.localized("undo"))
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                }
                .foregroundStyle(vm.placements.isEmpty ? Theme.secondaryText.opacity(0.35) : Theme.primaryText)
                .frame(height: 38)
                .padding(.horizontal, 10)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.lightBackground)
                )
            }
            .buttonStyle(.plain)
            .disabled(vm.placements.isEmpty)

            // 4. Apply to page Button
            Button {
                if vm.signatureImage == nil {
                    showSignaturePicker = true
                } else {
                    vm.addPlacementFromOverlay()
                }
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                    Text(localization.localized("apply"))
                        .font(.system(.caption, design: .rounded).weight(.bold))
                }
                .foregroundStyle(.white)
                .frame(height: 38)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Theme.buttonGradient)
                )
            }
            .buttonStyle(.plain)

            // 5. Open Full Screen Preview Button
            Button {
                openFullScreenPreview()
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(Theme.primaryText)
                    .frame(width: 38, height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.lightBackground)
                    )
            }
            .buttonStyle(.plain)
        }
        .padding(8)
        .glassCard(cornerRadius: 18)
    }

    // MARK: - Expandable Size Slider Bar
    private var sizeSliderBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "textformat.size.smaller")
                .font(.system(size: 12))
                .foregroundStyle(Theme.secondaryText)

            Slider(value: $signatureSize, in: 0.20 ... 1.50, step: 0.05)
                .tint(Theme.button)

            Image(systemName: "textformat.size.larger")
                .font(.system(size: 15))
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .glassCard(cornerRadius: 14)
    }

    // MARK: - Actions
    private func openFullScreenPreview() {
        if let previewDoc = vm.buildPreviewDocument() {
            previewItem = PDFPreviewItem(document: previewDoc)
            HapticFeedback.light()
        }
    }

    private func saveDocument() {
        Task {
            await vm.saveSignedPDF(displayName: displayName)
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

    private func applySignatureScale() {
        guard vm.signatureImage != nil else { return }
        let v = CGFloat(signatureSize)
        let w = clamp(0.32 * v, min: 0.06, max: 0.85)
        let h = clamp(w * 0.38, min: 0.025, max: 0.55)
        var r = vm.overlayNormalizedRect
        let c = CGPoint(x: r.midX, y: r.midY)
        r.size = CGSize(width: w, height: h)
        r.origin.x = clamp(c.x - w / 2, min: 0, max: 1 - w)
        r.origin.y = clamp(c.y - h / 2, min: 0, max: 1 - h)
        vm.overlayNormalizedRect = r
    }

    private func clamp<T: Comparable>(_ value: T, min minimum: T, max maximum: T) -> T {
        min(max(value, minimum), maximum)
    }
}

// MARK: - Full Screen Interactive PDF Preview Sheet
struct FullScreenPDFPreviewSheet: View {
    let document: PDFDocument
    let displayName: String
    var onSave: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localization = LocalizationManager.shared
    @State private var showShareSheet = false
    @State private var shareURL: URL?

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                PDFKitView(document: document)
                    .ignoresSafeArea(edges: .bottom)
            }
            .navigationTitle(displayName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(localization.localized("close")) {
                        dismiss()
                    }
                    .foregroundStyle(Theme.primary)
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        if let url = exportTempPDF() {
                            shareURL = url
                            showShareSheet = true
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .foregroundStyle(Theme.primary)

                    if let onSave {
                        Button {
                            dismiss()
                            onSave()
                        } label: {
                            Text(localization.localized("save"))
                                .font(.system(.subheadline, design: .rounded).weight(.bold))
                                .foregroundStyle(Theme.button)
                        }
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let shareURL {
                    SignatureShareActivityView(activityItems: [shareURL])
                }
            }
        }
    }

    private func exportTempPDF() -> URL? {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(displayName).pdf")
        if document.write(to: tempURL) {
            return tempURL
        }
        return nil
    }
}
