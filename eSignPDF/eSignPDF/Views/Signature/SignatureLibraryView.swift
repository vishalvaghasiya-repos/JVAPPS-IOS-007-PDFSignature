//
//  SignatureLibraryView.swift
//  eSignPDF
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

    @StateObject private var vm = SignatureViewModel()
    @State private var renameText = ""
    @State private var bannerIsLoaded = false
    @State private var bannerHeight: CGFloat = 0

    var body: some View {
        ZStack {
            Theme.primaryGradient.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 14) {
                    if vm.signatures.isEmpty {
                        ContentUnavailableView(
                            "No signatures",
                            systemImage: "signature",
                            description: Text("Tap the '+' button above to create one.")
                        )
                        .padding(.top, 48)
                    }
                    ForEach(vm.signatures) { sig in
                        HStack(spacing: 14) {
                            if let img = sig.loadImage() {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 44)
                                    .padding(6)
                                    .background(RoundedRectangle(cornerRadius: 10).fill(Color(white: 0.93)))
                            }
                            VStack(alignment: .leading, spacing: 4) {
                                Text(sig.name)
                                    .font(.system(.body, design: .rounded).weight(.semibold))
                                Text(sig.createdAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(.caption, design: .rounded))
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Menu {
                                Button("Rename") {
                                    vm.renameTarget = sig
                                    renameText = sig.name
                                }
                                Button("Delete", role: .destructive) {
                                    vm.delete(sig)
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.system(size: 22))
                                    .foregroundStyle(Theme.primaryText)
                            }
                        }
                        .padding(14)
                        .glassCard(cornerRadius: 18)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
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
        .navigationTitle("Signatures")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(colorScheme == .dark ? Color.black.opacity(0.92) : Color(uiColor: .systemBackground), for: .navigationBar)
        .toolbarColorScheme(colorScheme == .dark ? .dark : .light, for: .navigationBar)
        .tint(.primary)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    router.push(.newSignature, on: appState.selectedTab)
                } label: {
                    Image(systemName: "plus")
                }
                .tint(Theme.primaryText)
            }
        }
        .alert("Rename signature", isPresented: Binding(
            get: { vm.renameTarget != nil },
            set: { if !$0 { vm.renameTarget = nil } }
        )) {
            TextField("Name", text: $renameText)
            Button("Cancel", role: .cancel) { vm.renameTarget = nil }
            Button("Save") {
                vm.newName = renameText
                vm.rename()
            }
        } message: {
            Text("Give this signature a memorable name.")
        }
        .alert("Error", isPresented: Binding(
            get: { vm.errorMessage != nil },
            set: { if !$0 { vm.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { vm.errorMessage = nil }
        } message: {
            Text(vm.errorMessage ?? "")
        }
        .onAppear { vm.attach(context: modelContext) }
    }
}
