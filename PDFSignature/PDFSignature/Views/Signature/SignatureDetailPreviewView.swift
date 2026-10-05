//
//  SignatureDetailPreviewView.swift
//  PDFSignature
//

import Photos
import SwiftData
import SwiftUI
import UIKit

struct SignatureDetailPreviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @ObservedObject private var localization = LocalizationManager.shared

    let signature: SignatureModel
    var onDeleted: (() -> Void)? = nil

    @State private var previewBackground: PreviewBackgroundMode = .checkerboard
    @State private var showShareSheet = false
    @State private var isSaving = false
    @State private var toastMessage: String?
    @State private var showToast = false
    @State private var showRenameAlert = false
    @State private var renameText = ""
    @State private var currentName: String = ""
    @State private var alertError: String?

    enum PreviewBackgroundMode: String, CaseIterable, Identifiable {
        case checkerboard = "Checkerboard"
        case white = "White"
        case dark = "Dark"

        var id: String { rawValue }

        var iconName: String {
            switch self {
            case .checkerboard: return "checkerboard.rectangle"
            case .white: return "sun.max.fill"
            case .dark: return "moon.fill"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.primaryGradient.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        previewCard
                            .padding(.top, 8)

                        backgroundSelector

                        infoCard

                        actionButtons
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)

                if showToast, let toastMessage {
                    VStack {
                        Spacer()
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.white)
                                .font(.system(size: 16, weight: .bold))
                            Text(toastMessage)
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(Capsule().fill(Color.black.opacity(0.88)))
                        .shadow(color: .black.opacity(0.25), radius: 10, x: 0, y: 5)
                        .padding(.bottom, 24)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle(currentName.isEmpty ? signature.name : currentName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(currentName.isEmpty ? signature.name : currentName)
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

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showShareSheet = true
                        } label: {
                            Label(localization.localized("share_png"), systemImage: "square.and.arrow.up")
                        }

                        Button {
                            saveToPhotos()
                        } label: {
                            Label(localization.localized("save_to_photos"), systemImage: "arrow.down.to.line")
                        }

                        Button {
                            renameText = currentName.isEmpty ? signature.name : currentName
                            showRenameAlert = true
                        } label: {
                            Label(localization.localized("rename"), systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            deleteSignature()
                        } label: {
                            Label(localization.localized("delete"), systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18))
                            .foregroundStyle(Theme.primary)
                    }
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let shareItem = prepareShareItem() {
                    SignatureShareActivityView(activityItems: [shareItem])
                }
            }
            .alert(localization.localized("rename_signature"), isPresented: $showRenameAlert) {
                TextField(localization.localized("signature_name"), text: $renameText)
                Button(localization.localized("cancel"), role: .cancel) {}
                Button(localization.localized("save")) {
                    applyRename()
                }
            } message: {
                Text(localization.localized("rename_signature_desc"))
            }
            .alert(localization.localized("error"), isPresented: Binding(
                get: { alertError != nil },
                set: { if !$0 { alertError = nil } }
            )) {
                Button(localization.localized("ok"), role: .cancel) { alertError = nil }
            } message: {
                Text(alertError ?? "")
            }
            .onAppear {
                currentName = signature.name
            }
        }
    }

    // MARK: - Preview Card with Clear Background Indicator
    private var previewCard: some View {
        ZStack {
            Group {
                switch previewBackground {
                case .checkerboard:
                    CheckerboardView(squareSize: 12, lightColor: Color(white: 0.96), darkColor: Color(white: 0.88))
                case .white:
                    Color.white
                case .dark:
                    Color(white: 0.12)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            if let ui = signature.loadImage() {
                Image(uiImage: ui)
                    .resizable()
                    .scaledToFit()
                    .padding(24)
            } else {
                Text("No image")
                    .foregroundStyle(Theme.secondaryText)
            }

            VStack {
                HStack {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .bold))
                        Text(localization.localized("transparent_png"))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundStyle(Theme.button)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(.ultraThinMaterial))
                    .overlay(Capsule().stroke(Theme.border, lineWidth: 0.8))

                    Spacer()
                }
                Spacer()
            }
            .padding(14)
        }
        .frame(height: 240)
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Theme.border, lineWidth: 1)
        )
        .shadow(color: Theme.cardShadow, radius: 10, x: 0, y: 4)
    }

    // MARK: - Background Selector
    private var backgroundSelector: some View {
        HStack(spacing: 8) {
            ForEach(PreviewBackgroundMode.allCases) { mode in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        previewBackground = mode
                    }
                    HapticFeedback.selection()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: mode.iconName)
                            .font(.system(size: 12))
                        Text(mode.rawValue)
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .foregroundStyle(previewBackground == mode ? Color.white : Theme.primaryText)
                    .background {
                        if previewBackground == mode {
                            Capsule().fill(Theme.buttonGradient)
                        } else {
                            Capsule().fill(Theme.lightBackground)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .glassCard(cornerRadius: 16)
    }

    // MARK: - Info Card
    private var infoCard: some View {
        VStack(spacing: 12) {
            infoRow(title: localization.localized("signature_name"), value: currentName.isEmpty ? signature.name : currentName)
            Divider()
            infoRow(title: "Format", value: "PNG (Transparent Alpha)")
            Divider()
            if let ui = signature.loadImage() {
                infoRow(title: "Resolution", value: "\(Int(ui.size.width * ui.scale)) × \(Int(ui.size.height * ui.scale)) px")
                Divider()
            }
            infoRow(title: "Created", value: signature.createdAt.formatted(date: .abbreviated, time: .shortened))
        }
        .padding(16)
        .glassCard(cornerRadius: 18)
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Theme.secondaryText)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.primaryText)
        }
    }

    // MARK: - Action Buttons (Share PNG & Save to Photos)
    private var actionButtons: some View {
        VStack(spacing: 12) {
            // Share PNG Button
            Button {
                showShareSheet = true
                HapticFeedback.light()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 16, weight: .bold))
                    Text(localization.localized("share_png"))
                        .font(.system(.body, design: .rounded).weight(.bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(Theme.buttonGradient)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .shadow(color: Theme.button.opacity(0.35), radius: 8, x: 0, y: 4)
            }
            .buttonStyle(.plain)

            // Save to Photos Button (Clear PNG)
            Button {
                saveToPhotos()
            } label: {
                HStack(spacing: 8) {
                    if isSaving {
                        ProgressView()
                            .tint(Theme.button)
                    } else {
                        Image(systemName: "arrow.down.to.line.circle.fill")
                            .font(.system(size: 17))
                    }
                    Text(localization.localized("save_to_photos"))
                        .font(.system(.body, design: .rounded).weight(.semibold))
                }
                .foregroundStyle(Theme.button)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Theme.card)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Theme.button.opacity(0.35), lineWidth: 1.2)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isSaving)
        }
    }

    // MARK: - Actions
    private func prepareShareItem() -> Any? {
        // Prefer file URL directly so iOS shares the raw PNG file with alpha channel
        if FileManager.default.fileExists(atPath: signature.imageURL.path) {
            return signature.imageURL
        } else if let ui = signature.loadImage(), let data = ui.pngData() {
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(signature.name.replacingOccurrences(of: " ", with: "_")).png")
            try? data.write(to: tempURL)
            return tempURL
        }
        return nil
    }

    private func saveToPhotos() {
        guard let data = (try? Data(contentsOf: signature.imageURL)) ?? signature.loadImage()?.pngData() else {
            alertError = "Could not load signature PNG data."
            return
        }

        isSaving = true
        Task {
            let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
            guard status == .authorized || status == .limited else {
                await MainActor.run {
                    isSaving = false
                    alertError = "Photo library permission is needed to save the signature. Please enable it in Settings."
                }
                return
            }

            do {
                try await PHPhotoLibrary.shared().performChanges {
                    let request = PHAssetCreationRequest.forAsset()
                    request.addResource(with: .photo, data: data, options: nil)
                }
                await MainActor.run {
                    isSaving = false
                    toastMessage = localization.localized("saved_to_photos_success")
                    HapticFeedback.success()
                    withAnimation(.spring()) {
                        showToast = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                        withAnimation(.spring()) {
                            showToast = false
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    alertError = "Failed to save: \(error.localizedDescription)"
                    HapticFeedback.warning()
                }
            }
        }
    }

    private func applyRename() {
        let trimmed = renameText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        do {
            try SignatureManager.renameSignature(context: modelContext, id: signature.id, newName: trimmed)
            currentName = trimmed
            HapticFeedback.success()
        } catch {
            alertError = error.localizedDescription
        }
    }

    private func deleteSignature() {
        do {
            try SignatureManager.deleteSignature(context: modelContext, id: signature.id)
            HapticFeedback.light()
            onDeleted?()
            dismiss()
        } catch {
            alertError = error.localizedDescription
        }
    }
}

// MARK: - Reusable Activity View Controller
struct SignatureShareActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
