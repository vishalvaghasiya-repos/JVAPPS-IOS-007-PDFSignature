//
//  LanguageSelectionView.swift
//  eSignPDF
//

import SwiftUI

struct LanguageSelectionView: View {
    @ObservedObject private var localization = LocalizationManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredLanguages: [AppLanguage] {
        if searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return AppLanguage.allCases
        }
        let query = searchText.lowercased()
        return AppLanguage.allCases.filter {
            $0.nativeTitle.lowercased().contains(query) ||
            $0.englishTitle.lowercased().contains(query) ||
            $0.code.lowercased().contains(query)
        }
    }

    var body: some View {
        ZStack {
            Theme.primaryGradient
                .ignoresSafeArea()

            VStack(spacing: 16) {
                // Search Bar
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(Theme.secondaryText)
                    TextField(localization.localized("search_language"), text: $searchText)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .foregroundStyle(Theme.primaryText)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Theme.secondaryText)
                        }
                    }
                }
                .padding(14)
                .glassCard(cornerRadius: 16)
                .padding(.horizontal, 20)
                .padding(.top, 8)

                // Languages List
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 10) {
                        ForEach(filteredLanguages) { lang in
                            let isSelected = (localization.currentLanguage == lang)
                            Button {
                                localization.setLanguage(lang)
                            } label: {
                                HStack(spacing: 14) {
                                    // Flag badge
                                    Text(lang.flag)
                                        .font(.system(size: 26))
                                        .frame(width: 44, height: 44)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(Theme.lightBackground)
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .stroke(Theme.border, lineWidth: 0.8)
                                                }
                                        )

                                    // Titles
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(lang.nativeTitle)
                                            .font(.system(.body, design: .rounded).weight(.semibold))
                                            .foregroundStyle(Theme.primaryText)

                                        Text(lang.englishTitle)
                                            .font(.system(.caption, design: .rounded))
                                            .foregroundStyle(Theme.secondaryText)
                                    }

                                    Spacer()

                                    // Checkmark indicator
                                    ZStack {
                                        Circle()
                                            .fill(isSelected ? Theme.primary : Color.clear)
                                            .frame(width: 24, height: 24)

                                        if isSelected {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12, weight: .bold))
                                                .foregroundStyle(.white)
                                        } else {
                                            Circle()
                                                .stroke(Theme.border, lineWidth: 1.5)
                                                .frame(width: 24, height: 24)
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .glassCard(cornerRadius: 18)
                                .overlay {
                                    if isSelected {
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(Theme.primary.opacity(0.4), lineWidth: 1.5)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                }
                .scrollIndicators(.hidden)
            }
        }
        .navigationTitle(localization.localized("select_language"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .tint(Theme.primary)
    }
}
