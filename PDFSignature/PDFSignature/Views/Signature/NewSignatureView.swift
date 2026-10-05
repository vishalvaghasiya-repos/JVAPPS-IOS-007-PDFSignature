//
//  NewSignatureView.swift
//  PDFSignature
//

import PencilKit
import PhotosUI
import SwiftData
import SwiftUI
import UIKit
import AdsManagerKit
import GoogleMobileAds
struct NewSignatureView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var localization = LocalizationManager.shared
    @StateObject private var vm = SignatureViewModel()

    enum SignatureTab: Int, CaseIterable, Identifiable {
        case draw = 0
        case type = 1
        case photo = 2

        var id: Int { rawValue }

        func title(loc: LocalizationManager) -> String {
            switch self {
            case .draw: return loc.localized("draw")
            case .type: return loc.localized("type")
            case .photo: return loc.localized("scan_photo")
            }
        }

        var systemIcon: String {
            switch self {
            case .draw: return "hand.draw.fill"
            case .type: return "character.cursor.ibeam"
            case .photo: return "camera.metering.matrix"
            }
        }
    }

    @State private var selectedTab: SignatureTab = .draw

    // Common
    @State private var signatureName = "My signature"
    
    @State private var nativeIsLoaded = false
    @State private var nativeHeight: CGFloat = 170
    private let nativeAdView: NativeAdView = {
        let bundle = Bundle(for: NativeAdView.self)
        guard let adView = bundle.loadNibNamed("NativeAdsMedium", owner: nil, options: nil)?.first as? NativeAdView else {
            fatalError("Could not load NativeAdsMedium.xib")
        }
        return adView
    }()
    // Draw Tab State
    @State private var drawing = PKDrawing()
    @State private var drawColor: Color = .black
    @State private var drawUIColor: UIColor = .black

    // Type Tab State
    @State private var typedText = ""
    @State private var selectedFontName = "Zapfino"
    @State private var typeColor: Color = .black
    @State private var typeUIColor: UIColor = .black

    private let calligraphyFonts = [
        "Zapfino",
        "Snell Roundhand",
        "Bradley Hand",
        "Noteworthy-Bold",
        "SavoyeLetPlain",
        "MarkerFelt-Wide",
        "Papyrus"
    ]

    // Photo / Scan Tab State
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var rawPhoto: UIImage?
    @State private var processedPhoto: UIImage?
    @State private var showCameraPicker = false
    @State private var removeBackground = true
    @State private var bgSensitivity: Double = 0.78
    @State private var invertColors = false
    @State private var photoTint: Color = .black
    @State private var photoUITint: UIColor? = nil
    @State private var preserveOriginalColor = true
    @State private var isProcessingPhoto = false

    private var colorPresets: [(color: Color, ui: UIColor)] {
        [
            (.black, .black),
            (Color(red: 0.05, green: 0.22, blue: 0.55), UIColor(red: 0.05, green: 0.22, blue: 0.55, alpha: 1.0)),
            (Theme.primary, UIColor.appPrimary),
            (.blue, .systemBlue),
            (Theme.pdfRed, UIColor.appPDFRed),
            (Theme.success, UIColor.appSuccess),
        ]
    }

    var body: some View {
        ZStack {
            Theme.primaryGradient.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {
                    // Modern Tab Top Selection
                    tabPicker
                        .padding(.top, 4)

                    switch selectedTab {
                    case .draw:
                        drawSection
                    case .type:
                        typeSection
                    case .photo:
                        photoSection
                    }

                    // Signature Name Card
                    signatureNameCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 36)
            }
            .scrollIndicators(.hidden)
        }
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
        .navigationTitle(localization.localized("new_signature"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Theme.background, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .tint(Theme.primary)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(localization.localized("new_signature"))
                    .font(.system(.headline, design: .rounded).weight(.bold))
                    .foregroundStyle(Theme.titleText)
            }

            ToolbarItem(placement: .confirmationAction) {
                Button(localization.localized("save")) {
                    save()
                }
                .fontWeight(.bold)
                .foregroundStyle(Theme.primary)
                .disabled(!canSave)
            }
        }
        .onAppear {
            vm.attach(context: modelContext)
            drawUIColor = resolvedColor(from: drawColor)
            typeUIColor = resolvedColor(from: typeColor)
        }
        .onChange(of: drawColor) { _, newColor in
            drawUIColor = resolvedColor(from: newColor)
        }
        .onChange(of: typeColor) { _, newColor in
            typeUIColor = resolvedColor(from: newColor)
        }
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run {
                        self.rawPhoto = image.fixedOrientation()
                        triggerPhotoProcessing()
                    }
                }
            }
        }
        .sheet(isPresented: $showCameraPicker) {
            CameraPickerView { captured in
                self.rawPhoto = captured
                triggerPhotoProcessing()
            }
        }
    }

    // MARK: - Tab Picker
    private var tabPicker: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(SignatureTab.allCases) { tab in
                        let isSelected = selectedTab == tab
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                selectedTab = tab
                                proxy.scrollTo(tab.id, anchor: .center)
                            }
                            HapticFeedback.selection()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: tab.systemIcon)
                                    .font(.system(size: 14, weight: .semibold))
                                Text(tab.title(loc: localization))
                                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                    .lineLimit(1)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background {
                                if isSelected {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Theme.card)
                                        .shadow(
                                            color: colorScheme == .dark ? Color.black.opacity(0.3) : Theme.cardShadow,
                                            radius: 6,
                                            x: 0,
                                            y: 2
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(Theme.lightBackground)
                                }
                            }
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(
                                        isSelected ? Theme.primary : Theme.border,
                                        lineWidth: isSelected ? 1.4 : 0.8
                                    )
                            }
                            .foregroundStyle(isSelected ? Theme.primary : Theme.secondaryText)
                        }
                        .buttonStyle(.plain)
                        .id(tab.id)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 4)
            }
            .scrollBounceBehavior(.basedOnSize, axes: .horizontal)
            .padding(.horizontal, -20)
        }
    }

    // MARK: - Draw Section
    private var drawSection: some View {
        VStack(spacing: 14) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.card)

                SignatureCanvasView(
                    drawing: $drawing,
                    inkColor: drawUIColor
                )
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                // Canvas Actions
                HStack(spacing: 8) {
                    Button {
                        drawing = PKDrawing()
                        HapticFeedback.light()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                            Text(localization.localized("clear"))
                        }
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundStyle(Theme.pdfRed)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Theme.card).shadow(color: Color.black.opacity(0.08), radius: 4))
                    }
                }
                .padding(12)
            }
            .frame(maxWidth: .infinity)
            .frame(height: min(UIScreen.main.bounds.height * 0.44, 380))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Theme.border, lineWidth: 1.2)
            }

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
            
            // Draw Ink Color Picker
            colorPaletteRow(
                title: localization.localized("signature_color"),
                selectedColor: $drawColor,
                selectedUIColor: $drawUIColor
            )
        }
    }

    // MARK: - Type Section
    private var typeSection: some View {
        VStack(spacing: 16) {
            // Live Preview Card
            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Theme.card)
                    .overlay {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .stroke(Theme.border, lineWidth: 1.2)
                    }

                if typedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "character.cursor.ibeam")
                            .font(.system(size: 36))
                            .foregroundStyle(Theme.secondaryText.opacity(0.5))
                        Text(localization.localized("type_your_signature"))
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Theme.secondaryText)
                    }
                } else {
                    Text(typedText)
                        .font(customFont(named: selectedFontName, size: 48))
                        .foregroundStyle(typeColor)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.4)
                        .padding(24)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 220)

            // Text Input Field
            HStack(spacing: 10) {
                Image(systemName: "signature")
                    .foregroundStyle(Theme.primary)
                TextField(localization.localized("type_your_signature"), text: $typedText)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .foregroundStyle(Theme.primaryText)
                    .font(.system(.body, design: .rounded))

                if !typedText.isEmpty {
                    Button {
                        typedText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
            }
            .padding(14)
            .glassCard(cornerRadius: 16)

            // Font Style Picker
            VStack(alignment: .leading, spacing: 10) {
                Text(localization.localized("choose_font_style"))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.primaryText)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(calligraphyFonts, id: \.self) { fontName in
                            let isSelected = selectedFontName == fontName
                            Button {
                                selectedFontName = fontName
                                HapticFeedback.selection()
                            } label: {
                                VStack(spacing: 6) {
                                    Text("Signature")
                                        .font(customFont(named: fontName, size: 24))
                                        .foregroundStyle(isSelected ? Theme.primary : Theme.primaryText)
                                        .frame(height: 40)

                                    Text(friendlyFontName(fontName))
                                        .font(.system(.caption2, design: .rounded).weight(.medium))
                                        .foregroundStyle(Theme.secondaryText)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 10)
                                .glassCard(cornerRadius: 14)
                                .overlay {
                                    if isSelected {
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Theme.primary, lineWidth: 1.8)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .scrollIndicators(.hidden)
            }

            // Type Ink Color Picker
            colorPaletteRow(
                title: localization.localized("ink_color"),
                selectedColor: $typeColor,
                selectedUIColor: $typeUIColor
            )
        }
    }

    // MARK: - Photo Section (With Background Removal)
    private var photoSection: some View {
        VStack(spacing: 16) {
            if let displayImage = (removeBackground ? processedPhoto : rawPhoto) {
                // Interactive Preview with Checkerboard for Transparency
                ZStack {
                    if removeBackground {
                        CheckerboardView()
                            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    } else {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(Theme.card)
                    }

                    Image(uiImage: displayImage)
                        .resizable()
                        .scaledToFit()
                        .padding(16)

                    if isProcessingPhoto {
                        ProgressView()
                            .scaleEffect(1.2)
                            .padding(12)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 240)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Theme.border, lineWidth: 1.2)
                }

                // Controls for Background Removal & Adjustments
                VStack(spacing: 14) {
                    Toggle(localization.localized("remove_background"), isOn: $removeBackground)
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .foregroundStyle(Theme.primaryText)
                        .tint(Theme.button)
                        .onChange(of: removeBackground) { _, _ in
                            triggerPhotoProcessing()
                        }

                    if removeBackground {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(localization.localized("bg_sensitivity"))
                                    .font(.system(.caption, design: .rounded).weight(.semibold))
                                    .foregroundStyle(Theme.secondaryText)
                                Spacer()
                                Text("\(Int(bgSensitivity * 100))%")
                                    .font(.system(.caption, design: .rounded).monospacedDigit().weight(.bold))
                                    .foregroundStyle(Theme.primary)
                            }

                            Slider(value: $bgSensitivity, in: 0.35...0.95, step: 0.02)
                                .tint(Theme.button)
                                .onChange(of: bgSensitivity) { _, _ in
                                    triggerPhotoProcessing()
                                }
                        }

                        // Ink Color Tint Option
                        HStack {
                            Text(localization.localized("ink_color"))
                                .font(.system(.caption, design: .rounded).weight(.semibold))
                                .foregroundStyle(Theme.secondaryText)
                            Spacer()
                            Button(preserveOriginalColor ? "Original Ink" : "Custom Tint") {
                                preserveOriginalColor.toggle()
                                triggerPhotoProcessing()
                            }
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(Theme.primary)
                        }

                        if !preserveOriginalColor {
                            HStack(spacing: 10) {
                                ForEach(Array(colorPresets.enumerated()), id: \.offset) { _, preset in
                                    Button {
                                        photoTint = preset.color
                                        photoUITint = preset.ui
                                        triggerPhotoProcessing()
                                    } label: {
                                        Circle()
                                            .fill(preset.color)
                                            .frame(width: 28, height: 28)
                                            .overlay {
                                                Circle()
                                                    .stroke(
                                                        preset.color == photoTint ? Color.primary : Color.clear,
                                                        lineWidth: 2
                                                    )
                                            }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    // Rotate & Change Image buttons
                    HStack(spacing: 12) {
                        Button {
                            rotatePhoto()
                        } label: {
                            Label("Rotate", systemImage: "rotate.right")
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundStyle(Theme.primary)
                        }

                        Spacer()

                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            Label("Choose Another", systemImage: "photo")
                                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(16)
                .glassCard(cornerRadius: 18)

            } else {
                // Empty Photo Selector Card
                VStack(spacing: 20) {
                    Image(systemName: "camera.viewfinder")
                        .font(.system(size: 48, weight: .light))
                        .foregroundStyle(Theme.primary)

                    VStack(spacing: 6) {
                        Text(localization.localized("bg_removed_auto"))
                            .font(.system(.headline, design: .rounded).weight(.semibold))
                            .foregroundStyle(Theme.primaryText)
                        Text("Pick a photo of your signature from paper or take a picture. We automatically remove the background!")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Theme.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }

                    HStack(spacing: 14) {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            HStack(spacing: 8) {
                                Image(systemName: "photo.on.rectangle")
                                Text(localization.localized("pick_from_photos"))
                            }
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.button)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        Button {
                            showCameraPicker = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                Text(localization.localized("take_photo"))
                            }
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundStyle(Theme.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Theme.lightBackground)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Theme.border, lineWidth: 1)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(28)
                .glassCard(cornerRadius: 22)
            }
        }
    }

    // MARK: - Signature Name Field
    private var signatureNameCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(localization.localized("signature_name"))
                .font(.system(.caption, design: .rounded).weight(.semibold))
                .foregroundStyle(Theme.secondaryText)

            HStack {
                TextField(localization.localized("signature_name"), text: $signatureName)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .rounded).weight(.medium))
                    .foregroundStyle(Theme.primaryText)

                if !signatureName.isEmpty {
                    Button {
                        signatureName = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Theme.secondaryText)
                    }
                }
            }
            .padding(14)
            .glassCard(cornerRadius: 14)
        }
    }

    // MARK: - Color Palette Row
    private func colorPaletteRow(
        title: String,
        selectedColor: Binding<Color>,
        selectedUIColor: Binding<UIColor>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                ColorPicker("", selection: selectedColor, supportsOpacity: false)
                    .labelsHidden()
            }

            HStack(spacing: 12) {
                ForEach(Array(colorPresets.enumerated()), id: \.offset) { _, preset in
                    Button {
                        selectedColor.wrappedValue = preset.color
                        selectedUIColor.wrappedValue = preset.ui
                        HapticFeedback.selection()
                    } label: {
                        Circle()
                            .fill(preset.color)
                            .frame(width: 30, height: 30)
                            .overlay {
                                Circle()
                                    .stroke(
                                        preset.color == selectedColor.wrappedValue ? Color.primary : Color.clear,
                                        lineWidth: 2.2
                                    )
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .glassCard(cornerRadius: 16)
    }

    // MARK: - Validation & Save
    private var canSave: Bool {
        switch selectedTab {
        case .draw:
            return drawing.bounds.width > 2 && drawing.bounds.height > 2
        case .type:
            return !typedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case .photo:
            return (removeBackground ? processedPhoto : rawPhoto) != nil
        }
    }

    private func save() {
        let finalImage: UIImage?
        let finalName = signatureName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? localization.localized("signatures")
            : signatureName

        switch selectedTab {
        case .draw:
            let bounds = drawing.bounds.insetBy(dx: -12, dy: -12)
            guard bounds.width > 1, bounds.height > 1 else { return }
            let raw = drawing.image(from: bounds, scale: UIScreen.main.scale)
            finalImage = normalizedSignatureImage(from: raw, inkColor: drawUIColor)

        case .type:
            finalImage = renderTextSignature(
                text: typedText,
                fontName: selectedFontName,
                color: typeUIColor
            )

        case .photo:
            finalImage = removeBackground ? processedPhoto : rawPhoto
        }

        guard let imageToSave = finalImage else { return }

        vm.saveDrawing(name: finalName, image: imageToSave)
        AdsManager.shared.showInterstitialIfAvailable()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            dismiss()
        }
    }

    // MARK: - Helpers
    private func triggerPhotoProcessing() {
        guard let source = rawPhoto else { return }
        isProcessingPhoto = true

        let thresh = CGFloat(bgSensitivity)
        let tint = preserveOriginalColor ? nil : photoUITint
        let invert = invertColors

        Task.detached(priority: .userInitiated) {
            let processed = SignatureBackgroundRemover.removeBackground(
                from: source,
                threshold: thresh,
                smoothness: 0.08,
                inkColor: tint,
                invert: invert,
                autoCrop: true
            )

            await MainActor.run {
                self.processedPhoto = processed
                self.isProcessingPhoto = false
            }
        }
    }

    private func rotatePhoto() {
        guard let current = rawPhoto else { return }
        UIGraphicsBeginImageContextWithOptions(CGSize(width: current.size.height, height: current.size.width), false, current.scale)
        if let ctx = UIGraphicsGetCurrentContext() {
            ctx.translateBy(x: current.size.height / 2, y: current.size.width / 2)
            ctx.rotate(by: .pi / 2)
            current.draw(in: CGRect(x: -current.size.width / 2, y: -current.size.height / 2, width: current.size.width, height: current.size.height))
            let rotated = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            if let rotated {
                self.rawPhoto = rotated
                triggerPhotoProcessing()
            }
        }
    }

    private func renderTextSignature(text: String, fontName: String, color: UIColor) -> UIImage {
        let cleanText = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Signature" : text
        let font = UIFont(name: fontName, size: 54) ?? UIFont.systemFont(ofSize: 54, weight: .semibold)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let attrString = NSAttributedString(string: cleanText, attributes: attributes)
        let textSize = attrString.size()
        let padding: CGFloat = 20
        let targetSize = CGSize(width: ceil(textSize.width + padding * 2), height: ceil(textSize.height + padding * 2))

        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = UIScreen.main.scale
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            attrString.draw(at: CGPoint(x: padding, y: padding))
        }
    }

    private func customFont(named: String, size: CGFloat) -> Font {
        Font.custom(named, size: size)
    }

    private func friendlyFontName(_ fontName: String) -> String {
        switch fontName {
        case "Zapfino": return "Classic Script"
        case "Snell Roundhand": return "Elegant"
        case "Bradley Hand": return "Casual Hand"
        case "Noteworthy-Bold": return "Modern Pen"
        case "SavoyeLetPlain": return "Calligraphy"
        case "MarkerFelt-Wide": return "Marker"
        case "Papyrus": return "Artistic"
        default: return fontName
        }
    }

    private func resolvedColor(from color: Color) -> UIColor {
        UIColor(color).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    }

    private func normalizedSignatureImage(from source: UIImage, inkColor: UIColor) -> UIImage {
        let fixed = inkColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        format.scale = source.scale
        let renderer = UIGraphicsImageRenderer(size: source.size, format: format)
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: source.size)
            source.draw(in: rect)
            ctx.cgContext.setBlendMode(.sourceIn)
            fixed.setFill()
            ctx.cgContext.fill(rect)
        }
    }
}
