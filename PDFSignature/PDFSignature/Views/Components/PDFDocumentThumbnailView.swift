//
//  PDFDocumentThumbnailView.swift
//  PDFSignature
//

import PDFKit
import SwiftUI
import UIKit

struct PDFDocumentThumbnailView: View {
    let doc: SignedDocumentModel
    var width: CGFloat = 52
    var height: CGFloat = 60
    var cornerRadius: CGFloat = 12

    @State private var thumbnail: UIImage?
    private static let cache = NSCache<NSURL, UIImage>()

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Theme.pdfRed.opacity(0.14), Theme.pdfRed.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(Theme.pdfRed.opacity(0.22), lineWidth: 0.8)
                }

            if let thumbnail {
                Image(uiImage: thumbnail)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Theme.border.opacity(0.5), lineWidth: 0.5)
                    }
            } else {
                VStack(spacing: 3) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: width * 0.42, weight: .semibold))
                        .foregroundStyle(Theme.pdfRed)

                    Text("PDF")
                        .font(.system(size: max(8, width * 0.17), weight: .heavy, design: .rounded))
                        .foregroundStyle(Theme.pdfRed)
                        .tracking(0.6)
                }
            }
        }
        .frame(width: width, height: height)
        .task(id: doc.id) {
            loadThumbnail()
        }
    }

    private func loadThumbnail() {
        let url = doc.fileURL
        let nsURL = url as NSURL
        if let cached = Self.cache.object(forKey: nsURL) {
            self.thumbnail = cached
            return
        }

        Task.detached(priority: .userInitiated) {
            guard FileManager.default.fileExists(atPath: url.path),
                  let pdf = PDFDocument(url: url),
                  let rendered = PDFManager.renderPageThumbnail(document: pdf, pageIndex: 0, maxWidth: 140) else {
                return
            }
            Self.cache.setObject(rendered, forKey: nsURL)
            await MainActor.run {
                self.thumbnail = rendered
            }
        }
    }
}
