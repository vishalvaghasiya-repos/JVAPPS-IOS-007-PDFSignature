//
//  SignedPDFPreviewView.swift
//  PDFSignature
//

import PDFKit
import SwiftUI
import UIKit
import AdsManagerKit

struct SignedPDFPreviewView: View {
    @Environment(\.colorScheme) private var colorScheme
    let document: SignedDocumentModel

    @State private var pdf: PDFDocument?
    @State private var showShare = false
    @State private var bannerIsLoaded = false
    @State private var bannerHeight: CGFloat = 50

    var body: some View {
        ZStack {
            Theme.background
                .ignoresSafeArea()

            if let pdf {
                PDFKitView(document: pdf)
                    .ignoresSafeArea(edges: .bottom)
            } else {
                ProgressView("Opening PDF…")
                    .tint(Theme.primary)
            }
        }
        .safeAreaInset(edge: .bottom) {
            BannerAdView(
                adType: .adaptive,
                isLoaded: $bannerIsLoaded,
                height: $bannerHeight
            )
            .frame(height: bannerIsLoaded ? bannerHeight : 50)
        }
        .navigationTitle(document.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar(.hidden, for: .tabBar)
        .tint(Theme.primary)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showShare = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(pdf == nil)
                .foregroundStyle(pdf == nil ? Theme.secondaryText.opacity(0.45) : Theme.primary)

                Menu {
                    Button("Copy path (debug)") {
                        UIPasteboard.general.string = document.fileURL.path
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundStyle(Theme.primary)
                }
            }
        }
        .onAppear {
            pdf = PDFDocument(url: document.fileURL)
        }
        .sheet(isPresented: $showShare) {
            ActivityView(activityItems: [document.fileURL])
        }
    }
}

private struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
