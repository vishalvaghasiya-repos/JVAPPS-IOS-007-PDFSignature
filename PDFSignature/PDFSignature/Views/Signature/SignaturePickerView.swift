//
//  SignaturePickerView.swift
//  PDFSignature
//

import SwiftData
import SwiftUI

struct SignaturePickerView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \SignatureRecord.createdAt, order: .reverse) private var records: [SignatureRecord]
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var localization = LocalizationManager.shared

    var onPick: (SignatureModel) -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.primaryGradient.ignoresSafeArea()

                Group {
                    if records.isEmpty {
                        ContentUnavailableView(
                            localization.localized("no_signatures_yet"),
                            systemImage: "signature",
                            description: Text(localization.localized("create_signature_desc"))
                        )
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 12) {
                                ForEach(records) { record in
                                    let model = SignatureModel(entity: record)
                                    Button {
                                        onPick(model)
                                        HapticFeedback.light()
                                    } label: {
                                        HStack(spacing: 14) {
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
                                            .frame(width: 64, height: 48)

                                            Text(record.name)
                                                .font(.system(.body, design: .rounded).weight(.semibold))
                                                .foregroundStyle(Theme.primaryText)

                                            Spacer()

                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 20))
                                                .foregroundStyle(Theme.primary.opacity(0.8))
                                        }
                                        .padding(14)
                                        .glassCard(cornerRadius: 12, hasShadow: false)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                        }
                        .scrollIndicators(.hidden)
                    }
                }
            }
            .navigationTitle(localization.localized("choose_signature"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Theme.background, for: .navigationBar)
            .tint(Theme.primary)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(localization.localized("choose_signature"))
                        .font(.system(.headline, design: .rounded).weight(.bold))
                        .foregroundStyle(Theme.titleText)
                }

                ToolbarItem(placement: .cancellationAction) {
                    Button(localization.localized("close")) { dismiss() }
                        .foregroundStyle(Theme.primary)
                }
            }
        }
    }
}
