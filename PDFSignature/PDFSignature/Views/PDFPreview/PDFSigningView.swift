//
//  PDFSigningView.swift
//  PDFSignature
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
                            isFlippedHorizontally: Binding(
                                get: { vm.isFlippedHorizontally },
                                set: { vm.isFlippedHorizontally = $0 }
                            ),
                            committedStamps: vm.committedStampPreviews(forPage: vm.currentPageIndex),
                            onCancel: {
                                vm.clearWorkingSignatureOnCurrentPage()
                            },
                            onSelectStamp: { id in
                                vm.selectCommittedStamp(id: id)
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    showSizeSlider = true
                                }
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

                // Popover Size & Transformation Slider (when toggled)
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
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .tint(Theme.primary)
        .toolbar {
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
                    .foregroundStyle(Theme.primary)
                }

                // Save signed PDF Button
                Button {
                    saveDocument()
                } label: {
                    if vm.isSaving {
                        ProgressView()
                            .tint(Theme.onPrimary)
                    } else {
                        Text(localization.localized("save"))
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundStyle(Theme.onPrimary)
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
        .onChange(of: vm.overlayNormalizedRect.width) { _, newWidth in
            let calculated = Double(newWidth / 0.32)
            if abs(calculated - signatureSize) > 0.02 {
                signatureSize = min(max(calculated, 0.25), 2.20)
            }
        }
        .onChange(of: vm.currentPageIndex) { _, _ in
            vm.resetOverlayPosition()
            applySignatureScale()
        }
        .sheet(isPresented: $showSignaturePicker) {
            SignaturePickerView { model in
                vm.selectSignature(model)
                signatureSize = 1.0
                applySignatureScale()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showSizeSlider = true
                }
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
                    .foregroundStyle(vm.currentPageIndex > 0 ? Theme.titleText : Theme.placeholder.opacity(0.4))
            }
            .disabled(vm.currentPageIndex == 0)

            Text(localization.localized("page_x_of_y", vm.currentPageIndex + 1, max(vm.pageCount, 1)))
                .font(.system(.caption, design: .rounded).weight(.bold))
                .foregroundStyle(Theme.titleText)

            Button {
                vm.goToPage(vm.currentPageIndex + 1)
                HapticFeedback.selection()
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(vm.currentPageIndex < vm.pageCount - 1 ? Theme.titleText : Theme.placeholder.opacity(0.4))
            }
            .disabled(vm.currentPageIndex >= vm.pageCount - 1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Capsule().fill(Theme.card))
        .overlay(Capsule().stroke(Theme.border, lineWidth: 0.8))
        .shadow(color: Color.black.opacity(0.12), radius: 4, x: 0, y: 2)
    }

    // MARK: - Bottom Controls Dock
    private var bottomControlsDock: some View {
        VStack(spacing: 8) {
            // Row 1: Choose Signature & Quick Tools (Rotate, Flip, Undo, Zoom)
            HStack(spacing: 6) {
                // 1. Choose Signature Button (with compact name)
                Button {
                    showSignaturePicker = true
                    HapticFeedback.light()
                } label: {
                    HStack(spacing: 6) {
                        if let img = vm.signatureImage {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 16)
                                .padding(2)
                                .background(
                                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                                        .fill(Color.primary.opacity(0.06))
                                )
                        } else {
                            Image(systemName: "signature")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Theme.primary)
                        }

                        Text(vm.selectedSignature?.name ?? localization.localized("choose_signature_picker"))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.titleText)
                            .lineLimit(1)

                        Spacer(minLength: 2)

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(Theme.secondaryText)
                    }
                    .padding(.horizontal, 10)
                    .frame(height: 38)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Theme.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(Theme.border, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)

                // 2. Rotate Button (90° step)
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        vm.rotateSignatureClockwise()
                    }
                } label: {
                    Image(systemName: "rotate.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(vm.currentRotation != 0 ? Theme.primary : Theme.titleText)
                        .frame(width: 36, height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(vm.currentRotation != 0 ? Theme.secondary : Theme.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(vm.currentRotation != 0 ? Theme.primary : Theme.border, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)

                // 3. Flip Button (Horizontal Mirror)
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        vm.toggleFlipHorizontal()
                    }
                } label: {
                    Image(systemName: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(vm.isFlippedHorizontally ? Theme.primary : Theme.titleText)
                        .frame(width: 36, height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(vm.isFlippedHorizontally ? Theme.secondary : Theme.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(vm.isFlippedHorizontally ? Theme.primary : Theme.border, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)

                // 4. Undo Last Button
                Button {
                    vm.removeLastPlacement()
                    HapticFeedback.light()
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(vm.placements.isEmpty ? Theme.placeholder : Theme.titleText)
                        .frame(width: 36, height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Theme.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Theme.border, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(vm.placements.isEmpty)
                .opacity(vm.placements.isEmpty ? 0.4 : 1.0)

                // 5. Zoom / Full Preview Button
                Button {
                    openFullScreenPreview()
                    HapticFeedback.light()
                } label: {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Theme.titleText)
                        .frame(width: 36, height: 38)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Theme.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(Theme.border, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }

            // Row 2: Adjust Size & Apply Signature
            HStack(spacing: 8) {
                // Size Adjustment Toggle Button
                Button {
                    if vm.signatureImage == nil {
                        showSignaturePicker = true
                    } else {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            showSizeSlider.toggle()
                        }
                    }
                    HapticFeedback.light()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(showSizeSlider ? Theme.onPrimary : Theme.primary)

                        Text(localization.localized("signature_size_label"))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(showSizeSlider ? Theme.onPrimary : Theme.titleText)

                        Spacer(minLength: 2)

                        Text("\(Int(signatureSize * 100))%")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(showSizeSlider ? Theme.primaryDark : Theme.primary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(showSizeSlider ? Color.white : Theme.secondary)
                            )
                    }
                    .padding(.horizontal, 12)
                    .frame(height: 42)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(showSizeSlider ? Theme.primary : Theme.card)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .stroke(showSizeSlider ? Theme.primaryDark : Theme.border, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)

                // Apply to Page Button
                Button {
                    if vm.signatureImage == nil {
                        showSignaturePicker = true
                    } else {
                        vm.addPlacementFromOverlay()
                        withAnimation(.spring(response: 0.3)) {
                            showSizeSlider = false
                        }
                    }
                    HapticFeedback.success()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .black))

                        Text(localization.localized("apply"))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Theme.onPrimary)
                    .padding(.horizontal, 16)
                    .frame(height: 42)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Theme.buttonGradient)
                            .shadow(color: Theme.primaryDark.opacity(0.35), radius: 6, x: 0, y: 3)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .glassCard(cornerRadius: 12, hasShadow: false)
    }

    // MARK: - Expandable Size & Transform Bar
    private var sizeSliderBar: some View {
        VStack(spacing: 10) {
            // Header Row: Icon, Title, Percentage badge, Presets, Rotate & Flip, Close Button
            HStack(spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Theme.primary)

                    Text(localization.localized("signature_size"))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundStyle(Theme.titleText)
                }

                Text("\(Int(signatureSize * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(Theme.primary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Theme.secondary))

                Spacer()

                // Presets S, M, L
                HStack(spacing: 4) {
                    sizePresetPill(label: "S", scale: 0.65)
                    sizePresetPill(label: "M", scale: 1.0)
                    sizePresetPill(label: "L", scale: 1.45)
                }

                // Close Button
                Button {
                    withAnimation(.spring(response: 0.25)) {
                        showSizeSlider = false
                    }
                    HapticFeedback.light()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Theme.secondaryText)
                        .frame(width: 22, height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Theme.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(Theme.border, lineWidth: 0.8)
                                )
                        )
                }
                .buttonStyle(.plain)
            }

            // Slider & Stepper Row
            HStack(spacing: 10) {
                // Stepper - (Decrease)
                Button {
                    adjustSignatureSize(by: -0.10)
                } label: {
                    Image(systemName: "minus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(signatureSize <= 0.30 ? Theme.placeholder : Theme.titleText)
                        .frame(width: 34, height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Theme.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Theme.border, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(signatureSize <= 0.30)

                // Slider
                Slider(value: $signatureSize, in: 0.25 ... 2.20, step: 0.05)
                    .tint(Theme.primary)

                // Stepper + (Increase)
                Button {
                    adjustSignatureSize(by: 0.10)
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(signatureSize >= 2.15 ? Theme.placeholder : Theme.titleText)
                        .frame(width: 34, height: 34)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Theme.card)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(Theme.border, lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .disabled(signatureSize >= 2.15)
            }

            // Interactive hint
            Text(localization.localized("resize_hint"))
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.secondaryText)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassCard(cornerRadius: 12, hasShadow: false)
    }


    private func sizePresetPill(label: String, scale: Double) -> some View {
        let isSelected = abs(signatureSize - scale) < 0.12
        return Button {
            withAnimation(.spring(response: 0.25)) {
                signatureSize = scale
            }
            HapticFeedback.selection()
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? Theme.onPrimary : Theme.titleText)
                .frame(width: 28, height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isSelected ? Theme.primary : Theme.card)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(isSelected ? Theme.primaryDark : Theme.border, lineWidth: 1)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    private func adjustSignatureSize(by delta: Double) {
        let newSize = min(max(signatureSize + delta, 0.25), 2.20)
        withAnimation(.spring(response: 0.25)) {
            signatureSize = (newSize * 20).rounded() / 20
        }
        HapticFeedback.selection()
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
        guard let img = vm.signatureImage, img.size.height > 0 else { return }
        let imgAspect = img.size.width / img.size.height
        let pageAspect = vm.currentPageAspectRatio
        let v = CGFloat(signatureSize)
        let baseW: CGFloat = 0.32
        let w = clamp(baseW * v, min: 0.08, max: 0.90)
        let h = clamp(w * pageAspect / imgAspect, min: 0.025, max: 0.85)
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
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(displayName)
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.titleText)
                        .lineLimit(1)
                }

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
