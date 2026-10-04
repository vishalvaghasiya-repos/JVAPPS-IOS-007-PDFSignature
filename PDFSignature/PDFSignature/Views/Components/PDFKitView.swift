//
//  PDFKitView.swift
//  PDFSignature
//

import PDFKit
import SwiftUI

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument

    func makeUIView(context: Context) -> PDFView {
        let view = PDFView()
        view.document = document
        view.autoScales = true
        view.displayMode = .singlePageContinuous
        view.displayDirection = .vertical
        view.backgroundColor = UIColor.appBackground
        DispatchQueue.main.async {
            view.autoScales = true
            view.subviews.compactMap { $0 as? UIScrollView }.forEach {
                $0.showsVerticalScrollIndicator = false
                $0.showsHorizontalScrollIndicator = false
            }
        }
        return view
    }

    func updateUIView(_ uiView: PDFView, context: Context) {
        if uiView.document !== document {
            uiView.document = document
            DispatchQueue.main.async {
                uiView.autoScales = true
            }
        }
    }
}
